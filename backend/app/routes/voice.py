from typing import Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.ai_service import ask_ai_coach
from app.services.audio_service import build_audio_url, generate_audio_from_text


router = APIRouter(
    prefix="/voice",
    tags=["voice"],
)


class VoiceCoachRequest(BaseModel):
    message: str = Field(default="")
    mode: str = Field(default="general")
    context: dict[str, Any] = Field(default_factory=dict)
    recent_messages: list[dict[str, Any]] = Field(default_factory=list)
    language: str = Field(default="es")


class VoiceTtsRequest(BaseModel):
    message_id: str = Field(default="")
    text: str = Field(default="")
    voice_profile: str = Field(default="standard")
    language: str = Field(default="es")


@router.post("/coach")
async def voice_coach(payload: VoiceCoachRequest):
    return ask_ai_coach(
        message=payload.message,
        context=payload.context,
        recent_messages=payload.recent_messages,
        mode=payload.mode,
        language=payload.language,
    )


@router.post("/tts")
async def voice_tts(payload: VoiceTtsRequest):
    clean_text = (payload.text or "").strip()

    if not clean_text:
        raise HTTPException(
            status_code=400,
            detail="No hay texto válido para generar audio.",
        )

    try:
        filename = generate_audio_from_text(clean_text)
        return {
            "audio_url": build_audio_url(filename),
            "duration_seconds": max(1, round(len(clean_text.split()) / 2)),
        }
    except Exception:
        return {
            "audio_url": "",
            "duration_seconds": max(1, round(len(clean_text.split()) / 2)),
        }
