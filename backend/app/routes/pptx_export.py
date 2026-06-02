from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from io import BytesIO

from app.services.pptx_export_service import (
    build_summary_pptx,
)

router = APIRouter(
    tags=["pptx-export"],
)

class PptxExportRequest(BaseModel):
    title: str
    content: str


@router.post("/export/pptx")
def export_pptx(payload: PptxExportRequest):
    pptx_bytes = build_summary_pptx(
        title=payload.title,
        content=payload.content,
    )

    return StreamingResponse(
        BytesIO(pptx_bytes),
        media_type=(
            "application/vnd.openxmlformats-officedocument."
            "presentationml.presentation"
        ),
        headers={
            "Content-Disposition":
            'attachment; filename="studybook.pptx"'
        },
    )
