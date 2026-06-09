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
    max_chapters: int = 6,
) -> list[dict]:
    chapters = split_text_into_chapters(text)

    if not chapters:
        raise ValueError("No hay texto suficiente para generar audiolibro.")

    selected_chapters = chapters[:max_chapters]
    audiobook: list[dict] = []

    for index, chapter_text in enumerate(selected_chapters, start=1):
        audio_filename = generate_audio_from_text(chapter_text)

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
