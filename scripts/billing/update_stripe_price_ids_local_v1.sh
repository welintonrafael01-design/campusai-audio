#!/usr/bin/env bash
set -e

BACKEND="$HOME/Desktop/campusai-audio/backend"
ENV_FILE="$BACKEND/.env"

STUDENT_PRICE_ID="price_1TIXLHDwbFlJozTIAmYtFRSZ"
TEACHER_PRICE_ID="price_1TIXLoDwbFlJozTINlPEpaqh"
ACCESSIBILITY_PRICE_ID="price_1TlWjHDwbFlJozTID4CfwCFT"
ULTRA_PRICE_ID="price_1TlXAIDwbFlJozTlTrorPCkH"

python3 <<PY
from pathlib import Path

env_file = Path("$ENV_FILE")
text = env_file.read_text()

updates = {
    "STRIPE_STUDENT_PRICE_ID": "$STUDENT_PRICE_ID",
    "STRIPE_TEACHER_PRICE_ID": "$TEACHER_PRICE_ID",
    "STRIPE_ACCESSIBILITY_PRICE_ID": "$ACCESSIBILITY_PRICE_ID",
    "STRIPE_ULTRA_PRICE_ID": "$ULTRA_PRICE_ID",
}

lines = text.splitlines()
seen = set()
new_lines = []

for line in lines:
    if "=" in line and not line.strip().startswith("#"):
        key = line.split("=", 1)[0].strip()
        if key in updates:
            new_lines.append(f"{key}={updates[key]}")
            seen.add(key)
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

for key, value in updates.items():
    if key not in seen:
        new_lines.append(f"{key}={value}")

env_file.write_text("\\n".join(new_lines).rstrip() + "\\n")
PY

echo "Stripe Price IDs actualizados localmente."

cd "$HOME/Desktop/campusai-audio"
./safe_stripe_env_check_v2.sh
