from __future__ import annotations

from enum import Enum
from typing import Any, Mapping


class ProductCapability(str, Enum):
    LIBRARY = "library"
    DOCUMENT_UPLOAD = "document_upload"
    CHAT = "chat"
    SUMMARY = "summary"
    AUDIOBOOK = "audiobook"
    VOICE_TUTOR = "voice_tutor"
    FLASHCARDS = "flashcards"
    QUIZ = "quiz"
    EXAM_GENERATION = "exam_generation"
    QUESTION_BANK = "question_bank"
    CLOUD_RESTORE = "cloud_restore"
    EXPORT_PDF = "export_pdf"
    EXPORT_DOCX = "export_docx"
    EXPORT_PPTX = "export_pptx"
    ADVANCED_ANALYTICS = "advanced_analytics"
    CERTIFICATES = "certificates"
    ACADEMIC_BADGES = "academic_badges"
    PREMIUM_TRANSCRIPT = "premium_transcript"
    ACCESSIBILITY_EXPERIENCE = "accessibility_experience"
    TEACHER_WORKSPACE = "teacher_workspace"
    MANAGE_COURSES = "manage_courses"
    MANAGE_STUDENTS = "manage_students"
    MANAGE_ATTENDANCE = "manage_attendance"
    MANAGE_GRADES = "manage_grades"
    MANAGE_WEIGHTS = "manage_weights"
    TEACHING_PLAN = "teaching_plan"
    RUBRICS = "rubrics"
    TEACHER_EXAMS = "teacher_exams"
    FINAL_REPORT = "final_report"
    ADMIN_CONSOLE = "admin_console"


CANONICAL_PLANS = {"free", "student", "teacher", "institution"}
LEGACY_PLAN_ALIASES = {
    "pro": "student",
    "educator": "teacher",
    "accessibility": "student",
    "ultra": "student",
}
SUPPORTED_STORED_PLANS = CANONICAL_PLANS | {"accessibility", "ultra"}
ENTITLED_SUBSCRIPTION_STATUSES = {"active", "trialing"}

TEACHER_ROLES = {"teacher", "educator"}
ADMIN_METADATA_ROLES = {"admin", "institution_admin"}

FREE_CAPABILITIES = {
    ProductCapability.LIBRARY,
    ProductCapability.DOCUMENT_UPLOAD,
    ProductCapability.CHAT,
    ProductCapability.SUMMARY,
    ProductCapability.FLASHCARDS,
    ProductCapability.QUIZ,
    ProductCapability.CLOUD_RESTORE,
    ProductCapability.EXPORT_PDF,
}

STUDENT_CAPABILITIES = FREE_CAPABILITIES | {
    ProductCapability.AUDIOBOOK,
    ProductCapability.VOICE_TUTOR,
    ProductCapability.EXAM_GENERATION,
    ProductCapability.QUESTION_BANK,
    ProductCapability.EXPORT_DOCX,
}

TEACHER_CAPABILITIES = STUDENT_CAPABILITIES | {
    ProductCapability.EXPORT_PPTX,
    ProductCapability.ADVANCED_ANALYTICS,
    ProductCapability.CERTIFICATES,
    ProductCapability.ACADEMIC_BADGES,
    ProductCapability.PREMIUM_TRANSCRIPT,
    ProductCapability.TEACHER_WORKSPACE,
    ProductCapability.MANAGE_COURSES,
    ProductCapability.MANAGE_STUDENTS,
    ProductCapability.MANAGE_ATTENDANCE,
    ProductCapability.MANAGE_GRADES,
    ProductCapability.MANAGE_WEIGHTS,
    ProductCapability.TEACHING_PLAN,
    ProductCapability.RUBRICS,
    ProductCapability.TEACHER_EXAMS,
    ProductCapability.FINAL_REPORT,
}

TEACHER_ONLY_CAPABILITIES = {
    ProductCapability.TEACHER_WORKSPACE,
    ProductCapability.MANAGE_COURSES,
    ProductCapability.MANAGE_STUDENTS,
    ProductCapability.MANAGE_ATTENDANCE,
    ProductCapability.MANAGE_GRADES,
    ProductCapability.MANAGE_WEIGHTS,
    ProductCapability.TEACHING_PLAN,
    ProductCapability.RUBRICS,
    ProductCapability.TEACHER_EXAMS,
    ProductCapability.FINAL_REPORT,
}


def normalized_value(value: Any) -> str:
    return str(value or "").strip().lower()


def normalize_stored_plan(value: Any) -> str:
    plan = normalized_value(value)
    if plan in {"pro", "educator"}:
        return LEGACY_PLAN_ALIASES[plan]
    if plan in SUPPORTED_STORED_PLANS:
        return plan
    return "free"


def canonical_plan(value: Any) -> str:
    stored_plan = normalize_stored_plan(value)
    return LEGACY_PLAN_ALIASES.get(stored_plan, stored_plan)


def normalize_subscription_status(value: Any) -> str:
    status = normalized_value(value)
    return status or "unknown"


def subscription_is_entitled(*, plan: Any, status: Any) -> bool:
    if canonical_plan(plan) == "free":
        return True
    return normalize_subscription_status(status) in ENTITLED_SUBSCRIPTION_STATUSES


def effective_stored_plan(*, plan: Any, status: Any) -> str:
    stored_plan = normalize_stored_plan(plan)
    if not subscription_is_entitled(plan=stored_plan, status=status):
        return "free"
    return stored_plan


def resolve_role(
    app_metadata: Mapping[str, Any] | None,
    *,
    admin_authorized: bool = False,
) -> str:
    if admin_authorized:
        return "admin"

    raw_role = normalized_value((app_metadata or {}).get("role"))
    if raw_role in TEACHER_ROLES:
        return "teacher"

    # Admin metadata alone is not authority. Admin access is controlled by the
    # backend allowlist and arrives through admin_authorized.
    return "student"


def plan_capabilities(plan: Any, *, status: Any = "active") -> set[ProductCapability]:
    effective_plan = effective_stored_plan(plan=plan, status=status)
    canonical = canonical_plan(effective_plan)

    if canonical == "teacher" or canonical == "institution":
        capabilities = set(TEACHER_CAPABILITIES)
    elif canonical == "student":
        capabilities = set(STUDENT_CAPABILITIES)
    else:
        capabilities = set(FREE_CAPABILITIES)

    if effective_plan == "accessibility":
        capabilities.update(
            {
                ProductCapability.ACCESSIBILITY_EXPERIENCE,
                ProductCapability.CERTIFICATES,
                ProductCapability.ACADEMIC_BADGES,
            }
        )
    elif effective_plan == "ultra":
        capabilities.update(
            {
                ProductCapability.EXPORT_PPTX,
                ProductCapability.ADVANCED_ANALYTICS,
                ProductCapability.CERTIFICATES,
                ProductCapability.ACADEMIC_BADGES,
                ProductCapability.PREMIUM_TRANSCRIPT,
            }
        )

    return capabilities


def resolve_capabilities(
    *,
    role: str,
    plan: Any,
    status: Any,
) -> set[ProductCapability]:
    if role == "admin":
        return set(ProductCapability)

    capabilities = plan_capabilities(plan, status=status)
    if role != "teacher":
        capabilities.difference_update(TEACHER_ONLY_CAPABILITIES)
    return capabilities


def has_capability(
    capability: ProductCapability,
    *,
    role: str,
    plan: Any,
    status: Any,
) -> bool:
    return capability in resolve_capabilities(
        role=role,
        plan=plan,
        status=status,
    )


def commercial_plan_code(value: Any) -> str:
    return {
        "free": "free",
        "student": "student_pro",
        "teacher": "teacher_pro",
        "institution": "institution",
    }[canonical_plan(value)]


def entitlement_denial_detail(
    *,
    capability: ProductCapability,
    required_plan: str = "student_pro",
) -> dict[str, Any]:
    plan_name = "Teacher Pro" if required_plan == "teacher_pro" else "Student Pro"
    return {
        "code": "capability_required",
        "message": f"Esta función está disponible en {plan_name}.",
        "capability": capability.value,
        "required_plan": required_plan,
        "cta": {
            "label": f"Ver {plan_name}",
            "plan": "teacher" if required_plan == "teacher_pro" else "student",
        },
    }
