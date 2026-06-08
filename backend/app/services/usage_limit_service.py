from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException

from app.database.supabase_client import get_supabase_admin_client
from app.services.subscription_service import get_user_subscription


PLAN_UPLOAD_LIMITS = {
    "free": 3,
    "pro": 50,
    "educator": 200,
}

PLAN_CHAT_LIMITS = {
    "free": 25,
    "pro": 500,
    "educator": 2000,
}

PLAN_FLASHCARD_LIMITS = {
    "free": 10,
    "pro": 50,
    "educator": 100,
}

PLAN_EXAM_LIMITS = {
    "free": 10,
    "pro": 50,
    "educator": 100,
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


def enforce_pdf_upload_limit(
    *,
    user_id: str,
) -> str:
    plan = get_plan_for_user(user_id)

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


def enforce_flashcard_limit(
    *,
    user_id: str,
    requested_amount: int,
) -> str:
    plan = get_plan_for_user(user_id)

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
    plan = get_plan_for_user(user_id)

    limit = PLAN_EXAM_LIMITS.get(
        plan,
        PLAN_EXAM_LIMITS["free"],
    )

    if requested_amount > limit:
        raise HTTPException(
            status_code=403,
            detail=(
                f"Tu plan {plan} permite hasta {limit} preguntas por examen. "
                f"Solicitaste {requested_amount}."
            ),
        )

    return plan


PLAN_EXPORT_PERMISSIONS = {
    "free": {
        "pdf": True,
        "docx": False,
        "pptx": False,
    },
    "pro": {
        "pdf": True,
        "docx": True,
        "pptx": True,
    },
    "educator": {
        "pdf": True,
        "docx": True,
        "pptx": True,
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

    pdf_used = count_usage_today(
        user_id=user_id,
        event_type="pdf_upload",
    )

    chat_used = count_usage_today(
        user_id=user_id,
        event_type="chat_message",
    )

    flashcards_used = count_usage_today(
        user_id=user_id,
        event_type="flashcards_generated",
    )

    exams_used = count_usage_today(
        user_id=user_id,
        event_type="exam_generated",
    )

    exports_used = count_usage_today(
        user_id=user_id,
        event_type="export_generated",
    )

    return {
        "user_id": user_id,
        "plan": plan,
        "usage": {
            "pdf_uploads": {
                "used_today": pdf_used,
                "limit": PLAN_UPLOAD_LIMITS.get(
                    plan,
                    PLAN_UPLOAD_LIMITS["free"],
                ),
            },
            "chat_messages": {
                "used_today": chat_used,
                "limit": PLAN_CHAT_LIMITS.get(
                    plan,
                    PLAN_CHAT_LIMITS["free"],
                ),
            },
            "flashcards_generated": {
                "used_today": flashcards_used,
                "limit_per_pdf": PLAN_FLASHCARD_LIMITS.get(
                    plan,
                    PLAN_FLASHCARD_LIMITS["free"],
                ),
            },
            "exams_generated": {
                "used_today": exams_used,
                "limit_per_pdf": PLAN_EXAM_LIMITS.get(
                    plan,
                    PLAN_EXAM_LIMITS["free"],
                ),
            },
            "exports_generated": {
                "used_today": exports_used,
                "permissions": PLAN_EXPORT_PERMISSIONS.get(
                    plan,
                    PLAN_EXPORT_PERMISSIONS["free"],
                ),
            },
        },
    }
