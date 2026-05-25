from dotenv import load_dotenv
from openai import OpenAI

from app.services.rag_service import (
    store_document_embeddings,
    search_similar_chunks,
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


def generate_ai_summary(text: str) -> str:
    document_text = truncate_text(text)

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
                    "educativa, estructurada y útil para estudiantes."
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


def chat_with_document_id(
    document_id: str,
    question: str,
) -> str:
    clean_question = clean_text(question)

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

    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres StudyBook AI, un tutor universitario experto. "
                    "Responde SOLO utilizando el contexto recuperado del documento. "
                    "No inventes información. Si el documento no contiene la respuesta, "
                    "indícalo claramente. Explica de forma académica, precisa y útil."
                ),
            },
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
) -> str:
    document_id = index_document_for_rag(text)

    return chat_with_document_id(
        document_id=document_id,
        question=question,
    )


def generate_exam_questions(
    text: str,
    number_of_questions: int = 5,
) -> str:
    document_text = truncate_text(text)

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
                    "múltiple basadas únicamente en el documento."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Documento:\n\n{document_text}\n\n"
                    f"Genera {safe_number} preguntas de selección múltiple.\n\n"
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
) -> str:
    document_text = truncate_text(text)

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
                    "Genera flashcards académicas basadas únicamente en el documento."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Documento:\n\n{document_text}\n\n"
                    f"Genera {safe_number} flashcards.\n\n"
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
) -> str:
    document_text = truncate_text(context)

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
                    "Eres StudyBook AI, un profesor universitario experto."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto:\n\n{document_text}\n\n"
                    f"Genera {safe_number} preguntas.\n\n"
                    "Devuelve JSON válido."
                ),
            },
        ],
        temperature=0.35,
    )

    return response.choices[0].message.content.strip()


def generate_flashcards_from_context(
    context: str,
    number_of_cards: int = 10,
) -> str:
    document_text = truncate_text(context)

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
                    "Eres StudyBook AI, experto en aprendizaje."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Contexto:\n\n{document_text}\n\n"
                    f"Genera {safe_number} flashcards.\n\n"
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
):
    clean_question = clean_text(question)

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
                    "del documento. No inventes información."
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
