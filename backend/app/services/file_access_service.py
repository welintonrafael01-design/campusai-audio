from __future__ import annotations

import os
import time
import jwt


def _get_secret() -> str:
    secret = os.getenv("FILE_ACCESS_SECRET", "").strip()

    if not secret:
        raise RuntimeError(
            "FILE_ACCESS_SECRET no está configurada. "
            "Defina una clave segura en el archivo .env."
        )

    return secret


def create_file_access_token(
    *,
    document_id: str,
    user_id: str,
    expires_in_seconds: int = 120,
) -> str:
    now = int(time.time())

    payload = {
        "document_id": document_id,
        "user_id": user_id,
        "iat": now,
        "exp": now + expires_in_seconds,
        "scope": "pdf_file_access",
    }

    return jwt.encode(
        payload,
        _get_secret(),
        algorithm="HS256",
    )


def verify_file_access_token(
    *,
    token: str,
    document_id: str,
) -> dict:
    payload = jwt.decode(
        token,
        _get_secret(),
        algorithms=["HS256"],
    )

    if payload.get("document_id") != document_id:
        raise ValueError("Token no corresponde a este documento.")

    if payload.get("scope") != "pdf_file_access":
        raise ValueError("Token sin permiso para abrir PDF.")

    return payload
