#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN_DIR="$ROOT_DIR/QA/runs/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$RUN_DIR"

cd "$ROOT_DIR"

git status --short > "$RUN_DIR/git-status.txt"
{
  echo "StudyBook AI QA bundle"
  echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Branch: $(git branch --show-current)"
  echo "Commit: $(git log -1 --oneline)"
} > "$RUN_DIR/summary.txt"

{
  echo "Backend compile:"
  python3 -m py_compile $(find backend/app -name "*.py")
  echo
  echo "Backend tests:"
  if [ -x backend/.venv/bin/python ]; then
    PYTHONPATH="$ROOT_DIR/backend" backend/.venv/bin/python -m pytest backend/tests -q
  else
    PYTHONPATH="$ROOT_DIR/backend" python3 -m pytest backend/tests -q
  fi
  echo
  echo "Flutter analyze:"
  (cd mobile/campusai_mobile && flutter analyze)
  echo
  echo "Flutter test:"
  (cd mobile/campusai_mobile && flutter test)
} 2>&1 | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" > "$RUN_DIR/test-results.txt" || true

if [ -f "$ROOT_DIR/flutter.log" ]; then
  python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" < "$ROOT_DIR/flutter.log" > "$RUN_DIR/flutter.log"
fi

if [ -f "$ROOT_DIR/backend.log" ]; then
  python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" < "$ROOT_DIR/backend.log" > "$RUN_DIR/backend.log"
fi

if command -v adb >/dev/null 2>&1; then
  adb logcat -d -v time 2>/dev/null | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" > "$RUN_DIR/android.log" || true
fi

echo "$RUN_DIR"
