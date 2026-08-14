#!/usr/bin/env bash
set -euo pipefail

if ! command -v adb >/dev/null 2>&1; then
  echo "adb no está disponible. Instala Android platform-tools." >&2
  exit 1
fi

adb logcat -c
echo "Android logcat limpiado."
