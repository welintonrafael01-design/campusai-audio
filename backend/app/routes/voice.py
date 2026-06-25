from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.ai_service import ask_ai_coach


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


@router.post("/coach")
async def voice_coach(payload: VoiceCoachRequest):
    return ask_ai_coach(
        message=payload.message,
        context=payload.context,
        recent_messages=payload.recent_messages,
        mode=payload.mode,
        language=payload.language,
    )
