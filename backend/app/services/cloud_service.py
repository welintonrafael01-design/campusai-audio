from __future__ import annotations

import json

from app.database.supabase_client import get_supabase_admin_client


ALLOWED_STUDY_RESULT_TYPES = {
    "assessment_report",
    "audiobook",
    "curriculum_intelligence",
    "exam",
    "final_report",
    "flashcards",
    "question_bank",
    "quiz",
    "rubric",
    "study_guide",
    "teaching_plan",
    "teaching_resources",
}


class CloudResourceNotFoundError(LookupError):
    """Raised when an owner-scoped cloud resource is not visible."""


def canonical_study_result_type(value: str) -> str:
    clean_type = value.strip().lower()

    if clean_type not in ALLOWED_STUDY_RESULT_TYPES:
        raise ValueError("Tipo de resultado inválido.")

    return clean_type


def create_workspace(
    *,
    name: str,
    description: str = "",
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    payload = {
        "name": name.strip() or "Workspace",
        "description": description,
        "user_id": user_id,
    }

    response = (
        client
        .table("workspaces")
        .insert(payload)
        .execute()
    )

    return response.data[0]


def list_workspaces(
    *,
    user_id: str,
) -> list[dict]:
    client = get_supabase_admin_client()

    response = (
        client
        .table("workspaces")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )

    return response.data


def get_workspace(
    *,
    workspace_id: str,
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    response = (
        client
        .table("workspaces")
        .select("*")
        .eq("id", workspace_id)
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )

    if not response.data:
        raise PermissionError(
            "No tienes permiso para acceder a este workspace."
        )

    return response.data




def update_workspace(
    *,
    workspace_id: str,
    user_id: str,
    name: str,
    description: str = "",
) -> dict:
    client = get_supabase_admin_client()

    get_workspace(
        workspace_id=workspace_id,
        user_id=user_id,
    )

    payload = {
        "name": name.strip() or "Workspace",
        "description": description,
    }

    response = (
        client
        .table("workspaces")
        .update(payload)
        .eq("id", workspace_id)
        .eq("user_id", user_id)
        .execute()
    )

    return response.data[0]


def delete_workspace(
    *,
    workspace_id: str,
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    get_workspace(
        workspace_id=workspace_id,
        user_id=user_id,
    )

    (
        client
        .table("documents")
        .delete()
        .eq("workspace_id", workspace_id)
        .execute()
    )

    (
        client
        .table("chats")
        .delete()
        .eq("workspace_id", workspace_id)
        .eq("user_id", user_id)
        .execute()
    )

    (
        client
        .table("workspaces")
        .delete()
        .eq("id", workspace_id)
        .eq("user_id", user_id)
        .execute()
    )

    return {
        "deleted": True,
        "workspace_id": workspace_id,
    }


def create_document(
    *,
    workspace_id: str,
    document_name: str,
    document_id: str,
    user_id: str,
    file_url: str = "",
    summary: str = "",
    audio_url: str = "",
) -> dict:
    client = get_supabase_admin_client()

    get_workspace(
        workspace_id=workspace_id,
        user_id=user_id,
    )

    payload = {
        "workspace_id": workspace_id,
        "user_id": user_id,
        "document_name": document_name,
        "document_id": document_id,
        "file_url": file_url,
        "summary": summary,
        "audio_url": audio_url,
    }

    response = (
        client
        .table("documents")
        .insert(payload)
        .execute()
    )

    return response.data[0]


def list_documents(
    *,
    user_id: str,
    workspace_id: str | None = None,
) -> list[dict]:
    client = get_supabase_admin_client()

    workspace_query = (
        client
        .table("workspaces")
        .select("id")
        .eq("user_id", user_id)
    )

    if workspace_id:
        workspace_query = workspace_query.eq(
            "id",
            workspace_id,
        )

    workspace_response = workspace_query.execute()
    workspace_ids = [
        item["id"]
        for item in workspace_response.data
    ]

    if not workspace_ids:
        return []

    response = (
        client
        .table("documents")
        .select("*")
        .in_("workspace_id", workspace_ids)
        .order("created_at", desc=True)
        .execute()
    )

    return response.data






def delete_document(
    *,
    user_id: str,
    document_id: str,
) -> dict:
    client = get_supabase_admin_client()

    workspace_response = (
        client
        .table("workspaces")
        .select("id")
        .eq("user_id", user_id)
        .execute()
    )

    workspace_ids = [
        item["id"]
        for item in workspace_response.data
    ]

    if workspace_ids:
        (
            client
            .table("documents")
            .delete()
            .in_("workspace_id", workspace_ids)
            .eq("document_id", document_id)
            .execute()
        )

    (
        client
        .table("documents")
        .delete()
        .is_("workspace_id", "null")
        .eq("document_id", document_id)
        .like("storage_path", f"{user_id}/documents/%")
        .execute()
    )

    return {
        "deleted": True,
        "document_id": document_id,
    }


def upsert_study_result(
    *,
    user_id: str,
    document_id: str,
    type: str,
    content: str,
) -> dict:
    clean_type = canonical_study_result_type(type)
    client = get_supabase_admin_client()

    payload = {
        "user_id": user_id,
        "document_id": document_id,
        "type": clean_type,
        "content": content,
    }

    response = (
        client
        .table("study_results")
        .upsert(
            payload,
            on_conflict="user_id,document_id,type",
        )
        .execute()
    )

    return response.data[0]


def get_study_result(
    *,
    user_id: str,
    document_id: str,
    type: str,
) -> dict | None:
    clean_type = canonical_study_result_type(type)
    client = get_supabase_admin_client()

    response = (
        client
        .table("study_results")
        .select("*")
        .eq("user_id", user_id)
        .eq("document_id", document_id)
        .eq("type", clean_type)
        .maybe_single()
        .execute()
    )

    return response.data if response is not None else None


def list_study_results(
    *,
    user_id: str,
    type: str | None = None,
) -> list[dict]:
    clean_type = canonical_study_result_type(type) if type else None
    client = get_supabase_admin_client()

    query = (
        client
        .table("study_results")
        .select("*")
        .eq("user_id", user_id)
    )

    if clean_type:
        query = query.eq("type", clean_type)

    response = (
        query
        .order("updated_at", desc=True)
        .execute()
    )

    return response.data


def delete_study_result(
    *,
    user_id: str,
    document_id: str,
    type: str,
) -> dict:
    clean_type = canonical_study_result_type(type)
    client = get_supabase_admin_client()

    (
        client
        .table("study_results")
        .delete()
        .eq("user_id", user_id)
        .eq("document_id", document_id)
        .eq("type", clean_type)
        .execute()
    )

    return {
        "deleted": True,
        "document_id": document_id,
        "type": clean_type,
    }


def user_owns_legacy_audiobook_audio(*, user_id: str, filename: str) -> bool:
    clean_filename = filename.strip()
    if not clean_filename:
        return False

    client = get_supabase_admin_client()

    try:
        study_results = (
            client
            .table("study_results")
            .select("content")
            .eq("user_id", user_id)
            .eq("type", "audiobook")
            .execute()
        )
        for row in study_results.data or []:
            content = row.get("content") if isinstance(row, dict) else None
            try:
                payload = json.loads(content) if isinstance(content, str) else content
            except (TypeError, ValueError):
                continue
            if _audiobook_payload_contains_filename(payload, clean_filename):
                return True

        legacy_results = (
            client
            .table("audiobooks")
            .select("chapters")
            .eq("user_id", user_id)
            .execute()
        )
        return any(
            _audiobook_payload_contains_filename(row, clean_filename)
            for row in (legacy_results.data or [])
        )
    except Exception:
        return False


def _audiobook_payload_contains_filename(payload, filename: str) -> bool:
    if not isinstance(payload, dict):
        return False

    chapters = payload.get("chapters")
    if not isinstance(chapters, list):
        return False

    for chapter in chapters:
        if not isinstance(chapter, dict):
            continue
        audio_url = str(chapter.get("audio_url") or "").strip()
        if audio_url.rsplit("/", 1)[-1] == filename:
            return True
    return False




def upsert_audiobook(
    *,
    user_id: str,
    document_id: str,
    file_name: str,
    chapters: list[dict],
) -> dict:
    client = get_supabase_admin_client()

    if not document_id.strip():
        raise ValueError("document_id es requerido.")

    if not file_name.strip():
        raise ValueError("file_name es requerido.")

    if not chapters:
        raise ValueError("chapters es requerido.")

    payload = {
        "user_id": user_id,
        "document_id": document_id,
        "file_name": file_name,
        "chapters": chapters,
    }

    response = (
        client
        .table("audiobooks")
        .upsert(
            payload,
            on_conflict="user_id,document_id",
        )
        .execute()
    )

    return response.data[0]


def list_audiobooks(
    *,
    user_id: str,
) -> list[dict]:
    client = get_supabase_admin_client()

    response = (
        client
        .table("audiobooks")
        .select("*")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )

    return response.data


def delete_audiobook(
    *,
    user_id: str,
    document_id: str,
) -> dict:
    client = get_supabase_admin_client()

    (
        client
        .table("audiobooks")
        .delete()
        .eq("user_id", user_id)
        .eq("document_id", document_id)
        .execute()
    )

    return {
        "deleted": True,
        "document_id": document_id,
    }


def create_chat(
    *,
    user_id: str,
    workspace_id: str | None = None,
    document_id: str | None = None,
    title: str = "Nuevo chat",
) -> dict:
    client = get_supabase_admin_client()

    payload = {
        "title": title.strip() or "Nuevo chat",
        "user_id": user_id,
    }

    if workspace_id:
        get_workspace(
            workspace_id=workspace_id,
            user_id=user_id,
        )
        payload["workspace_id"] = workspace_id

    if document_id:
        payload["document_id"] = document_id

    response = (
        client
        .table("chats")
        .insert(payload)
        .execute()
    )

    return response.data[0]


def list_chats(
    *,
    user_id: str,
    workspace_id: str | None = None,
) -> list[dict]:
    client = get_supabase_admin_client()

    query = (
        client
        .table("chats")
        .select("*")
        .eq("user_id", user_id)
    )

    if workspace_id:
        get_workspace(
            workspace_id=workspace_id,
            user_id=user_id,
        )
        query = query.eq("workspace_id", workspace_id)

    response = (
        query
        .order("created_at", desc=True)
        .execute()
    )

    return response.data


def get_chat(
    *,
    chat_id: str,
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    response = (
        client
        .table("chats")
        .select("*")
        .eq("id", chat_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )

    rows = response.data if response is not None else []
    if not rows:
        raise CloudResourceNotFoundError("Conversación no encontrada.")

    return rows[0]


def save_message(
    *,
    chat_id: str,
    role: str,
    content: str,
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    get_chat(
        chat_id=chat_id,
        user_id=user_id,
    )

    payload = {
        "chat_id": chat_id,
        "role": role,
        "content": content,
    }

    response = (
        client
        .table("messages")
        .insert(payload)
        .execute()
    )

    return response.data[0]


def list_messages(
    *,
    chat_id: str,
    user_id: str,
) -> list[dict]:
    client = get_supabase_admin_client()

    get_chat(
        chat_id=chat_id,
        user_id=user_id,
    )

    response = (
        client
        .table("messages")
        .select("*")
        .eq("chat_id", chat_id)
        .order("created_at")
        .execute()
    )

    return response.data


def get_chat_messages(
    *,
    chat_id: str,
    user_id: str,
) -> list[dict]:
    return list_messages(
        chat_id=chat_id,
        user_id=user_id,
    )


def delete_chat(
    *,
    chat_id: str,
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    get_chat(
        chat_id=chat_id,
        user_id=user_id,
    )

    response = (
        client
        .table("chats")
        .delete()
        .eq("id", chat_id)
        .eq("user_id", user_id)
        .execute()
    )

    return {
        "deleted": True,
        "chat_id": chat_id,
        "data": response.data,
    }


def update_chat_title(
    *,
    chat_id: str,
    title: str,
    user_id: str,
) -> dict:
    client = get_supabase_admin_client()

    clean_title = title.strip()

    if not clean_title:
        raise ValueError("El título no puede estar vacío.")

    get_chat(
        chat_id=chat_id,
        user_id=user_id,
    )

    response = (
        client
        .table("chats")
        .update({
            "title": clean_title,
        })
        .eq("id", chat_id)
        .eq("user_id", user_id)
        .execute()
    )

    data = response.data

    if not data:
        raise ValueError("No se encontró la conversación.")

    return data[0]
