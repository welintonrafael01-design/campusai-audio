#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("backend/app/routes/educator.py")
text = path.read_text()

if "def _candidate_user_ids" not in text:
    marker = """def _upsert(table: str, rows: list[dict[str, Any]]) -> int:
    if not rows:
        return 0

    client = get_supabase_admin_client()
    response = client.table(table).upsert(rows, on_conflict="id").execute()

    if response.data is None:
        return len(rows)

    return len(response.data)
"""
    helper = marker + """

def _candidate_user_ids(current_user: AuthenticatedUser) -> list[str]:
    ids: list[str] = []

    primary = _safe_text(current_user.user_id).strip()
    if primary:
        ids.append(primary)

    email = _safe_text(getattr(current_user, "email", "")).strip().lower()
    if email:
        client = get_supabase_admin_client()
        try:
            response = (
                client.table("user_subscriptions")
                .select("user_id,email")
                .eq("email", email)
                .execute()
            )
            for row in response.data or []:
                candidate = _safe_text(row.get("user_id")).strip()
                if candidate and candidate not in ids:
                    ids.append(candidate)
        except Exception:
            pass

    return ids


def _select_for_user_candidates(
    *,
    table: str,
    user_ids: list[str],
) -> list[dict[str, Any]]:
    client = get_supabase_admin_client()

    for user_id in user_ids:
        rows = (
            client.table(table)
            .select("*")
            .eq("user_id", user_id)
            .execute()
            .data
            or []
        )

        if rows:
            return rows

    return []
"""
    text = text.replace(marker, helper)

old = """    client = get_supabase_admin_client()
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
"""

new = """    user_ids = _candidate_user_ids(current_user)

    try:
        courses = _select_for_user_candidates(
            table="educator_courses",
            user_ids=user_ids,
        )
        students = _select_for_user_candidates(
            table="educator_students",
            user_ids=user_ids,
        )
        attendance = _select_for_user_candidates(
            table="educator_attendance",
            user_ids=user_ids,
        )
        gradebook = _select_for_user_candidates(
            table="educator_gradebook",
            user_ids=user_ids,
        )
"""

if old in text:
    text = text.replace(old, new)
else:
    raise SystemExit("No se encontró el bloque snapshot esperado.")

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo "===== EDUCATOR ROUTE CHECK ====="
grep -n "_candidate_user_ids\|_select_for_user_candidates\|user_ids =" app/routes/educator.py

cd "$ROOT/mobile/campusai_mobile"
flutter analyze || true

cd "$ROOT"
git status --short
