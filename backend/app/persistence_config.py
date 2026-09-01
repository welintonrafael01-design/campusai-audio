from __future__ import annotations

import os
import re

from app.public_urls import is_production_environment


DEFAULT_DOCUMENT_BUCKET = "studybook-documents"
DEFAULT_PRIVATE_ARTIFACTS_BUCKET = "studybook-private-artifacts"
RAG_CHUNKS_TABLE = "document_chunks"

_SAFE_SEGMENT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,254}$")


class ProductionPersistenceConfigurationError(RuntimeError):
    """Raised when production could fall back to ephemeral persistence."""


def _required_environment_value(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise ProductionPersistenceConfigurationError(
            f"{name} es obligatorio para persistencia durable en produccion."
        )
    return value


def document_storage_bucket() -> str:
    value = os.getenv("SUPABASE_STORAGE_BUCKET", "").strip()
    if is_production_environment():
        return value or _required_environment_value("SUPABASE_STORAGE_BUCKET")
    return value or DEFAULT_DOCUMENT_BUCKET


def private_artifacts_bucket() -> str:
    value = os.getenv("SUPABASE_PRIVATE_ARTIFACTS_BUCKET", "").strip()
    if is_production_environment():
        return value or _required_environment_value(
            "SUPABASE_PRIVATE_ARTIFACTS_BUCKET"
        )
    return value or DEFAULT_PRIVATE_ARTIFACTS_BUCKET


def validate_storage_segment(value: str, *, field_name: str) -> str:
    clean = str(value or "").strip()
    if not _SAFE_SEGMENT.fullmatch(clean) or clean in {".", ".."}:
        raise ValueError(f"{field_name} contiene un identificador no permitido.")
    return clean


def validate_production_persistence_configuration() -> None:
    if not is_production_environment():
        return

    for name in (
        "SUPABASE_URL",
        "SUPABASE_ANON_KEY",
        "SUPABASE_SERVICE_ROLE_KEY",
        "SUPABASE_STORAGE_BUCKET",
        "SUPABASE_PRIVATE_ARTIFACTS_BUCKET",
    ):
        _required_environment_value(name)

    documents_bucket = document_storage_bucket()
    artifacts_bucket = private_artifacts_bucket()
    validate_storage_segment(documents_bucket, field_name="SUPABASE_STORAGE_BUCKET")
    validate_storage_segment(
        artifacts_bucket,
        field_name="SUPABASE_PRIVATE_ARTIFACTS_BUCKET",
    )
    if documents_bucket == artifacts_bucket:
        raise ProductionPersistenceConfigurationError(
            "Los documentos y artefactos privados requieren buckets separados."
        )
