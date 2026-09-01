from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

from app.database.supabase_client import get_supabase_admin_client
from app.public_urls import is_production_environment


DATA_DIR = Path(__file__).resolve().parents[2] / "data"
CERTIFICATES_FILE = DATA_DIR / "certificates.json"


def _ensure_store() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not CERTIFICATES_FILE.exists():
        CERTIFICATES_FILE.write_text("[]", encoding="utf-8")


def _read_certificates() -> list[dict]:
    _ensure_store()

    try:
        data = json.loads(CERTIFICATES_FILE.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else []
    except Exception:
        return []


def _public_record(record: dict) -> dict:
    return {
        key: value
        for key, value in record.items()
        if key != "user_id"
    }


def list_certificates(*, user_id: str) -> list[dict]:
    clean_user_id = str(user_id or "").strip()
    if not clean_user_id:
        return []

    if is_production_environment():
        response = (
            get_supabase_admin_client()
            .table("certificates")
            .select("*")
            .eq("user_id", clean_user_id)
            .order("issued_at", desc=True)
            .execute()
        )
        return [_public_record(item) for item in (response.data or [])]

    return [
        _public_record(item)
        for item in _read_certificates()
        if str(item.get("user_id") or "").strip() == clean_user_id
    ]


def save_certificate(record: dict, *, user_id: str) -> dict:
    clean_user_id = str(user_id or "").strip()
    if not clean_user_id:
        raise ValueError("user_id es obligatorio.")

    certificate_id = str(record.get("certificate_id", "")).strip()

    if not certificate_id:
        raise ValueError("certificate_id es obligatorio.")

    clean_record = {
        "certificate_id": certificate_id,
        "user_id": clean_user_id,
        "student_name": str(record.get("student_name", "")).strip(),
        "student_code": str(record.get("student_code", "")).strip(),
        "course_name": str(record.get("course_name", "")).strip(),
        "average": str(record.get("average", "")).strip(),
        "period": str(record.get("period", "")).strip(),
        "recognition_type": str(record.get("recognition_type", "certificate")).strip() or "certificate",
        "issued_at": str(record.get("issued_at") or datetime.now().isoformat()),
        "status": str(record.get("status", "valid")).strip() or "valid",
    }

    if is_production_environment():
        existing = (
            get_supabase_admin_client()
            .table("certificates")
            .select("user_id")
            .eq("certificate_id", certificate_id)
            .limit(1)
            .execute()
        )
        if existing.data and existing.data[0].get("user_id") != clean_user_id:
            raise PermissionError(
                "El identificador del certificado no esta disponible."
            )
        result = (
            get_supabase_admin_client()
            .table("certificates")
            .upsert(clean_record, on_conflict="certificate_id")
            .execute()
        )
        saved = (result.data or [clean_record])[0]
        return _public_record(saved)

    _ensure_store()
    certificates = _read_certificates()
    existing = next(
        (
            item
            for item in certificates
            if item.get("certificate_id") == certificate_id
        ),
        None,
    )
    if existing is not None and existing.get("user_id") != clean_user_id:
        raise PermissionError("El identificador del certificado no está disponible.")

    certificates = [
        item for item in certificates
        if item.get("certificate_id") != certificate_id
    ]
    certificates.insert(0, clean_record)

    CERTIFICATES_FILE.write_text(
        json.dumps(certificates, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    return _public_record(clean_record)


def get_certificate(certificate_id: str) -> dict | None:
    clean_id = str(certificate_id or "").strip()

    if not clean_id:
        return None

    if is_production_environment():
        response = (
            get_supabase_admin_client()
            .table("certificates")
            .select("*")
            .eq("certificate_id", clean_id)
            .limit(1)
            .execute()
        )
        return _public_record(response.data[0]) if response.data else None

    for item in _read_certificates():
        if item.get("certificate_id") == clean_id:
            return _public_record(item)

    return None


def delete_certificates_for_user(*, user_id: str) -> int:
    clean_user_id = str(user_id or "").strip()
    if not clean_user_id:
        raise ValueError("user_id es obligatorio.")

    if is_production_environment():
        existing = (
            get_supabase_admin_client()
            .table("certificates")
            .select("certificate_id")
            .eq("user_id", clean_user_id)
            .execute()
        )
        get_supabase_admin_client().table("certificates").delete().eq(
            "user_id", clean_user_id
        ).execute()
        return len(existing.data or [])

    certificates = _read_certificates()
    remaining = [
        item
        for item in certificates
        if str(item.get("user_id") or "").strip() != clean_user_id
    ]
    deleted = len(certificates) - len(remaining)

    _ensure_store()
    CERTIFICATES_FILE.write_text(
        json.dumps(remaining, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return deleted
