from datetime import datetime, timezone
import json
from pathlib import Path
import re
from uuid import uuid4

from app.services.ai_service import (
    MODEL_NAME,
    build_language_instruction,
    clean_text,
    client,
    truncate_text,
)


PROJECT_DIR = Path(__file__).resolve().parents[2]
AUDIOBOOK_AUDIO_DIR = PROJECT_DIR / "storage" / "audiobook_audio"
MAX_CHAPTER_TTS_CHARACTERS = 8000


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _estimate_duration_seconds(text: str) -> int:
    words = [
        word
        for word in clean_text(text).split()
        if word.strip()
    ]
    return min(600, max(30, round(len(words) / 2)))


def _estimate_study_minutes(text: str) -> int:
    words = [
        word
        for word in clean_text(text).split()
        if word.strip()
    ]
    return min(45, max(5, round(len(words) / 140) + 5))


def _safe_audio_filename(value: str) -> str:
    clean_value = re.sub(r"[^a-zA-Z0-9_.-]+", "_", value.strip())
    clean_value = clean_value.strip("._")
    return clean_value[:160] or uuid4().hex


def _safe_list(value) -> list:
    if isinstance(value, list):
        return value
    if isinstance(value, str) and value.strip():
        return [value.strip()]
    return []


def _safe_dict(value) -> dict:
    return value if isinstance(value, dict) else {}


def _split_chapters(text: str, max_chapters: int = 4) -> list[str]:
    paragraphs = [
        item.strip()
        for item in text.split("\n")
        if item.strip()
    ]

    if not paragraphs:
        paragraphs = [text.strip()]

    chapters: list[str] = []
    current = ""
    max_chars = 1800

    for paragraph in paragraphs:
        if len(current) + len(paragraph) + 2 <= max_chars:
            current = f"{current}\n\n{paragraph}".strip()
        else:
            if current:
                chapters.append(current)
            current = paragraph[:max_chars]

        if len(chapters) >= max_chapters:
            break

    if current and len(chapters) < max_chapters:
        chapters.append(current)

    return chapters[:max_chapters]


def fallback_audiobook_from_text(
    *,
    title: str,
    text: str,
    source_mode: str = "solo",
    source_type: str = "text",
    source_document_id: str = "",
    course_id: str = "",
    course_name: str = "",
    unit_id: str = "",
    unit_topic: str = "",
    language: str = "es",
    voice_profile: str = "standard",
) -> dict:
    clean_title = clean_text(title) or "Audio Libro"
    clean_source = clean_text(text)
    chapters = []

    for index, chapter_text in enumerate(_split_chapters(clean_source), start=1):
        chapter_title = (
            f"{unit_topic} - Parte {index}"
            if unit_topic
            else f"Capítulo {index}"
        )
        script = (
            f"En este capítulo estudiaremos {chapter_title}. "
            f"Escucha con atención la explicación y relaciona las ideas con "
            f"tus apuntes.\n\n{chapter_text}"
        )

        chapters.append(
            {
                "chapter_id": f"chapter_{index}",
                "chapter_number": index,
                "title": chapter_title,
                "summary": chapter_text[:280],
                "script": script,
                "transcript": script,
                "audio_url": "",
                "duration_seconds": max(60, round(len(script) / 14)),
                "key_concepts": [],
                "reflection_questions": [
                    "¿Cuál es la idea más importante de este capítulo?",
                    "¿Cómo aplicarías este contenido en una situación real?",
                ],
            }
        )

    estimated_duration = sum(
        chapter["duration_seconds"]
        for chapter in chapters
    ) // 60

    audiobook_id = (
        f"{unit_id}_audiobook"
        if unit_id
        else f"audiobook_{uuid4().hex}"
    )

    return {
        "audiobook_id": audiobook_id,
        "source_mode": source_mode or "solo",
        "source_type": source_type or "text",
        "source_document_id": source_document_id,
        "course_id": course_id,
        "course_name": course_name,
        "unit_id": unit_id,
        "unit_topic": unit_topic,
        "title": clean_title,
        "description": (
            f"Audio libro educativo basado en {unit_topic}."
            if unit_topic
            else "Audio libro educativo generado desde contenido académico."
        ),
        "language": language or "es",
        "voice_profile": voice_profile or "standard",
        "estimated_duration_minutes": max(1, estimated_duration),
        "chapters": chapters,
        "learning_objectives": [],
        "key_concepts": [],
        "review_questions": [
            "Resume el contenido en tus propias palabras.",
            "Identifica dos conceptos clave y explícalos con ejemplos.",
        ],
        "created_at": _utc_now(),
    }


def normalize_audiobook_payload(
    *,
    raw: dict,
    fallback: dict,
) -> dict:
    audiobook = {
        **fallback,
        **{
            key: value
            for key, value in raw.items()
            if value not in [None, ""]
        },
    }

    chapters = []
    raw_chapters = raw.get("chapters")
    if isinstance(raw_chapters, list):
        for index, raw_chapter in enumerate(raw_chapters, start=1):
            if not isinstance(raw_chapter, dict):
                continue

            fallback_chapter = (
                fallback["chapters"][index - 1]
                if index - 1 < len(fallback["chapters"])
                else {}
            )
            script = clean_text(
                raw_chapter.get("script")
                or raw_chapter.get("transcript")
                or fallback_chapter.get("script", "")
            )

            chapters.append(
                {
                    "chapter_id": clean_text(
                        raw_chapter.get("chapter_id")
                    ) or f"chapter_{index}",
                    "chapter_number": index,
                    "title": clean_text(
                        raw_chapter.get("title")
                    ) or f"Capítulo {index}",
                    "summary": clean_text(
                        raw_chapter.get("summary")
                    ) or script[:280],
                    "script": script,
                    "transcript": clean_text(
                        raw_chapter.get("transcript")
                    ) or script,
                    "audio_url": "",
                    "duration_seconds": int(
                        raw_chapter.get("duration_seconds") or
                        fallback_chapter.get("duration_seconds", 0)
                    ),
                    "key_concepts": _safe_list(raw_chapter.get("key_concepts")),
                    "reflection_questions": _safe_list(
                        raw_chapter.get("reflection_questions")
                    ),
                }
            )

    if chapters:
        audiobook["chapters"] = chapters

    audiobook["learning_objectives"] = _safe_list(
        audiobook.get("learning_objectives")
    )
    audiobook["key_concepts"] = _safe_list(audiobook.get("key_concepts"))
    audiobook["review_questions"] = _safe_list(
        audiobook.get("review_questions")
    )
    audiobook["created_at"] = audiobook.get("created_at") or _utc_now()

    return audiobook


def generate_audiobook_payload(
    *,
    title: str,
    text: str,
    source_mode: str = "solo",
    source_type: str = "text",
    source_document_id: str = "",
    course_id: str = "",
    course_name: str = "",
    unit_id: str = "",
    unit_topic: str = "",
    language: str = "es",
    voice_profile: str = "standard",
) -> dict:
    source_text = truncate_text(text, max_characters=12000)

    if not source_text:
        raise ValueError("No hay texto suficiente para generar Audio Libro.")

    clean_title = clean_text(title) or (
        f"Audio Libro - {unit_topic}" if unit_topic else "Audio Libro"
    )
    fallback = fallback_audiobook_from_text(
        title=clean_title,
        text=source_text,
        source_mode=source_mode,
        source_type=source_type,
        source_document_id=source_document_id,
        course_id=course_id,
        course_name=course_name,
        unit_id=unit_id,
        unit_topic=unit_topic,
        language=language,
        voice_profile=voice_profile,
    )

    language_instruction = build_language_instruction(language)

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Eres StudyBook AI, un diseñador instruccional experto "
                        "en audio aprendizaje. Convierte contenido académico en "
                        "guiones narrados claros para estudiantes. "
                        f"{language_instruction}"
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        "Convierte el siguiente contenido académico en un audio "
                        "libro educativo. Divide en capítulos breves, con título, "
                        "resumen, guion narrado, transcripción, conceptos clave y "
                        "preguntas de reflexión. No generes audio real.\n\n"
                        f"Título: {clean_title}\n"
                        f"Unidad: {unit_topic}\n"
                        f"Curso: {course_name}\n\n"
                        f"Contenido:\n{source_text}\n\n"
                        "Devuelve exclusivamente JSON válido con esta estructura:\n"
                        "{\n"
                        '  "description": "...",\n'
                        '  "estimated_duration_minutes": 0,\n'
                        '  "learning_objectives": ["..."],\n'
                        '  "key_concepts": ["..."],\n'
                        '  "review_questions": ["..."],\n'
                        '  "chapters": [\n'
                        "    {\n"
                        '      "title": "...",\n'
                        '      "summary": "...",\n'
                        '      "script": "...",\n'
                        '      "transcript": "...",\n'
                        '      "duration_seconds": 0,\n'
                        '      "key_concepts": ["..."],\n'
                        '      "reflection_questions": ["..."]\n'
                        "    }\n"
                        "  ]\n"
                        "}"
                    ),
                },
            ],
            temperature=0.35,
        )

        content = response.choices[0].message.content.strip()
        raw = json.loads(content)
        if not isinstance(raw, dict):
            return fallback

        return normalize_audiobook_payload(raw=raw, fallback=fallback)
    except Exception:
        return fallback


def generate_chapter_audio_payload(
    *,
    audiobook_id: str,
    chapter_id: str,
    chapter_title: str = "",
    script: str = "",
    voice_profile: str = "standard",
    language: str = "es",
) -> dict:
    clean_audiobook_id = _safe_audio_filename(audiobook_id)
    clean_chapter_id = _safe_audio_filename(chapter_id)
    clean_script = clean_text(script)

    if not clean_audiobook_id or not clean_chapter_id:
        raise ValueError("No se pudo identificar el audio libro o capítulo.")

    if not clean_script:
        raise ValueError("No hay guion suficiente para generar audio.")

    estimated_duration = _estimate_duration_seconds(clean_script)
    source_text = clean_script[:MAX_CHAPTER_TTS_CHARACTERS]
    if len(clean_script) > MAX_CHAPTER_TTS_CHARACTERS:
        print("AudioBook TTS: script truncado para generación de audio.")

    AUDIOBOOK_AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"{clean_audiobook_id}_{clean_chapter_id}.mp3"
    audio_path = AUDIOBOOK_AUDIO_DIR / filename

    try:
        response = client.audio.speech.create(
            model="gpt-4o-mini-tts",
            voice="marin",
            input=source_text,
        )
        response.write_to_file(str(audio_path))
    except Exception as error:
        print(f"AudioBook TTS no disponible: {type(error).__name__}")
        return {
            "audio_url": "",
            "duration_seconds": estimated_duration,
        }

    print(
        "AudioBook TTS generado:",
        filename,
        f"{estimated_duration}s",
    )

    return {
        "audio_url": f"/audiobook/audio/{filename}",
        "duration_seconds": estimated_duration,
    }


def fallback_learning_pack(
    *,
    chapter_id: str,
    chapter_title: str,
    summary: str = "",
    script: str = "",
    transcript: str = "",
    key_concepts: list | None = None,
) -> dict:
    source_text = clean_text(transcript) or clean_text(script) or clean_text(summary)
    source_summary = clean_text(summary) or source_text[:500]
    concepts = _safe_list(key_concepts)[:6]
    if not concepts:
        concepts = [
            "Idea principal",
            "Conceptos clave",
            "Aplicación práctica",
        ]

    flashcards = [
        {
            "front": f"¿Qué significa {concept}?",
            "back": (
                f"{concept} es un concepto importante del capítulo "
                f"{chapter_title or 'seleccionado'}."
            ),
            "hint": "Piensa en cómo se relaciona con el resumen del capítulo.",
        }
        for concept in concepts[:5]
    ]

    mini_quiz = [
        {
            "question": "¿Cuál es el propósito principal de este capítulo?",
            "options": [
                "Comprender las ideas centrales",
                "Memorizar datos aislados",
                "Ignorar los conceptos",
                "Evitar la reflexión",
            ],
            "correct_answer": "Comprender las ideas centrales",
            "explanation": "El capítulo busca construir comprensión sobre sus ideas centrales.",
            "bloom_level": "Comprender",
        },
        {
            "question": "¿Qué estrategia ayuda a estudiar este contenido?",
            "options": [
                "Resumir con palabras propias",
                "Leer sin atención",
                "Saltar las ideas clave",
                "No tomar notas",
            ],
            "correct_answer": "Resumir con palabras propias",
            "explanation": "Explicar con tus palabras fortalece la comprensión.",
            "bloom_level": "Aplicar",
        },
        {
            "question": "¿Qué conviene hacer después de escuchar el capítulo?",
            "options": [
                "Responder preguntas de reflexión",
                "Cerrar el material sin revisar",
                "Eliminar las notas",
                "Evitar practicar",
            ],
            "correct_answer": "Responder preguntas de reflexión",
            "explanation": "La reflexión permite conectar el contenido con experiencias y ejemplos.",
            "bloom_level": "Analizar",
        },
    ]

    return {
        "chapter_id": clean_text(chapter_id),
        "chapter_title": clean_text(chapter_title) or "Capítulo",
        "learning_pack_version": "A",
        "summary": source_summary,
        "estimated_study_minutes": _estimate_study_minutes(source_text),
        "difficulty": "Media",
        "key_concepts": concepts,
        "flashcards": flashcards,
        "mini_quiz": mini_quiz,
        "reflection_questions": [
            "¿Qué idea del capítulo puedes aplicar esta semana?",
            "¿Qué concepto necesitas repasar con más calma?",
            "¿Cómo explicarías el capítulo a otra persona?",
        ],
        "competencies": [
            "Comprensión conceptual",
            "Pensamiento crítico",
            "Aplicación del conocimiento",
        ],
        "mastery_check": {
            "initial_score": 0,
            "status": "Pendiente",
            "recommendation": "Escucha el capítulo, estudia las flashcards y responde el mini quiz.",
        },
        "created_at": _utc_now(),
    }


def normalize_learning_pack(raw: dict, fallback: dict) -> dict:
    learning_pack = {
        **fallback,
        **{
            key: value
            for key, value in raw.items()
            if value not in [None, ""]
        },
    }

    flashcards = []
    for item in _safe_list(learning_pack.get("flashcards")):
        if not isinstance(item, dict):
            continue
        flashcards.append(
            {
                "front": clean_text(item.get("front")),
                "back": clean_text(item.get("back")),
                "hint": clean_text(item.get("hint")),
            }
        )

    mini_quiz = []
    for item in _safe_list(learning_pack.get("mini_quiz")):
        if not isinstance(item, dict):
            continue
        options = _safe_list(item.get("options"))[:4]
        mini_quiz.append(
            {
                "question": clean_text(item.get("question")),
                "options": options,
                "correct_answer": clean_text(item.get("correct_answer")),
                "explanation": clean_text(item.get("explanation")),
                "bloom_level": clean_text(item.get("bloom_level")) or "Comprender",
            }
        )

    if flashcards:
        learning_pack["flashcards"] = flashcards
    if mini_quiz:
        learning_pack["mini_quiz"] = mini_quiz

    learning_pack["key_concepts"] = _safe_list(learning_pack.get("key_concepts"))
    learning_pack["reflection_questions"] = _safe_list(
        learning_pack.get("reflection_questions")
    )
    learning_pack["competencies"] = _safe_list(learning_pack.get("competencies"))
    learning_pack["mastery_check"] = {
        **fallback.get("mastery_check", {}),
        **_safe_dict(learning_pack.get("mastery_check")),
    }
    learning_pack["created_at"] = learning_pack.get("created_at") or _utc_now()

    return learning_pack


def generate_learning_pack(
    *,
    audiobook_id: str = "",
    chapter_id: str,
    chapter_title: str = "",
    summary: str = "",
    script: str = "",
    transcript: str = "",
    key_concepts: list | None = None,
    language: str = "es",
) -> dict:
    source_text = truncate_text(
        clean_text(transcript) or clean_text(script) or clean_text(summary),
        max_characters=10000,
    )
    if not clean_text(chapter_id):
        raise ValueError("No se pudo identificar el capítulo.")
    if not source_text:
        raise ValueError("No hay contenido suficiente para generar actividades.")

    fallback = fallback_learning_pack(
        chapter_id=chapter_id,
        chapter_title=chapter_title,
        summary=summary,
        script=script,
        transcript=transcript,
        key_concepts=key_concepts,
    )
    language_instruction = build_language_instruction(language)

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Eres StudyBook AI, un diseñador de actividades de "
                        "aprendizaje para estudiantes. Devuelve solo JSON válido. "
                        f"{language_instruction}"
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        "Convierte el siguiente capítulo de un audio libro educativo "
                        "en un paquete de aprendizaje para estudiantes. Devuelve JSON "
                        "válido en español con resumen, flashcards, mini quiz de 5 "
                        "preguntas, preguntas de reflexión, competencias, dificultad, "
                        "tiempo estimado de estudio y mastery_check. No incluyas "
                        "markdown.\n\n"
                        f"AudioBook ID: {clean_text(audiobook_id)}\n"
                        f"Chapter ID: {clean_text(chapter_id)}\n"
                        f"Título: {clean_text(chapter_title)}\n"
                        f"Conceptos clave: {_safe_list(key_concepts)}\n\n"
                        f"Contenido del capítulo:\n{source_text}\n\n"
                        "Estructura obligatoria:\n"
                        "{\n"
                        '  "chapter_id": "...",\n'
                        '  "chapter_title": "...",\n'
                        '  "learning_pack_version": "A",\n'
                        '  "summary": "...",\n'
                        '  "estimated_study_minutes": 0,\n'
                        '  "difficulty": "Básica/Media/Avanzada",\n'
                        '  "key_concepts": ["..."],\n'
                        '  "flashcards": [{"front": "...", "back": "...", "hint": "..."}],\n'
                        '  "mini_quiz": [{"question": "...", "options": ["...", "...", "...", "..."], "correct_answer": "...", "explanation": "...", "bloom_level": "Comprender"}],\n'
                        '  "reflection_questions": ["..."],\n'
                        '  "competencies": ["..."],\n'
                        '  "mastery_check": {"initial_score": 0, "status": "Pendiente", "recommendation": "..."},\n'
                        '  "created_at": "..."\n'
                        "}"
                    ),
                },
            ],
            temperature=0.35,
        )
        content = response.choices[0].message.content.strip()
        raw = json.loads(content)
        if not isinstance(raw, dict):
            return fallback
        return normalize_learning_pack(raw, fallback)
    except Exception:
        print("AudioBook Learning Pack: fallback local aplicado.")
        return fallback


def audiobook_audio_path(filename: str) -> Path | None:
    clean_filename = _safe_audio_filename(filename)
    if not clean_filename.endswith(".mp3"):
        return None

    audio_path = AUDIOBOOK_AUDIO_DIR / clean_filename
    if not audio_path.exists() or not audio_path.is_file():
        return None

    return audio_path
