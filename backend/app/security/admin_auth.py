import os

from fastapi import Depends, Header, HTTPException

from app.security.user_auth import AuthenticatedUser, require_current_user


def is_admin_user(current_user: AuthenticatedUser) -> bool:
    admin_emails = {
        email.strip().lower()
        for email in os.getenv("ADMIN_EMAILS", "").split(",")
        if email.strip()
    }

    user_email = (current_user.email or "").strip().lower()
    return bool(admin_emails and user_email in admin_emails)


def require_admin_key(
    x_admin_key: str = Header(default=""),
):
    admin_key = os.getenv("ADMIN_API_KEY", "")

    if not admin_key:
        raise HTTPException(
            status_code=500,
            detail="ADMIN_API_KEY no está configurada.",
        )

    if x_admin_key != admin_key:
        raise HTTPException(
            status_code=403,
            detail="No autorizado.",
        )

    return True


def require_admin_user(
    current_user: AuthenticatedUser = Depends(require_current_user),
) -> AuthenticatedUser:
    if is_admin_user(current_user):
        return current_user

    raise HTTPException(
        status_code=403,
        detail="No tienes permiso para acceder a esta consola.",
    )
