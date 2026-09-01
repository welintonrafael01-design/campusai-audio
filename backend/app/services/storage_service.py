from __future__ import annotations

from pathlib import Path
import re

from app.database.supabase_client import get_supabase_admin_client
from app.persistence_config import (
    document_storage_bucket,
    validate_storage_segment,
)


def get_storage_bucket() -> str:
    return document_storage_bucket()


def build_document_storage_path(
    *,
    user_id: str,
    document_id: str,
    filename: str,
) -> str:
    owner = validate_storage_segment(user_id, field_name="user_id")
    document = validate_storage_segment(document_id, field_name="document_id")
    safe_name = re.sub(
        r"[^A-Za-z0-9_.-]+",
        "_",
        Path(filename).name,
    ).strip("._")
    safe_name = safe_name[:255] or "document.pdf"
    safe_name = validate_storage_segment(safe_name, field_name="filename")

    return (
        f"{owner}/documents/"
        f"{document}/{safe_name}"
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
    content = download_document_bytes(
        bucket=bucket,
        storage_path=storage_path,
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


def download_document_bytes(*, bucket: str, storage_path: str) -> bytes:
    clean_bucket = validate_storage_segment(bucket, field_name="bucket")
    parts = str(storage_path or "").split("/")
    if len(parts) != 4 or parts[1] != "documents":
        raise ValueError("storage_path de documento no permitido.")
    for index, part in enumerate(parts):
        validate_storage_segment(part, field_name=f"storage_path[{index}]")
    content = (
        get_supabase_admin_client()
        .storage.from_(clean_bucket)
        .download("/".join(parts))
    )
    return bytes(content)


def delete_document_storage_object(*, bucket: str, storage_path: str) -> None:
    clean_bucket = validate_storage_segment(bucket, field_name="bucket")
    parts = str(storage_path or "").split("/")
    if len(parts) != 4 or parts[1] != "documents":
        raise ValueError("storage_path de documento no permitido.")
    for index, part in enumerate(parts):
        validate_storage_segment(part, field_name=f"storage_path[{index}]")
    get_supabase_admin_client().storage.from_(clean_bucket).remove(
        ["/".join(parts)]
    )
