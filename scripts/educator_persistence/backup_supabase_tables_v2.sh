#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKUP_DIR="$ROOT/backups/supabase_educator_stable_v1"
BACKEND="$ROOT/backend"

mkdir -p "$BACKUP_DIR"

cd "$BACKEND"

python3 <<'PY'
import csv
import json
from pathlib import Path

from dotenv import load_dotenv
from app.database.supabase_client import get_supabase_admin_client

backend_dir = Path.home() / "Desktop/campusai-audio/backend"
load_dotenv(backend_dir / ".env")

backup_dir = Path.home() / "Desktop/campusai-audio/backups/supabase_educator_stable_v1"
backup_dir.mkdir(parents=True, exist_ok=True)

tables = [
    "user_subscriptions",
    "workspaces",
    "documents",
    "chats",
    "messages",
    "courses",
    "students",
    "attendance",
    "gradebook",
    "rubrics",
    "question_bank",
    "certificates",
    "academic_badges",
    "academic_recognitions",
]

client = get_supabase_admin_client()
summary = {}

for table in tables:
    try:
        response = client.table(table).select("*").execute()
        rows = response.data or []

        (backup_dir / f"{table}.json").write_text(
            json.dumps(rows, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        csv_path = backup_dir / f"{table}.csv"

        if rows:
            fieldnames = sorted({key for row in rows for key in row.keys()})
            with csv_path.open("w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(rows)
        else:
            csv_path.write_text("", encoding="utf-8")

        summary[table] = {"ok": True, "rows": len(rows)}
        print(f"OK {table}: {len(rows)} filas")

    except Exception as exc:
        summary[table] = {"ok": False, "error": str(exc)}
        print(f"ERROR {table}: {exc}")

(backup_dir / "_backup_summary.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2),
    encoding="utf-8",
)

print(f"\nBackup guardado en: {backup_dir}")
PY
