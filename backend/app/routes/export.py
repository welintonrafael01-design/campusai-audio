import hashlib
import io
import openpyxl
from typing import Any
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

from app.services.certificate_service import save_certificate
from app.services.export_service import build_text_pdf, build_final_report_pdf, build_teaching_plan_pdf, build_rubric_pdf, build_exam_pdf, build_certificate_pdf, build_academic_badge_pdf, build_student_transcript_pdf
from app.services.docx_export_service import build_text_docx
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.security.teacher_auth import require_teacher_access
from app.services.usage_limit_service import (
    enforce_export_permission,
    register_usage_event,
)


router = APIRouter(
    prefix="/export",
    tags=["Export"],
)








class RubricPdfPayload(BaseModel):
    title: str = "Rúbrica evaluada"
    rubric: dict[str, Any]
    student: dict[str, Any] | None = None
    scores: dict[str, Any] | None = None
    observations: dict[str, Any] | None = None

class TeachingPlanPdfPayload(BaseModel):
    title: str = "Planificación docente"
    plan: dict[str, Any]

class ExamPdfPayload(BaseModel):
    title: str = "Examen StudyBook AI"
    questions: list[dict[str, Any]]
    include_answers: bool = False

class CertificatePdfPayload(BaseModel):
    student_name: str
    student_code: str = ""
    course_name: str
    average: str
    period: str = ""
    certificate_id: str = ""
    certificate_title: str = "CERTIFICADO ACADÉMICO"

class AcademicBadgePdfPayload(BaseModel):
    student_name: str
    student_code: str = ""
    course_name: str
    badge_title: str = "Curso Aprobado"
    average: str = ""
    certificate_id: str = ""

class StudentTranscriptPdfPayload(BaseModel):
    student_name: str
    student_code: str = ""
    general_average: str = ""
    attendance_average: str = ""
    gpa4: str = ""
    academic_standing: str = ""
    distinctions: list[str] = []
    ranking_position: int = 0
    ranking_total: int = 0
    ranking_percentile: float = 0
    courses: list[dict[str, Any]]

class FinalReportPdfPayload(BaseModel):
    title: str = "Acta Final StudyBook AI"
    course_name: str
    rows: list[dict[str, Any]]
    stats: dict[str, Any]

class ExportXlsxPayload(BaseModel):
    title: str = "StudyBook AI Export"
    rows: list[dict[str, Any]]

class ExportPdfPayload(BaseModel):
    title: str = "StudyBook AI Export"
    content: str












@router.post("/student-transcript-pdf")
async def export_student_transcript_pdf(
    payload: StudentTranscriptPdfPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        pdf_bytes = build_student_transcript_pdf(
            student_name=payload.student_name,
            student_code=payload.student_code,
            general_average=payload.general_average,
            attendance_average=payload.attendance_average,
            gpa4=payload.gpa4,
            academic_standing=payload.academic_standing,
            distinctions=payload.distinctions,
            ranking_position=payload.ranking_position,
            ranking_total=payload.ranking_total,
            ranking_percentile=payload.ranking_percentile,
            courses=payload.courses,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "student_transcript_pdf",
                "student_name": payload.student_name,
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": 'attachment; filename="studybook_expediente_academico.pdf"',
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error

@router.post("/academic-badge-pdf")
async def export_academic_badge_pdf(
    payload: AcademicBadgePdfPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        certificate_id = payload.certificate_id.strip()

        if not certificate_id:
            year = datetime.now().strftime("%Y")
            raw = f"{current_user.user_id}|BADGE|{payload.student_code}|{payload.student_name}|{payload.course_name}|{payload.average}|{payload.badge_title}|{year}"
            digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()[:8].upper()
            certificate_id = f"BADGE-{year}-{digest}"

        badge_type = (
            "excellence"
            if "excelencia" in payload.badge_title.lower()
            else "badge"
        )

        save_certificate(
            {
                "certificate_id": certificate_id,
                "student_name": payload.student_name,
                "student_code": payload.student_code,
                "course_name": payload.course_name,
                "average": payload.average,
                "period": payload.badge_title,
                "recognition_type": badge_type,
                "status": "valid",
            },
            user_id=current_user.user_id,
        )

        pdf_bytes = build_academic_badge_pdf(
            student_name=payload.student_name,
            student_code=payload.student_code,
            course_name=payload.course_name,
            badge_title=payload.badge_title,
            average=payload.average,
            certificate_id=certificate_id,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "academic_badge_pdf",
                "student_name": payload.student_name,
                "course_name": payload.course_name,
                "badge_title": payload.badge_title,
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": 'attachment; filename="studybook_insignia_academica.pdf"',
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error

@router.post("/certificate-pdf")
async def export_certificate_pdf(
    payload: CertificatePdfPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        certificate_id = payload.certificate_id.strip()

        if not certificate_id:
            year = datetime.now().strftime("%Y")
            raw = f"{current_user.user_id}|{payload.student_code}|{payload.student_name}|{payload.course_name}|{payload.average}|{payload.period}|{year}"
            digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()[:8].upper()
            certificate_id = f"CERT-{year}-{digest}"

        certificate_type = (
            "excellence"
            if "excelencia" in payload.certificate_title.lower()
            else "certificate"
        )

        save_certificate(
            {
                "certificate_id": certificate_id,
                "student_name": payload.student_name,
                "student_code": payload.student_code,
                "course_name": payload.course_name,
                "average": payload.average,
                "period": payload.period,
                "recognition_type": certificate_type,
                "status": "valid",
            },
            user_id=current_user.user_id,
        )

        pdf_bytes = build_certificate_pdf(
            student_name=payload.student_name,
            student_code=payload.student_code,
            course_name=payload.course_name,
            average=payload.average,
            period=payload.period,
            certificate_id=certificate_id,
            certificate_title=payload.certificate_title,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "certificate_pdf",
                "student_name": payload.student_name,
                "course_name": payload.course_name,
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": 'attachment; filename="studybook_certificado.pdf"',
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error

@router.post("/exam-pdf")
async def export_exam_pdf(
    payload: ExamPdfPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        pdf_bytes = build_exam_pdf(
            title=payload.title,
            questions=payload.questions,
            include_answers=payload.include_answers,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "exam_pdf",
                "title": payload.title,
                "questions": len(payload.questions),
                "include_answers": payload.include_answers,
            },
        )

        filename = "studybook_clave_docente.pdf" if payload.include_answers else "studybook_examen_estudiante.pdf"

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error

@router.post("/rubric-pdf")
async def export_rubric_pdf(
    payload: RubricPdfPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        pdf_bytes = build_rubric_pdf(
            title=payload.title,
            rubric=payload.rubric,
            student=payload.student,
            scores=payload.scores,
            observations=payload.observations,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "rubric_pdf",
                "title": payload.title,
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": (
                    'attachment; filename="studybook_rubrica_evaluada.pdf"'
                ),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error

@router.post("/teaching-plan-pdf")
async def export_teaching_plan_pdf(
    payload: TeachingPlanPdfPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        pdf_bytes = build_teaching_plan_pdf(
            title=payload.title,
            plan=payload.plan,
        )

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "teaching_plan_pdf",
                "title": payload.title,
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": (
                    'attachment; filename="studybook_planificacion_docente.pdf"'
                ),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error

@router.post("/final-report-pdf")
async def export_final_report_pdf(
    payload: FinalReportPdfPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        pdf_bytes = build_final_report_pdf(
            title=payload.title,
            course_name=payload.course_name,
            rows=payload.rows,
            stats=payload.stats,
        )

        safe_filename = "studybook_acta_final"

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "final_report_pdf",
                "title": payload.title,
                "rows": len(payload.rows),
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": (
                    f'attachment; filename="{safe_filename}.pdf"'
                ),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error


@router.post("/xlsx")
async def export_xlsx(
    payload: ExportXlsxPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="xlsx",
        )

        workbook = openpyxl.Workbook()
        sheet = workbook.active
        sheet.title = "StudyBook AI"

        headers = []
        for row in payload.rows:
            for key in row.keys():
                if key not in headers:
                    headers.append(key)

        if not headers:
            headers = ["message"]
            payload.rows = [{"message": "Sin datos para exportar"}]

        sheet.append(headers)

        for row in payload.rows:
            sheet.append([row.get(header, "") for header in headers])

        for column_cells in sheet.columns:
            max_length = 0
            column_letter = column_cells[0].column_letter

            for cell in column_cells:
                value = str(cell.value or "")
                if len(value) > max_length:
                    max_length = len(value)

            sheet.column_dimensions[column_letter].width = min(
                max(max_length + 2, 12),
                45,
            )

        output = io.BytesIO()
        workbook.save(output)
        output.seek(0)

        filename = payload.title.strip() or "studybook_export"

        safe_filename = "".join(
            char
            if char.isalnum() or char in ["_", "-"]
            else "_"
            for char in filename
        )[:80]

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "xlsx",
                "title": payload.title,
            },
        )

        return Response(
            content=output.getvalue(),
            media_type=(
                "application/vnd.openxmlformats-officedocument."
                "spreadsheetml.sheet"
            ),
            headers={
                "Content-Disposition": (
                    f'attachment; filename="{safe_filename}.xlsx"'
                ),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error


@router.post("/pdf")
async def export_pdf(
    payload: ExportPdfPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="pdf",
        )

        pdf_bytes = build_text_pdf(
            title=payload.title,
            content=payload.content,
        )

        filename = (
            payload.title.strip()
            or "studybook_export"
        )

        safe_filename = "".join(
            char
            if char.isalnum() or char in ["_", "-"]
            else "_"
            for char in filename
        )[:80]

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "pdf",
                "title": payload.title,
            },
        )

        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": (
                    f'attachment; filename="{safe_filename}.pdf"'
                ),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error



@router.post("/docx")
async def export_docx(
    payload: ExportPdfPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        plan = enforce_export_permission(
            user_id=current_user.user_id,
            export_type="docx",
        )

        docx_bytes = build_text_docx(
            title=payload.title,
            content=payload.content,
        )

        filename = (
            payload.title.strip()
            or "studybook_export"
        )

        safe_filename = "".join(
            char
            if char.isalnum() or char in ["_", "-"]
            else "_"
            for char in filename
        )[:80]

        register_usage_event(
            user_id=current_user.user_id,
            event_type="export_generated",
            plan=plan,
            metadata={
                "export_type": "docx",
                "title": payload.title,
            },
        )

        return Response(
            content=docx_bytes,
            media_type=(
                "application/vnd.openxmlformats-officedocument."
                "wordprocessingml.document"
            ),
            headers={
                "Content-Disposition": (
                    f'attachment; filename="{safe_filename}.docx"'
                ),
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo generar la exportación solicitada.",
        ) from error
