#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/mobile/campusai_mobile"
SECRETS_FILE="${QA_SECRETS_FILE:-$ROOT_DIR/QA/secrets/qa_android.local.json}"
RUN_DIR="$ROOT_DIR/QA/automated/runs/$(date +%Y%m%d_%H%M%S)_android"
LOGCAT_PID=""

stop_logcat() {
  if [[ -n "$LOGCAT_PID" ]] && kill -0 "$LOGCAT_PID" 2>/dev/null; then
    kill "$LOGCAT_PID" 2>/dev/null || true
    wait "$LOGCAT_PID" 2>/dev/null || true
  fi
}
trap stop_logcat EXIT

"$ROOT_DIR/tools/qa/validate_qa_secrets.sh" "$SECRETS_FILE"
"$ROOT_DIR/tools/qa/check_backend.sh"

if ! command -v adb >/dev/null 2>&1; then
  echo "adb is unavailable. Install Android platform-tools." >&2
  exit 1
fi

if ! adb devices | awk '$1 == "emulator-5554" && $2 == "device" { found = 1 } END { exit !found }'; then
  echo "Android emulator emulator-5554 is not ready." >&2
  exit 1
fi

mkdir -p "$RUN_DIR"
git -C "$ROOT_DIR" status --short > "$RUN_DIR/git-status.txt"
{
  echo "StudyBook AI Full Real E2E"
  echo "Target: Android emulator-5554"
  echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Branch: $(git -C "$ROOT_DIR" branch --show-current)"
  echo "Commit: $(git -C "$ROOT_DIR" rev-parse --short HEAD)"
} > "$RUN_DIR/metadata.txt"

adb logcat -c
adb logcat -v time | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" > "$RUN_DIR/android.log" &
LOGCAT_PID=$!

set +e
(
  cd "$FLUTTER_DIR"
  flutter test integration_test -d emulator-5554 \
    --dart-define-from-file="$SECRETS_FILE"
) 2>&1 | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" | tee "$RUN_DIR/test.log"
TEST_STATUS=${PIPESTATUS[0]}
set -e

stop_logcat
LOGCAT_PID=""

if [[ -x "$ROOT_DIR/tools/qa/collect_qa_bundle.sh" ]]; then
  "$ROOT_DIR/tools/qa/collect_qa_bundle.sh" || true
fi

exit "$TEST_STATUS"
