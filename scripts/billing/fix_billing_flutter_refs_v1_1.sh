#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "===== FIX BILLING FLUTTER REFS V1.1 ====="

mkdir -p "$ROOT/backups/billing_fix_$STAMP"

cp "$FLUTTER/lib/config/app_plans.dart" "$ROOT/backups/billing_fix_$STAMP/app_plans.dart.bak"
cp "$FLUTTER/lib/screens/settings_screen.dart" "$ROOT/backups/billing_fix_$STAMP/settings_screen.dart.bak"
cp "$FLUTTER/lib/widgets/dashboard/dashboard_educator_center.dart" "$ROOT/backups/billing_fix_$STAMP/dashboard_educator_center.dart.bak"
cp "$FLUTTER/lib/widgets/dashboard/dashboard_stats.dart" "$ROOT/backups/billing_fix_$STAMP/dashboard_stats.dart.bak"
cp "$FLUTTER/lib/widgets/sidebar.dart" "$ROOT/backups/billing_fix_$STAMP/sidebar.dart.bak"

python3 <<'PY'
from pathlib import Path

root = Path.home() / "Desktop/campusai-audio"
flutter = root / "mobile/campusai_mobile"

# Add compatibility getter maxChatMessagesPerDay.
app_plans = flutter / "lib/config/app_plans.dart"
text = app_plans.read_text()

if "int get maxChatMessagesPerDay => maxChatsPerDay;" not in text:
    text = text.replace(
        "final int maxChatsPerDay;\n",
        "final int maxChatsPerDay;\n  int get maxChatMessagesPerDay => maxChatsPerDay;\n",
    )

app_plans.write_text(text)

# Replace enum refs in affected files.
for rel in [
    "lib/screens/settings_screen.dart",
    "lib/widgets/dashboard/dashboard_educator_center.dart",
    "lib/widgets/dashboard/dashboard_stats.dart",
    "lib/widgets/sidebar.dart",
]:
    path = flutter / rel
    text = path.read_text()

    text = text.replace("CampusPlan.pro", "CampusPlan.student")
    text = text.replace("CampusPlan.educator", "CampusPlan.teacher")

    text = text.replace("'Pro'", "'Student'")
    text = text.replace("'Educator'", "'Teacher'")
    text = text.replace('"Pro"', '"Student"')
    text = text.replace('"Educator"', '"Teacher"')

    text = text.replace("Cuenta Pro", "Cuenta Student")
    text = text.replace("Cuenta Educator", "Cuenta Teacher")

    text = text.replace("Plan Pro", "Plan Student")
    text = text.replace("Plan Educator", "Plan Teacher")

    path.write_text(text)
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
echo "===== OLD REFERENCES CHECK ====="
cd "$ROOT"
grep -R "CampusPlan.pro\|CampusPlan.educator" mobile/campusai_mobile/lib -n || true

echo ""
echo "===== GIT STATUS ====="
git status --short

echo ""
echo "===== DONE ====="
echo "Backups en: $ROOT/backups/billing_fix_$STAMP"
