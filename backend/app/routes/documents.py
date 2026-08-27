import time
import json
import asyncio
import openpyxl
from pathlib import Path
from uuid import uuid4

from fastapi.responses import StreamingResponse, FileResponse

from fastapi import (
    APIRouter,
    Body,
    Depends,
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
    generate_academic_rubric_from_context,
    generate_study_guide_from_context,
    generate_teaching_resources_from_context,
    generate_assessment_report_from_payload,
    generate_teaching_plan_from_context,
    parse_students_from_text,
    parse_grades_from_text,
    index_document_for_rag,
    index_document_pages_for_rag,
    stream_chat_with_document_id,
    stream_chat_with_workspace,
)

from app.services.usage_limit_service import (
    enforce_pdf_upload_limit,
    enforce_chat_limit,
    enforce_flashcard_limit,
    enforce_exam_limit,
    enforce_audiobook_permission,
    enforce_question_bank_permission,
    register_usage_event,
)

from app.services.audio_service import (
    build_audio_url,
    generate_audio_from_text,
    generate_audiobook_from_text,
)

from app.services.pdf_service import (
    extract_text_from_pdf,
    extract_pages_from_pdf,
)

from app.services.storage_service import upload_document_to_storage
from app.services.documents_cloud_service import create_document as create_cloud_document
from app.services.document_registry_service import (
    register_document_file,
    get_document_info,
    require_document_owner,
    is_document_owner,
)

from app.services.file_access_service import (
    create_file_access_token,
    verify_file_access_token,
)

from app.services.rag_service import (
    search_similar_chunks_multi,
    search_similar_chunks,
    semantic_search_all_documents,
    get_source_chunk,
    get_retrieval_citations,
)

from app.security.user_auth import (
    AuthenticatedUser,
    require_current_user,
)
from app.security.teacher_auth import require_teacher_access


def secure_filename(filename: str) -> str:
    clean = "".join(
        char if char.isalnum() or char in "._-" else "_"
        for char in filename
    ).strip("._")

    return clean or "document.pdf"


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
MAX_UPLOAD_SIZE_BYTES = MAX_UPLOAD_SIZE_MB * 1024 * 1024


def build_upload_response(
    *,
    filename: str | None,
    document_id: str,
    ai_summary: str,
) -> dict:
    return {
        "filename": filename,
        "file_name": filename,
        "document_id": document_id,
        "message": "Documento procesado correctamente.",
        "ai_summary": ai_summary,
        "audio_file": "",
        "audio_url": "",
    }


def validate_pdf_file(
    file: UploadFile,
) -> None:
    filename = file.filename or ""
    content_type = file.content_type or ""

    if not filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Solo se permiten archivos PDF.",
        )

    if content_type and content_type not in [
        "application/pdf",
        "application/octet-stream",
    ]:
        raise HTTPException(
            status_code=400,
            detail=(
                "Tipo de archivo no permitido. "
                "Solo se aceptan PDFs válidos."
            ),
        )


def validate_pdf_signature(
    content: bytes,
) -> None:
    if not content.startswith(b"%PDF"):
        raise HTTPException(
            status_code=400,
            detail=(
                "El archivo no parece ser un PDF válido."
            ),
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

    content = await read_upload_content(file)

    validate_pdf_signature(content)

    file_path.write_bytes(content)

    return file_path


async def read_upload_content(file: UploadFile) -> bytes:
    content = await file.read(MAX_UPLOAD_SIZE_BYTES + 1)

    if not content:
        raise HTTPException(
            status_code=400,
            detail="El archivo está vacío.",
        )

    if len(content) > MAX_UPLOAD_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=(
                f"El archivo supera el límite "
                f"de {MAX_UPLOAD_SIZE_MB} MB."
            ),
        )

    return content


def remove_temporary_file(file_path: Path | None) -> None:
    if file_path is None:
        return
    try:
        file_path.unlink(missing_ok=True)
    except OSError:
        pass




def validate_document_owner(
    *,
    document_id: str,
    current_user: AuthenticatedUser,
) -> dict:
    try:
        return require_document_owner(
            document_id=document_id,
            user_id=current_user.user_id,
        )
    except PermissionError as error:
        raise HTTPException(
            status_code=403,
            detail="No tienes permiso para acceder a este documento.",
        ) from error




def validate_documents_owner(
    *,
    document_ids: list[str],
    current_user: AuthenticatedUser,
) -> None:
    clean_document_ids = [
        item.strip()
        for item in document_ids
        if item and item.strip()
    ]

    if not clean_document_ids:
        raise HTTPException(
            status_code=400,
            detail="No hay documentos válidos.",
        )

    for document_id in clean_document_ids:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )


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





@router.post("/import-grades-excel")
async def import_grades_excel(
    file: UploadFile = File(...),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    file_path: Path | None = None
    workbook = None
    try:
        filename = file.filename or "grades.xlsx"

        if not filename.lower().endswith((".xlsx", ".xlsm")):
            raise HTTPException(
                status_code=400,
                detail="El archivo debe ser Excel .xlsx o .xlsm.",
            )

        content = await read_upload_content(file)
        if not content.startswith(b"PK"):
            raise HTTPException(
                status_code=400,
                detail="El archivo no parece ser un Excel válido.",
            )

        uploads_dir = Path(__file__).resolve().parent.parent / "uploads"
        uploads_dir.mkdir(parents=True, exist_ok=True)

        safe_filename = secure_filename(filename)
        file_path = uploads_dir / f"grades_import_{uuid4()}_{safe_filename}"
        file_path.write_bytes(content)

        workbook = openpyxl.load_workbook(file_path, data_only=True)
        sheet = workbook.active
        rows = list(sheet.iter_rows(values_only=True))

        if not rows:
            return {"grades": []}

        headers = [str(value or "").strip() for value in rows[0]]
        clean_headers = [
            header.lower().replace(" ", "_").replace("-", "_")
            for header in headers
        ]

        def find_col(*names):
            for name in names:
                for index, header in enumerate(clean_headers):
                    if header == name or name in header:
                        return index
            return -1

        code_col = find_col(
            "student_code",
            "codigo",
            "código",
            "matricula",
            "matrícula",
            "id",
        )
        name_col = find_col(
            "student_name",
            "nombre",
            "estudiante",
            "name",
            "alumno",
        )

        max_col = find_col(
            "max_score",
            "valor",
            "puntuacion",
            "puntuación",
            "sobre",
        )

        ignored_cols = {index for index in [code_col, name_col, max_col] if index >= 0}

        explicit_score_col = find_col(
            "score",
            "nota",
            "calificacion",
            "calificación",
        )

        explicit_assessment_col = find_col(
            "assessment",
            "actividad",
            "evaluacion",
            "evaluación",
        )

        if explicit_score_col >= 0:
            ignored_cols.add(explicit_score_col)
        if explicit_assessment_col >= 0:
            ignored_cols.add(explicit_assessment_col)

        grade_cols = []

        if explicit_score_col >= 0:
            grade_cols.append(
                (
                    explicit_score_col,
                    headers[explicit_assessment_col]
                    if explicit_assessment_col >= 0
                    else "Evaluación importada",
                )
            )
        else:
            for index, header in enumerate(headers):
                if index in ignored_cols:
                    continue

                if not header.strip():
                    continue

                normalized = header.strip()

                # Cualquier columna restante con valores numéricos se considera evaluación.
                has_numeric_value = False
                for row in rows[1:8]:
                    if index < len(row):
                        try:
                            float(row[index])
                            has_numeric_value = True
                            break
                        except Exception:
                            pass

                if has_numeric_value:
                    grade_cols.append((index, normalized))

        grades = []

        for row in rows[1:]:
            student_code = (
                str(row[code_col] or "").strip()
                if code_col >= 0 and code_col < len(row)
                else ""
            )
            student_name = (
                str(row[name_col] or "").strip()
                if name_col >= 0 and name_col < len(row)
                else ""
            )

            if not student_code and not student_name:
                continue

            raw_max = (
                row[max_col]
                if max_col >= 0 and max_col < len(row)
                else 100
            )

            try:
                default_max_score = float(raw_max or 100)
            except Exception:
                default_max_score = 100

            for col_index, assessment in grade_cols:
                if col_index >= len(row):
                    continue

                raw_score = row[col_index]

                if raw_score in (None, ""):
                    continue

                try:
                    score = float(raw_score)
                except Exception:
                    continue

                grades.append(
                    {
                        "student_code": student_code,
                        "student_name": student_name,
                        "score": score,
                        "max_score": default_max_score,
                        "assessment": assessment or "Evaluación importada",
                    }
                )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="grades_excel_imported",
            plan="educator",
            metadata={
                "filename": safe_filename,
                "grades_count": len(grades),
            },
        )

        return {
            "grades": grades,
            "detected_columns": headers,
            "grade_columns": [item[1] for item in grade_cols],
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo importar el archivo de calificaciones.",
        ) from error
    finally:
        if workbook is not None:
            workbook.close()
        remove_temporary_file(file_path)


@router.post("/import-grades-pdf")
async def import_grades_pdf(
    file: UploadFile = File(...),
    language: str = Query(default="es"),
    program_topic: str = Query(default=""),
    learning_objective: str = Query(default=""),
    competency: str = Query(default=""),
    bloom_level: str = Query(default=""),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    file_path: Path | None = None
    try:
        validate_pdf_file(file)

        content = await read_upload_content(file)
        validate_pdf_signature(content)

        uploads_dir = Path(__file__).resolve().parent.parent / "uploads"
        uploads_dir.mkdir(parents=True, exist_ok=True)

        safe_filename = secure_filename(
            file.filename or "grades.pdf"
        )

        file_path = uploads_dir / f"grades_import_{uuid4()}_{safe_filename}"
        file_path.write_bytes(content)

        text = extract_text_from_pdf(str(file_path))

        parsed = parse_grades_from_text(
            text=text,
            language=language,
        )

        grades_data = json.loads(parsed)

        register_usage_event(
            user_id=current_user.user_id,
            event_type="grades_pdf_imported",
            plan="educator",
            metadata={
                "filename": safe_filename,
                "grades_count": len(grades_data.get("grades", [])),
            },
        )

        return grades_data

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo importar el PDF de calificaciones.",
        ) from error
    finally:
        remove_temporary_file(file_path)

@router.post("/import-students-pdf")
async def import_students_pdf(
    file: UploadFile = File(...),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    file_path: Path | None = None
    try:
        validate_pdf_file(file)

        content = await read_upload_content(file)
        validate_pdf_signature(content)

        uploads_dir = Path(__file__).resolve().parent.parent / "uploads"
        uploads_dir.mkdir(parents=True, exist_ok=True)

        safe_filename = secure_filename(
            file.filename or "students.pdf"
        )

        file_path = uploads_dir / f"students_import_{uuid4()}_{safe_filename}"
        file_path.write_bytes(content)

        text = extract_text_from_pdf(str(file_path))

        parsed = parse_students_from_text(
            text=text,
            language=language,
        )

        students_data = json.loads(parsed)

        register_usage_event(
            user_id=current_user.user_id,
            event_type="students_pdf_imported",
            plan="educator",
            metadata={
                "filename": safe_filename,
                "students_count": len(students_data.get("students", [])),
            },
        )

        return students_data

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo importar el PDF de estudiantes.",
        ) from error
    finally:
        remove_temporary_file(file_path)

@router.post("/upload")
async def upload_document(
    file: UploadFile = File(...),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    start_time = time.perf_counter()

    try:
        plan = enforce_pdf_upload_limit(
            user_id=current_user.user_id,
        )

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
        document_id = index_document_pages_for_rag(
            pages,
            owner_scope=current_user.user_id,
        )
        print(f"[UPLOAD] rag_page_index: {time.perf_counter() - step:.2f}s")

        step = time.perf_counter()
        storage_result = {
            "bucket": None,
            "storage_path": None,
        }

        try:
            storage_result = upload_document_to_storage(
                user_id=current_user.user_id,
                document_id=document_id,
                filename=file.filename or file_path.name,
                file_path=str(file_path),
            )
            print(f"[UPLOAD] storage_upload: {time.perf_counter() - step:.2f}s")
        except Exception as storage_error:
            print(
                "[UPLOAD] storage_upload_failed "
                f"type={type(storage_error).__name__}"
            )

        step = time.perf_counter()
        document_record = register_document_file(
            document_id=document_id,
            filename=file.filename or file_path.name,
            file_path=str(file_path),
            size_bytes=file_path.stat().st_size,
            user_id=current_user.user_id,
            storage_bucket=storage_result.get("bucket"),
            storage_path=storage_result.get("storage_path"),
        )
        print(f"[UPLOAD] register_document: {time.perf_counter() - step:.2f}s")

        register_usage_event(
            user_id=current_user.user_id,
            event_type="pdf_upload",
            plan=plan,
            metadata={
                "document_id": document_id,
                "filename": file.filename or file_path.name,
                "size_bytes": file_path.stat().st_size,
            },
        )

        step = time.perf_counter()
        ai_summary = generate_ai_summary(
            extracted_text,
            language=language,
        )
        print(f"[UPLOAD] ai_summary: {time.perf_counter() - step:.2f}s")

        step = time.perf_counter()
        try:
            create_cloud_document(
                user_id=current_user.user_id,
                document_id=document_id,
                filename=file.filename or file_path.name,
                storage_bucket=document_record.get("storage_bucket"),
                storage_path=document_record.get("storage_path"),
                file_path=str(file_path),
                size_bytes=file_path.stat().st_size,
                summary=ai_summary,
            )
            print(f"[UPLOAD] cloud_document_insert: {time.perf_counter() - step:.2f}s")
        except Exception as cloud_document_error:
            print(
                "[UPLOAD] cloud_document_insert_failed "
                f"type={type(cloud_document_error).__name__}"
            )

        print(f"[UPLOAD] total: {time.perf_counter() - start_time:.2f}s")

        return build_upload_response(
            filename=file.filename,
            document_id=document_id,
            ai_summary=ai_summary,
        )

    except HTTPException:
        raise

    except Exception as error:
        print(
            f"[UPLOAD] failed after {time.perf_counter() - start_time:.2f}s "
            f"type={type(error).__name__}"
        )
        raise HTTPException(
            status_code=500,
            detail="No se pudo procesar el documento.",
        )


def calculate_rag_confidence(
    citations: list[dict],
) -> dict:
    distances = [
        item.get("distance")
        for item in citations
        if item.get("distance") is not None
    ]

    if not distances:
        return {
            "confidence": "unknown",
            "average_distance": None,
            "message": "No se pudo calcular la confianza.",
        }

    average_distance = sum(distances) / len(distances)

    if average_distance <= 0.35:
        confidence = "high"
        message = "Alta confianza en las fuentes recuperadas."
    elif average_distance <= 0.65:
        confidence = "medium"
        message = "Confianza media en las fuentes recuperadas."
    else:
        confidence = "low"
        message = (
            "Baja confianza: el documento puede no contener "
            "información suficiente para responder con precisión."
        )

    return {
        "confidence": confidence,
        "average_distance": average_distance,
        "message": message,
    }


@router.post("/chat/{document_id}")
async def chat_document_by_id(
    document_id: str,
    question: str = Query(default=""),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        document_record = validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        plan = enforce_chat_limit(
            user_id=current_user.user_id,
        )

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
                language=language,
            )
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="chat_message",
            plan=plan,
            metadata={
                "document_id": document_id,
                "mode": "document_chat",
            },
        )

        citations = get_retrieval_citations(
            document_id=document_id,
            question=question,
        )
        document_title = str(
            document_record.get("filename")
            or document_record.get("file_name")
            or "Documento"
        ).strip()
        for citation in citations:
            citation["document_title"] = document_title

        confidence_data = calculate_rag_confidence(
            citations
        )

        return {
            "document_id": document_id,
            "question": question,
            "answer": answer,
            "citations": citations,
            **confidence_data,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo completar el chat con este documento.",
        )





@router.post("/teaching-plan/{document_id}")
async def teaching_plan_document_by_id(
    document_id: str,
    language: str = Query(default="es"),
    weeks: int = Query(default=4, ge=1, le=16),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        context = build_document_context(
            document_id=document_id,
            question=(
                "planificación docente unidad didáctica objetivos competencias "
                "contenidos actividades evaluación recursos cronograma"
            ),
            top_k=14,
        )

        teaching_plan = generate_teaching_plan_from_context(
            context=context,
            language=language,
            weeks=weeks,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="teaching_plan_generated",
            plan="educator",
            metadata={
                "document_id": document_id,
                "weeks": weeks,
            },
        )

        return {
            "document_id": document_id,
            "teaching_plan": json.loads(teaching_plan),
        }

    except HTTPException:
        raise

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo abrir la fuente citada.",
        )

@router.post("/rubric/{document_id}")
async def rubric_document_by_id(
    document_id: str,
    language: str = Query(default="es"),
    total_points: int = Query(default=100, ge=10, le=200),
    rubric_type: str = Query(default="Analítica"),
    criteria_count: int = Query(default=5, ge=3, le=10),
    performance_levels: int = Query(default=4, ge=3, le=6),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        context = build_document_context(
            document_id=document_id,
            question=(
                "criterios de evaluación objetivos competencias resultados "
                "aprendizaje metodología contenido académico"
            ),
            top_k=12,
        )

        rubric = generate_academic_rubric_from_context(
            context=context,
            language=language,
            total_points=total_points,
            rubric_type=rubric_type,
            criteria_count=criteria_count,
            performance_levels=performance_levels,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="rubric_generated",
            plan="educator",
            metadata={
                "document_id": document_id,
                "total_points": total_points,
                "rubric_type": rubric_type,
                "criteria_count": criteria_count,
                "performance_levels": performance_levels,
            },
        )

        return {
            "document_id": document_id,
            "rubric": json.loads(rubric),
        }

    except HTTPException:
        raise

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo abrir la fuente citada.",
        )


@router.post("/study-guide/{document_id}")
async def study_guide_document_by_id(
    document_id: str,
    language: str = Query(default="es"),
    program_topic: str = Query(default=""),
    learning_objective: str = Query(default=""),
    competency: str = Query(default=""),
    guide_type: str = Query(default="student"),
    include_summary: bool = Query(default=True),
    include_key_concepts: bool = Query(default=True),
    include_practice_activities: bool = Query(default=True),
    include_self_assessment: bool = Query(default=True),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        context = build_document_context(
            document_id=document_id,
            question=(
                "guía de estudio resumen conceptos clave pasos de estudio "
                "actividades de práctica autoevaluación recomendaciones "
                f"tema del programa: {program_topic} "
                f"objetivo de aprendizaje: {learning_objective} "
                f"competencia: {competency}"
            ),
            top_k=14,
        )

        study_guide = generate_study_guide_from_context(
            context=context,
            language=language,
            program_topic=program_topic,
            learning_objective=learning_objective,
            competency=competency,
            guide_type=guide_type,
            include_summary=include_summary,
            include_key_concepts=include_key_concepts,
            include_practice_activities=include_practice_activities,
            include_self_assessment=include_self_assessment,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="study_guide_generated",
            plan="educator",
            metadata={
                "document_id": document_id,
                "program_topic": program_topic,
                "learning_objective": learning_objective,
                "competency": competency,
                "guide_type": guide_type,
            },
        )

        return {
            "document_id": document_id,
            "study_guide": json.loads(study_guide),
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la guía de estudio.",
        ) from error


@router.post("/teaching-resources/{document_id}")
async def teaching_resources_document_by_id(
    document_id: str,
    language: str = Query(default="es"),
    program_topic: str = Query(default=""),
    learning_objective: str = Query(default=""),
    competency: str = Query(default=""),
    include_presentation_outline: bool = Query(default=True),
    include_class_activities: bool = Query(default=True),
    include_collaborative_activities: bool = Query(default=True),
    include_discussion_questions: bool = Query(default=True),
    include_problem_based_learning: bool = Query(default=True),
    include_gamification_ideas: bool = Query(default=True),
    include_homework: bool = Query(default=True),
    include_accessibility_adaptations: bool = Query(default=True),
    include_complementary_readings: bool = Query(default=True),
    include_multimedia_suggestions: bool = Query(default=True),
    include_web_resources: bool = Query(default=True),
    include_ai_prompts_for_students: bool = Query(default=True),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        context = build_document_context(
            document_id=document_id,
            question=(
                "recursos docentes presentación actividades de clase "
                "actividades colaborativas preguntas discusión problemas "
                "gamificación tareas accesibilidad lecturas multimedia web "
                "prompts IA recomendaciones docentes "
                f"tema del programa: {program_topic} "
                f"objetivo de aprendizaje: {learning_objective} "
                f"competencia: {competency}"
            ),
            top_k=14,
        )

        teaching_resources = generate_teaching_resources_from_context(
            context=context,
            language=language,
            program_topic=program_topic,
            learning_objective=learning_objective,
            competency=competency,
            include_presentation_outline=include_presentation_outline,
            include_class_activities=include_class_activities,
            include_collaborative_activities=include_collaborative_activities,
            include_discussion_questions=include_discussion_questions,
            include_problem_based_learning=include_problem_based_learning,
            include_gamification_ideas=include_gamification_ideas,
            include_homework=include_homework,
            include_accessibility_adaptations=include_accessibility_adaptations,
            include_complementary_readings=include_complementary_readings,
            include_multimedia_suggestions=include_multimedia_suggestions,
            include_web_resources=include_web_resources,
            include_ai_prompts_for_students=include_ai_prompts_for_students,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="teaching_resources_generated",
            plan="educator",
            metadata={
                "document_id": document_id,
                "program_topic": program_topic,
                "learning_objective": learning_objective,
                "competency": competency,
            },
        )

        return {
            "document_id": document_id,
            "teaching_resources": json.loads(teaching_resources),
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudieron generar los recursos docentes.",
        ) from error


@router.post("/analyze-assessment")
async def analyze_assessment_for_unit(
    payload: dict = Body(...),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        academic_metadata = payload.get("academic_metadata") or {}
        source_document_id = str(
            academic_metadata.get("source_document_id") or ""
        ).strip()

        if source_document_id:
            validate_document_owner(
                document_id=source_document_id,
                current_user=current_user,
            )

        assessment_report = generate_assessment_report_from_payload(
            payload=payload,
            language=language,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="assessment_report_generated",
            plan="educator",
            metadata={
                "unit_id": academic_metadata.get("unit_id"),
                "source_document_id": source_document_id,
            },
        )

        return {
            "assessment_report": json.loads(assessment_report),
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo analizar la evaluación.",
        ) from error


@router.post("/question-bank/{document_id}")
async def question_bank_document_by_id(
    document_id: str,
    number_of_questions: int = Query(
        default=50,
        ge=5,
        le=100,
    ),
    language: str = Query(default="es"),
    program_topic: str = Query(default=""),
    learning_objective: str = Query(default=""),
    competency: str = Query(default=""),
    bloom_level: str = Query(default=""),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        enforce_question_bank_permission(user_id=current_user.user_id)

        plan = enforce_exam_limit(
            user_id=current_user.user_id,
            requested_amount=number_of_questions,
        )

        context = build_document_context(
            document_id=document_id,
            question=(
                "banco de preguntas conceptos clave evaluación "
                "comprensión aplicación análisis académico "
                f"tema del programa: {program_topic} "
                f"objetivo de aprendizaje: {learning_objective} "
                f"competencia: {competency} "
                f"nivel bloom: {bloom_level}"
            ),
            top_k=14,
        )

        questions = generate_exam_questions_from_context(
            context=context,
            number_of_questions=number_of_questions,
            language=language,
        )

        parsed_questions = parse_ai_json_list(questions, "questions")

        register_usage_event(
            user_id=current_user.user_id,
            event_type="question_bank_generated",
            plan=plan,
            metadata={
                "document_id": document_id,
                "number_of_questions": number_of_questions,
                "mode": "single_document_question_bank",
                "program_topic": program_topic,
                "learning_objective": learning_objective,
                "competency": competency,
                "bloom_level": bloom_level,
            },
        )

        return {
            "document_id": document_id,
            "number_of_questions": number_of_questions,
            "questions": parsed_questions,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar el banco de preguntas.",
        ) from error

@router.post("/exam/{document_id}")
async def exam_document_by_id(
    document_id: str,
    number_of_questions: int = Query(
        default=5,
        ge=1,
        le=20,
    ),
    exam_type: str = Query(default="Selección múltiple"),
    difficulty: str = Query(default="Intermedio"),
    total_points: int = Query(default=100),
    exam_topic: str = Query(default=""),
    exam_objective: str = Query(default=""),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        plan = enforce_exam_limit(
            user_id=current_user.user_id,
            requested_amount=number_of_questions,
        )

        context = build_document_context(
            document_id=document_id,
            question=(
                "Resumen general y "
                "conceptos clave"
            ),
            top_k=10,
        )

        questions = generate_exam_questions_from_context(
            context=context,
            number_of_questions=number_of_questions,
            language=language,
            exam_type=exam_type,
            difficulty=difficulty,
            total_points=total_points,
            exam_topic=exam_topic,
            exam_objective=exam_objective,
        )

        parsed_questions = parse_ai_json_list(
            questions,
            "questions",
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="exam_generated",
            plan=plan,
            metadata={
                "document_id": document_id,
                "number_of_questions": number_of_questions,
            },
        )

        return {
            "document_id": document_id,
            "number_of_questions":
                number_of_questions,
            "questions": parsed_questions,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar el examen.",
        ) from error


@router.post("/flashcards/{document_id}")
async def flashcards_document_by_id(
    document_id: str,
    number_of_cards: int = Query(
        default=10,
        ge=1,
        le=30,
    ),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        plan = enforce_flashcard_limit(
            user_id=current_user.user_id,
            requested_amount=number_of_cards,
        )

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
                language=language,
            )
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="flashcards_generated",
            plan=plan,
            metadata={
                "document_id": document_id,
                "number_of_cards": number_of_cards,
            },
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
            detail="No se pudieron generar las flashcards.",
        ) from error

@router.post("/chat-stream/{document_id}")
async def stream_chat_document(
    document_id: str,
    question: str = Query(default=""),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        plan = enforce_chat_limit(
            user_id=current_user.user_id,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="chat_message",
            plan=plan,
            metadata={
                "document_id": document_id,
                "mode": "document_chat_stream",
            },
        )

        async def event_generator():
            async for chunk in stream_chat_with_document_id(
                document_id=document_id,
                question=question,
                language=language,
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
            detail="No se pudo iniciar la respuesta del chat.",
        ) from error















@router.get("/file-token/{document_id}")
async def document_file_token(
    document_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        token = create_file_access_token(
            document_id=document_id,
            user_id=current_user.user_id,
        )

        return {
            "document_id": document_id,
            "token": token,
            "expires_in_seconds": 120,
            "file_url": f"/documents/file-secure/{document_id}?token={token}",
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo preparar el acceso al documento.",
        ) from error


@router.get("/file-secure/{document_id}")
async def document_file_secure(
    document_id: str,
    token: str = Query(default=""),
):
    try:
        if not token:
            raise HTTPException(
                status_code=401,
                detail="Falta token de acceso al PDF.",
            )

        verify_file_access_token(
            token=token,
            document_id=document_id,
        )

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
            status_code=401,
            detail="El acceso al documento no es válido o expiró.",
        ) from error



@router.get("/file/{document_id}")
async def document_file(
    document_id: str,
):
    raise HTTPException(
        status_code=410,
        detail=(
            "Este endpoint fue deshabilitado por seguridad. "
            "Use /documents/file-token/{document_id} y luego "
            "/documents/file-secure/{document_id}?token=..."
        ),
    )

@router.get("/info/{document_id}")
async def document_info(
    document_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        info = validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        return {
            "document_id": info.get("document_id") or document_id,
            "filename": info.get("filename") or "document.pdf",
            "uploaded_at": info.get("uploaded_at"),
            "size_bytes": info.get("size_bytes") or 0,
            "available": True,
        }
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=404,
            detail="No se encontró el documento solicitado.",
        ) from error

@router.get("/source-chunk")
async def source_chunk(
    document_id: str = Query(default=""),
    chunk_index: int = Query(default=0),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_document_owner(
            document_id=document_id,
            current_user=current_user,
        )

        return get_source_chunk(
            document_id=document_id,
            chunk_index=chunk_index,
        )

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo abrir la fuente citada.",
        ) from error


@router.get("/semantic-search")
async def semantic_search(
    query: str = Query(default=""),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        results = semantic_search_all_documents(
            query=query,
            document_filter=lambda document_id: is_document_owner(
                document_id=document_id,
                user_id=current_user.user_id,
            ),
        )

        filtered_results = []

        for result in results:
            document_id = (
                result.get("document_id")
                or result.get("metadata", {}).get("document_id")
            )

            if not document_id:
                continue

            if is_document_owner(
                document_id=document_id,
                user_id=current_user.user_id,
            ):
                filtered_results.append(result)

        return {
            "query": query,
            "count": len(filtered_results),
            "results": filtered_results,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo completar la búsqueda en este momento.",
        )



@router.post("/audio")
async def generate_audio_endpoint(
    text: str = Query(default=""),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    start_time = time.perf_counter()

    try:
        enforce_audiobook_permission(user_id=current_user.user_id)

        if not text.strip():
            raise HTTPException(
                status_code=400,
                detail="El texto para generar audio está vacío.",
            )

        audio_filename = generate_audio_from_text(
            text,
            user_id=current_user.user_id,
        )

        print(f"[AUDIO] total: {time.perf_counter() - start_time:.2f}s")

        return {
            "audio_file": audio_filename,
            "audio_url": build_audio_url(audio_filename),
        }

    except HTTPException:
        raise

    except Exception as error:
        print(
            f"[AUDIO] failed after {time.perf_counter() - start_time:.2f}s "
            f"type={type(error).__name__}"
        )
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar el audio en este momento.",
        ) from error



@router.post("/audiobook")
async def generate_audiobook_endpoint(
    text: str = Query(default=""),
    max_chapters: int = Query(default=6, ge=1, le=12),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    start_time = time.perf_counter()

    try:
        enforce_audiobook_permission(user_id=current_user.user_id)

        if not text.strip():
            raise HTTPException(
                status_code=400,
                detail="El texto para generar audiolibro está vacío.",
            )

        chapters = generate_audiobook_from_text(
            text=text,
            user_id=current_user.user_id,
            max_chapters=max_chapters,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="audiobook_generated",
            plan="unknown",
            metadata={
                "chapter_count": len(chapters),
                "max_chapters": max_chapters,
            },
        )

        print(
            f"[AUDIOBOOK] chapters={len(chapters)} "
            f"total={time.perf_counter() - start_time:.2f}s"
        )

        return {
            "chapter_count": len(chapters),
            "chapters": chapters,
        }

    except HTTPException:
        raise

    except Exception as error:
        print(
            f"[AUDIOBOOK] failed after "
            f"{time.perf_counter() - start_time:.2f}s "
            f"type={type(error).__name__}"
        )
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar el AudioBook en este momento.",
        ) from error



def parse_ai_json_list(raw_value, expected_key: str):
    if isinstance(raw_value, list):
        return raw_value

    if isinstance(raw_value, dict):
        value = raw_value.get(expected_key)
        return value if isinstance(value, list) else []

    if isinstance(raw_value, str):
        clean = raw_value.strip()

        if clean.startswith("```"):
            clean = clean.replace("```json", "").replace("```", "").strip()

        parsed = json.loads(clean)

        if isinstance(parsed, list):
            return parsed

        if isinstance(parsed, dict):
            value = parsed.get(expected_key)
            return value if isinstance(value, list) else []

    return []


@router.post("/chat-workspace")
async def chat_workspace(
    document_ids: list[str] = Body(...),
    question: str = Query(default=""),
    language: str = Query(default="es"),
    history: list[dict] | None = Body(default=None),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_documents_owner(
            document_ids=document_ids,
            current_user=current_user,
        )

        plan = enforce_chat_limit(
            user_id=current_user.user_id,
        )

        answer = chat_with_workspace(
            document_ids=document_ids,
            question=question,
            history=history,
            language=language,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="chat_message",
            plan=plan,
            metadata={
                "document_count": len(document_ids),
                "mode": "workspace_chat",
            },
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
            detail="No se pudo completar el chat del espacio de estudio.",
        ) from error


@router.post("/chat-workspace-stream")
async def stream_chat_workspace(
    document_ids: list[str] = Body(...),
    question: str = Query(default=""),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_documents_owner(
            document_ids=document_ids,
            current_user=current_user,
        )

        plan = enforce_chat_limit(
            user_id=current_user.user_id,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="chat_message",
            plan=plan,
            metadata={
                "document_count": len(document_ids),
                "mode": "workspace_chat_stream",
            },
        )

        async def event_generator():
            async for chunk in stream_chat_with_workspace(
                document_ids=document_ids,
                question=question,
                language=language,
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
            detail="No se pudo iniciar el chat del espacio de estudio.",
        ) from error



@router.post("/workspace-flashcards")
async def workspace_flashcards(
    document_ids: list[str] = Body(...),
    number: int = Query(default=20),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_documents_owner(
            document_ids=document_ids,
            current_user=current_user,
        )

        plan = enforce_flashcard_limit(
            user_id=current_user.user_id,
            requested_amount=number,
        )

        context = search_similar_chunks_multi(
            document_ids=document_ids,
            question=(
                "conceptos principales definiciones fechas ideas clave "
                "preguntas de estudio evaluación académica"
            ),
            top_k_per_document=6,
        )

        if not context.strip():
            raise HTTPException(
                status_code=404,
                detail="No se encontró contexto suficiente en el workspace.",
            )

        flashcards = generate_flashcards_from_context(
            context=context,
            number_of_cards=number,
            language=language,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="flashcards_generated",
            plan=plan,
            metadata={
                "document_count": len(document_ids),
                "mode": "workspace_flashcards",
                "requested_number": number,
            },
        )

        return {
            "flashcards": parse_ai_json_list(flashcards, "flashcards"),
            "document_count": len(document_ids),
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudieron generar las flashcards del espacio.",
        ) from error



@router.post("/workspace-question-bank")
async def workspace_question_bank(
    document_ids: list[str] = Body(...),
    number: int = Query(default=50, ge=5, le=100),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_documents_owner(
            document_ids=document_ids,
            current_user=current_user,
        )

        enforce_question_bank_permission(user_id=current_user.user_id)

        plan = enforce_exam_limit(
            user_id=current_user.user_id,
            requested_amount=number,
        )

        context = search_similar_chunks_multi(
            document_ids=document_ids,
            question=(
                "banco de preguntas conceptos clave evaluación comprensión "
                "aplicación análisis académico preguntas objetivas"
            ),
            top_k_per_document=8,
        )

        if not context.strip():
            raise HTTPException(
                status_code=404,
                detail="No se encontró contexto suficiente para crear el banco de preguntas.",
            )

        questions = generate_exam_questions_from_context(
            context=context,
            number_of_questions=number,
            language=language,
        )

        parsed_questions = parse_ai_json_list(questions, "questions")

        register_usage_event(
            user_id=current_user.user_id,
            event_type="question_bank_generated",
            plan=plan,
            metadata={
                "document_count": len(document_ids),
                "mode": "workspace_question_bank",
                "requested_number": number,
            },
        )

        return {
            "questions": parsed_questions,
            "document_count": len(document_ids),
            "number_of_questions": number,
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar el banco del espacio de estudio.",
        ) from error

@router.post("/workspace-exam")
async def workspace_exam(
    document_ids: list[str] = Body(...),
    number: int = Query(default=20),
    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        validate_documents_owner(
            document_ids=document_ids,
            current_user=current_user,
        )

        plan = enforce_exam_limit(
            user_id=current_user.user_id,
            requested_amount=number,
        )

        context = search_similar_chunks_multi(
            document_ids=document_ids,
            question=(
                "temas principales preguntas de examen conceptos clave "
                "aplicación análisis académico evaluación"
            ),
            top_k_per_document=6,
        )

        if not context.strip():
            raise HTTPException(
                status_code=404,
                detail="No se encontró contexto suficiente en el workspace.",
            )

        questions = generate_exam_questions_from_context(
            context=context,
            number_of_questions=number,
            language=language,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="exam_generated",
            plan=plan,
            metadata={
                "document_count": len(document_ids),
                "mode": "workspace_exam",
                "requested_number": number,
            },
        )

        return {
            "questions": parse_ai_json_list(questions, "questions"),
            "document_count": len(document_ids),
        }

    except HTTPException:
        raise

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar el examen del espacio de estudio.",
        ) from error
