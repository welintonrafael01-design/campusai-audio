from dotenv import load_dotenv
from openai import OpenAI

from app.services.rag_service import (
    store_document_embeddings,
    store_document_page_embeddings,
    search_similar_chunks,
    search_similar_chunks_multi,
)

import json
import os


load_dotenv()

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

MODEL_NAME = os.getenv(
    "OPENAI_MODEL",
    "gpt-5.4-mini",
)

MAX_CONTEXT_CHARACTERS = 12000


SUPPORTED_LANGUAGE_INSTRUCTIONS = {
    "es": "Responde siempre en español.",
    "en": "Always respond in English.",
    "pt": "Responda sempre em português.",
    "fr": "Réponds toujours en français.",
}


def normalize_language(language: str | None = None) -> str:
    clean_language = (language or "es").strip().lower()

    if clean_language not in SUPPORTED_LANGUAGE_INSTRUCTIONS:
        return "es"

    return clean_language


def build_language_instruction(language: str | None = None) -> str:
    return SUPPORTED_LANGUAGE_INSTRUCTIONS[
        normalize_language(language)
    ]



def clean_text(text: str) -> str:
    if not text:
        return ""

    return (
        text.replace("\x00", "")
        .replace("\r", " ")
        .replace("\t", " ")
        .strip()
    )


def truncate_text(
    text: str,
    max_characters: int = MAX_CONTEXT_CHARACTERS,
) -> str:
    clean = clean_text(text)

    return clean[:max_characters]





def build_memory_messages(
    history: list[dict] | None,
    max_messages: int = 8,
) -> list[dict]:
    if not history:
        return []

    safe_history = history[-max_messages:]

    messages: list[dict] = []

    for item in safe_history:
        role = item.get("role", "")
        content = clean_text(item.get("content", ""))

        if role not in ["user", "assistant"]:
            continue

        if not content:
            continue

        messages.append(
            {
                "role": role,
                "content": content[:2000],
            }
        )

    return messages


def generate_ai_summary(text: str, language: str = "es") -> str:
    document_text = truncate_text(text)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError(
            "No hay texto válido para resumir."
        )

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor universitario experto. "
                    "Resume documentos académicos de forma clara, profesional, "
                    "educativa, estructurada y útil para estudiantes. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    "Resume el siguiente documento académico. "
                    "Incluye: tema central, ideas principales, conceptos clave "
                    "y utilidad académica.\n\n"
                    f"{document_text}"
                ),
            },
        ],
        temperature=0.4,
    )

    return response.choices[0].message.content.strip()


def index_document_for_rag(text: str) -> str:
    clean = clean_text(text)

    if not clean:
        raise ValueError(
            "No hay texto válido para indexar."
        )

    return store_document_embeddings(clean)


def index_document_pages_for_rag(
    pages: list[dict],
) -> str:
    if not pages:
        raise ValueError(
            "No hay páginas válidas para indexar."
        )

    clean_pages: list[dict] = []

    for page in pages:
        page_number = page.get("page_number")
        text = clean_text(page.get("text", ""))

        if not page_number or not text:
            continue

        clean_pages.append(
            {
                "page_number": page_number,
                "text": text,
            }
        )

    if not clean_pages:
        raise ValueError(
            "No hay texto válido por páginas para indexar."
        )

    return store_document_page_embeddings(clean_pages)


def chat_with_document_id(
    document_id: str,
    question: str,
    history: list[dict] | None = None,
    language: str = "es",
) -> str:
    clean_question = clean_text(question)
    language_instruction = build_language_instruction(language)

    if not document_id.strip():
        raise ValueError(
            "document_id inválido."
        )

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
        )

    relevant_context = search_similar_chunks(
        document_id=document_id,
        question=clean_question,
        top_k=5,
    )

    if not relevant_context.strip():
        return (
            "No se encontró contexto suficiente en el documento "
            "para responder esta pregunta."
        )

    memory_messages = build_memory_messages(history)

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor universitario experto. "
                    "Mantén continuidad conversacional con el estudiante. "
                    "Responde SOLO utilizando el contexto recuperado del documento. "
                    "No inventes información. No muestres identificadores técnicos como document_id, chunk, [FUENTE...] ni metadatos internos en la respuesta visible; esos datos serán usados por la interfaz para mostrar citas. No muestres identificadores técnicos como document_id, chunk, [FUENTE...] ni metadatos internos en la respuesta visible; esos datos serán usados por la interfaz para mostrar citas. "
                    "Si el documento no contiene la respuesta, indícalo claramente. "
                    f"{language_instruction}"
                ),
            },

            *memory_messages,

            {
                "role": "user",
                "content": (
                    "Contexto recuperado del documento:\n\n"
                    f"{relevant_context}\n\n"
                    "Pregunta del estudiante:\n"
                    f"{clean_question}"
                ),
            },
        ],
        temperature=0.3,
    )

    return response.choices[0].message.content.strip()


def chat_with_document(
    text: str,
    question: str,
    language: str = "es",
) -> str:
    document_id = index_document_for_rag(text)

    return chat_with_document_id(
        document_id=document_id,
        question=question,
        language=language,
    )


def generate_exam_questions(
    text: str,
    number_of_questions: int = 5,
    language: str = "es",
) -> str:
    document_text = truncate_text(text)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError(
            "No hay texto válido para generar preguntas."
        )

    safe_number = max(
        1,
        min(number_of_questions, 20),
    )

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un profesor universitario experto "
                    "en evaluación académica. Genera preguntas de selección "
                    "múltiple basadas únicamente en el documento. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Documento:\n\n{document_text}\n\n"
                    f"Genera {safe_number} preguntas de selección múltiple.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, pero redacta los valores visibles para estudiantes en el idioma solicitado."
                    "Devuelve exclusivamente JSON válido con esta estructura:\n"
                    "{\n"
                    '  "questions": [\n'
                    "    {\n"
                    '      "question": "...",\n'
                    '      "options": {\n'
                    '        "A": "...",\n'
                    '        "B": "...",\n'
                    '        "C": "...",\n'
                    '        "D": "..."\n'
                    "      },\n"
                    '      "correct_answer": "A",\n'
                    '      "explanation": "..."\n'
                    "    }\n"
                    "  ]\n"
                    "}"
                ),
            },
        ],
        temperature=0.35,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "questions": [],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content
def generate_flashcards(
    text: str,
    number_of_cards: int = 10,
    language: str = "es",
) -> str:
    document_text = truncate_text(text)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay texto válido para generar flashcards.")

    safe_number = max(1, min(number_of_cards, 30))

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor universitario experto. "
                    "Genera flashcards académicas basadas únicamente en el documento. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Documento:\n\n{document_text}\n\n"
                    f"Genera {safe_number} flashcards.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, pero redacta los valores visibles para estudiantes en el idioma solicitado."
                    "Devuelve exclusivamente JSON válido con esta estructura:\n"
                    "{\n"
                    '  "flashcards": [\n'
                    "    {\n"
                    '      "question": "...",\n'
                    '      "answer": "..."\n'
                    "    }\n"
                    "  ]\n"
                    "}"
                ),
            },
        ],
        temperature=0.35,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "flashcards": [],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content


def generate_exam_questions_from_context(
    context: str,
    number_of_questions: int = 5,
    language: str = "es",
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError(
            "No hay contexto válido para generar preguntas."
        )

    safe_number = max(
        1,
        min(number_of_questions, 20),
    )

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, profesor universitario experto. "
                    "Genera EXCLUSIVAMENTE preguntas de selección múltiple. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto:\n\n{document_text}\n\n"
                    f"Genera {safe_number} preguntas.\n\n"

                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, pero redacta los valores visibles para estudiantes en el idioma solicitado."
                    "Devuelve EXCLUSIVAMENTE JSON válido.\n\n"

                    "{\n"
                    '  "questions": [\n'
                    "    {\n"
                    '      "question": "...",\n'
                    '      "options": {\n'
                    '        "A": "...",\n'
                    '        "B": "...",\n'
                    '        "C": "...",\n'
                    '        "D": "..."\n'
                    "      },\n"
                    '      "correct_answer": "A",\n'
                    '      "explanation": "..."\n'
                    "    }\n"
                    "  ]\n"
                    "}\n\n"

                    "TODAS las preguntas deben tener "
                    "A, B, C y D."
                ),
            },
        ],
        temperature=0.3,
    )

    content = (
        response.choices[0]
        .message
        .content
        .strip()
    )

    return content


def generate_flashcards_from_context(
    context: str,
    number_of_cards: int = 10,
    language: str = "es",
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError(
            "No hay contexto válido para generar flashcards."
        )

    safe_number = max(
        1,
        min(number_of_cards, 30),
    )

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, experto en aprendizaje. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto:\n\n{document_text}\n\n"
                    f"Genera {safe_number} flashcards.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, pero redacta los valores visibles para estudiantes en el idioma solicitado."
                    "Devuelve JSON válido."
                ),
            },
        ],
        temperature=0.35,
    )

    return response.choices[0].message.content.strip()

async def stream_chat_with_document_id(
    document_id: str,
    question: str,
    language: str = "es",
):
    clean_question = clean_text(question)
    language_instruction = build_language_instruction(language)

    if not document_id.strip():
        raise ValueError(
            "document_id inválido."
        )

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
        )

    relevant_context = search_similar_chunks(
        document_id=document_id,
        question=clean_question,
        top_k=5,
    )

    if not relevant_context.strip():
        yield (
            "No se encontró contexto suficiente "
            "en el documento."
        )
        return

    stream = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor universitario experto. "
                    "Responde SOLO utilizando el contexto recuperado "
                    "del documento. No inventes información. No muestres identificadores técnicos como document_id, chunk, [FUENTE...] ni metadatos internos en la respuesta visible; esos datos serán usados por la interfaz para mostrar citas. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    "Contexto recuperado:\n\n"
                    f"{relevant_context}\n\n"
                    "Pregunta:\n"
                    f"{clean_question}"
                ),
            },
        ],
        temperature=0.3,
        stream=True,
    )

    for chunk in stream:
        delta = (
            chunk.choices[0]
            .delta
            .content
        )

        if delta:
            yield delta



def chat_with_workspace(
    document_ids: list[str],
    question: str,
    history: list[dict] | None = None,
    language: str = "es",
) -> str:
    clean_question = clean_text(question)
    language_instruction = build_language_instruction(language)

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
        )

    relevant_context = search_similar_chunks_multi(
        document_ids=document_ids,
        question=clean_question,
        top_k_per_document=4,
    )

    if not relevant_context.strip():
        return (
            "No se encontró contexto suficiente "
            "en los documentos del workspace."
        )

    memory_messages = build_memory_messages(history)

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor universitario experto. "
                    "Mantén continuidad conversacional con el estudiante. "
                    "Puedes combinar información de múltiples documentos "
                    "del workspace. Responde únicamente usando el contexto "
                    "recuperado. No inventes información. No muestres identificadores técnicos como document_id, chunk, [FUENTE...] ni metadatos internos en la respuesta visible; esos datos serán usados por la interfaz para mostrar citas. "
                    f"{language_instruction}"
                ),
            },

            *memory_messages,

            {
                "role": "user",
                "content": (
                    "Contexto recuperado del workspace:\n\n"
                    f"{relevant_context}\n\n"
                    "Pregunta del estudiante:\n"
                    f"{clean_question}"
                ),
            },
        ],
        temperature=0.3,
    )

    return response.choices[0].message.content.strip()


async def stream_chat_with_workspace(
    document_ids: list[str],
    question: str,
    language: str = "es",
):
    clean_question = clean_text(question)
    language_instruction = build_language_instruction(language)

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
        )

    relevant_context = search_similar_chunks_multi(
        document_ids=document_ids,
        question=clean_question,
        top_k_per_document=4,
    )

    if not relevant_context.strip():
        yield (
            "No se encontró contexto suficiente "
            "en el workspace."
        )
        return

    stream = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor experto "
                    "capaz de combinar múltiples documentos."
                ),
            },
            {
                "role": "user",
                "content": (
                    "Contexto recuperado:\n\n"
                    f"{relevant_context}\n\n"
                    "Pregunta:\n"
                    f"{clean_question}"
                ),
            },
        ],
        temperature=0.3,
        stream=True,
    )

    for chunk in stream:
        delta = (
            chunk.choices[0]
            .delta
            .content
        )

        if delta:
            yield delta


def generate_academic_rubric_from_context(
    context: str,
    language: str = "es",
    total_points: int = 100,
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay contexto válido para generar la rúbrica.")

    safe_points = max(10, min(total_points, 100))

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, especialista universitario en evaluación académica. "
                    "Genera rúbricas claras, medibles y profesionales. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto del documento:\n\n{document_text}\n\n"
                    f"Genera una rúbrica académica con total de {safe_points} puntos.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, "
                    "pero redacta los valores visibles en el idioma solicitado. "
                    "Devuelve EXCLUSIVAMENTE JSON válido.\n\n"
                    "{\n"
                    '  "title": "...",\n'
                    '  "total_points": 100,\n'
                    '  "criteria": [\n'
                    "    {\n"
                    '      "criterion": "...",\n'
                    '      "description": "...",\n'
                    '      "points": 20,\n'
                    '      "levels": {\n'
                    '        "excellent": "...",\n'
                    '        "good": "...",\n'
                    '        "basic": "...",\n'
                    '        "insufficient": "..."\n'
                    "      }\n"
                    "    }\n"
                    "  ],\n"
                    '  "recommendations": ["...", "..."]\n'
                    "}\n\n"
                    "La suma de points debe ser igual al total_points."
                ),
            },
        ],
        temperature=0.25,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "title": "Rúbrica académica",
                "total_points": safe_points,
                "criteria": [],
                "recommendations": [],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content


def generate_teaching_plan_from_context(
    context: str,
    language: str = "es",
    weeks: int = 4,
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay contexto válido para generar la planificación docente.")

    safe_weeks = max(1, min(weeks, 16))

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, experto en planificación docente, diseño curricular "
                    "y evaluación educativa. Genera planificaciones claras, aplicables y profesionales. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto del documento:\n\n{document_text}\n\n"
                    f"Genera una planificación docente de {safe_weeks} semanas.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, "
                    "pero redacta los valores visibles en el idioma solicitado. "
                    "Devuelve EXCLUSIVAMENTE JSON válido.\n\n"
                    "{\n"
                    '  "title": "...",\n'
                    '  "subject": "...",\n'
                    '  "general_objective": "...",\n'
                    '  "competencies": ["...", "..."],\n'
                    '  "methodology": "...",\n'
                    '  "resources": ["...", "..."],\n'
                    '  "evaluation_strategy": "...",\n'
                    '  "weeks": [\n'
                    "    {\n"
                    '      "week": 1,\n'
                    '      "topic": "...",\n'
                    '      "objectives": ["...", "..."],\n'
                    '      "contents": ["...", "..."],\n'
                    '      "activities": ["...", "..."],\n'
                    '      "assessment": "...",\n'
                    '      "resources": ["...", "..."]\n'
                    "    }\n"
                    "  ],\n"
                    '  "recommendations": ["...", "..."]\n'
                    "}\n"
                ),
            },
        ],
        temperature=0.25,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "title": "Planificación docente",
                "subject": "",
                "general_objective": "",
                "competencies": [],
                "methodology": "",
                "resources": [],
                "evaluation_strategy": "",
                "weeks": [],
                "recommendations": [],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content


def parse_students_from_text(
    text: str,
    language: str = "es",
) -> str:
    document_text = truncate_text(text)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay texto válido para importar estudiantes.")

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, experto en extraer listados académicos. "
                    "Debes identificar estudiantes en textos provenientes de PDF, tablas, listas o reportes. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Texto extraído del documento:\n\n{document_text}\n\n"
                    "Extrae únicamente los estudiantes encontrados. "
                    "Devuelve EXCLUSIVAMENTE JSON válido con esta estructura exacta:\n\n"
                    "{\n"
                    '  "students": [\n'
                    "    {\n"
                    '      "name": "...",\n'
                    '      "course": "...",\n'
                    '      "email": "",\n'
                    '      "student_code": ""\n'
                    "    }\n"
                    "  ]\n"
                    "}\n\n"
                    "Reglas:\n"
                    "- Si no hay correo, usa cadena vacía.\n"
                    "- Si no hay curso, intenta inferirlo del encabezado; si no, cadena vacía.\n"
                    "- No inventes estudiantes.\n"
                    "- No incluyas docentes, autoridades ni encabezados.\n"
                    "- Normaliza nombres con mayúsculas y minúsculas correctas."
                ),
            },
        ],
        temperature=0.1,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "students": [],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content
