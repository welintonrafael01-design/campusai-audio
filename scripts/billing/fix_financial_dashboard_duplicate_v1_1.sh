#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

file = Path.home() / "Desktop/campusai-audio/backend/app/routes/billing.py"
text = file.read_text()

marker = '@router.get(\n    "/admin/financial-dashboard",'
first = text.find(marker)
second = text.find(marker, first + 1)

if first != -1 and second != -1:
    text = text[:second].rstrip() + "\n"
    file.write_text(text)
    print("Endpoint financiero duplicado eliminado.")
else:
    print("No se encontró duplicado.")
PY

echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== DUPLICATE CHECK ====="
grep -n "admin/financial-dashboard" app/routes/billing.py

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$ROOT/mobile/campusai_mobile"
flutter analyze

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short
