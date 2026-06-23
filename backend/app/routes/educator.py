from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.database.supabase_client import get_supabase_admin_client
from app.security.user_auth import AuthenticatedUser, require_current_user


router = APIRouter(
    prefix="/educator",
    tags=["educator"],
)


class EducatorSyncPayload(BaseModel):
    courses: list[dict[str, Any]] = Field(default_factory=list)
    students: list[dict[str, Any]] = Field(default_factory=list)
    attendance: list[dict[str, Any]] = Field(default_factory=list)
    gradebook: list[dict[str, Any]] = Field(default_factory=list)


def _safe_text(value: Any) -> str:
    return "" if value is None else str(value)


def _upsert(table: str, rows: list[dict[str, Any]]) -> int:
    if not rows:
        return 0

    client = get_supabase_admin_client()
    response = client.table(table).upsert(rows, on_conflict="id").execute()

    if response.data is None:
        return len(rows)

    return len(response.data)


@router.get("/snapshot")
def get_educator_snapshot(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    client = get_supabase_admin_client()
    user_id = current_user.user_id

    try:
        courses = (
            client.table("educator_courses")
            .select("*")
            .eq("user_id", user_id)
            .execute()
            .data
            or []
        )
        students = (
            client.table("educator_students")
            .select("*")
            .eq("user_id", user_id)
            .execute()
            .data
            or []
        )
        attendance = (
            client.table("educator_attendance")
            .select("*")
            .eq("user_id", user_id)
            .execute()
            .data
            or []
        )
        gradebook = (
            client.table("educator_gradebook")
            .select("*")
            .eq("user_id", user_id)
            .execute()
            .data
            or []
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo cargar el snapshot Educator: {exc}",
        ) from exc

    return {
        "courses": [row.get("payload") or row for row in courses],
        "students": [row.get("payload") or row for row in students],
        "attendance": [row.get("payload") or row for row in attendance],
        "gradebook": [row.get("payload") or row for row in gradebook],
        "source": "supabase",
    }


@router.post("/sync")
def sync_educator_snapshot(
    payload: EducatorSyncPayload,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    user_id = current_user.user_id

    course_rows = []
    for item in payload.courses:
        record_id = _safe_text(item.get("id")).strip()
        name = _safe_text(item.get("name")).strip()
        if not record_id or not name:
            continue

        course_rows.append(
            {
                "id": record_id,
                "user_id": user_id,
                "name": name,
                "code": _safe_text(item.get("code")),
                "section": _safe_text(item.get("section")),
                "period": _safe_text(item.get("period")),
                "is_active": False,
                "program_document_id": _safe_text(
                    item.get("programDocumentId") or item.get("program_document_id")
                ),
                "payload": item,
            }
        )

    student_rows = []
    for item in payload.students:
        record_id = _safe_text(item.get("id")).strip()
        name = _safe_text(item.get("name")).strip()
        if not record_id or not name:
            continue

        student_rows.append(
            {
                "id": record_id,
                "user_id": user_id,
                "course_id": _safe_text(item.get("courseId") or item.get("course_id")),
                "name": name,
                "student_id": _safe_text(
                    item.get("studentCode")
                    or item.get("student_code")
                    or item.get("studentId")
                    or item.get("id")
                ),
                "email": _safe_text(item.get("email")),
                "phone": _safe_text(item.get("phone")),
                "payload": item,
            }
        )

    attendance_rows = []
    for item in payload.attendance:
        record_id = _safe_text(item.get("id")).strip()
        date = _safe_text(item.get("date") or item.get("attendance_date"))[:10]
        status = _safe_text(item.get("status")).strip()
        if not record_id or not date or not status:
            continue

        attendance_rows.append(
            {
                "id": record_id,
                "user_id": user_id,
                "course_id": _safe_text(item.get("courseId") or item.get("course_id")),
                "student_id": _safe_text(item.get("studentId") or item.get("student_id")),
                "attendance_date": date,
                "status": status,
                "payload": item,
            }
        )

    gradebook_rows = []
    for item in payload.gradebook:
        record_id = _safe_text(item.get("id")).strip()
        if not record_id:
            continue

        gradebook_rows.append(
            {
                "id": record_id,
                "user_id": user_id,
                "course_id": _safe_text(item.get("courseId") or item.get("course_id")),
                "student_id": _safe_text(item.get("studentId") or item.get("student_id")),
                "assessment_name": _safe_text(
                    item.get("rubricTitle")
                    or item.get("assessmentName")
                    or item.get("assessment_name")
                ),
                "score": item.get("score") or 0,
                "max_score": item.get("maxScore") or item.get("max_score") or 0,
                "weight": item.get("weight"),
                "payload": item,
            }
        )

    try:
        return {
            "source": "supabase",
            "courses": _upsert("educator_courses", course_rows),
            "students": _upsert("educator_students", student_rows),
            "attendance": _upsert("educator_attendance", attendance_rows),
            "gradebook": _upsert("educator_gradebook", gradebook_rows),
        }
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo sincronizar Educator: {exc}",
        ) from exc
