from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse

from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.audio_service import (
    audio_file_path,
    audio_filename_belongs_to_user,
)
from app.services.cloud_service import user_owns_legacy_audiobook_audio


router = APIRouter(
    prefix="/audio",
    tags=["Audio"],
)


@router.get("/{filename}")
async def get_audio_file(
    filename: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    owns_scoped_audio = audio_filename_belongs_to_user(
        user_id=current_user.user_id,
        filename=filename,
    )
    owns_legacy_audio = owns_scoped_audio or user_owns_legacy_audiobook_audio(
        user_id=current_user.user_id,
        filename=filename,
    )
    if not owns_legacy_audio:
        raise HTTPException(status_code=404, detail="Audio no encontrado.")

    audio_path = audio_file_path(filename)
    if audio_path is None:
        raise HTTPException(status_code=404, detail="Audio no encontrado.")

    return FileResponse(
        str(audio_path),
        media_type="audio/mpeg",
        filename=audio_path.name,
    )
