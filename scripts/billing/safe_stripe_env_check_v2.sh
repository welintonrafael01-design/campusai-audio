#!/usr/bin/env bash
set -e

cd "$HOME/Desktop/campusai-audio/backend"

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
    is_placeholder = "PEGA_AQUI" in value or "PEGAR_" in value
    valid = bool(value) and not is_placeholder
    status = "OK" if valid else "FALTA/INVALIDO"
    masked = value[:8] + "..." + value[-4:] if len(value) > 14 else ("***" if value else "")
    print(f"{key}: {status} {masked}")
PY
