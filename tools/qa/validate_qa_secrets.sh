#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SECRETS_FILE="${1:-$ROOT_DIR/QA/secrets/qa_android.local.json}"

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "QA secrets file is missing: $SECRETS_FILE" >&2
  exit 1
fi

python3 - "$SECRETS_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
required = {
    "API_BASE_URL",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "QA_STUDENT_A_EMAIL",
    "QA_STUDENT_A_PASSWORD",
    "QA_STUDENT_B_EMAIL",
    "QA_STUDENT_B_PASSWORD",
    "QA_TEACHER_EMAIL",
    "QA_TEACHER_PASSWORD",
}
expected_emails = {
    "QA_STUDENT_A_EMAIL": "welintonrafael01+qa.student.a@gmail.com",
    "QA_STUDENT_B_EMAIL": "welintonrafael01+qa.student.b@gmail.com",
    "QA_TEACHER_EMAIL": "welintonrafael01+qa.teacher@gmail.com",
}

try:
    with open(path, encoding="utf-8") as source:
        values = json.load(source)
except (OSError, json.JSONDecodeError):
    print("QA secrets file is not valid JSON.", file=sys.stderr)
    raise SystemExit(1)

missing = sorted(required - values.keys())
if missing:
    print("QA secrets file is missing required configuration keys.", file=sys.stderr)
    raise SystemExit(1)

invalid = [
    key for key in required
    if not isinstance(values[key], str)
    or not values[key].strip()
    or values[key].strip().startswith("<")
]
if invalid:
    print("QA secrets file contains empty or placeholder configuration values.", file=sys.stderr)
    raise SystemExit(1)

if any(values[key].strip() != email for key, email in expected_emails.items()):
    print("QA secrets file contains unexpected QA account identifiers.", file=sys.stderr)
    raise SystemExit(1)

print("QA secrets validation: PASS")
PY
