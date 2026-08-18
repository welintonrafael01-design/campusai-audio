from __future__ import annotations

from typing import Any

from fastapi import Depends, HTTPException

from app.security.admin_auth import is_admin_user
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.subscription_service import get_user_subscription


TEACHER_ROLES = {"teacher", "educator"}
TEACHER_PLANS = {"teacher", "ultra"}


def _normalized_value(value: Any) -> str:
    return str(value or "").strip().lower()


def teacher_role_from_app_metadata(current_user: AuthenticatedUser) -> str:
    return _normalized_value(current_user.app_metadata.get("role"))


def normalized_teacher_plan(value: Any) -> str:
    plan = _normalized_value(value)
    return "teacher" if plan == "educator" else plan


def has_teacher_access(
    current_user: AuthenticatedUser,
    *,
    subscription: dict[str, Any] | None = None,
) -> bool:
    if is_admin_user(current_user):
        return True

    role = teacher_role_from_app_metadata(current_user)
    if role not in TEACHER_ROLES:
        return False

    current_subscription = subscription or get_user_subscription(
        user_id=current_user.user_id,
    )
    status = _normalized_value(current_subscription.get("subscription_status"))
    plan = normalized_teacher_plan(current_subscription.get("plan"))

    return status == "active" and plan in TEACHER_PLANS


def require_teacher_access(
    current_user: AuthenticatedUser = Depends(require_current_user),
) -> AuthenticatedUser:
    if has_teacher_access(current_user):
        return current_user

    raise HTTPException(
        status_code=403,
        detail="No tienes permiso para acceder a las herramientas docentes.",
    )
