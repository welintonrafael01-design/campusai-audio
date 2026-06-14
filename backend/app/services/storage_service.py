from __future__ import annotations

import os
from pathlib import Path

from app.database.supabase_client import get_supabase_admin_client


DEFAULT_BUCKET = "studybook-documents"


def get_storage_bucket() -> str:
    return os.getenv(
        "SUPABASE_STORAGE_BUCKET",
        DEFAULT_BUCKET,
    ).strip() or DEFAULT_BUCKET


def build_document_storage_path(
    *,
    user_id: str,
    document_id: str,
    filename: str,
) -> str:
    safe_name = Path(filename).name.replace(" ", "_")

    return (
        f"{user_id}/documents/"
        f"{document_id}/{safe_name}"
    )


def upload_document_to_storage(
    *,
    user_id: str,
    document_id: str,
    filename: str,
    file_path: str,
) -> dict:
    bucket = get_storage_bucket()
    storage_path = build_document_storage_path(
        user_id=user_id,
        document_id=document_id,
        filename=filename,
    )

    client = get_supabase_admin_client()

    content = Path(file_path).read_bytes()

    response = (
        client
        .storage
        .from_(bucket)
        .upload(
            path=storage_path,
            file=content,
            file_options={
                "content-type": "application/pdf",
                "upsert": "true",
            },
        )
    )

    return {
        "bucket": bucket,
        "storage_path": storage_path,
        "response": str(response),
    }



def download_document_from_storage(
    *,
    bucket: str,
    storage_path: str,
    destination_path: str,
) -> dict:
    client = get_supabase_admin_client()

    content = (
        client
        .storage
        .from_(bucket)
        .download(storage_path)
    )

    Path(destination_path).parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    Path(destination_path).write_bytes(content)

    return {
        "bucket": bucket,
        "storage_path": storage_path,
        "destination_path": destination_path,
        "size_bytes": Path(destination_path).stat().st_size,
    }
