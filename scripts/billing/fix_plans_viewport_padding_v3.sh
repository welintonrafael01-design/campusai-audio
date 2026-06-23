#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

file = Path.home() / "Desktop/campusai-audio/mobile/campusai_mobile/lib/screens/plans_screen.dart"
text = file.read_text()

# Más espacio debajo del AppBar para evitar que el contenido quede oculto.
text = text.replace(
    "padding: const EdgeInsets.all(22),",
    "padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),",
    1,
)

# Cambiar breakpoint de desktop para evitar 5 columnas apretadas.
text = text.replace(
    "final columns = maxWidth >= 1500\n                  ? 5\n                  : maxWidth >= 1100\n                      ? 3",
    "final columns = maxWidth >= 1200\n                  ? 3\n                  : maxWidth >= 720\n                      ? 2",
)

# Por si quedó la rama vieja de 720 duplicada, normalizar expresión.
text = text.replace(
    """: maxWidth >= 720
                          ? 2
                          : 1;""",
    """: 1;""",
)

# Hero más compacto.
text = text.replace(
    "padding: const EdgeInsets.all(22),",
    "padding: const EdgeInsets.all(18),",
    1,
)

# Reducir separación vertical excesiva.
text = text.replace(
    "const SizedBox(height: 16),\n          LayoutBuilder(",
    "const SizedBox(height: 14),\n          LayoutBuilder(",
)

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -n "fromLTRB\|final columns\|maxWidth >= 1200\|Wrap(" mobile/campusai_mobile/lib/screens/plans_screen.dart

git status --short
