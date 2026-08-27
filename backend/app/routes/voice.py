from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.services.ai_service import ask_ai_coach
from app.services.audio_service import build_audio_url, generate_audio_from_text
from app.services.usage_limit_service import enforce_voice_permission
from app.security.user_auth import AuthenticatedUser, require_current_user


router = APIRouter(
    prefix="/voice",
    tags=["voice"],
)


class VoiceRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class VoiceCoachRequest(VoiceRequestModel):
    message: str = Field(default="", max_length=12000)
    mode: str = Field(default="general", max_length=64)
    context: dict[str, Any] = Field(default_factory=dict)
    recent_messages: list[dict[str, Any]] = Field(default_factory=list, max_length=20)
    language: str = Field(default="es", max_length=16)


class VoiceTtsRequest(VoiceRequestModel):
    message_id: str = Field(default="", max_length=255)
    text: str = Field(default="", max_length=12000)
    voice_profile: str = Field(default="standard", max_length=64)
    language: str = Field(default="es", max_length=16)


@router.post("/coach")
async def voice_coach(
    payload: VoiceCoachRequest,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    enforce_voice_permission(user_id=current_user.user_id)
    return ask_ai_coach(
        message=payload.message,
        context=payload.context,
        recent_messages=payload.recent_messages,
        mode=payload.mode,
        language=payload.language,
    )


@router.post("/tts")
async def voice_tts(
    payload: VoiceTtsRequest,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    enforce_voice_permission(user_id=current_user.user_id)
    clean_text = (payload.text or "").strip()

    if not clean_text:
        raise HTTPException(
            status_code=400,
            detail="No hay texto válido para generar audio.",
        )

    try:
        filename = generate_audio_from_text(
            clean_text,
            user_id=current_user.user_id,
        )
        return {
            "audio_url": build_audio_url(filename),
            "duration_seconds": max(1, round(len(clean_text.split()) / 2)),
        }
    except Exception:
        return {
            "audio_url": "",
            "duration_seconds": max(1, round(len(clean_text.split()) / 2)),
        }
