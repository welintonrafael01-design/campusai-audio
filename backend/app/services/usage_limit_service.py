from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException

from app.database.supabase_client import get_supabase_admin_client
from app.security.entitlements import (
    ProductCapability,
    entitlement_denial_detail,
    plan_capabilities,
)
from app.services.subscription_service import get_user_subscription


FREE_MONTHLY_USAGE_LIMITS = {
    "pdf_upload": 3,
    "chat_message": 10,
    "summary_generated": 3,
    "flashcards_generated": 1,
    "quiz_generated": 1,
}


PLAN_UPLOAD_LIMITS = {
    "free": 3,
    "student": 25,
    "teacher": 100,
    "accessibility": 15,
    "ultra": 999999,
    "institution": 100,
}

PLAN_CHAT_LIMITS = {
    "free": 10,
    "student": 300,
    "teacher": 1000,
    "accessibility": 200,
    "ultra": 999999,
    "institution": 1000,
}

PLAN_FLASHCARD_LIMITS = {
    "free": 20,
    "student": 200,
    "teacher": 1000,
    "accessibility": 100,
    "ultra": 999999,
    "institution": 1000,
}

PLAN_EXAM_LIMITS = {
    "free": 10,
    "student": 100,
    "teacher": 300,
    "accessibility": 80,
    "ultra": 999999,
    "institution": 300,
}


def get_plan_for_user(user_id: str) -> str:
    subscription = get_user_subscription(
        user_id=user_id,
    )

    plan = subscription.get("plan", "free")

    if plan not in PLAN_UPLOAD_LIMITS:
        return "free"

    return plan


def count_usage_today(
    *,
    user_id: str,
    event_type: str,
) -> int:
    client = get_supabase_admin_client()

    today = datetime.now(timezone.utc).date().isoformat()

    response = (
        client
        .table("user_usage_events")
        .select("id", count="exact")
        .eq("user_id", user_id)
        .eq("event_type", event_type)
        .gte("created_at", f"{today}T00:00:00+00:00")
        .execute()
    )

    return response.count or 0


def count_usage_this_month(
    *,
    user_id: str,
    event_type: str,
) -> int:
    client = get_supabase_admin_client()
    now = datetime.now(timezone.utc)
    month_start = datetime(
        now.year,
        now.month,
        1,
        tzinfo=timezone.utc,
    ).isoformat()

    response = (
        client
        .table("user_usage_events")
        .select("id", count="exact")
        .eq("user_id", user_id)
        .eq("event_type", event_type)
        .gte("created_at", month_start)
        .execute()
    )

    return response.count or 0



def count_usage_total(
    *,
    user_id: str,
    event_type: str,
) -> int:
    client = get_supabase_admin_client()

    response = (
        client
        .table("user_usage_events")
        .select("id", count="exact")
        .eq("user_id", user_id)
        .eq("event_type", event_type)
        .execute()
    )

    return response.count or 0


def register_usage_event(
    *,
    user_id: str,
    event_type: str,
    plan: str,
    metadata: dict | None = None,
) -> dict:
    client = get_supabase_admin_client()

    payload = {
        "user_id": user_id,
        "event_type": event_type,
        "plan": plan,
        "metadata": metadata or {},
    }

    response = (
        client
        .table("user_usage_events")
        .insert(payload)
        .execute()
    )

    if response.data:
        return response.data[0]

    return payload


def quota_denial_detail(
    *,
    event_type: str,
    limit: int,
    used: int,
) -> dict:
    return {
        "code": "monthly_quota_exceeded",
        "message": f"Has utilizado tus {limit} usos gratuitos de este mes.",
        "event_type": event_type,
        "period": "month",
        "limit": limit,
        "used": used,
        "required_plan": "student_pro",
        "cta": {
            "label": "Ver Student Pro",
            "plan": "student",
        },
    }


def _enforce_free_monthly_quota(
    *,
    user_id: str,
    plan: str,
    event_type: str,
) -> None:
    if plan != "free":
        return

    limit = FREE_MONTHLY_USAGE_LIMITS[event_type]
    used = count_usage_this_month(
        user_id=user_id,
        event_type=event_type,
    )
    if used >= limit:
        raise HTTPException(
            status_code=403,
            detail=quota_denial_detail(
                event_type=event_type,
                limit=limit,
                used=used,
            ),
        )


def enforce_pdf_upload_limit(
    *,
    user_id: str,
) -> str:
    plan = get_plan_for_user(user_id)

    _enforce_free_monthly_quota(
        user_id=user_id,
        plan=plan,
        event_type="pdf_upload",
    )

    if plan != "free":
        limit = PLAN_UPLOAD_LIMITS.get(plan, PLAN_UPLOAD_LIMITS["free"])
        used_today = count_usage_today(
            user_id=user_id,
            event_type="pdf_upload",
        )
        if used_today >= limit:
            raise HTTPException(
                status_code=403,
                detail=(
                    f"Tu plan {plan} permite {limit} PDFs por día. "
                    "Ya alcanzaste el límite de hoy."
                ),
            )

    return plan


def enforce_chat_limit(
    *,
    user_id: str,
) -> str:
    plan = get_plan_for_user(user_id)

    _enforce_free_monthly_quota(
        user_id=user_id,
        plan=plan,
        event_type="chat_message",
    )

    if plan != "free":
        limit = PLAN_CHAT_LIMITS.get(plan, PLAN_CHAT_LIMITS["free"])
        used_today = count_usage_today(
            user_id=user_id,
            event_type="chat_message",
        )
        if used_today >= limit:
            raise HTTPException(
                status_code=403,
                detail=(
                    f"Tu plan {plan} permite {limit} mensajes de chat por día. "
                    "Ya alcanzaste el límite de hoy."
                ),
            )

    return plan


def enforce_summary_limit(*, user_id: str) -> str:
    plan = enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.SUMMARY,
    )
    _enforce_free_monthly_quota(
        user_id=user_id,
        plan=plan,
        event_type="summary_generated",
    )
    return plan


def enforce_flashcard_limit(
    *,
    user_id: str,
    requested_amount: int,
) -> str:
    plan = enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.FLASHCARDS,
    )

    _enforce_free_monthly_quota(
        user_id=user_id,
        plan=plan,
        event_type="flashcards_generated",
    )

    limit = PLAN_FLASHCARD_LIMITS.get(
        plan,
        PLAN_FLASHCARD_LIMITS["free"],
    )

    if requested_amount > limit:
        raise HTTPException(
            status_code=403,
            detail=(
                f"Tu plan {plan} permite hasta {limit} flashcards por PDF. "
                f"Solicitaste {requested_amount}."
            ),
        )

    return plan


def enforce_exam_limit(
    *,
    user_id: str,
    requested_amount: int,
) -> str:
    plan = enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.EXAM_GENERATION,
    )

    return enforce_question_count_limit(
        user_id=user_id,
        requested_amount=requested_amount,
        plan=plan,
    )


def enforce_quiz_limit(
    *,
    user_id: str,
    requested_amount: int,
) -> str:
    plan = enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.QUIZ,
    )
    _enforce_free_monthly_quota(
        user_id=user_id,
        plan=plan,
        event_type="quiz_generated",
    )
    return enforce_question_count_limit(
        user_id=user_id,
        requested_amount=requested_amount,
        plan=plan,
    )


def enforce_question_count_limit(
    *,
    user_id: str,
    requested_amount: int,
    plan: str | None = None,
) -> str:
    resolved_plan = plan or get_plan_for_user(user_id)

    limit = PLAN_EXAM_LIMITS.get(
        resolved_plan,
        PLAN_EXAM_LIMITS["free"],
    )

    if requested_amount > limit:
        raise HTTPException(
            status_code=403,
            detail=(
                f"Tu plan {resolved_plan} permite hasta {limit} preguntas por evaluación. "
                f"Solicitaste {requested_amount}."
            ),
        )

    return resolved_plan


def enforce_voice_permission(*, user_id: str) -> str:
    """Require an active subscription that includes the voice experience."""
    return enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.VOICE_TUTOR,
    )


def enforce_audiobook_permission(*, user_id: str) -> str:
    """Gate new AudioBook generation without blocking owned playback."""
    return enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.AUDIOBOOK,
    )


def enforce_question_bank_permission(*, user_id: str) -> str:
    """Require a subscription that includes question-bank generation."""
    return enforce_plan_capability(
        user_id=user_id,
        capability=ProductCapability.QUESTION_BANK,
    )


def enforce_plan_capability(
    *,
    user_id: str,
    capability: ProductCapability,
) -> str:
    # get_plan_for_user already applies the server-side subscription status and
    # returns Free for unknown or inactive paid subscriptions.
    plan = get_plan_for_user(user_id)

    if capability not in plan_capabilities(plan, status="active"):
        raise HTTPException(
            status_code=403,
            detail=entitlement_denial_detail(capability=capability),
        )

    return plan


PLAN_EXPORT_PERMISSIONS = {
    "free": {
        "pdf": True,
        "docx": False,
        "pptx": False,
    },
    "student": {
        "pdf": True,
        "docx": True,
        "pptx": False,
        "xlsx": False,
    },
    "accessibility": {
        "pdf": True,
        "docx": True,
        "pptx": False,
        "xlsx": False,
    },
    "teacher": {
        "pdf": True,
        "docx": True,
        "pptx": True,
        "xlsx": True,
    },
    "ultra": {
        "pdf": True,
        "docx": True,
        "pptx": True,
        "xlsx": True,
    },
    "institution": {
        "pdf": True,
        "docx": True,
        "pptx": True,
        "xlsx": True,
    },
}


def enforce_export_permission(
    *,
    user_id: str,
    export_type: str,
) -> str:
    plan = get_plan_for_user(user_id)
    clean_export_type = export_type.strip().lower()

    permissions = PLAN_EXPORT_PERMISSIONS.get(
        plan,
        PLAN_EXPORT_PERMISSIONS["free"],
    )

    allowed = permissions.get(clean_export_type, False)

    if not allowed:
        raise HTTPException(
            status_code=403,
            detail=(
                f"Tu plan {plan} no permite exportar en formato "
                f"{clean_export_type.upper()}."
            ),
        )

    return plan


def get_usage_summary_for_user(
    *,
    user_id: str,
) -> dict:
    plan = get_plan_for_user(user_id)
    is_free = plan == "free"

    def period_count(event_type: str) -> int:
        counter = count_usage_this_month if is_free else count_usage_today
        return counter(user_id=user_id, event_type=event_type)

    def total_count(event_type: str) -> int:
        return count_usage_total(user_id=user_id, event_type=event_type)

    period = "month" if is_free else "day"
    pdf_used = period_count("pdf_upload")
    chat_used = period_count("chat_message")
    summary_used = period_count("summary_generated")
    flashcards_used = period_count("flashcards_generated")
    quiz_used = period_count("quiz_generated")
    exams_used = period_count("exam_generated")
    exports_used = period_count("export_generated")

    return {
        "user_id": user_id,
        "plan": plan,
        "quota_period": period,
        "totals": {
            "pdf_uploads": total_count("pdf_upload"),
            "chat_messages": total_count("chat_message"),
            "summaries_generated": total_count("summary_generated"),
            "flashcards_generated": total_count("flashcards_generated"),
            "quizzes_generated": total_count("quiz_generated"),
            "exams_generated": total_count("exam_generated"),
            "exports_generated": total_count("export_generated"),
            "audiobooks_generated": total_count("audiobook_generated"),
        },
        "usage": {
            "pdf_uploads": {
                "used": pdf_used,
                "period": period,
                "limit": (
                    FREE_MONTHLY_USAGE_LIMITS["pdf_upload"]
                    if is_free
                    else PLAN_UPLOAD_LIMITS.get(plan)
                ),
            },
            "chat_messages": {
                "used": chat_used,
                "period": period,
                "limit": (
                    FREE_MONTHLY_USAGE_LIMITS["chat_message"]
                    if is_free
                    else PLAN_CHAT_LIMITS.get(plan)
                ),
            },
            "summaries_generated": {
                "used": summary_used,
                "period": "month" if is_free else "expanded",
                "limit": (
                    FREE_MONTHLY_USAGE_LIMITS["summary_generated"]
                    if is_free
                    else None
                ),
            },
            "flashcards_generated": {
                "used": flashcards_used,
                "period": "month" if is_free else "generation",
                "limit": (
                    FREE_MONTHLY_USAGE_LIMITS["flashcards_generated"]
                    if is_free
                    else None
                ),
                "limit_per_pdf": PLAN_FLASHCARD_LIMITS.get(
                    plan,
                    PLAN_FLASHCARD_LIMITS["free"],
                ),
            },
            "quizzes_generated": {
                "used": quiz_used,
                "period": "month" if is_free else "expanded",
                "limit": (
                    FREE_MONTHLY_USAGE_LIMITS["quiz_generated"]
                    if is_free
                    else None
                ),
            },
            "exams_generated": {
                "used": exams_used,
                "period": "not_included" if is_free else "generation",
                "limit": 0 if is_free else None,
                "limit_per_pdf": 0 if is_free else PLAN_EXAM_LIMITS.get(plan),
            },
            "exports_generated": {
                "used": exports_used,
                "period": period,
                "permissions": PLAN_EXPORT_PERMISSIONS.get(
                    plan,
                    PLAN_EXPORT_PERMISSIONS["free"],
                ),
            },
        },
    }
