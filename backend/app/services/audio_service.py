from openai import OpenAI
from dotenv import load_dotenv

from pathlib import Path

import os
import uuid

load_dotenv()

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

BASE_DIR = Path(__file__).resolve().parent.parent

AUDIO_FOLDER = BASE_DIR / "audio"

AUDIO_FOLDER.mkdir(
    parents=True,
    exist_ok=True,
)

MAX_TTS_CHARACTERS = 4000


def generate_audio_from_text(text: str) -> str:
    clean_text = clean_input_text(text)

    if not clean_text:
        raise ValueError(
            "No hay texto válido para generar audio."
        )

    audio_filename = f"{uuid.uuid4()}.mp3"

    audio_path = AUDIO_FOLDER / audio_filename

    short_text = clean_text[:MAX_TTS_CHARACTERS]

    try:
        response = client.audio.speech.create(
            model="gpt-4o-mini-tts",
            voice="marin",
            input=short_text,
        )

        response.write_to_file(str(audio_path))

    except Exception as error:
        raise Exception(
            f"Error generando audio IA: {error}"
        )

    return audio_filename


def clean_input_text(text: str) -> str:
    if not text:
        return ""

    return (
        text.replace("###", "")
        .replace("##", "")
        .replace("#", "")
        .replace("**", "")
        .replace("__", "")
        .replace("*", "")
        .strip()
    )


def build_audio_url(audio_filename: str) -> str:
    return f"/audio/{audio_filename}"