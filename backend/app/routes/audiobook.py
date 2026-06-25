from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.audiobook_service import (
    audiobook_audio_path,
    generate_audiobook_payload,
    generate_chapter_audio_payload,
    generate_learning_pack,
)


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
        return generate_chapter_audio_payload(
            audiobook_id=payload.audiobook_id,
            chapter_id=payload.chapter_id,
            chapter_title=payload.chapter_title,
            script=payload.script,
            voice_profile=payload.voice_profile,
            language=payload.language,
        )
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
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo generar el paquete de aprendizaje: {error}",
        ) from error


@router.get("/audio/{filename}")
async def get_audiobook_audio(filename: str):
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
