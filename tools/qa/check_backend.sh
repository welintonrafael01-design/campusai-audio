#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:8000}"
HEALTH_URL="${BASE_URL%/}/health"

RESPONSE="$(curl --fail --silent --show-error --max-time 5 "$HEALTH_URL" || true)"

if [[ -n "$RESPONSE" ]]; then
  ACTUAL_BUILD_SHA="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("build_sha", "unknown"))' <<<"$RESPONSE")"
  EXPECTED_BUILD_SHA="${EXPECTED_BUILD_SHA:-}"

  if [[ -n "$EXPECTED_BUILD_SHA" && "$ACTUAL_BUILD_SHA" != "$EXPECTED_BUILD_SHA" ]]; then
    echo "Backend health check: STALE" >&2
    echo "Expected build: $EXPECTED_BUILD_SHA" >&2
    echo "Running build:  $ACTUAL_BUILD_SHA" >&2
    exit 1
  fi

  echo "Backend health check: READY (build=$ACTUAL_BUILD_SHA)"
  exit 0
fi

echo "Backend health check: NOT READY ($HEALTH_URL)" >&2
echo "Start the local backend separately, then retry this command." >&2
exit 1
