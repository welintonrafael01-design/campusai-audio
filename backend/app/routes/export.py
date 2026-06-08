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


class ExportPdfPayload(BaseModel):
    title: str = "StudyBook AI Export"
    content: str


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
