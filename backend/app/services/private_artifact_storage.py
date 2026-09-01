from __future__ import annotations

from app.database.supabase_client import get_supabase_admin_client
from app.persistence_config import (
    private_artifacts_bucket,
    validate_storage_segment,
)


ARTIFACT_CATEGORIES = ("audio", "audiobook")


def build_private_artifact_path(
    *,
    user_id: str,
    category: str,
    filename: str,
) -> str:
    owner = validate_storage_segment(user_id, field_name="user_id")
    safe_category = validate_storage_segment(category, field_name="category")
    safe_filename = validate_storage_segment(filename, field_name="filename")
    if safe_category not in ARTIFACT_CATEGORIES:
        raise ValueError("Categoria de artefacto no permitida.")
    return f"{owner}/{safe_category}/{safe_filename}"


def upload_private_artifact(
    *,
    user_id: str,
    category: str,
    filename: str,
    content: bytes,
    content_type: str,
    client=None,
) -> dict:
    if not content:
        raise ValueError("El artefacto privado esta vacio.")
    storage_path = build_private_artifact_path(
        user_id=user_id,
        category=category,
        filename=filename,
    )
    bucket = private_artifacts_bucket()
    storage = (client or get_supabase_admin_client()).storage.from_(bucket)
    response = storage.upload(
        path=storage_path,
        file=content,
        file_options={"content-type": content_type, "upsert": "true"},
    )
    return {
        "bucket": bucket,
        "storage_path": storage_path,
        "response": str(response),
    }


def download_private_artifact(
    *,
    user_id: str,
    category: str,
    filename: str,
    client=None,
) -> bytes:
    storage_path = build_private_artifact_path(
        user_id=user_id,
        category=category,
        filename=filename,
    )
    content = (
        (client or get_supabase_admin_client())
        .storage.from_(private_artifacts_bucket())
        .download(storage_path)
    )
    return bytes(content)


def delete_private_artifact(
    *,
    user_id: str,
    category: str,
    filename: str,
    client=None,
) -> None:
    storage_path = build_private_artifact_path(
        user_id=user_id,
        category=category,
        filename=filename,
    )
    (
        (client or get_supabase_admin_client())
        .storage.from_(private_artifacts_bucket())
        .remove([storage_path])
    )


def list_private_artifacts_for_user(*, user_id: str, client=None) -> list[str]:
    owner = validate_storage_segment(user_id, field_name="user_id")
    storage = (
        (client or get_supabase_admin_client())
        .storage.from_(private_artifacts_bucket())
    )
    paths: list[str] = []
    for category in ARTIFACT_CATEGORIES:
        offset = 0
        while True:
            rows = storage.list(
                path=f"{owner}/{category}",
                options={"limit": 1000, "offset": offset},
            ) or []
            for row in rows:
                name = str((row or {}).get("name") or "").strip()
                if not name:
                    continue
                safe_name = validate_storage_segment(name, field_name="filename")
                paths.append(f"{owner}/{category}/{safe_name}")
            if len(rows) < 1000:
                break
            offset += len(rows)
    return paths


def delete_private_artifacts_for_user(*, user_id: str, client=None) -> int:
    storage_client = client or get_supabase_admin_client()
    paths = list_private_artifacts_for_user(
        user_id=user_id,
        client=storage_client,
    )
    if paths:
        storage_client.storage.from_(private_artifacts_bucket()).remove(paths)
    return len(paths)
