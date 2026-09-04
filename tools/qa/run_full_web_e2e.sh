#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/mobile/campusai_mobile"
SECRETS_FILE="${QA_SECRETS_FILE:-$ROOT_DIR/QA/secrets/qa_web.local.json}"
RUN_DIR="$ROOT_DIR/QA/automated/runs/$(date +%Y%m%d_%H%M%S)_web"
TEST_LOG="$RUN_DIR/test.log"
MANIFEST="$RUN_DIR/artifact-manifest.txt"
WEB_PORT="${QA_WEB_PORT:-}"
if [[ -z "$WEB_PORT" ]]; then
  for candidate in 3000 3001 3002; do
    if ! lsof -nP -iTCP:"$candidate" -sTCP:LISTEN >/dev/null 2>&1; then
      WEB_PORT="$candidate"
      break
    fi
  done
fi
if [[ -z "$WEB_PORT" ]]; then
  echo "No free local Web QA port is available (3000-3002)." >&2
  exit 1
fi
WEB_BASE_URL="http://127.0.0.1:$WEB_PORT"
WEB_SERVER_PID=""
WEBDRIVER_PORT="${QA_WEBDRIVER_PORT:-4444}"
WEBDRIVER_PID=""

cleanup() {
  if [[ -n "$WEB_SERVER_PID" ]]; then
    kill "$WEB_SERVER_PID" 2>/dev/null || true
    wait "$WEB_SERVER_PID" 2>/dev/null || true
    WEB_SERVER_PID=""
  fi
  if [[ -n "$WEBDRIVER_PID" ]]; then
    kill "$WEBDRIVER_PID" 2>/dev/null || true
    wait "$WEBDRIVER_PID" 2>/dev/null || true
    WEBDRIVER_PID=""
  fi
  local child_pids
  child_pids="$(jobs -pr 2>/dev/null || true)"
  if [[ -n "$child_pids" ]]; then
    kill $child_pids 2>/dev/null || true
    wait $child_pids 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

"$ROOT_DIR/tools/qa/validate_qa_secrets.sh" "$SECRETS_FILE"
"$ROOT_DIR/tools/qa/check_backend.sh"

FLUTTER_DEVICES="$(flutter devices 2>/dev/null || true)"
if [[ "$FLUTTER_DEVICES" != *"Chrome"* ]]; then
  echo "Chrome is not available to Flutter. Install or enable Chrome, then retry." >&2
  exit 1
fi

CORS_ORIGIN="${QA_WEB_ORIGIN:-$WEB_BASE_URL}"
CORS_HEADERS="$(mktemp)"
trap 'rm -f "$CORS_HEADERS"; cleanup' EXIT INT TERM

curl --silent --show-error --max-time 10 \
  --request OPTIONS \
  --dump-header "$CORS_HEADERS" \
  --output /dev/null \
  --header "Origin: $CORS_ORIGIN" \
  --header "Access-Control-Request-Method: GET" \
  --header "Access-Control-Request-Headers: authorization,content-type" \
  "http://127.0.0.1:8000/cloud/library-documents"

if ! grep -Eiq "^access-control-allow-origin: ($CORS_ORIGIN|\\*)" "$CORS_HEADERS"; then
  echo "CORS preflight did not allow the Web QA origin." >&2
  exit 1
fi

echo "CORS preflight: PASS"

mkdir -p "$RUN_DIR"
git -C "$ROOT_DIR" status --short > "$RUN_DIR/git-status.txt"
{
  echo "StudyBook AI Full Real E2E"
  echo "Target: Chrome"
  echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Branch: $(git -C "$ROOT_DIR" branch --show-current)"
  echo "Commit: $(git -C "$ROOT_DIR" rev-parse --short HEAD)"
} > "$RUN_DIR/metadata.txt"

CHROMEDRIVER_BIN="${QA_CHROMEDRIVER_BINARY:-$(command -v chromedriver || true)}"
if [[ -z "$CHROMEDRIVER_BIN" ]]; then
  echo "ChromeDriver is required for Flutter Web integration tests." >&2
  exit 1
fi
if lsof -nP -iTCP:"$WEBDRIVER_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "WebDriver port $WEBDRIVER_PORT is already in use." >&2
  exit 1
fi

"$CHROMEDRIVER_BIN" --port="$WEBDRIVER_PORT" \
  > "$RUN_DIR/chromedriver.log" 2>&1 &
WEBDRIVER_PID=$!
for _ in {1..30}; do
  if curl --fail --silent --max-time 2 \
    "http://127.0.0.1:$WEBDRIVER_PORT/status" >/dev/null; then
    break
  fi
  sleep 1
done
if ! curl --fail --silent --max-time 2 \
  "http://127.0.0.1:$WEBDRIVER_PORT/status" >/dev/null; then
  echo "ChromeDriver did not become ready." >&2
  exit 1
fi

set +e
(
  cd "$FLUTTER_DIR"
  python3 "$ROOT_DIR/tools/qa/supervise_flutter_web_drive.py" -- \
    flutter drive \
    -d chrome \
    --driver-port="$WEBDRIVER_PORT" \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/full_real_user_journey_e2e_test.dart \
    --dart-define-from-file="$SECRETS_FILE"
) 2>&1 | PYTHONUNBUFFERED=1 \
  python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" | tee "$TEST_LOG"
TEST_STATUS=${PIPESTATUS[0]}
set -e

{
  echo "E2E_RESULT CORS=PASS"
  grep -E 'E2E_(ARTIFACT|RESULT|MANUAL_GATE|BLOCKED)' "$TEST_LOG" || true
} | python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" > "$MANIFEST"

CONSOLE_PATTERN='EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK|Uncaught (Error|Exception)|A RenderFlex overflowed|XMLHttpRequest error|ClientException: Failed to fetch'
if grep -Ei "$CONSOLE_PATTERN" "$TEST_LOG" > "$RUN_DIR/console-errors.log"; then
  echo "E2E_RESULT CONSOLE_ERRORS=FAIL" >> "$MANIFEST"
  if [[ "$TEST_STATUS" -eq 0 ]]; then
    TEST_STATUS=1
  fi
else
  : > "$RUN_DIR/console-errors.log"
  echo "E2E_RESULT CONSOLE_ERRORS=PASS" >> "$MANIFEST"
fi

if [[ "$TEST_STATUS" -eq 0 ]]; then
  BUILD_DEFINES="$RUN_DIR/web-build-defines.json"
  python3 - "$SECRETS_FILE" "$BUILD_DEFINES" <<'PY'
import json
import sys

source_path, output_path = sys.argv[1:]
source = json.loads(open(source_path, encoding="utf-8").read())
allowed = {
    key: source[key]
    for key in ("API_BASE_URL", "SUPABASE_URL", "SUPABASE_ANON_KEY")
    if source.get(key)
}
open(output_path, "w", encoding="utf-8").write(json.dumps(allowed))
PY

  set +e
  (
    cd "$FLUTTER_DIR"
    # Local QA endpoints are intentionally rejected by release mode. Profile
    # keeps production-like compilation while allowing the disposable stack.
    flutter build web --profile --dart-define-from-file="$BUILD_DEFINES"
  ) 2>&1 | PYTHONUNBUFFERED=1 \
    python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" | tee "$RUN_DIR/web-build.log"
  BUILD_STATUS=${PIPESTATUS[0]}
  set -e

  if [[ "$BUILD_STATUS" -ne 0 ]]; then
    TEST_STATUS="$BUILD_STATUS"
    echo "E2E_RESULT WEB_BUILD=FAIL" >> "$MANIFEST"
  else
    echo "E2E_RESULT WEB_BUILD=PASS" >> "$MANIFEST"
  fi
fi

if [[ "$TEST_STATUS" -eq 0 ]]; then
  if lsof -nP -iTCP:"$WEB_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Web QA port $WEB_PORT is already in use." >&2
    TEST_STATUS=1
  else
    python3 "$ROOT_DIR/tools/qa/serve_static.py" \
      --port "$WEB_PORT" \
      --bind 127.0.0.1 \
      --directory "$FLUTTER_DIR/build/web" \
      > "$RUN_DIR/web-server.log" 2>&1 &
    WEB_SERVER_PID=$!

    for _ in {1..30}; do
      if curl --fail --silent --max-time 2 "$WEB_BASE_URL" >/dev/null; then
        break
      fi
      sleep 1
    done
    if ! curl --fail --silent --max-time 2 "$WEB_BASE_URL" >/dev/null; then
      echo "Flutter Web build server did not become ready." >&2
      TEST_STATUS=1
    fi
  fi
fi

if [[ "$TEST_STATUS" -eq 0 ]]; then
  NODE_BIN="${QA_NODE_BINARY:-$(command -v node || true)}"
  if [[ -z "$NODE_BIN" ]]; then
    echo "Node.js is required for hard reload and browser lifecycle gates." >&2
    TEST_STATUS=1
  elif ! "$NODE_BIN" -e "require.resolve('playwright')" >/dev/null 2>&1; then
    echo "Playwright is required for hard reload and browser lifecycle gates." >&2
    TEST_STATUS=1
  else
    set +e
    "$NODE_BIN" "$ROOT_DIR/tools/qa/web_browser_lifecycle_probe.cjs" \
      "$SECRETS_FILE" \
      "$WEB_BASE_URL" \
      "$RUN_DIR/browser" \
      2>&1 | PYTHONUNBUFFERED=1 \
      python3 "$ROOT_DIR/tools/qa/redact_qa_output.py" | tee "$RUN_DIR/browser-probe.log"
    PROBE_STATUS=${PIPESTATUS[0]}
    set -e
    grep -E 'E2E_(RESULT|MANUAL_GATE|BLOCKED)' "$RUN_DIR/browser-probe.log" \
      >> "$MANIFEST" || true
    if [[ "$PROBE_STATUS" -ne 0 ]]; then
      TEST_STATUS="$PROBE_STATUS"
      echo "E2E_RESULT BROWSER_LIFECYCLE=FAIL" >> "$MANIFEST"
    fi
  fi
fi

if [[ "$TEST_STATUS" -eq 0 ]]; then
  set +e
  python3 - "$SECRETS_FILE" "$ROOT_DIR/backend/.env" "$FLUTTER_DIR/build/web" <<'PY'
import json
import os
import sys
from pathlib import Path

qa_path, backend_env_path, build_path = sys.argv[1:]
values = {}

qa = json.loads(Path(qa_path).read_text(encoding="utf-8"))
for key, value in qa.items():
    if key.startswith("QA_") and isinstance(value, str) and value:
        values[key] = value.encode()

env_path = Path(backend_env_path)
if env_path.exists():
    privileged = {
        "ADMIN_API_KEY",
        "OPENAI_API_KEY",
        "STRIPE_SECRET_KEY",
        "STRIPE_WEBHOOK_SECRET",
        "SUPABASE_SERVICE_ROLE_KEY",
    }
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" not in line or line.lstrip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        if key.strip() in privileged and value.strip():
            values[key.strip()] = value.strip().encode()

found = set()
for file_path in Path(build_path).rglob("*"):
    if not file_path.is_file():
        continue
    content = file_path.read_bytes()
    for key, value in values.items():
        if len(value) >= 8 and value in content:
            found.add(key)

if found:
    print("Privileged values found in Web build for keys: " + ", ".join(sorted(found)))
    raise SystemExit(1)

print("Web build privileged-value scan: PASS")
PY
  SECRETS_STATUS=$?
  set -e
  if [[ "$SECRETS_STATUS" -ne 0 ]]; then
    TEST_STATUS="$SECRETS_STATUS"
    echo "E2E_RESULT SECRETS_REVIEW=FAIL" >> "$MANIFEST"
  else
    echo "E2E_RESULT SECRETS_REVIEW=PASS" >> "$MANIFEST"
  fi
fi

echo "Flutter Web integration tests: COMPLETE"
echo "Web E2E runner: COMPLETE"
echo "Run directory: $RUN_DIR"
echo "Test exit code: $TEST_STATUS"
exit "$TEST_STATUS"
