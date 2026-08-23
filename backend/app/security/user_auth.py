from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from fastapi import Header, HTTPException

from app.database.supabase_client import get_supabase_client


@dataclass
class AuthenticatedUser:
    user_id: str
    email: str | None = None
    app_metadata: dict[str, Any] = field(default_factory=dict)


def require_current_user(
    authorization: str = Header(default=""),
) -> AuthenticatedUser:
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Falta el header Authorization.",
        )

    parts = authorization.split(" ", 1)

    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=401,
            detail="Authorization debe tener formato Bearer token.",
        )

    token = parts[1].strip()

    if not token:
        raise HTTPException(
            status_code=401,
            detail="Token vacío.",
        )

    try:
        client = get_supabase_client()
        user_response = client.auth.get_user(token)
        user = user_response.user
    except Exception as error:
        raise HTTPException(
            status_code=401,
            detail="La sesión no es válida o ha expirado.",
        ) from error

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Usuario no autenticado.",
        )

    return AuthenticatedUser(
        user_id=user.id,
        email=user.email,
        app_metadata=dict(user.app_metadata or {}),
    )
