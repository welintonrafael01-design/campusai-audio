from fastapi import APIRouter, Depends, HTTPException
from pathlib import Path
import tempfile
from typing import Literal
from uuid import uuid4
from pydantic import BaseModel, ConfigDict, Field

from app.security.user_auth import (
    AuthenticatedUser,
    require_current_user,
)

from app.services.documents_cloud_service import list_library_documents, get_document_download_url
from app.services.storage_service import download_document_from_storage
from app.services.pdf_service import extract_pages_from_pdf
from app.services.ai_service import index_document_pages_for_rag
from app.services.document_registry_service import register_document_file
from app.public_urls import is_production_environment
from app.services.cloud_service import (
    CloudResourceNotFoundError,
    create_workspace,
    list_workspaces,
    update_workspace,
    delete_workspace,
    create_document,
    list_documents,
    delete_document,
    create_chat,
    list_chats,
    save_message,
    list_messages,
    get_chat_messages,
    delete_chat,
    update_chat_title,
    upsert_study_result,
    get_study_result,
    list_study_results,
    delete_study_result,
    upsert_audiobook,
    list_audiobooks,
    delete_audiobook,
)


router = APIRouter(
    prefix="/cloud",
    tags=["Cloud"],
)


class StrictRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class WorkspaceCreate(StrictRequestModel):
    name: str = Field(min_length=1, max_length=200)
    description: str = Field(default="", max_length=4000)


class WorkspaceUpdate(WorkspaceCreate):
    pass


class DocumentCreate(StrictRequestModel):
    workspace_id: str = Field(min_length=1, max_length=255)
    document_name: str = Field(min_length=1, max_length=255)
    document_id: str = Field(min_length=1, max_length=255)
    file_url: str = Field(default="", max_length=4096)
    summary: str = Field(default="", max_length=100000)
    audio_url: str = Field(default="", max_length=4096)


class ChatCreate(StrictRequestModel):
    workspace_id: str | None = Field(default=None, max_length=255)
    document_id: str | None = Field(default=None, max_length=255)
    title: str = Field(default="Nuevo chat", min_length=1, max_length=300)


class ChatUpdate(StrictRequestModel):
    title: str = Field(min_length=1, max_length=300)


class MessageCreate(StrictRequestModel):
    chat_id: str = Field(min_length=1, max_length=255)
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=50000)


class StudyResultCreate(StrictRequestModel):
    document_id: str = Field(min_length=1, max_length=255)
    type: str = Field(min_length=1, max_length=64)
    content: str = Field(min_length=1, max_length=2_000_000)


class AudiobookCreate(StrictRequestModel):
    document_id: str = Field(min_length=1, max_length=255)
    file_name: str = Field(min_length=1, max_length=255)
    chapters: list[dict] = Field(min_length=1, max_length=200)


def handle_cloud_error(error: Exception) -> HTTPException:
    if isinstance(error, CloudResourceNotFoundError):
        return HTTPException(
            status_code=404,
            detail="Recurso no encontrado.",
        )

    if isinstance(error, PermissionError):
        return HTTPException(
            status_code=403,
            detail="No tienes permiso para acceder a este recurso.",
        )

    if isinstance(error, ValueError):
        return HTTPException(
            status_code=400,
            detail=str(error),
        )

    return HTTPException(
        status_code=500,
        detail="No se pudo completar la operación en la nube.",
    )


@router.post("/workspaces")
async def create_workspace_endpoint(
    payload: WorkspaceCreate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return create_workspace(
            name=payload.name,
            description=payload.description,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/workspaces")
async def list_workspaces_endpoint(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "workspaces": list_workspaces(
                user_id=current_user.user_id,
            ),
        }
    except Exception as error:
        raise handle_cloud_error(error)




@router.get("/library-documents")
async def list_library_documents_endpoint(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "documents": list_library_documents(
                user_id=current_user.user_id,
            ),
        }
    except Exception as error:
        raise handle_cloud_error(error)






@router.post("/rehydrate-document/{document_id}")
async def rehydrate_document_endpoint(
    document_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    local_path: Path | None = None
    try:
        download_info = get_document_download_url(
            document_id=document_id,
            user_id=current_user.user_id,
        )

        bucket = download_info["bucket"]
        storage_path = download_info["storage_path"]

        filename = Path(storage_path).name
        uploads_dir = (
            Path(tempfile.gettempdir()) / "studybook-ai"
            if is_production_environment()
            else Path(__file__).resolve().parent.parent / "uploads"
        )
        uploads_dir.mkdir(parents=True, exist_ok=True)
        local_path = uploads_dir / f"rehydrated_{uuid4()}_{filename}"

        download_document_from_storage(
            bucket=bucket,
            storage_path=storage_path,
            destination_path=str(local_path),
        )

        pages = extract_pages_from_pdf(str(local_path))

        new_document_id = index_document_pages_for_rag(
            pages,
            owner_scope=current_user.user_id,
        )

        if new_document_id != document_id:
            raise ValueError(
                "El document_id rehidratado no coincide con el document_id cloud."
            )

        register_document_file(
            document_id=document_id,
            filename=filename,
            file_path=str(local_path),
            size_bytes=local_path.stat().st_size,
            user_id=current_user.user_id,
            storage_bucket=bucket,
            storage_path=storage_path,
        )

        return {
            "ready": True,
            "document_id": document_id,
            "filename": filename,
            "page_count": len(pages),
        }

    except Exception as error:
        raise handle_cloud_error(error)
    finally:
        if is_production_environment() and local_path is not None:
            local_path.unlink(missing_ok=True)


@router.get("/document-download-url/{document_id}")
async def document_download_url_endpoint(
    document_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return get_document_download_url(
            document_id=document_id,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.post("/documents")
async def create_document_endpoint(
    payload: DocumentCreate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return create_document(
            workspace_id=payload.workspace_id,
            document_name=payload.document_name,
            document_id=payload.document_id,
            file_url=payload.file_url,
            summary=payload.summary,
            audio_url=payload.audio_url,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/documents")
async def list_documents_endpoint(
    workspace_id: str | None = None,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "documents": list_documents(
                user_id=current_user.user_id,
                workspace_id=workspace_id,
            ),
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.post("/chats")
async def create_chat_endpoint(
    payload: ChatCreate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return create_chat(
            user_id=current_user.user_id,
            workspace_id=payload.workspace_id,
            document_id=payload.document_id,
            title=payload.title,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/chats")
async def list_chats_endpoint(
    workspace_id: str | None = None,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "chats": list_chats(
                user_id=current_user.user_id,
                workspace_id=workspace_id,
            ),
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/chats/{chat_id}/messages")
async def get_chat_messages_endpoint(
    chat_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "messages": get_chat_messages(
                chat_id=chat_id,
                user_id=current_user.user_id,
            ),
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.post("/messages")
async def save_message_endpoint(
    payload: MessageCreate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return save_message(
            chat_id=payload.chat_id,
            role=payload.role,
            content=payload.content,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/messages/{chat_id}")
async def list_messages_endpoint(
    chat_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "messages": list_messages(
                chat_id=chat_id,
                user_id=current_user.user_id,
            ),
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.delete("/chats/{chat_id}")
async def delete_chat_endpoint(
    chat_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return delete_chat(
            chat_id=chat_id,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.patch("/chats/{chat_id}")
async def update_chat_endpoint(
    chat_id: str,
    payload: ChatUpdate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return update_chat_title(
            chat_id=chat_id,
            title=payload.title,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.post("/study-results")
async def upsert_study_result_endpoint(
    payload: StudyResultCreate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return upsert_study_result(
            user_id=current_user.user_id,
            document_id=payload.document_id,
            type=payload.type,
            content=payload.content,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/study-results")
async def list_study_results_endpoint(
    type: str | None = None,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "study_results": list_study_results(
                user_id=current_user.user_id,
                type=type,
            )
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/study-results/{document_id}/{type}")
async def get_study_result_endpoint(
    document_id: str,
    type: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "study_result": get_study_result(
                user_id=current_user.user_id,
                document_id=document_id,
                type=type,
            )
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.delete("/study-results/{document_id}/{type}")
async def delete_study_result_endpoint(
    document_id: str,
    type: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return delete_study_result(
            user_id=current_user.user_id,
            document_id=document_id,
            type=type,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.post("/audiobooks")
async def upsert_audiobook_endpoint(
    payload: AudiobookCreate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return upsert_audiobook(
            user_id=current_user.user_id,
            document_id=payload.document_id,
            file_name=payload.file_name,
            chapters=payload.chapters,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.get("/audiobooks")
async def list_audiobooks_endpoint(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "audiobooks": list_audiobooks(
                user_id=current_user.user_id,
            )
        }
    except Exception as error:
        raise handle_cloud_error(error)


@router.delete("/audiobooks/{document_id}")
async def delete_audiobook_endpoint(
    document_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return delete_audiobook(
            user_id=current_user.user_id,
            document_id=document_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.delete("/documents/{document_id}")
async def delete_document_endpoint(
    document_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return delete_document(
            user_id=current_user.user_id,
            document_id=document_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.patch("/workspaces/{workspace_id}")
async def update_workspace_endpoint(
    workspace_id: str,
    payload: WorkspaceUpdate,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return update_workspace(
            workspace_id=workspace_id,
            user_id=current_user.user_id,
            name=payload.name,
            description=payload.description,
        )
    except Exception as error:
        raise handle_cloud_error(error)


@router.delete("/workspaces/{workspace_id}")
async def delete_workspace_endpoint(
    workspace_id: str,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return delete_workspace(
            workspace_id=workspace_id,
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise handle_cloud_error(error)
