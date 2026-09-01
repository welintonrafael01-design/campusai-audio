from __future__ import annotations

from app.database.supabase_client import get_supabase_admin_client
from app.public_urls import is_production_environment


def _document_path_pattern(user_id: str) -> str:
    clean_user_id = str(user_id).strip()

    if not clean_user_id:
        raise ValueError("user_id es requerido para acceder a documentos cloud.")

    return f"{clean_user_id}/documents/%"


def _with_owner(rows, *, user_id: str):
    return [
        {
            **row,
            "user_id": user_id,
        }
        for row in (rows or [])
    ]


def _missing_user_id_column(error: Exception) -> bool:
    message = str(error).lower()
    missing_column_code = "42703" in message or "pgrst204" in message
    return missing_column_code and "user_id" in message


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

    try:
        result = client.table("documents").insert(payload).execute()
    except Exception as error:
        if is_production_environment() or not _missing_user_id_column(error):
            raise

        # Production still has the legacy documents schema in some projects.
        # Ownership remains enforceable through the user-scoped storage path.
        legacy_payload = {
            key: value
            for key, value in payload.items()
            if key != "user_id"
        }
        result = client.table("documents").insert(legacy_payload).execute()

    return _with_owner(result.data, user_id=user_id)


def list_documents(
    *,
    user_id: str,
):
    client = get_supabase_admin_client()

    result = (
        client.table("documents")
        .select("*")
        .like("storage_path", _document_path_pattern(user_id))
        .order("uploaded_at", desc=True)
        .execute()
    )

    return _with_owner(result.data, user_id=user_id)


def delete_document(
    *,
    document_id: str,
    user_id: str,
):
    client = get_supabase_admin_client()

    return (
        client.table("documents")
        .delete()
        .eq("document_id", document_id)
        .like("storage_path", _document_path_pattern(user_id))
        .execute()
    )



def list_library_documents(*, user_id: str):
    client = get_supabase_admin_client()

    result = (
        client
        .table("documents")
        .select("*")
        .not_.is_("filename", "null")
        .not_.is_("storage_path", "null")
        .like("storage_path", _document_path_pattern(user_id))
        .order("uploaded_at", desc=True)
        .execute()
    )

    return _with_owner(result.data, user_id=user_id)



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
