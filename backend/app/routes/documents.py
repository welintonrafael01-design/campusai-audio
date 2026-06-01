import time
import asyncio
from pathlib import Path
from uuid import uuid4

from fastapi.responses import StreamingResponse, FileResponse

from fastapi import (
    APIRouter,
    Body,
    File,
    HTTPException,
    Query,
    UploadFile,
)

from app.services.ai_service import (
    chat_with_document,
    chat_with_document_id,
    chat_with_workspace,
    generate_ai_summary,
    generate_exam_questions,
    generate_exam_questions_from_context,
    generate_flashcards,
    generate_flashcards_from_context,
    index_document_for_rag,
    index_document_pages_for_rag,
    stream_chat_with_document_id,
    stream_chat_with_workspace,
)

from app.services.audio_service import (
    build_audio_url,
    generate_audio_from_text,
)

from app.services.pdf_service import (
    extract_text_from_pdf,
    extract_pages_from_pdf,
)

from app.services.document_registry_service import (
    register_document_file,
    get_document_info,
)

from app.services.rag_service import (
    search_similar_chunks,
    semantic_search_all_documents,
    get_source_chunk,
    get_retrieval_citations,
)

router = APIRouter(
    prefix="/documents",
    tags=["Documents"],
)

BASE_DIR = Path(__file__).resolve().parent.parent.parent

UPLOAD_FOLDER = BASE_DIR / "uploads"

UPLOAD_FOLDER.mkdir(
    parents=True,
    exist_ok=True,
)

MAX_UPLOAD_SIZE_MB = 25


def validate_pdf_file(
    file: UploadFile,
) -> None:
    filename = file.filename or ""

    if not filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Solo se permiten archivos PDF.",
        )


def build_safe_file_path(
    filename: str,
) -> Path:
    safe_name = Path(filename).name

    unique_name = (
        f"{uuid4()}_{safe_name}"
    )

    return UPLOAD_FOLDER / unique_name


async def save_upload_file(
    file: UploadFile,
) -> Path:
    validate_pdf_file(file)

    file_path = build_safe_file_path(
        file.filename or "document.pdf"
    )

    content = await file.read()

    if not content:
        raise HTTPException(
            status_code=400,
            detail="El archivo está vacío.",
        )

    size_mb = (
        len(content) / (1024 * 1024)
    )

    if size_mb > MAX_UPLOAD_SIZE_MB:
        raise HTTPException(
            status_code=413,
            detail=(
                f"El archivo supera el límite "
                f"de {MAX_UPLOAD_SIZE_MB} MB."
            ),
        )

    file_path.write_bytes(content)

    return file_path


def build_document_context(
    document_id: str,
    question: str,
    top_k: int = 10,
) -> str:
    clean_document_id = (
        document_id.strip()
    )

    if not clean_document_id:
        raise HTTPException(
            status_code=400,
            detail="document_id inválido.",
        )

    context = search_similar_chunks(
        document_id=clean_document_id,
        question=question,
        top_k=top_k,
    )

    if not context.strip():
        raise HTTPException(
            status_code=404,
            detail=(
                "No se encontró contexto "
                "suficiente."
            ),
        )

    return context


@router.post("/upload")
async def upload_document(
    file: UploadFile = File(...),
):
    start_time = time.perf_counter()

    try:
        step = time.perf_counter()
        file_path = await save_upload_file(file)
        print(f"[UPLOAD] save_file: {time.perf_counter() - step:.2f}s")

        step = time.perf_counter()
        pages = extract_pages_from_pdf(str(file_path))
        extracted_text = "\n".join(
            page["text"]
            for page in pages
        )
        print(f"[UPLOAD] extract_pages: {time.perf_counter() - step:.2f}s")

        step = time.perf_counter()
        document_id = index_document_pages_for_rag(pages)
        print(f"[UPLOAD] rag_page_index: {time.perf_counter() - step:.2f}s")

        step = time.perf_counter()
        document_record = register_document_file(
            document_id=document_id,
            filename=file.filename or file_path.name,
            file_path=str(file_path),
            size_bytes=file_path.stat().st_size,
        )
        print(f"[UPLOAD] register_document: {time.perf_counter() - step:.2f}s")

        step = time.perf_counter()
        ai_summary = generate_ai_summary(extracted_text)
        print(f"[UPLOAD] ai_summary: {time.perf_counter() - step:.2f}s")

        print(f"[UPLOAD] total: {time.perf_counter() - start_time:.2f}s")

        return {
            "filename": file.filename,
            "file_name": file.filename,
            "document_id": document_id,
            "message": "Documento procesado correctamente.",
            "text_preview": extracted_text[:1000],
            "ai_summary": ai_summary,
            "audio_file": "",
            "audio_url": "",
            "document_info": document_record,
        }

    except HTTPException:
        raise

    except Exception as error:
        print(f"[UPLOAD] error after {time.perf_counter() - start_time:.2f}s: {error}")
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/chat")
async def chat_document(
    file: UploadFile = File(...),
    question: str = Query(default=""),
):
    try:
        if not question.strip():
            raise HTTPException(
                status_code=400,
                detail=(
                    "La pregunta no puede "
                    "estar vacía."
                ),
            )

        file_path = await save_upload_file(file)

        extracted_text = (
            extract_text_from_pdf(
                str(file_path)
            )
        )

        answer = chat_with_document(
            extracted_text,
            question,
        )

        return {
            "filename": file.filename,
            "question": question,
            "answer": answer,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/chat/{document_id}")
async def chat_document_by_id(
    document_id: str,
    question: str = Query(default=""),
):
    try:
        if not question.strip():
            raise HTTPException(
                status_code=400,
                detail=(
                    "La pregunta no puede "
                    "estar vacía."
                ),
            )

        answer = (
            chat_with_document_id(
                document_id=document_id,
                question=question,
            )
        )

        citations = get_retrieval_citations(
            document_id=document_id,
            question=question,
        )

        return {
            "document_id": document_id,
            "question": question,
            "answer": answer,
            "citations": citations,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/exam")
async def exam_document(
    file: UploadFile = File(...),
    number_of_questions: int = Query(
        default=5,
        ge=1,
        le=20,
    ),
):
    try:
        file_path = await save_upload_file(file)

        extracted_text = (
            extract_text_from_pdf(
                str(file_path)
            )
        )

        questions = (
            generate_exam_questions(
                extracted_text,
                number_of_questions,
            )
        )

        return {
            "filename": file.filename,
            "number_of_questions":
                number_of_questions,
            "questions": questions,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/flashcards")
async def flashcards_document(
    file: UploadFile = File(...),
    number_of_cards: int = Query(
        default=10,
        ge=1,
        le=30,
    ),
):
    try:
        file_path = await save_upload_file(file)

        extracted_text = (
            extract_text_from_pdf(
                str(file_path)
            )
        )

        flashcards = (
            generate_flashcards(
                extracted_text,
                number_of_cards,
            )
        )

        return {
            "filename": file.filename,
            "number_of_cards":
                number_of_cards,
            "flashcards": flashcards,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/exam/{document_id}")
async def exam_document_by_id(
    document_id: str,
    number_of_questions: int = Query(
        default=5,
        ge=1,
        le=20,
    ),
):
    try:
        context = build_document_context(
            document_id=document_id,
            question=(
                "Resumen general y "
                "conceptos clave"
            ),
            top_k=10,
        )

        questions = (
            generate_exam_questions_from_context(
                context,
                number_of_questions,
            )
        )

        return {
            "document_id": document_id,
            "number_of_questions":
                number_of_questions,
            "questions": questions,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/flashcards/{document_id}")
async def flashcards_document_by_id(
    document_id: str,
    number_of_cards: int = Query(
        default=10,
        ge=1,
        le=30,
    ),
):
    try:
        context = build_document_context(
            document_id=document_id,
            question=(
                "Conceptos importantes "
                "y elementos memorables"
            ),
            top_k=10,
        )

        flashcards = (
            generate_flashcards_from_context(
                context,
                number_of_cards,
            )
        )

        return {
            "document_id": document_id,
            "number_of_cards":
                number_of_cards,
            "flashcards": flashcards,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )

@router.post("/chat-stream/{document_id}")
async def stream_chat_document(
    document_id: str,
    question: str = Query(default=""),
):
    try:
        async def event_generator():
            async for chunk in stream_chat_with_document_id(
                document_id=document_id,
                question=question,
            ):
                yield chunk

        return StreamingResponse(
            event_generator(),
            media_type="text/plain; charset=utf-8",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
                "Connection": "keep-alive",
            },
        )

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )















@router.get("/file/{document_id}")
async def document_file(
    document_id: str,
):
    try:
        info = get_document_info(
            document_id=document_id,
        )

        file_path = Path(info["file_path"])

        if not file_path.exists():
            raise HTTPException(
                status_code=404,
                detail="Archivo PDF no encontrado.",
            )

        return FileResponse(
            path=str(file_path),
            media_type="application/pdf",
            headers={
                "Content-Disposition": "inline",
            },
        )
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=404,
            detail=str(error),
        )

@router.get("/info/{document_id}")
async def document_info(
    document_id: str,
):
    try:
        return get_document_info(
            document_id=document_id,
        )
    except Exception as error:
        raise HTTPException(
            status_code=404,
            detail=str(error),
        )

@router.get("/source-chunk")
async def source_chunk(
    document_id: str = Query(default=""),
    chunk_index: int = Query(default=0),
):
    try:
        return get_source_chunk(
            document_id=document_id,
            chunk_index=chunk_index,
        )

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/semantic-search")
async def semantic_search(
    query: str = Query(default=""),
):
    try:
        results = semantic_search_all_documents(
            query=query,
        )

        return {
            "query": query,
            "count": len(results),
            "results": results,
        }

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/audio")
async def generate_audio_endpoint(
    text: str = Query(default=""),
):
    start_time = time.perf_counter()

    try:
        if not text.strip():
            raise HTTPException(
                status_code=400,
                detail="El texto para generar audio está vacío.",
            )

        audio_filename = generate_audio_from_text(text)

        print(f"[AUDIO] total: {time.perf_counter() - start_time:.2f}s")

        return {
            "audio_file": audio_filename,
            "audio_url": build_audio_url(audio_filename),
        }

    except HTTPException:
        raise

    except Exception as error:
        print(f"[AUDIO] error after {time.perf_counter() - start_time:.2f}s: {error}")
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )



@router.post("/chat-workspace")
async def chat_workspace(
    document_ids: list[str] = Body(...),
    question: str = Query(default=""),
    history: list[dict] | None = Body(default=None),
):
    try:
        answer = chat_with_workspace(
            document_ids=document_ids,
            question=question,
            history=history,
        )

        return {
            "answer": answer,
            "document_count": len(document_ids),
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/chat-workspace-stream")
async def stream_chat_workspace(
    document_ids: list[str] = Body(...),
    question: str = Query(default=""),
):
    try:
        async def event_generator():
            async for chunk in stream_chat_with_workspace(
                document_ids=document_ids,
                question=question,
            ):
                yield chunk

        return StreamingResponse(
            event_generator(),
            media_type="text/plain; charset=utf-8",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
                "Connection": "keep-alive",
            },
        )

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )
