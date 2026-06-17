import io
import openpyxl
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

from app.services.export_service import build_text_pdf
from app.services.docx_export_service import build_text_docx
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.usage_limit_service import (
    enforce_export_permission,
    register_usage_event,
)


router = APIRouter(
    prefix="/export",
    tags=["Export"],
)




class ExportXlsxPayload(BaseModel):
    title: str = "StudyBook AI Export"
    rows: list[dict[str, Any]]

class ExportPdfPayload(BaseModel):
    title: str = "StudyBook AI Export"
    content: str



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

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


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

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )



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

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )
