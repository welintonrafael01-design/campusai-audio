from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

from app.services.export_service import build_text_pdf
from app.services.docx_export_service import build_text_docx


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
):
    try:
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
):
    try:
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
