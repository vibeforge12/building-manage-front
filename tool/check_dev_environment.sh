#!/usr/bin/env bash
set -Eeuo pipefail

FRONT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACK_DIR="$(cd "$FRONT_DIR/../Building-Manager-BackEnd" && pwd)"

bash -n "$FRONT_DIR/tool/dev_android.sh" "$FRONT_DIR/tool/dev_stop.sh"
bash -n "$FRONT_DIR/tool/test_complaint_postgres.sh"
bash -n "$FRONT_DIR/tool/dev_ios.sh" "$FRONT_DIR/tool/ios_firebase_config.sh"
grep -q 'com.j2partners.buildingManageFront.dev' "$FRONT_DIR/tool/dev_ios.sh"
grep -q 'building-management-dev-7ce57' "$FRONT_DIR/tool/ios_firebase_config.sh"

grep -q '"ENVIRONMENT": "dev"' "$FRONT_DIR/config/dev.json"
grep -q '"API_BASE_URL": "http://127.0.0.1:3002"' "$FRONT_DIR/config/dev.json"
grep -q "current_database() <> 'building-manager-dev'" "$BACK_DIR/tools/dev/seed.sql"
grep -q "const DEV_DATABASE_NAME = 'building-manager-dev'" \
  "$BACK_DIR/libs/entity/src/getPgRealTypeOrmModule.ts"
grep -q 'FCM_ENABLED=true' "$BACK_DIR/apps/api/src/configs/.env.dev"
grep -q 'if (AppConfig.fcmEnabled)' "$FRONT_DIR/lib/main.dart"
grep -q 'if (!AppConfig.fcmEnabled) return;' \
  "$FRONT_DIR/lib/modules/common/services/notification_service.dart"
grep -q 'building-management-dev-7ce57' "$FRONT_DIR/config/firebase/dev/google-services.json"

if grep -q 'play-service-account\|\.env\.staging' "$FRONT_DIR/tool/dev_android.sh"; then
  printf 'dev 실행 스크립트가 staging/배포 인증 정보를 참조합니다.\n' >&2
  exit 1
fi

printf 'dev 환경 정적 검사가 통과했습니다.\n'
