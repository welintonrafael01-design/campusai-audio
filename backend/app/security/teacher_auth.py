from __future__ import annotations

from typing import Any

from fastapi import Depends, HTTPException

from app.security.admin_auth import is_admin_user
from app.security.entitlements import (
    ProductCapability,
    canonical_plan,
    has_capability,
    normalized_value,
    resolve_role,
)
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.subscription_service import get_user_subscription


TEACHER_ROLES = {"teacher", "educator"}
TEACHER_PLANS = {"teacher", "institution"}


def _normalized_value(value: Any) -> str:
    return normalized_value(value)


def teacher_role_from_app_metadata(current_user: AuthenticatedUser) -> str:
    return _normalized_value(current_user.app_metadata.get("role"))


def normalized_teacher_plan(value: Any) -> str:
    return canonical_plan(value)


def has_teacher_access(
    current_user: AuthenticatedUser,
    *,
    subscription: dict[str, Any] | None = None,
) -> bool:
    current_subscription = subscription or get_user_subscription(
        user_id=current_user.user_id,
    )
    role = resolve_role(
        current_user.app_metadata,
        admin_authorized=is_admin_user(current_user),
    )

    return has_capability(
        ProductCapability.TEACHER_WORKSPACE,
        role=role,
        plan=current_subscription.get("plan"),
        status=current_subscription.get("subscription_status"),
    )


def require_teacher_access(
    current_user: AuthenticatedUser = Depends(require_current_user),
) -> AuthenticatedUser:
    if has_teacher_access(current_user):
        return current_user

    raise HTTPException(
        status_code=403,
        detail="No tienes permiso para acceder a las herramientas docentes.",
    )
