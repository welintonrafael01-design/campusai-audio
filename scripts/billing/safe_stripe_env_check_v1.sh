#!/usr/bin/env bash
set -e

BACKEND="$HOME/Desktop/campusai-audio/backend"

cd "$BACKEND"

python3 <<'PY'
from pathlib import Path

required = [
    "STRIPE_SECRET_KEY",
    "STRIPE_WEBHOOK_SECRET",
    "STRIPE_STUDENT_PRICE_ID",
    "STRIPE_TEACHER_PRICE_ID",
    "STRIPE_ACCESSIBILITY_PRICE_ID",
    "STRIPE_ULTRA_PRICE_ID",
    "ADMIN_EMAILS",
]

env = {}
for line in Path(".env").read_text().splitlines():
    if "=" in line and not line.strip().startswith("#"):
        key, value = line.split("=", 1)
        env[key.strip()] = value.strip()

for key in required:
    value = env.get(key, "")
    status = "OK" if value else "FALTA"
    masked = value[:8] + "..." + value[-4:] if len(value) > 14 else ("***" if value else "")
    print(f"{key}: {status} {masked}")
PY

python -m py_compile $(find app -name "*.py")
