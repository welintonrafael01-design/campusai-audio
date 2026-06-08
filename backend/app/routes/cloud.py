from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.security.user_auth import (
    AuthenticatedUser,
    require_current_user,
)

from app.services.cloud_service import (
    create_workspace,
    list_workspaces,
    create_document,
    list_documents,
    create_chat,
    list_chats,
    save_message,
    list_messages,
    get_chat_messages,
    delete_chat,
    update_chat_title,
)


router = APIRouter(
    prefix="/cloud",
    tags=["Cloud"],
)


class WorkspaceCreate(BaseModel):
    name: str
    description: str = ""


class DocumentCreate(BaseModel):
    workspace_id: str
    document_name: str
    document_id: str
    file_url: str = ""


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
