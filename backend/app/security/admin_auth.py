import os

from fastapi import Header, HTTPException


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
