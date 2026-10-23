#!/usr/bin/env bash
set -Eeuo pipefail

FRONT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACK_DIR="$(cd "$FRONT_DIR/../Building-Manager-BackEnd" && pwd)"
PID_FILE="$BACK_DIR/.dev/backend.pid"

if [[ ! -f "$PID_FILE" ]]; then
  printf 'dev 백엔드는 실행 중이 아닙니다.\n'
  exit 0
fi

BACKEND_PID="$(<"$PID_FILE")"
if kill -0 "$BACKEND_PID" 2>/dev/null; then
  kill "$BACKEND_PID"
fi
rm -f "$PID_FILE"
printf 'dev 백엔드를 종료했습니다.\n'
