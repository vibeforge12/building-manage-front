#!/usr/bin/env bash
set -Eeuo pipefail

FRONT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACK_DIR="$(cd "$FRONT_DIR/../Building-Manager-BackEnd" && pwd)"
DEV_DB="building-manager-dev"
DEV_PORT="${DEV_API_PORT:-3002}"
STATE_DIR="$BACK_DIR/.dev"
PID_FILE="$STATE_DIR/backend.pid"
LOG_FILE="$STATE_DIR/backend.log"
APK_FILE="$FRONT_DIR/build/dev-apk/building-manager-dev-1.0.13+34.apk"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for command_name in psql adb curl lsof; do
  command -v "$command_name" >/dev/null 2>&1 || fail "$command_name 명령을 찾을 수 없습니다."
done

FLUTTER_BIN="$FRONT_DIR/.fvm/flutter_sdk/bin/flutter"
[[ -x "$FLUTTER_BIN" ]] || fail "프로젝트 Flutter SDK를 찾을 수 없습니다: $FLUTTER_BIN"

NODE_BIN="${NODE_BIN_OVERRIDE:-}"
if [[ -z "$NODE_BIN" ]]; then
  NODE_BIN="$(find "$HOME/.nvm/versions/node" -path '*/bin/node' -type f 2>/dev/null | sort -V | tail -1)"
fi
[[ -n "${NODE_BIN:-}" && -x "$NODE_BIN" ]] || fail "실행 가능한 Node.js를 찾을 수 없습니다."
NODE_DIR="$(dirname "$NODE_BIN")"
"$NODE_BIN" "$BACK_DIR/scripts/check-node-version.cjs" || fail "보안 패치된 Node.js 22가 필요합니다."
[[ -r "$BACK_DIR/.dev/secrets/firebase-admin.json" ]] || fail "Dev Firebase Admin 키가 필요합니다."

DEVICE_ID="${ANDROID_DEVICE_ID:-$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')}"
[[ -n "$DEVICE_ID" ]] || fail "연결되고 승인된 Android 기기가 없습니다."

psql -h 127.0.0.1 -d postgres -Atc \
  "select 1 from pg_database where datname='$DEV_DB'" | grep -qx 1 \
  || fail "dev DB가 없습니다: $DEV_DB"

mkdir -p "$STATE_DIR/backups"
bash "$BACK_DIR/tools/backup-db.sh" "$DEV_DB" "$STATE_DIR/backups"
psql -h 127.0.0.1 -d "$DEV_DB" -v ON_ERROR_STOP=1 \
  -f "$BACK_DIR/scripts/1.0.14-01-life-services.sql" >/dev/null
psql -h 127.0.0.1 -d "$DEV_DB" -v ON_ERROR_STOP=1 \
  -f "$BACK_DIR/scripts/1.0.14-02-life-service-images.sql" >/dev/null
psql -h 127.0.0.1 -d "$DEV_DB" -v ON_ERROR_STOP=1 \
  -f "$BACK_DIR/scripts/1.0.15-01-complaint-actions.sql" >/dev/null
psql -h 127.0.0.1 -d "$DEV_DB" -v ON_ERROR_STOP=1 \
  -f "$BACK_DIR/tools/dev/seed.sql" >/dev/null

env PATH="$NODE_DIR:$PATH" npm --prefix "$BACK_DIR" run build >/dev/null

if [[ -f "$PID_FILE" ]] && kill -0 "$(<"$PID_FILE")" 2>/dev/null; then
  BACKEND_PID="$(<"$PID_FILE")"
elif lsof -nP -iTCP:"$DEV_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  fail "포트 $DEV_PORT 을 다른 프로세스가 사용 중입니다."
else
  (
    cd "$BACK_DIR"
    nohup env \
      PATH="$NODE_DIR:$PATH" \
      NODE_ENV=dev \
      PORT="$DEV_PORT" \
      FCM_ENABLED=true \
      FIREBASE_SERVICE_ACCOUNT_FILE="$BACK_DIR/.dev/secrets/firebase-admin.json" \
      "$NODE_BIN" dist/apps/api/main.js >"$LOG_FILE" 2>&1 < /dev/null &
    echo $! >"$PID_FILE"
  )
  BACKEND_PID="$(<"$PID_FILE")"
fi

for _ in {1..30}; do
  if curl -fsS "http://127.0.0.1:$DEV_PORT/" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -fsS "http://127.0.0.1:$DEV_PORT/" >/dev/null \
  || fail "dev API가 준비되지 않았습니다. 로그: $LOG_FILE"

adb -s "$DEVICE_ID" reverse "tcp:$DEV_PORT" "tcp:$DEV_PORT"

mkdir -p "$FRONT_DIR/build/dev-apk"
(
  cd "$FRONT_DIR"
  env \
    ORG_GRADLE_PROJECT_appIdOverride=com.example.building_manage_front \
    ORG_GRADLE_PROJECT_appLabelOverride='엄지 Dev' \
    ORG_GRADLE_PROJECT_cleartextOverride=true \
    "$FLUTTER_BIN" build apk --release --target-platform android-arm64 \
      --dart-define-from-file=config/dev.json \
      --dart-define="DEV_BUILD_REVISION=dev-$(date -u '+%Y%m%dT%H%M%SZ')" \
      --dart-define="API_BASE_URL=http://127.0.0.1:$DEV_PORT"
  cp build/app/outputs/flutter-apk/app-release.apk "$APK_FILE"
)

if ! adb -s "$DEVICE_ID" install -r "$APK_FILE"; then
  fail "설치 실패. 기존 앱과 데이터를 보존했습니다. 서명 및 기기 상태를 확인하세요."
fi
adb -s "$DEVICE_ID" shell pm grant \
  com.example.building_manage_front android.permission.POST_NOTIFICATIONS
adb -s "$DEVICE_ID" shell am force-stop com.example.building_manage_front
adb -s "$DEVICE_ID" shell monkey -p com.example.building_manage_front \
  -c android.intent.category.LAUNCHER 1 >/dev/null

printf 'PASS: dev 환경 준비 완료\n'
printf '  device: %s\n' "$DEVICE_ID"
printf '  api: http://127.0.0.1:%s/api/v1\n' "$DEV_PORT"
printf '  database: %s\n' "$DEV_DB"
printf '  FCM: building-management-dev-7ce57\n'
printf '  backend pid: %s\n' "$BACKEND_PID"
printf '  app: 엄지 Dev (com.example.building_manage_front)\n'
printf '  apk: %s\n' "$APK_FILE"
