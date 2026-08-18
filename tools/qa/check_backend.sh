#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:8000}"
HEALTH_URL="${BASE_URL%/}/health"

if curl --fail --silent --show-error --max-time 5 "$HEALTH_URL" >/dev/null; then
  echo "Backend health check: READY"
  exit 0
fi

echo "Backend health check: NOT READY ($HEALTH_URL)" >&2
echo "Start the local backend separately, then retry this command." >&2
exit 1
