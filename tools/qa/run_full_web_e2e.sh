#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/mobile/campusai_mobile"
SECRETS_FILE="${QA_SECRETS_FILE:-$ROOT_DIR/QA/secrets/qa_web.local.json}"
RUN_DIR="$ROOT_DIR/QA/automated/runs/$(date +%Y%m%d_%H%M%S)_web"

"$ROOT_DIR/tools/qa/validate_qa_secrets.sh" "$SECRETS_FILE"
"$ROOT_DIR/tools/qa/check_backend.sh"

if ! flutter devices 2>/dev/null | grep -q 'Chrome'; then
  echo "Chrome is not available to Flutter. Install or enable Chrome, then retry." >&2
  exit 1
fi

mkdir -p "$RUN_DIR"
git -C "$ROOT_DIR" status --short > "$RUN_DIR/git-status.txt"
{
  echo "StudyBook AI Full Real E2E"
  echo "Target: Chrome"
  echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Branch: $(git -C "$ROOT_DIR" branch --show-current)"
  echo "Commit: $(git -C "$ROOT_DIR" rev-parse --short HEAD)"
} > "$RUN_DIR/metadata.txt"

set +e
(
  cd "$FLUTTER_DIR"
  flutter test integration_test -d chrome \
    --dart-define-from-file="$SECRETS_FILE"
) 2>&1 | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" | tee "$RUN_DIR/test.log"
TEST_STATUS=${PIPESTATUS[0]}
set -e

exit "$TEST_STATUS"
