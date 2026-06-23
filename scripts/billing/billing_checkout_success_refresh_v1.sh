#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"
FILE="$FLUTTER/lib/screens/plans_screen.dart"

python3 <<'PY'
from pathlib import Path

file = Path("mobile/campusai_mobile/lib/screens/plans_screen.dart")
text = file.read_text()

# Insertar llamada de refresh cuando ya existe manejo de checkout success.
if "refreshSubscriptionFromServer" not in text:
    old = """      if (mounted) {
        setState(() {});
      }"""
    new = """      try {
        await const BillingService().refreshSubscriptionFromServer();
      } catch (_) {
        // Si el webhook aún no ha procesado, se mantiene el plan local.
      }

      if (mounted) {
        setState(() {});
      }"""
    if old in text:
        text = text.replace(old, new, 1)
    else:
        raise SystemExit("No se encontró el bloque setState esperado.")

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "refreshSubscriptionFromServer\|checkout=success" \
mobile/campusai_mobile/lib/screens/plans_screen.dart \
mobile/campusai_mobile/lib/services/billing_service.dart -n

git status --short
