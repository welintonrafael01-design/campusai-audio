from __future__ import annotations

from app.database.supabase_client import get_supabase_admin_client


ALLOWED_STUDY_RESULT_TYPES = {
    "assessment_report",
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
    client = get_supabase_admin_client()

    clean_type = type.strip().lower()

    if clean_type not in ALLOWED_STUDY_RESULT_TYPES:
        raise ValueError("Tipo de resultado inválido.")

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
    client = get_supabase_admin_client()

    response = (
        client
        .table("study_results")
        .select("*")
        .eq("user_id", user_id)
        .eq("document_id", document_id)
        .eq("type", type.strip().lower())
        .maybe_single()
        .execute()
    )

    return response.data if response is not None else None


def list_study_results(
    *,
    user_id: str,
    type: str | None = None,
) -> list[dict]:
    client = get_supabase_admin_client()

    query = (
        client
        .table("study_results")
        .select("*")
        .eq("user_id", user_id)
    )

    if type:
        query = query.eq("type", type.strip().lower())

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
    client = get_supabase_admin_client()

    (
        client
        .table("study_results")
        .delete()
        .eq("user_id", user_id)
        .eq("document_id", document_id)
        .eq("type", type.strip().lower())
        .execute()
    )

    return {
        "deleted": True,
        "document_id": document_id,
        "type": type,
    }




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

    print(
        "[CLOUD_CHAT_CREATE]",
        {
            "workspace_id": payload.get("workspace_id"),
            "document_id": payload.get("document_id"),
            "title": payload.get("title"),
        },
    )

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
        .maybe_single()
        .execute()
    )

    if not response.data:
        raise PermissionError(
            "No tienes permiso para acceder a esta conversación."
        )

    return response.data


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
