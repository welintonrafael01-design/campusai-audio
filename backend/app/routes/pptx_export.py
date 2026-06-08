from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from io import BytesIO

from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.usage_limit_service import (
    enforce_export_permission,
    register_usage_event,
)

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
def export_pptx(
    payload: PptxExportRequest,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    plan = enforce_export_permission(
        user_id=current_user.user_id,
        export_type="pptx",
    )

    pptx_bytes = build_summary_pptx(
        title=payload.title,
        content=payload.content,
    )

    register_usage_event(
        user_id=current_user.user_id,
        event_type="export_generated",
        plan=plan,
        metadata={
            "export_type": "pptx",
            "title": payload.title,
        },
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
