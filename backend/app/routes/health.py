from datetime import datetime, timezone
import os

from fastapi import APIRouter

router = APIRouter()
PROCESS_STARTED_AT = datetime.now(timezone.utc).isoformat()

@router.get("/health")
def health_check():
    build_sha = (
        os.getenv("APP_BUILD_SHA", "").strip()
        or os.getenv("RENDER_GIT_COMMIT", "").strip()
        or "unknown"
    )
    return {
        "status": "ok",
        "service": "StudyBook AI API",
        "version": "1.0.0",
        "build_sha": build_sha,
        "started_at": PROCESS_STARTED_AT,
        "message": "El backend está funcionando correctamente",
    }
