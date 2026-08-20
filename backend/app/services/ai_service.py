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
    *,
    owner_scope: str | None = None,
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

    return store_document_page_embeddings(
        clean_pages,
        owner_scope=owner_scope,
    )


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
    exam_type: str = "Selección múltiple",
    difficulty: str = "Intermedio",
    total_points: int = 100,
    exam_topic: str = "",
    exam_objective: str = "",
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay contexto válido para generar preguntas.")

    safe_number = max(1, min(number_of_questions, 100))
    clean_type = (exam_type or "Selección múltiple").strip().lower()

    if "verdadero" in clean_type or "falso" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Verdadero/Falso.
Todas las preguntas deben tener:
- question_type: "Verdadero/Falso"
- options: {"A": "Verdadero", "B": "Falso"}
- correct_answer: "A" o "B"
NO uses opciones C ni D.
"""
    elif "mixto" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Mixto real.
Distribuye las preguntas entre varios tipos:
- Selección múltiple
- Verdadero/Falso
- Completar espacios
- Pregunta abierta
- Análisis de caso
No generes todas del mismo tipo.
"""
    elif "abierta" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Preguntas abiertas.
Todas las preguntas deben tener:
- question_type: "Pregunta abierta"
- options: {}
- correct_answer: respuesta modelo o criterios mínimos.
NO uses selección múltiple.
"""
    elif "caso" in clean_type or "análisis" in clean_type or "analisis" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Análisis de caso.
Todas las preguntas deben presentar un caso o situación aplicada.
Deben tener:
- question_type: "Análisis de caso"
- options: {}
- correct_answer: criterios de evaluación o respuesta modelo.
NO uses selección múltiple.
"""
    elif "ensayo" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Ensayo corto.
Todas las preguntas deben tener:
- question_type: "Ensayo corto"
- options: {}
- correct_answer: criterios de evaluación.
NO uses selección múltiple.
"""
    elif "completar" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Completar espacios.
Todas las preguntas deben tener:
- question_type: "Completar espacios"
- options: {}
- correct_answer: término o frase correcta.
"""
    elif "relacionar" in clean_type:
        format_rule = """
TIPO OBLIGATORIO: Relacionar columnas.
Todas las preguntas deben tener:
- question_type: "Relacionar columnas"
- options: objeto con columnas o pares.
- correct_answer: relaciones correctas.
"""
    else:
        format_rule = """
TIPO OBLIGATORIO: Selección múltiple.
Todas las preguntas deben tener:
- question_type: "Selección múltiple"
- options: {"A": "...", "B": "...", "C": "...", "D": "..."}
- correct_answer: "A", "B", "C" o "D"
"""

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, profesor universitario experto en evaluación académica. "
                    "Diseña exámenes claros, válidos y alineados al programa de clase. "
                    "Respeta estrictamente el tipo de examen solicitado. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto del programa:\n\n{document_text}\n\n"
                    f"Cantidad de preguntas: {safe_number}\n"
                    f"Tipo solicitado: {exam_type}\n"
                    f"Dificultad: {difficulty}\n"
                    f"Valor total: {total_points} puntos\n"
                    f"Tema específico: {exam_topic or 'No especificado'}\n"
                    f"Objetivo de evaluación: {exam_objective or 'No especificado'}\n\n"
                    f"{format_rule}\n\n"
                    "Si hay tema u objetivo específico, enfoca el examen exclusivamente en eso, "
                    "sin salirte del documento base.\n\n"
                    "Devuelve EXCLUSIVAMENTE JSON válido con esta estructura:\n"
                    "{\n"
                    '  "questions": [\n'
                    "    {\n"
                    '      "question_type": "...",\n'
                    '      "question": "...",\n'
                    '      "options": {},\n'
                    '      "correct_answer": "...",\n'
                    '      "explanation": "...",\n'
                    '      "topic": "...",\n'
                    '      "difficulty": "..."\n'
                    "    }\n"
                    "  ]\n"
                    "}\n"
                ),
            },
        ],
        temperature=0.25,
    )

    return response.choices[0].message.content.strip()


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
    rubric_type: str = "Analítica",
    criteria_count: int = 5,
    performance_levels: int = 4,
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
                    f"Genera una rúbrica académica de tipo {rubric_type}, con {criteria_count} criterios, {performance_levels} niveles de desempeño y total de {safe_points} puntos.\n\n"
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


def generate_study_guide_from_context(
    context: str,
    language: str = "es",
    program_topic: str = "",
    learning_objective: str = "",
    competency: str = "",
    guide_type: str = "student",
    include_summary: bool = True,
    include_key_concepts: bool = True,
    include_practice_activities: bool = True,
    include_self_assessment: bool = True,
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay contexto válido para generar la guía de estudio.")

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, especialista universitario en diseño de guías "
                    "de estudio para estudiantes. Genera materiales claros, prácticos "
                    "y alineados al contenido de la unidad. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto del documento:\n\n{document_text}\n\n"
                    f"Tema del programa: {program_topic}\n"
                    f"Objetivo de aprendizaje: {learning_objective}\n"
                    f"Competencia: {competency}\n"
                    f"Tipo de guía: {guide_type}\n\n"
                    "Genera una guía de estudio para una unidad didáctica.\n"
                    f"Incluir resumen: {include_summary}.\n"
                    f"Incluir conceptos clave: {include_key_concepts}.\n"
                    f"Incluir actividades de práctica: {include_practice_activities}.\n"
                    f"Incluir autoevaluación: {include_self_assessment}.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, "
                    "pero redacta los valores visibles en el idioma solicitado. "
                    "Devuelve EXCLUSIVAMENTE JSON válido.\n\n"
                    "{\n"
                    '  "summary": "...",\n'
                    '  "key_concepts": ["...", "..."],\n'
                    '  "learning_objectives": ["...", "..."],\n'
                    '  "study_steps": ["...", "..."],\n'
                    '  "practice_activities": ["...", "..."],\n'
                    '  "self_assessment": ["...", "..."],\n'
                    '  "recommendations": ["...", "..."]\n'
                    "}"
                ),
            },
        ],
        temperature=0.3,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "summary": content,
                "key_concepts": [],
                "learning_objectives": [],
                "study_steps": [],
                "practice_activities": [],
                "self_assessment": [],
                "recommendations": [],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content


def generate_teaching_resources_from_context(
    context: str,
    language: str = "es",
    program_topic: str = "",
    learning_objective: str = "",
    competency: str = "",
    include_presentation_outline: bool = True,
    include_class_activities: bool = True,
    include_collaborative_activities: bool = True,
    include_discussion_questions: bool = True,
    include_problem_based_learning: bool = True,
    include_gamification_ideas: bool = True,
    include_homework: bool = True,
    include_accessibility_adaptations: bool = True,
    include_complementary_readings: bool = True,
    include_multimedia_suggestions: bool = True,
    include_web_resources: bool = True,
    include_ai_prompts_for_students: bool = True,
) -> str:
    document_text = truncate_text(context)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay contexto válido para generar recursos docentes.")

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, especialista universitario en diseño de "
                    "recursos docentes por unidad didáctica. Genera materiales "
                    "prácticos, accionables y alineados al currículo. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto del documento:\n\n{document_text}\n\n"
                    f"Tema del programa: {program_topic}\n"
                    f"Objetivo de aprendizaje: {learning_objective}\n"
                    f"Competencia: {competency}\n\n"
                    "Genera un paquete de recursos docentes para una unidad didáctica.\n"
                    f"Incluir esquema de presentación: {include_presentation_outline}.\n"
                    f"Incluir actividades de clase: {include_class_activities}.\n"
                    f"Incluir actividades colaborativas: {include_collaborative_activities}.\n"
                    f"Incluir preguntas de discusión: {include_discussion_questions}.\n"
                    f"Incluir aprendizaje basado en problemas: {include_problem_based_learning}.\n"
                    f"Incluir gamificación: {include_gamification_ideas}.\n"
                    f"Incluir tareas: {include_homework}.\n"
                    f"Incluir adaptaciones de accesibilidad: {include_accessibility_adaptations}.\n"
                    f"Incluir lecturas complementarias: {include_complementary_readings}.\n"
                    f"Incluir multimedia: {include_multimedia_suggestions}.\n"
                    f"Incluir recursos web: {include_web_resources}.\n"
                    f"Incluir prompts de IA para estudiantes: {include_ai_prompts_for_students}.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, "
                    "pero redacta los valores visibles en el idioma solicitado. "
                    "Devuelve EXCLUSIVAMENTE JSON válido.\n\n"
                    "{\n"
                    '  "presentation_outline": [],\n'
                    '  "class_activities": [],\n'
                    '  "collaborative_activities": [],\n'
                    '  "discussion_questions": [],\n'
                    '  "problem_based_learning": [],\n'
                    '  "gamification_ideas": [],\n'
                    '  "homework": [],\n'
                    '  "accessibility_adaptations": [],\n'
                    '  "complementary_readings": [],\n'
                    '  "multimedia_suggestions": [],\n'
                    '  "web_resources": [],\n'
                    '  "ai_prompts_for_students": [],\n'
                    '  "teacher_recommendations": []\n'
                    "}"
                ),
            },
        ],
        temperature=0.3,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "presentation_outline": [],
                "class_activities": [],
                "collaborative_activities": [],
                "discussion_questions": [],
                "problem_based_learning": [],
                "gamification_ideas": [],
                "homework": [],
                "accessibility_adaptations": [],
                "complementary_readings": [],
                "multimedia_suggestions": [],
                "web_resources": [],
                "ai_prompts_for_students": [],
                "teacher_recommendations": [content],
                "error": "La IA no devolvió JSON válido.",
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content


def generate_assessment_report_from_payload(
    payload: dict,
    language: str = "es",
) -> str:
    payload_text = truncate_text(
        json.dumps(payload, ensure_ascii=False),
        max_characters=18000,
    )
    language_instruction = build_language_instruction(language)

    if not payload_text:
        raise ValueError("No hay recursos válidos para analizar la evaluación.")

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, arquitecto académico especializado en "
                    "coherencia evaluativa por unidad didáctica. Analiza cobertura, "
                    "alineación, riesgos y calidad académica con criterios claros. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    "Analiza el siguiente paquete académico de unidad:\n\n"
                    f"{payload_text}\n\n"
                    "Evalúa coherencia entre banco de preguntas, examen, rúbrica, guía, "
                    "objetivos y competencias. Si faltan recursos, decláralo en risks y "
                    "recommendations, pero calcula lo que sea posible.\n\n"
                    "IMPORTANTE: conserva las claves JSON en inglés exactamente como se indican, "
                    "pero redacta los valores visibles en el idioma solicitado. "
                    "Todos los puntajes deben estar entre 0 y 100. "
                    "Devuelve EXCLUSIVAMENTE JSON válido.\n\n"
                    "{\n"
                    '  "objectives_coverage": 0,\n'
                    '  "competencies_coverage": 0,\n'
                    '  "bloom_distribution": {\n'
                    '    "recordar": 0,\n'
                    '    "comprender": 0,\n'
                    '    "aplicar": 0,\n'
                    '    "analizar": 0,\n'
                    '    "evaluar": 0,\n'
                    '    "crear": 0\n'
                    "  },\n"
                    '  "estimated_difficulty": "Media",\n'
                    '  "estimated_time_minutes": 0,\n'
                    '  "duplicate_questions_count": 0,\n'
                    '  "exam_rubric_alignment": 0,\n'
                    '  "exam_guide_alignment": 0,\n'
                    '  "academic_quality_score": 0,\n'
                    '  "strengths": [],\n'
                    '  "risks": [],\n'
                    '  "recommendations": [],\n'
                    '  "coverage_details": {\n'
                    '    "covered_objectives": [],\n'
                    '    "uncovered_objectives": [],\n'
                    '    "covered_competencies": [],\n'
                    '    "uncovered_competencies": []\n'
                    "  }\n"
                    "}"
                ),
            },
        ],
        temperature=0.2,
    )

    content = response.choices[0].message.content.strip()

    try:
        json.loads(content)
    except json.JSONDecodeError:
        return json.dumps(
            {
                "objectives_coverage": 0,
                "competencies_coverage": 0,
                "bloom_distribution": {
                    "recordar": 0,
                    "comprender": 0,
                    "aplicar": 0,
                    "analizar": 0,
                    "evaluar": 0,
                    "crear": 0,
                },
                "estimated_difficulty": "Media",
                "estimated_time_minutes": 0,
                "duplicate_questions_count": 0,
                "exam_rubric_alignment": 0,
                "exam_guide_alignment": 0,
                "academic_quality_score": 0,
                "strengths": [],
                "risks": ["La IA no devolvió JSON válido."],
                "recommendations": [
                    "Revisar manualmente la coherencia entre examen, rúbrica y guía."
                ],
                "coverage_details": {
                    "covered_objectives": [],
                    "uncovered_objectives": [],
                    "covered_competencies": [],
                    "uncovered_competencies": [],
                },
                "raw_response": content,
            },
            ensure_ascii=False,
        )

    return content


def parse_grades_from_text(
    text: str,
    language: str = "es",
) -> str:
    document_text = truncate_text(text, max_chars=18000)
    language_instruction = build_language_instruction(language)

    if not document_text:
        raise ValueError("No hay texto válido para extraer calificaciones.")

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, especialista en análisis académico. "
                    "Extrae calificaciones de textos, tablas pegadas, reportes o actas. "
                    "Devuelve exclusivamente JSON válido. "
                    f"{language_instruction}"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Texto fuente:\n\n{document_text}\n\n"
                    "Extrae las calificaciones encontradas y devuelve JSON válido con esta estructura:\n"
                    "{\n"
                    '  "grades": [\n'
                    "    {\n"
                    '      "student_code": "...",\n'
                    '      "student_name": "...",\n'
                    '      "assessment": "...",\n'
                    '      "score": 0,\n'
                    '      "max_score": 100,\n'
                    '      "course": "...",\n'
                    '      "notes": "..."\n'
                    "    }\n"
                    "  ]\n"
                    "}\n"
                ),
            },
        ],
        temperature=0.1,
    )

    return response.choices[0].message.content.strip()


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


def ask_ai_coach(
    message: str,
    context: dict | None = None,
    recent_messages: list | None = None,
    mode: str = "general",
    language: str = "es",
) -> dict:
    clean_message = clean_text(message)
    language_instruction = build_language_instruction(language)

    if not clean_message:
        raise ValueError("La pregunta del estudiante está vacía.")

    safe_context = context or {}
    safe_mode = clean_text(mode) or "general"

    context_summary = {
        "audiobook_title": clean_text(str(safe_context.get("audiobookTitle", ""))),
        "chapter_title": clean_text(str(safe_context.get("chapterTitle", ""))),
        "chapter_summary": clean_text(str(safe_context.get("chapterSummary", ""))),
        "key_concepts": safe_context.get("keyConcepts", []),
        "learning_pack_summary": clean_text(
            str(safe_context.get("learningPackSummary", ""))
        ),
        "competencies": safe_context.get("competencies", []),
        "mastery": safe_context.get("mastery", {}),
        "recommendations": safe_context.get("recommendations", []),
    }

    transcript = truncate_text(
        str(safe_context.get("transcript", "")),
        max_characters=5000,
    )

    memory_messages = build_memory_messages(
        recent_messages if isinstance(recent_messages, list) else [],
        max_messages=6,
    )

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Eres el Tutor IA de StudyBook AI. "
                        "Actúas como un coach educativo claro, breve, motivador y pedagógico. "
                        "Responde usando el contexto académico proporcionado. "
                        "Si el estudiante pide explicación, explica paso a paso. "
                        "Si pide práctica o preguntas, formula una pregunta concreta. "
                        "Si pide repaso, resume y recomienda qué hacer después. "
                        "No inventes datos fuera del contexto. "
                        "No menciones IDs técnicos, JSON ni detalles internos. "
                        f"Modo solicitado: {safe_mode}. "
                        f"{language_instruction}"
                    ),
                },
                *memory_messages,
                {
                    "role": "user",
                    "content": (
                        "Contexto académico resumido:\n"
                        f"{json.dumps(context_summary, ensure_ascii=False)}\n\n"
                        "Transcripción parcial del capítulo:\n"
                        f"{transcript}\n\n"
                        "Mensaje del estudiante:\n"
                        f"{clean_message}\n\n"
                        "Devuelve una respuesta útil, breve y accionable. "
                        "No uses markdown excesivo."
                    ),
                },
            ],
            temperature=0.35,
        )

        text = clean_text(response.choices[0].message.content)

        if not text:
            text = (
                "Puedo ayudarte con este capítulo. Te recomiendo revisar el resumen, "
                "escuchar nuevamente el audio y responder el mini quiz."
            )

        return {
            "text": text,
            "suggestions": [
                "Explícame con otro ejemplo",
                "Hazme una pregunta",
                "Resume lo más importante",
            ],
            "follow_up_questions": [
                "¿Quieres practicar con una pregunta?",
                "¿Deseas repasar los conceptos clave?",
            ],
            "detected_intent": safe_mode,
            "confidence": 0.85,
        }
    except Exception:
        return {
            "text": (
                "Puedo ayudarte con este capítulo. Te recomiendo revisar el resumen, "
                "escuchar nuevamente el audio y responder el mini quiz."
            ),
            "suggestions": [
                "Explícame el capítulo",
                "Hazme preguntas",
                "Dame un resumen",
            ],
            "follow_up_questions": [
                "¿Qué parte quieres repasar primero?",
            ],
            "detected_intent": safe_mode,
            "confidence": 0.55,
        }
