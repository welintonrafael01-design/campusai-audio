from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import logging
import re
from uuid import uuid4

from fastapi import HTTPException

from app.database.supabase_client import get_supabase_admin_client
from app.security.entitlements import (
    ProductCapability,
    entitlement_denial_detail,
    plan_capabilities,
)
from app.services.subscription_service import get_user_subscription


logger = logging.getLogger("studybook.quota")


FREE_MONTHLY_USAGE_LIMITS = {
    "pdf_upload": 3,
    "chat_message": 10,
    "summary_generated": 3,
    "flashcards_generated": 1,
    "quiz_generated": 1,
}

QUOTA_CAPABILITIES = {
    "pdf_upload": ProductCapability.DOCUMENT_UPLOAD.value,
    "chat_message": ProductCapability.CHAT.value,
    "summary_generated": ProductCapability.SUMMARY.value,
    "flashcards_generated": ProductCapability.FLASHCARDS.value,
    "quiz_generated": ProductCapability.QUIZ.value,
}

_IDEMPOTENCY_KEY_PATTERN = re.compile(r"^[A-Za-z0-9._:-]{8,128}$")


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


def operation_id_for_request(
    *,
    idempotency_key: str | None,
    request_id: str | None,
    scope: str = "request",
) -> str:
    """Return a non-reversible operation ID safe for durable storage."""
    candidate = (idempotency_key or "").strip()
    if candidate and not _IDEMPOTENCY_KEY_PATTERN.fullmatch(candidate):
        raise HTTPException(
            status_code=400,
            detail={
                "code": "invalid_idempotency_key",
                "message": (
                    "Idempotency-Key debe contener entre 8 y 128 caracteres "
                    "alfanuméricos seguros."
                ),
            },
        )
    if not candidate:
        candidate = (request_id or "").strip() or str(uuid4())
    return hashlib.sha256(f"{scope}:{candidate}".encode("utf-8")).hexdigest()


def _quota_log(
    *,
    status: str,
    user_id: str,
    event_type: str,
    reservation_id: str | None = None,
) -> None:
    logger.info(
        "quota_event=%s",
        json.dumps(
            {
                "status": status,
                "event_type": event_type,
                "user_scope": hashlib.sha256(
                    user_id.encode("utf-8")
                ).hexdigest()[:12],
                "reservation_id": reservation_id,
            },
            separators=(",", ":"),
        ),
    )


@dataclass
class UsageOperation:
    user_id: str
    event_type: str
    plan: str
    reservation_id: str | None = None
    status: str = "unreserved"
    used: int = 0
    limit: int | None = None
    period_start: str | None = None
    period_end: str | None = None
    idempotent: bool = False
    _finalized: bool = field(default=False, repr=False)

    def __enter__(self) -> "UsageOperation":
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> bool:
        if not self._finalized:
            self.release(reason="operation_failed" if exc_type else "not_committed")
        return False

    def commit(self, metadata: dict | None = None) -> None:
        commit_usage_operations([(self, metadata or {})])

    def release(self, *, reason: str = "operation_failed") -> None:
        if self._finalized:
            return
        if self.plan != "free" or not self.reservation_id:
            self._finalized = True
            return
        try:
            get_supabase_admin_client().rpc(
                "release_studybook_free_quota",
                {
                    "p_user_id": self.user_id,
                    "p_reservation_id": self.reservation_id,
                    "p_reason": reason[:80],
                },
            ).execute()
            _quota_log(
                status="released",
                user_id=self.user_id,
                event_type=self.event_type,
                reservation_id=self.reservation_id,
            )
            self._finalized = True
        except Exception as error:
            logger.warning(
                "quota_release_failed event_type=%s error_type=%s",
                self.event_type,
                type(error).__name__,
            )


def begin_usage_operation(
    *,
    user_id: str,
    event_type: str,
    plan: str,
    operation_id: str,
) -> UsageOperation:
    """Atomically reserve one monthly Free slot, or create a paid tracker."""
    if plan != "free":
        return UsageOperation(user_id=user_id, event_type=event_type, plan=plan)
    if event_type not in FREE_MONTHLY_USAGE_LIMITS:
        raise ValueError(f"Unsupported Free quota event: {event_type}")

    try:
        response = get_supabase_admin_client().rpc(
            "reserve_studybook_free_quota",
            {
                "p_user_id": user_id,
                "p_event_type": event_type,
                "p_operation_id": operation_id,
            },
        ).execute()
    except Exception as error:
        logger.error(
            "quota_reservation_failed event_type=%s error_type=%s",
            event_type,
            type(error).__name__,
        )
        raise HTTPException(
            status_code=503,
            detail={
                "code": "quota_service_unavailable",
                "message": "No se pudo validar el límite de uso. Inténtalo nuevamente.",
            },
        ) from error

    rows = response.data if response is not None else None
    row = rows[0] if isinstance(rows, list) and rows else None
    if not isinstance(row, dict):
        raise HTTPException(
            status_code=503,
            detail={
                "code": "quota_service_unavailable",
                "message": "No se pudo validar el límite de uso. Inténtalo nuevamente.",
            },
        )

    status = str(row.get("reservation_status") or "")
    used = int(row.get("used_count") or 0)
    limit = int(row.get("quota_limit") or FREE_MONTHLY_USAGE_LIMITS[event_type])
    reservation_id = str(row.get("reservation_id") or "").strip() or None

    if status == "denied":
        _quota_log(status="denied", user_id=user_id, event_type=event_type)
        raise HTTPException(
            status_code=403,
            detail=quota_denial_detail(
                event_type=event_type,
                limit=limit,
                used=used,
            ),
        )
    if status == "reserved" and not bool(row.get("acquired")):
        raise HTTPException(
            status_code=409,
            detail={
                "code": "quota_operation_in_progress",
                "reason": "duplicate_request",
                "capability": QUOTA_CAPABILITIES[event_type],
                "message": "Esta operación ya está en progreso.",
                "retryable": True,
            },
        )
    if status not in {"reserved", "consumed"} or not reservation_id:
        raise HTTPException(
            status_code=503,
            detail={
                "code": "quota_service_unavailable",
                "message": "No se pudo validar el límite de uso. Inténtalo nuevamente.",
            },
        )

    operation = UsageOperation(
        user_id=user_id,
        event_type=event_type,
        plan=plan,
        reservation_id=reservation_id,
        status=status,
        used=used,
        limit=limit,
        period_start=row.get("quota_period_start"),
        period_end=row.get("quota_period_end"),
        idempotent=bool(row.get("idempotent")),
        _finalized=status == "consumed",
    )
    _quota_log(
        status="idempotent" if operation._finalized else "reserved",
        user_id=user_id,
        event_type=event_type,
        reservation_id=reservation_id,
    )
    return operation


def commit_usage_operations(
    operations: list[tuple[UsageOperation, dict]],
) -> None:
    pending = [
        (operation, metadata)
        for operation, metadata in operations
        if not operation._finalized
    ]
    free_operations = [item for item in pending if item[0].plan == "free"]
    paid_operations = [item for item in pending if item[0].plan != "free"]

    if free_operations:
        reservation_ids = [item[0].reservation_id for item in free_operations]
        if any(not reservation_id for reservation_id in reservation_ids):
            raise RuntimeError("Free usage operation is missing its reservation.")
        metadata_by_event = {
            operation.event_type: metadata
            for operation, metadata in free_operations
        }
        try:
            get_supabase_admin_client().rpc(
                "commit_studybook_free_quotas",
                {
                    "p_user_id": free_operations[0][0].user_id,
                    "p_reservation_ids": reservation_ids,
                    "p_metadata_by_event": metadata_by_event,
                },
            ).execute()
        except Exception as error:
            logger.error(
                "quota_commit_failed event_types=%s error_type=%s",
                ",".join(item[0].event_type for item in free_operations),
                type(error).__name__,
            )
            raise
        for operation, _ in free_operations:
            operation._finalized = True
            operation.status = "consumed"
            _quota_log(
                status="consumed",
                user_id=operation.user_id,
                event_type=operation.event_type,
                reservation_id=operation.reservation_id,
            )

    for operation, metadata in paid_operations:
        register_usage_event(
            user_id=operation.user_id,
            event_type=operation.event_type,
            plan=operation.plan,
            metadata=metadata,
        )
        operation._finalized = True
        operation.status = "consumed"


def quota_denial_detail(
    *,
    event_type: str,
    limit: int,
    used: int,
) -> dict:
    return {
        "code": "monthly_quota_exceeded",
        "reason": "quota_exceeded",
        "capability": QUOTA_CAPABILITIES[event_type],
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
