#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

echo "===== ADD EDUCATOR AUTO RESTORE ON LOGIN V1 ====="

python3 <<'PY'
from pathlib import Path

flutter = Path.home() / "Desktop/campusai-audio/mobile/campusai_mobile"

auth = flutter / "lib/screens/auth_screen.dart"
text = auth.read_text()

if "educator_sync_service.dart" not in text:
    text = text.replace(
        "import '../services/auth_service.dart';",
        "import '../services/auth_service.dart';\nimport '../services/educator_sync_service.dart';",
    )

old = """        await AuthService.signIn(
          email: email,
          password: password,
        );"""

new = """        await AuthService.signIn(
          email: email,
          password: password,
        );

        await const EducatorSyncService().pullRemoteIntoLocalIfAvailable();"""

if old in text and "pullRemoteIntoLocalIfAvailable" not in text:
    text = text.replace(old, new)

auth.write_text(text)
PY

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$FLUTTER"
flutter analyze || true

echo ""
echo "===== RESTORE CHECK ====="
grep -R "pullRemoteIntoLocalIfAvailable\|EducatorSyncService" lib/screens lib/services -n

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
