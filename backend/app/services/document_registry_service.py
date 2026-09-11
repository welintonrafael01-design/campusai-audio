from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from app.database.supabase_client import get_supabase_admin_client
from app.public_urls import is_production_environment


BASE_DIR = Path(__file__).resolve().parent.parent
DATABASE_DIR = BASE_DIR / "database"
REGISTRY_FILE = DATABASE_DIR / "document_registry.json"


class DocumentNotFoundError(LookupError):
    """Raised when a document is unavailable in the caller's owner scope."""


def _ensure_registry() -> None:
    DATABASE_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    if not REGISTRY_FILE.exists():
        REGISTRY_FILE.write_text(
            "{}",
            encoding="utf-8",
        )


def _read_registry() -> dict:
    _ensure_registry()

    try:
        return json.loads(
            REGISTRY_FILE.read_text(
                encoding="utf-8",
            )
        )
    except Exception:
        return {}


def _write_registry(data: dict) -> None:
    _ensure_registry()

    REGISTRY_FILE.write_text(
        json.dumps(
            data,
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )


def register_document_file(
    *,
    document_id: str,
    filename: str,
    file_path: str,
    size_bytes: int,
    user_id: str | None = None,
    storage_bucket: str | None = None,
    storage_path: str | None = None,
) -> dict:
    if not user_id or not str(user_id).strip():
        raise ValueError(
            "user_id es requerido para registrar documentos reales.",
        )

    record = {
        "document_id": document_id,
        "filename": filename,
        "file_path": file_path,
        "uploaded_at": datetime.now(
            timezone.utc,
        ).isoformat(),
        "size_bytes": size_bytes,
        "user_id": user_id,
        "storage_bucket": storage_bucket,
        "storage_path": storage_path,
    }

    if is_production_environment():
        if not storage_bucket or not storage_path:
            raise RuntimeError(
                "El documento no tiene almacenamiento durable configurado."
            )
        return record

    registry = _read_registry()

    registry[document_id] = record

    _write_registry(registry)

    return record


def get_document_info(
    document_id: str,
    *,
    user_id: str | None = None,
) -> dict:
    if is_production_environment():
        clean_user_id = str(user_id or "").strip()
        if not clean_user_id:
            raise PermissionError(
                "user_id es requerido para consultar documentos en produccion."
            )
        response = (
            get_supabase_admin_client()
            .table("documents")
            .select("*")
            .eq("document_id", document_id)
            .eq("user_id", clean_user_id)
            .limit(1)
            .execute()
        )
        if not response.data:
            raise DocumentNotFoundError(
                "No se encontro informacion del documento."
            )
        record = dict(response.data[0])
        record.setdefault("filename", record.get("document_name"))
        record["user_id"] = clean_user_id
        return record

    registry = _read_registry()

    record = registry.get(document_id)

    if not record:
        raise DocumentNotFoundError(
            "No se encontró información del documento.",
        )

    return record


def require_document_owner(
    *,
    document_id: str,
    user_id: str,
) -> dict:
    record = get_document_info(document_id, user_id=user_id)

    owner_id = record.get("user_id")

    if not owner_id:
        raise PermissionError(
            "El documento no tiene propietario asignado.",
        )

    if owner_id != user_id:
        raise PermissionError(
            "No tienes permiso para acceder a este documento.",
        )

    return record


def is_document_owner(
    *,
    document_id: str,
    user_id: str,
) -> bool:
    try:
        record = get_document_info(document_id, user_id=user_id)
    except Exception:
        return False

    owner_id = record.get("user_id")

    if not owner_id:
        return False

    return owner_id == user_id


def list_documents_for_user(*, user_id: str) -> list[dict]:
    clean_user_id = str(user_id or "").strip()
    if not clean_user_id:
        raise ValueError("user_id es requerido para listar documentos.")

    if is_production_environment():
        response = (
            get_supabase_admin_client()
            .table("documents")
            .select("*")
            .eq("user_id", clean_user_id)
            .execute()
        )
        return [dict(item) for item in (response.data or [])]

    return [
        record
        for record in _read_registry().values()
        if isinstance(record, dict)
        and str(record.get("user_id") or "").strip() == clean_user_id
    ]


def delete_documents_for_user(*, user_id: str) -> list[dict]:
    clean_user_id = str(user_id or "").strip()
    if not clean_user_id:
        raise ValueError("user_id es requerido para eliminar documentos.")

    owned_records = list_documents_for_user(user_id=clean_user_id)

    if is_production_environment():
        return owned_records

    registry = _read_registry()

    for record in owned_records:
        file_path = Path(str(record.get("file_path") or ""))
        if file_path.is_file():
            file_path.unlink()

        document_id = str(record.get("document_id") or "").strip()
        if document_id:
            registry.pop(document_id, None)

    _write_registry(registry)
    return owned_records
