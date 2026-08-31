#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$ROOT_DIR/mobile/campusai_mobile"
CONFIG_FILE="${1:-}"
ARTIFACT_FILE="${2:-}"

if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
  echo "Usage: $0 <release-config.json> [apk-or-aab]" >&2
  exit 2
fi

python3 - "$CONFIG_FILE" <<'PY'
import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
required = {
    "API_BASE_URL",
    "APP_WEB_URL",
    "ACCOUNT_DELETION_URL",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "STUDENT_PRO_PLAY_PRODUCT_ID",
    "TEACHER_PRO_PLAY_PRODUCT_ID",
}
missing = sorted(key for key in required if not str(data.get(key, "")).strip())
privacy_url = str(
    data.get("PRIVACY_URL") or data.get("PRIVACY_POLICY_URL") or ""
).strip()
if not privacy_url:
    missing.append("PRIVACY_URL")
if missing:
    raise SystemExit(f"Missing release values: {', '.join(missing)}")

public_urls = {
    key: str(data[key]).strip()
    for key in (
    "API_BASE_URL",
    "APP_WEB_URL",
    "ACCOUNT_DELETION_URL",
    "SUPABASE_URL",
    )
}
public_urls["PRIVACY_URL"] = privacy_url

for key, value in public_urls.items():
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.hostname:
        raise SystemExit(f"{key} must be a production HTTPS URL")
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise SystemExit(f"{key} contains unsupported URL components")
    if parsed.hostname in {"localhost", "127.0.0.1", "10.0.2.2", "::1"}:
        raise SystemExit(f"{key} cannot use a loopback host")
    if parsed.hostname.endswith(".invalid"):
        raise SystemExit(f"{key} cannot use a reserved .invalid host")

for key in ("API_BASE_URL", "APP_WEB_URL", "SUPABASE_URL"):
    if urlparse(str(data[key])).path not in {"", "/"}:
        raise SystemExit(f"{key} must contain only the public origin")

serialized = json.dumps(data, sort_keys=True)
for pattern in (
    r"com\.example",
    r"qa\.(?:student|teacher)",
    r"service_role",
    r"sk-[A-Za-z0-9_-]{12,}",
    r"password",
):
    if re.search(pattern, serialized, re.IGNORECASE):
        raise SystemExit(f"Forbidden release configuration pattern: {pattern}")

if any(str(value).startswith("REQUIRED_") for value in data.values()):
    raise SystemExit("Release configuration still contains placeholders")
PY

if rg -n "com\.example\." \
  "$APP_DIR/android/app/build.gradle.kts" \
  "$APP_DIR/android/app/src/main" >/dev/null; then
  echo "Provisional Android identity found" >&2
  exit 1
fi

if [[ -n "$ARTIFACT_FILE" ]]; then
  if [[ ! -f "$ARTIFACT_FILE" ]]; then
    echo "Artifact not found: $ARTIFACT_FILE" >&2
    exit 2
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  unzip -oq "$ARTIFACT_FILE" -d "$TMP_DIR"

  find "$TMP_DIR" -type f -size -32M -print0 \
    | xargs -0 strings 2>/dev/null \
    | rg -n "qa\.(student|teacher)|service_role|sk-[A-Za-z0-9_-]{12,}" \
    && {
      echo "Sensitive release artifact pattern found" >&2
      exit 1
    }
fi

echo "Android release configuration check: PASS"
