#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

file = Path.home() / "Desktop/campusai-audio/mobile/campusai_mobile/lib/screens/plans_screen.dart"
text = file.read_text()

# Hacer cards un poco más compactas y evitar cortes agresivos en nombres.
text = text.replace(
    "final isWide = constraints.maxWidth >= 980;",
    "final isWide = constraints.maxWidth >= 1180;",
)

text = text.replace(
    "final width = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;",
    "final width = isWide ? (constraints.maxWidth - 64) / 5 : constraints.maxWidth;",
)

# Reducir altura/espacio del hero si existen estos valores.
text = text.replace("padding: const EdgeInsets.all(28),", "padding: const EdgeInsets.all(22),")
text = text.replace("const SizedBox(height: 22),", "const SizedBox(height: 16),")

# Mejorar nombres largos.
text = text.replace("name: 'Accessibility',", "name: 'Access Plan',")
text = text.replace("name: 'Ultra Premium',", "name: 'Ultra',")
text = text.replace("badge: 'TODO INCLUIDO',", "badge: 'PREMIUM',")

# Reducir textos largos.
text = text.replace(
    "'PDFs, chats, flashcards y preguntas sin límites prácticos'",
    "'Límites ampliados premium'"
)
text = text.replace(
    "'Ideal para usuarios intensivos e instituciones pequeñas'",
    "'Ideal para usuarios intensivos'"
)

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
git status --short
