#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
BACKUP="$ROOT/backups/browser_educator_full_v1/studybook_educator_browser_backup_downloaded.json"

cd "$BACKEND"

python3 <<PY
import json
from pathlib import Path
from datetime import datetime, timezone

from dotenv import load_dotenv
from app.database.supabase_client import get_supabase_admin_client

load_dotenv(".env")

backup_path = Path("$BACKUP")
data = json.loads(backup_path.read_text())
keys = data.get("educatorKeys", {})

def parse_maybe_json(value):
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            decoded = json.loads(value)
            if isinstance(decoded, dict):
                return decoded
        except Exception:
            return {}
    return {}

def load_key(name):
    raw = keys.get(name, "[]")
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, list):
            return [parse_maybe_json(item) for item in parsed]
        return []
    except Exception:
        return []

courses = load_key("flutter.studybook_courses")
students = load_key("flutter.studybook_students_roster")
attendance = load_key("flutter.studybook_attendance_entries")
gradebook = load_key("flutter.studybook_gradebook_entries")

client = get_supabase_admin_client()

email = "welintonrafael01@gmail.com"
sub = (
    client.table("user_subscriptions")
    .select("user_id,email")
    .eq("email", email)
    .limit(1)
    .execute()
)

if not sub.data:
    raise SystemExit("ERROR: No se encontró user_id en user_subscriptions para " + email)

user_id = sub.data[0]["user_id"]
now = datetime.now(timezone.utc).isoformat()

print("USER_ID:", user_id)
print("courses:", len(courses))
print("students:", len(students))
print("attendance:", len(attendance))
print("gradebook:", len(gradebook))

course_rows = []
for item in courses:
    course_id = str(item.get("id") or "").strip()
    name = str(item.get("name") or "").strip()
    if not course_id or not name:
        continue

    course_rows.append({
        "id": course_id,
        "user_id": user_id,
        "name": name,
        "code": str(item.get("code") or ""),
        "section": str(item.get("section") or ""),
        "period": str(item.get("period") or ""),
        "is_active": True,
        "payload": item,
        "updated_at": now,
    })

student_rows = []
for item in students:
    student_pk = str(item.get("id") or "").strip()
    name = str(item.get("name") or "").strip()
    if not student_pk or not name:
        continue

    student_rows.append({
        "id": student_pk,
        "user_id": user_id,
        "course_id": str(item.get("courseId") or item.get("course_id") or ""),
        "name": name,
        "student_id": str(item.get("studentCode") or item.get("student_code") or item.get("id") or ""),
        "email": str(item.get("email") or ""),
        "phone": "",
        "payload": item,
        "updated_at": now,
    })

attendance_rows = []
for item in attendance:
    entry_id = str(item.get("id") or "").strip()
    date = str(item.get("date") or "")[:10]
    status = str(item.get("status") or "").strip()
    if not entry_id or not date or not status:
        continue

    attendance_rows.append({
        "id": entry_id,
        "user_id": user_id,
        "course_id": str(item.get("courseId") or item.get("course_id") or ""),
        "student_id": str(item.get("studentId") or ""),
        "attendance_date": date,
        "status": status,
        "payload": item,
        "updated_at": now,
    })

gradebook_rows = []
for item in gradebook:
    entry_id = str(item.get("id") or "").strip()
    if not entry_id:
        continue

    gradebook_rows.append({
        "id": entry_id,
        "user_id": user_id,
        "course_id": str(item.get("courseId") or item.get("course_id") or ""),
        "student_id": str(item.get("studentId") or ""),
        "assessment_name": str(item.get("rubricTitle") or ""),
        "score": item.get("score") or 0,
        "max_score": item.get("maxScore") or 0,
        "weight": None,
        "payload": item,
        "updated_at": now,
    })

def upsert(table, rows):
    if not rows:
        print(f"SKIP {table}: 0 filas")
        return

    response = client.table(table).upsert(rows, on_conflict="id").execute()
    print(f"OK {table}: {len(response.data or rows)} filas")

upsert("educator_courses", course_rows)
upsert("educator_students", student_rows)
upsert("educator_attendance", attendance_rows)
upsert("educator_gradebook", gradebook_rows)

print("MIGRATION_DONE")
PY
