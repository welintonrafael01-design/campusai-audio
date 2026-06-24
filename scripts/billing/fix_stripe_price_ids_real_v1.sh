#!/usr/bin/env bash
set -e

python3 - <<'PY'
from pathlib import Path

env = Path(".env")
text = env.read_text()

text = text.replace(
    "STRIPE_STUDENT_PRICE_ID=price_1TIXLHDwbFlJozTIAmYtFRSZ",
    "STRIPE_STUDENT_PRICE_ID=price_1TlXLHDwbFlJozTIAmYtFRSZ",
)

text = text.replace(
    "STRIPE_TEACHER_PRICE_ID=price_1TIXLoDwbFlJozTINlPEpaqh",
    "STRIPE_TEACHER_PRICE_ID=price_1TlXLoDwbFlJozTINlPEpaqh",
)

text = text.replace(
    "STRIPE_ULTRA_PRICE_ID=price_1TlXAIDwbFlJozTlTrorPCkH",
    "STRIPE_ULTRA_PRICE_ID=price_1TlXAIDwbFlJozTITrorPCkH",
)

env.write_text(text)
PY

grep -n "STRIPE_STUDENT_PRICE_ID\|STRIPE_TEACHER_PRICE_ID\|STRIPE_ACCESSIBILITY_PRICE_ID\|STRIPE_ULTRA_PRICE_ID" .env
