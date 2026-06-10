from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.security.user_auth import (
    AuthenticatedUser,
    require_current_user,
)

from app.services.cloud_service import (
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


class WorkspaceCreate(BaseModel):
    name: str
    description: str = ""


class WorkspaceUpdate(BaseModel):
    name: str
    description: str = ""


class DocumentCreate(BaseModel):
    workspace_id: str
    document_name: str
    document_id: str
    file_url: str = ""
    summary: str = ""
    audio_url: str = ""


class ChatCreate(BaseModel):
    workspace_id: str | None = None
    document_id: str | None = None
    title: str = "Nuevo chat"


class ChatUpdate(BaseModel):
    title: str


class MessageCreate(BaseModel):
    chat_id: str
    role: str
    content: str


class StudyResultCreate(BaseModel):
    document_id: str
    type: str
    content: str


class AudiobookCreate(BaseModel):
    document_id: str
    file_name: str
    chapters: list[dict]


def handle_cloud_error(error: Exception) -> HTTPException:
    if isinstance(error, PermissionError):
        return HTTPException(
            status_code=403,
            detail=str(error),
        )

    return HTTPException(
        status_code=500,
        detail=str(error),
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
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return {
            "chats": list_chats(
                user_id=current_user.user_id,
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
