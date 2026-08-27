from __future__ import annotations

import hashlib
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.security.teacher_auth import require_teacher_access
from app.security.user_auth import AuthenticatedUser
from app.services.certificate_service import get_certificate, list_certificates, save_certificate


router = APIRouter(prefix="/certificates", tags=["certificates"])


class RecognitionRecordPayload(BaseModel):
    student_name: str
    student_code: str = ""
    course_name: str = ""
    average: str = ""
    period: str = ""
    recognition_type: str = "certificate"


class AutoRecognitionPayload(BaseModel):
    recognitions: list[RecognitionRecordPayload]






@router.get("/stats")
async def recognition_stats(
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    certificates = list_certificates(user_id=current_user.user_id)
    by_type: dict[str, int] = {}

    for item in certificates:
        recognition_type = str(item.get("recognition_type", "certificate") or "certificate")
        by_type[recognition_type] = by_type.get(recognition_type, 0) + 1

    return {
        "total": len(certificates),
        "by_type": by_type,
        "certificates": by_type.get("certificate", 0),
        "badges": by_type.get("badge", 0),
        "excellence": by_type.get("excellence", 0),
        "honor": by_type.get("honor", 0),
        "gold_medal": by_type.get("gold_medal", 0),
        "silver_medal": by_type.get("silver_medal", 0),
        "bronze_medal": by_type.get("bronze_medal", 0),
    }


@router.post("/auto-recognitions")
async def save_auto_recognitions(
    payload: AutoRecognitionPayload,
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    saved = []

    for item in payload.recognitions:
        recognition_type = item.recognition_type.strip().lower() or "certificate"
        year = datetime.now().strftime("%Y")
        raw = (
            f"{current_user.user_id}|{recognition_type}|{item.student_code}|"
            f"{item.student_name}|"
            f"{item.course_name}|{item.average}|{year}"
        )
        digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()[:8].upper()
        certificate_id = f"REC-{year}-{digest}"

        saved.append(
            save_certificate(
                {
                    "certificate_id": certificate_id,
                    "student_name": item.student_name,
                    "student_code": item.student_code,
                    "course_name": item.course_name,
                    "average": item.average,
                    "period": item.period or recognition_type,
                    "recognition_type": recognition_type,
                    "status": "valid",
                },
                user_id=current_user.user_id,
            )
        )

    return {
        "saved": saved,
        "count": len(saved),
    }


@router.get("/list")
async def list_recognitions(
    current_user: AuthenticatedUser = Depends(require_teacher_access),
):
    return {
        "certificates": list_certificates(user_id=current_user.user_id),
    }


@router.get("/verify/{certificate_id}")
async def verify_certificate(certificate_id: str):
    certificate = get_certificate(certificate_id)

    if certificate is None:
        raise HTTPException(
            status_code=404,
            detail="Certificado no encontrado.",
        )

    return {
        "valid": certificate.get("status") == "valid",
        "certificate_id": certificate.get("certificate_id", ""),
        "student_name": certificate.get("student_name", ""),
        "student_code": certificate.get("student_code", ""),
        "course_name": certificate.get("course_name", ""),
        "average": certificate.get("average", ""),
        "period": certificate.get("period", ""),
        "recognition_type": certificate.get("recognition_type", "certificate"),
        "issued_at": certificate.get("issued_at", ""),
        "status": certificate.get("status", "valid"),
    }
