#!/usr/bin/env bash
set -euo pipefail

export PRIVACY_URL="${PRIVACY_URL:-${PRIVACY_POLICY_URL:-}}"

python3 <<'PY'
import os
import re
from urllib.parse import urlparse

def public_https_url(name, *, origin_only=False):
    value = os.getenv(name, "").strip().rstrip("/")
    parsed = urlparse(value)
    host = (parsed.hostname or "").lower()
    if (
        parsed.scheme != "https"
        or not host
        or parsed.username
        or parsed.password
        or host in {"localhost", "127.0.0.1", "10.0.2.2", "::1"}
        or host.endswith(".invalid")
        or parsed.query
        or parsed.fragment
        or (origin_only and parsed.path not in {"", "/"})
    ):
        raise SystemExit(f"{name} debe ser una URL HTTPS publica no local.")
    return value


api_base_url = public_https_url("API_BASE_URL", origin_only=True)
app_web_url = public_https_url("APP_WEB_URL", origin_only=True)
privacy_url = public_https_url("PRIVACY_URL")
account_deletion_url = public_https_url("ACCOUNT_DELETION_URL")

if privacy_url != f"{app_web_url}/privacy":
    raise SystemExit("PRIVACY_URL debe pertenecer al sitio Web configurado.")
if account_deletion_url != f"{app_web_url}/account-deletion":
    raise SystemExit(
        "ACCOUNT_DELETION_URL debe pertenecer al sitio Web configurado."
    )

canonical_required = os.getenv(
    "REQUIRE_CANONICAL_PRODUCTION_URLS", "false"
).strip().lower() in {"1", "true", "yes", "on"}
if canonical_required:
    expected = {
        "API_BASE_URL": "https://api.studybookai.com",
        "APP_WEB_URL": "https://studybookai.com",
        "PRIVACY_URL": "https://studybookai.com/privacy",
        "ACCOUNT_DELETION_URL": "https://studybookai.com/account-deletion",
    }
    actual = {
        "API_BASE_URL": api_base_url,
        "APP_WEB_URL": app_web_url,
        "PRIVACY_URL": privacy_url,
        "ACCOUNT_DELETION_URL": account_deletion_url,
    }
    if actual != expected:
        raise SystemExit("Las URLs canonicas de produccion no coinciden.")

supabase_url = os.getenv("SUPABASE_URL", "").strip()
supabase_anon_key = os.getenv("SUPABASE_ANON_KEY", "").strip()
parsed = urlparse(supabase_url)

if (
    parsed.scheme != "https"
    or not parsed.hostname
    or parsed.path not in {"", "/"}
    or parsed.username
    or parsed.password
    or parsed.query
    or parsed.fragment
):
    raise SystemExit("SUPABASE_URL debe ser un origen HTTPS sin credenciales.")

if not supabase_anon_key or re.search(
    r"service[_-]?role", supabase_anon_key, re.IGNORECASE
):
    raise SystemExit(
        "SUPABASE_ANON_KEY publica es obligatoria; service role esta prohibida."
    )

print("Vercel public production configuration: PASS")
PY

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/.cache/studybook-flutter}"
  if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
    rm -rf "$FLUTTER_ROOT"
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
  fi
  export PATH="$FLUTTER_ROOT/bin:$PATH"
fi

flutter config --no-analytics
flutter pub get
flutter build web --release \
  --dart-define="API_BASE_URL=$API_BASE_URL" \
  --dart-define="APP_WEB_URL=$APP_WEB_URL" \
  --dart-define="PRIVACY_URL=$PRIVACY_URL" \
  --dart-define="PRIVACY_POLICY_URL=$PRIVACY_URL" \
  --dart-define="ACCOUNT_DELETION_URL=$ACCOUNT_DELETION_URL" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
