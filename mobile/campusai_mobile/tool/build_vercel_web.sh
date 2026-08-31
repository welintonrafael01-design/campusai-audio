#!/usr/bin/env bash
set -euo pipefail

export PRIVACY_URL="${PRIVACY_URL:-${PRIVACY_POLICY_URL:-}}"

python3 <<'PY'
import os
import re
from urllib.parse import urlparse

required_exact_urls = {
    "API_BASE_URL": "https://api.studybookai.com",
    "APP_WEB_URL": "https://studybookai.com",
    "PRIVACY_URL": "https://studybookai.com/privacy",
    "ACCOUNT_DELETION_URL": "https://studybookai.com/account-deletion",
}

for name, expected in required_exact_urls.items():
    if os.getenv(name, "").strip() != expected:
        raise SystemExit(
            f"{name} debe configurarse con el URL productivo aprobado."
        )

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
