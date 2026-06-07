from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent
DATABASE_DIR = BASE_DIR / "database"
REGISTRY_FILE = DATABASE_DIR / "document_registry.json"


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
) -> dict:
    registry = _read_registry()

    record = {
        "document_id": document_id,
        "filename": filename,
        "file_path": file_path,
        "uploaded_at": datetime.now(
            timezone.utc,
        ).isoformat(),
        "size_bytes": size_bytes,
        "user_id": user_id,
    }

    registry[document_id] = record

    _write_registry(registry)

    return record


def get_document_info(
    document_id: str,
) -> dict:
    registry = _read_registry()

    record = registry.get(document_id)

    if not record:
        raise ValueError(
            "No se encontró información del documento.",
        )

    return record


def require_document_owner(
    *,
    document_id: str,
    user_id: str,
) -> dict:
    record = get_document_info(document_id)

    owner_id = record.get("user_id")

    if owner_id and owner_id != user_id:
        raise PermissionError(
            "No tienes permiso para acceder a este documento.",
        )

    return record
