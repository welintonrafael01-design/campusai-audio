#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/mobile/campusai_mobile"
SECRETS_FILE="${QA_SECRETS_FILE:-$ROOT_DIR/QA/secrets/qa_android.local.json}"
RUN_DIR="$ROOT_DIR/QA/automated/runs/$(date +%Y%m%d_%H%M%S)_android"

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

for attempt in 1 2 3 4 5; do
  if [[ "$(adb -s emulator-5554 get-state 2>/dev/null || true)" != "device" ]] ||
    ! adb -s emulator-5554 shell 'test "$(getprop sys.boot_completed)" = "1"' 2>/dev/null; then
    echo "Android emulator lost readiness during preflight." >&2
    exit 1
  fi
  if [[ "$attempt" != "5" ]]; then
    sleep 2
  fi
done

echo "Android emulator stability check: READY"

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

set +e
(
  cd "$FLUTTER_DIR"
  flutter test integration_test/full_real_user_journey_e2e_test.dart \
    -d emulator-5554 \
    --dart-define-from-file="$SECRETS_FILE"
) 2>&1 | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" | tee "$RUN_DIR/test.log"
TEST_STATUS=${PIPESTATUS[0]}
set -e

echo "Flutter integration tests: COMPLETE"
grep -E 'E2E_(ARTIFACT|RESULT|MANUAL_GATE|BLOCKED)' "$RUN_DIR/test.log" \
  | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" \
  > "$RUN_DIR/artifact-manifest.txt" || true
echo "Collecting Android logcat..."
if adb logcat -d -v time 2>/dev/null | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" > "$RUN_DIR/android.log"; then
  echo "Android logcat: COMPLETE"
else
  # Diagnostic collection is secondary to the Flutter integration test result.
  echo "WARNING: Android logcat collection failed; preserving test exit code." >&2
fi

if [[ -x "$ROOT_DIR/tools/qa/collect_qa_bundle.sh" ]]; then
  echo "Collecting QA bundle..."
  if "$ROOT_DIR/tools/qa/collect_qa_bundle.sh"; then
    echo "QA bundle: COMPLETE"
  else
    echo "WARNING: QA bundle collection failed; preserving test exit code." >&2
  fi
fi

echo "Android E2E runner: COMPLETE"
echo "Run directory: $RUN_DIR"
echo "Test exit code: $TEST_STATUS"
exit "$TEST_STATUS"
