#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

root = Path.home() / "Desktop/campusai-audio"
flutter = root / "mobile/campusai_mobile"

files = [
    flutter / "lib/screens/settings_screen.dart",
    flutter / "lib/widgets/sidebar.dart",
]

for path in files:
    text = path.read_text()

    # Settings / labels
    text = text.replace(
        "CampusPlan.teacher => 'Teacher',",
        "CampusPlan.teacher => 'Teacher',\n      CampusPlan.accessibility => 'Accessibility',",
    )

    # Sidebar account title
    text = text.replace(
        "CampusPlan.student => 'Cuenta Student',",
        "CampusPlan.student => 'Cuenta Student',\n                CampusPlan.accessibility => 'Cuenta Accessibility',",
    )

    # Sidebar subtitles
    text = text.replace(
        "CampusPlan.student =>",
        "CampusPlan.accessibility =>\n                    'Plan accesible con audio, IA y exportaciones.',\n                CampusPlan.student =>",
        1,
    )

    # Sidebar icons
    text = text.replace(
        "CampusPlan.student => Icons.workspace_premium_rounded,",
        "CampusPlan.student => Icons.workspace_premium_rounded,\n                CampusPlan.accessibility => Icons.accessibility_new_rounded,",
    )

    path.write_text(text)
PY

echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$FLUTTER"
flutter analyze

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short
