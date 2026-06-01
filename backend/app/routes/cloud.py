from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

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
    user_id: str | None = None


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


@router.post("/workspaces")
async def create_workspace_endpoint(
    payload: WorkspaceCreate,
):
    try:
        return create_workspace(
            name=payload.name,
            description=payload.description,
            user_id=payload.user_id,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/workspaces")
async def list_workspaces_endpoint():
    try:
        return {
            "workspaces": list_workspaces(),
        }
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/documents")
async def create_document_endpoint(
    payload: DocumentCreate,
):
    try:
        return create_document(
            workspace_id=payload.workspace_id,
            document_name=payload.document_name,
            document_id=payload.document_id,
            file_url=payload.file_url,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/documents")
async def list_documents_endpoint(
    workspace_id: str | None = None,
):
    try:
        return {
            "documents": list_documents(
                workspace_id=workspace_id,
            ),
        }
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/chats")
async def create_chat_endpoint(
    payload: ChatCreate,
):
    try:
        return create_chat(
            workspace_id=payload.workspace_id,
            document_id=payload.document_id,
            title=payload.title,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/chats")
async def list_chats_endpoint():
    try:
        return {
            "chats": list_chats(),
        }
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/chats/{chat_id}/messages")
async def get_chat_messages_endpoint(
    chat_id: str,
):
    try:
        return {
            "messages": get_chat_messages(
                chat_id=chat_id,
            ),
        }
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/messages")
async def save_message_endpoint(
    payload: MessageCreate,
):
    try:
        return save_message(
            chat_id=payload.chat_id,
            role=payload.role,
            content=payload.content,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/messages/{chat_id}")
async def list_messages_endpoint(
    chat_id: str,
):
    try:
        return {
            "messages": list_messages(
                chat_id=chat_id,
            ),
        }
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )



@router.delete("/chats/{chat_id}")
async def delete_chat_endpoint(
    chat_id: str,
):
    try:
        return delete_chat(chat_id=chat_id)
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )



@router.patch("/chats/{chat_id}")
async def update_chat_endpoint(
    chat_id: str,
    payload: ChatUpdate,
):
    try:
        return update_chat_title(
            chat_id=chat_id,
            title=payload.title,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )
