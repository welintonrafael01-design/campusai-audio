#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN_DIR="${1:-$ROOT_DIR/QA/runs/$(date +%Y%m%d_%H%M%S)}"

mkdir -p "$RUN_DIR"

if ! command -v adb >/dev/null 2>&1; then
  echo "adb no está disponible. Instala Android platform-tools." >&2
  exit 1
fi

echo "Capturando logcat en $RUN_DIR/android.log"
adb logcat -v time > "$RUN_DIR/android.log"
