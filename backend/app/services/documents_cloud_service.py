from __future__ import annotations

from app.database.supabase_client import get_supabase_admin_client


def create_document(
    *,
    user_id: str,
    document_id: str,
    filename: str,
    storage_bucket: str | None = None,
    storage_path: str | None = None,
    file_path: str | None = None,
    size_bytes: int = 0,
    summary: str = "",
):
    client = get_supabase_admin_client()

    if not user_id or not str(user_id).strip():
        raise ValueError("user_id es requerido para crear documentos cloud.")

    payload = {
        "user_id": user_id,
        "document_id": document_id,
        "document_name": filename,
        "filename": filename,
        "storage_bucket": storage_bucket,
        "storage_path": storage_path,
        "file_path": file_path,
        "size_bytes": size_bytes,
        "summary": summary,
    }

    result = (
        client
        .table("documents")
        .insert(payload)
        .execute()
    )

    return result.data


def list_documents(
    *,
    user_id: str,
):
    client = get_supabase_admin_client()

    result = (
        client
        .table("documents")
        .select("*")
        .eq("user_id", user_id)
        .order("uploaded_at", desc=True)
        .execute()
    )

    return result.data or []


def delete_document(
    *,
    document_id: str,
    user_id: str,
):
    client = get_supabase_admin_client()

    return (
        client
        .table("documents")
        .delete()
        .eq("document_id", document_id)
        .eq("user_id", user_id)
        .execute()
    )



def list_library_documents(*, user_id: str):
    client = get_supabase_admin_client()

    expected_prefix = f"{user_id}/documents/%"

    result = (
        client
        .table("documents")
        .select("*")
        .not_.is_("filename", "null")
        .not_.is_("storage_path", "null")
        .like("storage_path", expected_prefix)
        .order("uploaded_at", desc=True)
        .execute()
    )

    return result.data or []



def get_document_download_url(
    *,
    document_id: str,
    user_id: str,
    expires_in: int = 3600,
):
    client = get_supabase_admin_client()

    response = (
        client
        .table("documents")
        .select("*")
        .eq("document_id", document_id)
        .eq("user_id", user_id)
        .not_.is_("storage_path", "null")
        .limit(1)
        .execute()
    )

    if not response.data:
        raise ValueError("No se encontró el documento en la Biblioteca Cloud.")

    document = response.data[0]

    bucket = document.get("storage_bucket") or "studybook-documents"
    storage_path = document.get("storage_path")

    if not storage_path:
        raise ValueError("El documento no tiene storage_path.")

    expected_prefix = f"{user_id}/documents/"
    if not storage_path.startswith(expected_prefix):
        raise PermissionError("No tienes permiso para descargar este documento.")

    signed = (
        client
        .storage
        .from_(bucket)
        .create_signed_url(
            path=storage_path,
            expires_in=expires_in,
        )
    )

    return {
        "document_id": document_id,
        "bucket": bucket,
        "storage_path": storage_path,
        "signed_url": signed.get("signedURL") or signed.get("signed_url"),
        "expires_in": expires_in,
    }
