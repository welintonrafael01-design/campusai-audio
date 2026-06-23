#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "===== FIX PLAN SWITCHES CLEAN V1.3 ====="

mkdir -p "$ROOT/backups/billing_switch_clean_$STAMP"
cp "$FLUTTER/lib/screens/settings_screen.dart" "$ROOT/backups/billing_switch_clean_$STAMP/settings_screen.dart.bak"
cp "$FLUTTER/lib/widgets/sidebar.dart" "$ROOT/backups/billing_switch_clean_$STAMP/sidebar.dart.bak"

python3 <<'PY'
from pathlib import Path

root = Path.home() / "Desktop/campusai-audio"
flutter = root / "mobile/campusai_mobile"

def replace_switch_blocks(text: str, mapper) -> str:
    out = []
    i = 0
    marker = "switch (plan) {"

    while True:
        start = text.find(marker, i)
        if start == -1:
            out.append(text[i:])
            break

        out.append(text[i:start])
        brace_start = text.find("{", start)
        depth = 0
        end = brace_start

        while end < len(text):
            if text[end] == "{":
                depth += 1
            elif text[end] == "}":
                depth -= 1
                if depth == 0:
                    end += 1
                    break
            end += 1

        block = text[start:end]
        replacement = mapper(block)

        if replacement is None:
            out.append(block)
        else:
            out.append(replacement)

        i = end

    return "".join(out)

# settings_screen.dart
settings = flutter / "lib/screens/settings_screen.dart"
text = settings.read_text()

def settings_mapper(block: str):
    if "CampusPlan." not in block:
        return None
    if "'Free'" in block or '"Free"' in block or "Student" in block or "Teacher" in block:
        return """switch (plan) {
      CampusPlan.free => 'Free',
      CampusPlan.student => 'Student',
      CampusPlan.accessibility => 'Accessibility',
      CampusPlan.teacher => 'Teacher',
      CampusPlan.ultra => 'Ultra Premium',
    }"""
    return None

text = replace_switch_blocks(text, settings_mapper)
settings.write_text(text)

# sidebar.dart
sidebar = flutter / "lib/widgets/sidebar.dart"
text = sidebar.read_text()

def sidebar_mapper(block: str):
    if "CampusPlan." not in block:
        return None

    if "Cuenta" in block:
        return """switch (plan) {
                CampusPlan.free => 'Cuenta Free',
                CampusPlan.student => 'Cuenta Student',
                CampusPlan.accessibility => 'Cuenta Accessibility',
                CampusPlan.teacher => 'Cuenta Teacher',
                CampusPlan.ultra => 'Cuenta Ultra Premium',
              }"""

    if "Icons." in block:
        return """switch (plan) {
                CampusPlan.free => Icons.school_outlined,
                CampusPlan.student => Icons.workspace_premium_rounded,
                CampusPlan.accessibility => Icons.accessibility_new_rounded,
                CampusPlan.teacher => Icons.school_rounded,
                CampusPlan.ultra => Icons.auto_awesome_rounded,
              }"""

    if "Plan" in block or "plan" in block:
        return """switch (plan) {
                CampusPlan.free =>
                    'Plan gratuito para comenzar con StudyBook AI.',
                CampusPlan.student =>
                    'Plan para estudiantes con IA, PDFs, audio y estudio avanzado.',
                CampusPlan.accessibility =>
                    'Plan accesible con audio, voz, IA y exportaciones.',
                CampusPlan.teacher =>
                    'Plan docente con herramientas académicas completas.',
                CampusPlan.ultra =>
                    'Máximo poder con límites ampliados y funciones premium.',
              }"""

    return None

text = replace_switch_blocks(text, sidebar_mapper)
sidebar.write_text(text)
PY

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$FLUTTER"
flutter analyze

echo ""
echo "===== PLAN REFERENCES CHECK ====="
cd "$ROOT"
grep -R "CampusPlan.pro\|CampusPlan.educator" mobile/campusai_mobile/lib -n || true

echo ""
echo "===== GIT STATUS ====="
git status --short

echo ""
echo "===== DONE ====="
echo "Backups en: $ROOT/backups/billing_switch_clean_$STAMP"
