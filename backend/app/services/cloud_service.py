from app.database.supabase_client import get_supabase_client


def create_workspace(
    name: str,
    description: str = "",
    user_id: str | None = None,
) -> dict:
    client = get_supabase_client()

    payload = {
        "name": name,
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


def list_workspaces() -> list[dict]:
    client = get_supabase_client()

    response = (
        client
        .table("workspaces")
        .select("*")
        .order("created_at", desc=True)
        .execute()
    )

    return response.data


def create_document(
    workspace_id: str,
    document_name: str,
    document_id: str,
    file_url: str = "",
) -> dict:
    client = get_supabase_client()

    payload = {
        "workspace_id": workspace_id,
        "document_name": document_name,
        "document_id": document_id,
        "file_url": file_url,
    }

    response = (
        client
        .table("documents")
        .insert(payload)
        .execute()
    )

    return response.data[0]


def list_documents(
    workspace_id: str | None = None,
) -> list[dict]:
    client = get_supabase_client()

    query = client.table("documents").select("*")

    if workspace_id:
        query = query.eq(
            "workspace_id",
            workspace_id,
        )

    response = (
        query
        .order("created_at", desc=True)
        .execute()
    )

    return response.data


def create_chat(
    workspace_id: str,
    title: str = "Nuevo chat",
) -> dict:
    client = get_supabase_client()

    payload = {
        "workspace_id": workspace_id,
        "title": title,
    }

    response = (
        client
        .table("chats")
        .insert(payload)
        .execute()
    )

    return response.data[0]


def save_message(
    chat_id: str,
    role: str,
    content: str,
) -> dict:
    client = get_supabase_client()

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
    chat_id: str,
) -> list[dict]:
    client = get_supabase_client()

    response = (
        client
        .table("messages")
        .select("*")
        .eq("chat_id", chat_id)
        .order("created_at")
        .execute()
    )

    return response.data
