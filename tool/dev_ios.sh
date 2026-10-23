#!/usr/bin/env bash
set -Eeuo pipefail
FRONT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$FRONT_DIR"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[[ -n "${IOS_DEVICE_ID:-}" ]] || fail 'IOS_DEVICE_ID에 연결한 iPhone의 UDID를 지정하세요.'
DEV_HOST="${DEV_API_HOST:-$(ipconfig getifaddr en0 || true)}"
case "$DEV_HOST" in
  10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*) ;;
  *) fail 'DEV_API_HOST는 맥의 사설 LAN IPv4 주소여야 합니다.' ;;
esac
DEV_PORT="${DEV_API_PORT:-3002}"
[[ "$DEV_PORT" =~ ^[0-9]+$ ]] || fail '잘못된 API 포트입니다.'
curl --max-time 5 -fsS "http://$DEV_HOST:$DEV_PORT/api/v1/health" >/dev/null \
  || fail '로컬 Dev API를 먼저 실행하세요. iPhone과 맥은 같은 LAN에 있어야 합니다.'
OUTPUT="$FRONT_DIR/build/dev-ios"
mkdir -p "$OUTPUT"
# Generate build-only metadata: the production source plist is preserved.
cp ios/Runner/Info.plist "$OUTPUT/Info.plist"
plutil -replace CFBundleDisplayName -string '엄지 Dev' "$OUTPUT/Info.plist"
plutil -replace CFBundleName -string '엄지 Dev' "$OUTPUT/Info.plist"
plutil -insert NSLocalNetworkUsageDescription -string '개발용 맥의 로컬 테스트 서버에 연결합니다.' "$OUTPUT/Info.plist"
.fvm/flutter_sdk/bin/flutter build ios --release --config-only \
  --dart-define-from-file=config/dev.json \
  --dart-define="DEV_BUILD_REVISION=dev-ios-$(date -u '+%Y%m%dT%H%M%SZ')" \
  --dart-define="API_BASE_URL=http://$DEV_HOST:$DEV_PORT"
xcodebuild -quiet -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination "id=$IOS_DEVICE_ID" -derivedDataPath "$OUTPUT/DerivedData" \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  BM_BUNDLE_ID=com.j2partners.buildingManageFront.dev \
  BM_INFO_PLIST="$OUTPUT/Info.plist" \
  CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' \
  DEVELOPMENT_TEAM=6FPY2KA2DA build
APP="$OUTPUT/DerivedData/Build/Products/Release-iphoneos/Runner.app"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")" == com.j2partners.buildingManageFront.dev ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "$APP/GoogleService-Info.plist")" == building-management-dev-7ce57 ]]
codesign --verify --deep --strict "$APP"
codesign -d --entitlements :- "$APP" >"$OUTPUT/signed-entitlements.plist" 2>/dev/null
[[ "$(/usr/libexec/PlistBuddy -c 'Print :aps-environment' "$OUTPUT/signed-entitlements.plist")" == development ]] \
  || fail 'Sandbox APNs용 개발 서명이 아닙니다. 설치를 중단합니다.'
xcrun devicectl device install app --device "$IOS_DEVICE_ID" "$APP"
printf 'PASS: 엄지 Dev 설치 완료. 앱을 열고 로컬 네트워크 및 알림 권한을 허용하세요.\n'
