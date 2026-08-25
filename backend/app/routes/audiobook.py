from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.audiobook_service import (
    audio_filename_belongs_to_user,
    audiobook_audio_path,
    generate_audiobook_payload,
    generate_chapter_audio_payload,
    generate_learning_pack,
    scoped_audiobook_storage_id,
)
from app.services.cloud_service import user_owns_legacy_audiobook_audio
from app.services.usage_limit_service import enforce_audiobook_permission


router = APIRouter(
    prefix="/audiobook",
    tags=["AudioBook"],
)


class AudioBookGeneratePayload(BaseModel):
    title: str = ""
    text: str = ""
    source_mode: str = "solo"
    source_type: str = "text"
    source_document_id: str = ""
    course_id: str = ""
    course_name: str = ""
    unit_id: str = ""
    unit_topic: str = ""
    language: str = "es"
    voice_profile: str = "standard"


class AudioBookChapterAudioPayload(BaseModel):
    audiobook_id: str = ""
    chapter_id: str = ""
    chapter_title: str = ""
    script: str = ""
    voice_profile: str = "standard"
    language: str = "es"


class AudioBookLearningPackPayload(BaseModel):
    audiobook_id: str = ""
    chapter_id: str = ""
    chapter_title: str = ""
    summary: str = ""
    script: str = ""
    transcript: str = ""
    key_concepts: list[str] = []
    language: str = "es"


@router.post("/generate")
async def generate_audiobook_endpoint(
    payload: AudioBookGeneratePayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        enforce_audiobook_permission(user_id=current_user.user_id)
        audiobook = generate_audiobook_payload(
            title=payload.title,
            text=payload.text,
            source_mode=payload.source_mode,
            source_type=payload.source_type,
            source_document_id=payload.source_document_id,
            course_id=payload.course_id,
            course_name=payload.course_name,
            unit_id=payload.unit_id,
            unit_topic=payload.unit_topic,
            language=payload.language,
            voice_profile=payload.voice_profile,
        )

        return {
            "audiobook": audiobook,
        }
    except HTTPException:
        raise
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo generar el Audio Libro: {error}",
        ) from error


@router.post("/generate-chapter-audio")
async def generate_chapter_audio_endpoint(
    payload: AudioBookChapterAudioPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        enforce_audiobook_permission(user_id=current_user.user_id)
        return generate_chapter_audio_payload(
            audiobook_id=scoped_audiobook_storage_id(
                user_id=current_user.user_id,
                audiobook_id=payload.audiobook_id,
            ),
            chapter_id=payload.chapter_id,
            chapter_title=payload.chapter_title,
            script=payload.script,
            voice_profile=payload.voice_profile,
            language=payload.language,
        )
    except HTTPException:
        raise
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo generar el audio del capítulo: {error}",
        ) from error


@router.post("/generate-learning-pack")
async def generate_learning_pack_endpoint(
    payload: AudioBookLearningPackPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        enforce_audiobook_permission(user_id=current_user.user_id)
        learning_pack = generate_learning_pack(
            audiobook_id=payload.audiobook_id,
            chapter_id=payload.chapter_id,
            chapter_title=payload.chapter_title,
            summary=payload.summary,
            script=payload.script,
            transcript=payload.transcript,
            key_concepts=payload.key_concepts,
            language=payload.language,
        )

        return {
            "learning_pack": learning_pack,
        }
    except HTTPException:
        raise
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo generar el paquete de aprendizaje: {error}",
        ) from error


@router.get("/audio/{filename}")
async def get_audiobook_audio(
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
        raise HTTPException(
            status_code=404,
            detail="Audio de capítulo no encontrado.",
        )

    audio_path = audiobook_audio_path(filename)
    if audio_path is None:
        raise HTTPException(
            status_code=404,
            detail="Audio de capítulo no encontrado.",
        )

    return FileResponse(
        str(audio_path),
        media_type="audio/mpeg",
        filename=audio_path.name,
    )
