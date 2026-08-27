from openai import OpenAI
from dotenv import load_dotenv

from pathlib import Path
from hashlib import sha256

import os
import re
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


def _safe_audio_filename(value: str) -> str:
    clean_value = re.sub(r"[^a-zA-Z0-9_.-]+", "_", value.strip())
    return clean_value.strip("._")[:160]


def audio_owner_scope(user_id: str) -> str:
    clean_user_id = user_id.strip()
    if not clean_user_id:
        raise ValueError("No se pudo identificar al propietario del audio.")
    return sha256(clean_user_id.encode("utf-8")).hexdigest()[:20]


def audio_filename_belongs_to_user(*, user_id: str, filename: str) -> bool:
    clean_filename = _safe_audio_filename(filename)
    return bool(clean_filename) and clean_filename.startswith(
        f"{audio_owner_scope(user_id)}_"
    )


def audio_file_path(filename: str) -> Path | None:
    clean_filename = _safe_audio_filename(filename)
    if (
        not clean_filename
        or clean_filename != filename
        or not clean_filename.endswith(".mp3")
    ):
        return None

    audio_path = AUDIO_FOLDER / clean_filename
    if not audio_path.exists() or not audio_path.is_file():
        return None
    return audio_path


def generate_audio_from_text(text: str, *, user_id: str) -> str:
    clean_text = clean_input_text(text)

    if not clean_text:
        raise ValueError(
            "No hay texto válido para generar audio."
        )

    audio_filename = f"{audio_owner_scope(user_id)}_{uuid.uuid4().hex}.mp3"

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
        raise RuntimeError("No se pudo generar el audio solicitado.") from error

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

def split_text_into_chapters(
    text: str,
    max_chars: int = 2500,
) -> list[str]:
    clean_text = clean_input_text(text)

    if not clean_text:
        return []

    paragraphs = [
        item.strip()
        for item in clean_text.split("\n")
        if item.strip()
    ]

    if not paragraphs:
        paragraphs = [
            clean_text[index:index + max_chars]
            for index in range(0, len(clean_text), max_chars)
        ]

    chapters: list[str] = []
    current = ""

    for paragraph in paragraphs:
        if len(current) + len(paragraph) + 2 <= max_chars:
            current = f"{current}\n\n{paragraph}".strip()
        else:
            if current:
                chapters.append(current)
            current = paragraph[:max_chars]

    if current:
        chapters.append(current)

    return chapters


def generate_audiobook_from_text(
    text: str,
    *,
    user_id: str,
    max_chapters: int = 6,
) -> list[dict]:
    chapters = split_text_into_chapters(text)

    if not chapters:
        raise ValueError("No hay texto suficiente para generar audiolibro.")

    selected_chapters = chapters[:max_chapters]
    audiobook: list[dict] = []

    for index, chapter_text in enumerate(selected_chapters, start=1):
        audio_filename = generate_audio_from_text(
            chapter_text,
            user_id=user_id,
        )

        audiobook.append(
            {
                "chapter": index,
                "title": f"Capítulo {index}",
                "text_preview": chapter_text[:280],
                "audio_file": audio_filename,
                "audio_url": build_audio_url(audio_filename),
                "estimated_minutes": max(1, round(len(chapter_text) / 900)),
            }
        )

    return audiobook
