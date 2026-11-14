#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="${QUALITY_BACKEND_DIR:-$(cd "$FRONT_DIR/../Building-Manager-BackEnd" 2>/dev/null && pwd || true)}"
THRESHOLDS_FILE="$SCRIPT_DIR/quality_thresholds.env"

if [[ -f "$THRESHOLDS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$THRESHOLDS_FILE"
else
  echo "품질 기준 파일을 찾을 수 없습니다: $THRESHOLDS_FILE" >&2
  exit 2
fi

RUN_ID="$(date '+%Y%m%d-%H%M%S')"
REPORT_ROOT="${QUALITY_REPORT_DIR:-$FRONT_DIR/build/quality-gate}"
REPORT_DIR="$REPORT_ROOT/$RUN_ID"
REPORT_FILE="$REPORT_DIR/report.md"
ANDROID_PACKAGE="${QUALITY_ANDROID_PACKAGE:-com.example.building_manage_front}"
ANDROID_COMPONENT="$ANDROID_PACKAGE/com.j2partners.buildingManageFront.MainActivity"
mkdir -p "$REPORT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
WARN_COUNT=0
RESULT_ROWS=""

print_header() {
  printf '\n[%s] %s\n' "$1" "$2"
}

add_result() {
  local status="$1"
  local name="$2"
  local detail="$3"
  RESULT_ROWS+="| $status | $name | $detail |"$'\n'
  case "$status" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    SKIP) SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
  esac
}

run_step() {
  local name="$1"
  local slug="$2"
  local directory="$3"
  shift 3
  local log_file="$REPORT_DIR/$slug.log"

  print_header RUN "$name"
  local exit_code
  if (cd "$directory" && "$@") >"$log_file" 2>&1; then
    echo "PASS"
    add_result PASS "$name" "[$slug.log](./$slug.log)"
    return 0
  else
    exit_code=$?
  fi

  echo "FAIL (exit $exit_code) — $log_file"
  tail -n 20 "$log_file" || true
  add_result FAIL "$name" "exit $exit_code · [$slug.log](./$slug.log)"
  return 0
}

skip_step() {
  local name="$1"
  local reason="$2"
  print_header SKIP "$name — $reason"
  add_result SKIP "$name" "$reason"
}

warn_step() {
  local name="$1"
  local reason="$2"
  print_header WARN "$name — $reason"
  add_result WARN "$name" "$reason"
}

find_flutter() {
  if [[ -x "$FRONT_DIR/.fvm/flutter_sdk/bin/flutter" ]]; then
    printf '%s\n' "$FRONT_DIR/.fvm/flutter_sdk/bin/flutter"
  elif command -v fvm >/dev/null 2>&1; then
    printf '%s\n' "fvm flutter"
  elif command -v flutter >/dev/null 2>&1; then
    command -v flutter
  else
    return 1
  fi
}

find_node_bin_dir() {
  local candidate
  if [[ -n "${QUALITY_NODE_BIN_DIR:-}" ]]; then
    printf '%s\n' "$QUALITY_NODE_BIN_DIR"
    return 0
  fi
  for candidate in \
    "${QUALITY_NODE_BIN_DIR:-}" \
    "$HOME"/.nvm/versions/node/*/bin \
    "$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin" \
    "$(dirname "$(command -v node 2>/dev/null || printf '/missing/node')")"; do
    if [[ -n "$candidate" && -x "$candidate/node" ]] && "$candidate/node" "$BACKEND_DIR/scripts/check-node-version.cjs" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

percentile_from_file() {
  local file="$1"
  local percentile="$2"
  awk -F',' -v p="$percentile" '
    NR > 1 && $2 ~ /^[0-9]+$/ { values[++count] = $2 }
    END {
      if (count == 0) exit 1
      for (i = 1; i <= count; i++) {
        for (j = i + 1; j <= count; j++) {
          if (values[i] > values[j]) {
            tmp = values[i]; values[i] = values[j]; values[j] = tmp
          }
        }
      }
      rank = int((p * count + 99) / 100)
      if (rank < 1) rank = 1
      if (rank > count) rank = count
      print values[rank]
    }
  ' "$file"
}

measure_android_startup() {
  local device_id="$1"
  local csv_file="$REPORT_DIR/android-startup.csv"
  local raw_file="$REPORT_DIR/android-startup-raw.log"
  local component="$ANDROID_COMPONENT"
  local samples="${QUALITY_STARTUP_SAMPLES:-5}"

  printf 'sample,total_time_ms\n' >"$csv_file"
  : >"$raw_file"

  for ((sample = 1; sample <= samples; sample++)); do
    adb -s "$device_id" shell am force-stop "$ANDROID_PACKAGE"
    local output
    output="$(adb -s "$device_id" shell am start -W -n "$component" 2>&1)"
    printf '\n[sample %d]\n%s\n' "$sample" "$output" >>"$raw_file"
    local total_time
    total_time="$(printf '%s\n' "$output" | awk -F': ' '/^(TotalTime|WaitTime):/ {gsub(/\r/, "", $2); print $2; exit}')"
    if [[ ! "$total_time" =~ ^[0-9]+$ ]]; then
      warn_step "Android 콜드 스타트" "ADB TotalTime을 읽지 못했습니다. 원본 로그를 확인하세요."
      return 0
    fi
    printf '%d,%s\n' "$sample" "$total_time" >>"$csv_file"
  done

  local p50 p95 p50_limit p95_limit target_label
  p50="$(percentile_from_file "$csv_file" 50)"
  p95="$(percentile_from_file "$csv_file" 95)"
  if [[ "$device_id" == emulator-* ]]; then
    p50_limit="$QUALITY_EMULATOR_COLD_START_P50_MS"
    p95_limit="$QUALITY_EMULATOR_COLD_START_P95_MS"
    target_label="AVD 회귀 기준"
  else
    p50_limit="$QUALITY_COLD_START_P50_MS"
    p95_limit="$QUALITY_COLD_START_P95_MS"
    target_label="실기기 기준"
  fi
  local detail="p50 ${p50}ms / p95 ${p95}ms · ${target_label} · [CSV](./android-startup.csv)"

  if (( p50 <= p50_limit && p95 <= p95_limit )); then
    add_result PASS "Android 콜드 스타트" "$detail"
    echo "PASS — $detail"
  else
    add_result FAIL "Android 콜드 스타트" "$detail (기준: p50 ≤ ${p50_limit}ms, p95 ≤ ${p95_limit}ms)"
    FAIL_COUNT=$((FAIL_COUNT + 0))
    echo "FAIL — $detail"
  fi
}

write_report() {
  cat >"$REPORT_FILE" <<EOF
# 통합 품질 게이트 결과

- 실행 시각: $(date '+%Y-%m-%d %H:%M:%S %Z')
- 프론트: $FRONT_DIR
- 백엔드: ${BACKEND_DIR:-찾지 못함}
- 결과: PASS $PASS_COUNT / FAIL $FAIL_COUNT / WARN $WARN_COUNT / SKIP $SKIP_COUNT

| 상태 | 검사 | 상세 |
|---|---|---|
$RESULT_ROWS
## 적용 기준

- 화면 프레임: ${QUALITY_FRAME_BUDGET_MS}ms 이하
- 느린 프레임: ${QUALITY_MAX_SLOW_FRAME_PERCENT}% 이하
- Android AVD 느린 프레임: ${QUALITY_EMULATOR_MAX_SLOW_FRAME_PERCENT}% 이하 (회귀 감시용)
- frozen frame: ${QUALITY_FROZEN_FRAME_MS}ms 이상 0건
- Android 콜드 스타트: p50 ${QUALITY_COLD_START_P50_MS}ms 이하, p95 ${QUALITY_COLD_START_P95_MS}ms 이하
- Android AVD 콜드 스타트: p50 ${QUALITY_EMULATOR_COLD_START_P50_MS}ms 이하, p95 ${QUALITY_EMULATOR_COLD_START_P95_MS}ms 이하 (회귀 감시용)
- API: p95 ${QUALITY_API_P95_MS}ms 이하, 오류율 ${QUALITY_API_ERROR_RATE_PERCENT}% 미만

자세한 근거와 측정 한계는 [품질 게이트 문서](../../../docs/품질게이트.md)를 참고하세요.
EOF

  mkdir -p "$REPORT_ROOT"
  ln -sfn "$REPORT_DIR" "$REPORT_ROOT/latest"
}

echo "Building Manager 통합 품질 게이트"
echo "보고서: $REPORT_FILE"

run_step "Dev 환경 안전 설정" dev-environment "$FRONT_DIR" \
  bash "$FRONT_DIR/tool/check_dev_environment.sh"

run_step "iOS 배포 타깃 정합성" ios-release-config "$FRONT_DIR" \
  python3 "$FRONT_DIR/tool/check_ios_release_config.py"

run_step "Android 자동 보호 최소 SDK" android-release-config "$FRONT_DIR" \
  python3 "$FRONT_DIR/tool/check_android_release_config.py"

FLUTTER_BIN="$(find_flutter || true)"
if [[ -z "$FLUTTER_BIN" ]]; then
  add_result FAIL "Flutter 도구" "Flutter SDK를 찾지 못했습니다."
else
  if [[ "$FLUTTER_BIN" == "fvm flutter" ]]; then
    FLUTTER=(fvm flutter)
  else
    FLUTTER=("$FLUTTER_BIN")
  fi

  if [[ "${QUALITY_SKIP_DEPS:-0}" != "1" ]]; then
    run_step "Flutter 의존성 확인" flutter-pub-get "$FRONT_DIR" "${FLUTTER[@]}" pub get
  else
    skip_step "Flutter 의존성 확인" "QUALITY_SKIP_DEPS=1"
  fi
  run_step "Flutter 정적 분석" flutter-analyze "$FRONT_DIR" "${FLUTTER[@]}" analyze
  run_step "홈 신청 가능 필터·전체 목록 재진입 회귀" resident-life-service-home "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/resident_life_service_section_test.dart
  run_step "Flutter 전체 테스트" flutter-test "$FRONT_DIR" "${FLUTTER[@]}" test
  run_step "알림 스택·신청 화면 새로고침 회귀" notification-refresh "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/notification_navigation_test.dart test/life_service_refresh_test.dart
  run_step "만석 수동 마감 회귀" life-service-close "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/life_service_close_test.dart
  run_step "서비스 사진·기존 디자인 회귀" life-service-images "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/life_service_images_test.dart
  run_step "총관리자 민원 처리·답변 수정 회귀" complaint-actions "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/complaint_actions_test.dart
  run_step "로그아웃 전 기기 푸시 해제·실패 재시도 회귀" logout-push "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/logout_usecase_test.dart
  run_step "강제 업데이트·오프라인·스토어 이동 회귀" app-update "$FRONT_DIR" \
    "${FLUTTER[@]}" test test/app_update_test.dart
  run_step "Android 릴리스 APK·크기 분석" android-release-build "$FRONT_DIR" \
    env ORG_GRADLE_PROJECT_appIdOverride="$ANDROID_PACKAGE" \
    ORG_GRADLE_PROJECT_appLabelOverride='엄지 Dev' \
    ORG_GRADLE_PROJECT_cleartextOverride=true \
    "${FLUTTER[@]}" build apk --release --target-platform android-arm64 --analyze-size \
    --dart-define-from-file=config/dev.json \
    --dart-define="DEV_BUILD_REVISION=quality-$RUN_ID" \
    --code-size-directory="$REPORT_DIR/code-size"
fi

run_step "프론트 변경 공백 검사" front-diff-check "$FRONT_DIR" git diff --check

if [[ -z "$BACKEND_DIR" || ! -f "$BACKEND_DIR/package.json" ]]; then
  skip_step "백엔드 전체 검사" "백엔드 저장소를 찾지 못했습니다. QUALITY_BACKEND_DIR로 지정할 수 있습니다."
else
  NODE_BIN_DIR="$(find_node_bin_dir || true)"
  if [[ -z "$NODE_BIN_DIR" ]] || ! env PATH="$NODE_BIN_DIR:$PATH" npm --version >/dev/null 2>&1; then
    add_result FAIL "Node/npm 도구" "실행 가능한 Node/npm 조합을 찾지 못했습니다. QUALITY_NODE_BIN_DIR로 지정할 수 있습니다."
  else
    NODE_VERSION="$("$NODE_BIN_DIR/node" --version)"
    run_step "Node.js 22 보안 패치 버전 검사" node-security-version "$BACKEND_DIR" \
      "$NODE_BIN_DIR/node" scripts/check-node-version.cjs
    run_step "Node 버전 경계 회귀 검사" node-version-test "$BACKEND_DIR" \
      "$NODE_BIN_DIR/node" --test scripts/check-node-version.test.cjs
    add_result PASS "Node 런타임" "$NODE_VERSION · $NODE_BIN_DIR"
    NPM=(env PATH="$NODE_BIN_DIR:$PATH" npm)
    if [[ "${QUALITY_INSTALL_DEPS:-0}" == "1" ]]; then
      run_step "백엔드 의존성 재설치" backend-npm-ci "$BACKEND_DIR" "${NPM[@]}" ci
    else
      run_step "백엔드 의존성 무결성" backend-dependencies "$BACKEND_DIR" \
        "${NPM[@]}" ls --depth=0
    fi
    run_step "백엔드 린트" backend-lint "$BACKEND_DIR" "${NPM[@]}" run lint
    run_step "백엔드 서비스 신청 보안 회귀 테스트" backend-security-test "$BACKEND_DIR" \
      "${NPM[@]}" test -- --runInBand \
      apps/api/src/modules/life-services/life-services.dto.spec.ts \
      apps/api/src/modules/life-services/life-services.service.spec.ts \
      apps/api/src/modules/life-services/life-service-images.service.spec.ts
    run_step "백엔드 단위 테스트" backend-test "$BACKEND_DIR" "${NPM[@]}" test -- --runInBand
    run_step "민원·계정·앱 버전·테스트 건물 PostgreSQL 검증" complaint-postgres "$FRONT_DIR" \
      env PATH="$NODE_BIN_DIR:$PATH" QUALITY_BACKEND_DIR="$BACKEND_DIR" \
      bash "$FRONT_DIR/tool/test_complaint_postgres.sh"
    run_step "백엔드 E2E 테스트" backend-e2e "$BACKEND_DIR" "${NPM[@]}" run test:e2e -- --runInBand
    run_step "로컬 API 성능 스모크" backend-api-performance "$BACKEND_DIR" \
      env QUALITY_API_P95_MS="$QUALITY_API_P95_MS" \
      "${NPM[@]}" run test:e2e -- --runInBand --testNamePattern="local API p95"
    run_step "백엔드 프로덕션 빌드" backend-build "$BACKEND_DIR" "${NPM[@]}" run build
  fi
  run_step "백엔드 변경 공백 검사" backend-diff-check "$BACKEND_DIR" git diff --check
fi

STARTED_EMULATOR=0
EMULATOR_DEVICE_ID=""
cleanup_emulator() {
  if [[ "$STARTED_EMULATOR" == "1" && -n "$EMULATOR_DEVICE_ID" ]]; then
    adb -s "$EMULATOR_DEVICE_ID" emu kill >/dev/null 2>&1 || true
  fi
}
trap cleanup_emulator EXIT

install_android_apk() {
  local device_id="$1"
  local apk_path="$2"
  if adb -s "$device_id" install -r "$apk_path"; then
    return 0
  fi
  if [[ "$STARTED_EMULATOR" != "1" ]]; then
    return 1
  fi

  # 자동 생성한 테스트 에뮬레이터의 앱 데이터만 초기화한다.
  # 사용자 실기기에서는 서명 충돌이 나도 임의 삭제하지 않는다.
  adb -s "$device_id" uninstall "$ANDROID_PACKAGE" >/dev/null 2>&1 || true
  adb -s "$device_id" install "$apk_path"
}

if command -v adb >/dev/null 2>&1 && [[ -n "$FLUTTER_BIN" ]]; then
  DEVICE_ID="${QUALITY_ANDROID_DEVICE_ID:-$(adb devices | awk 'NR > 1 && $2 == "device" {print $1; exit}')}"
  if [[ -n "$DEVICE_ID" && "$(adb -s "$DEVICE_ID" get-state 2>/dev/null)" != "device" ]]; then
    add_result FAIL "Android 지정 기기" "$DEVICE_ID 연결을 확인할 수 없습니다."
    DEVICE_ID=""
  fi
  if [[ -z "$DEVICE_ID" && -z "${QUALITY_ANDROID_DEVICE_ID:-}" && "${QUALITY_START_EMULATOR:-1}" == "1" ]]; then
    EMULATOR_BIN="${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator"
    if [[ -x "$EMULATOR_BIN" ]]; then
      AVD_NAME="${QUALITY_ANDROID_AVD:-$($EMULATOR_BIN -list-avds | head -n 1)}"
      if [[ -z "${QUALITY_ANDROID_AVD:-}" ]] && "$EMULATOR_BIN" -list-avds | grep -qx 'BuildingManagerQuality'; then
        AVD_NAME='BuildingManagerQuality'
      fi
      if [[ -n "$AVD_NAME" ]]; then
        print_header RUN "Android 에뮬레이터 자동 시작 — $AVD_NAME"
        "$EMULATOR_BIN" -avd "$AVD_NAME" -no-window -no-audio -no-boot-anim \
          -no-snapshot -gpu host >"$REPORT_DIR/android-emulator.log" 2>&1 &
        STARTED_EMULATOR=1
        for _ in $(seq 1 90); do
          DEVICE_ID="$(adb devices | awk 'NR > 1 && $2 == "device" {print $1; exit}')"
          if [[ -n "$DEVICE_ID" && "$(adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
            EMULATOR_DEVICE_ID="$DEVICE_ID"
            break
          fi
          sleep 2
        done
      fi
    fi
  fi
  if [[ -n "$DEVICE_ID" ]]; then
    APP_PRESENT_BEFORE_GATE=0
    if adb -s "$DEVICE_ID" shell pm path "$ANDROID_PACKAGE" 2>/dev/null | grep -q '^package:'; then
      APP_PRESENT_BEFORE_GATE=1
    fi
    APK_PATH="$FRONT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    if [[ -f "$APK_PATH" ]]; then
      run_step "Android 릴리스 APK 설치" android-install "$FRONT_DIR" \
        install_android_apk "$DEVICE_ID" "$APK_PATH"
      print_header RUN "Android 콜드 스타트 측정"
      measure_android_startup "$DEVICE_ID"
    else
      add_result FAIL "Android 기기 검사" "릴리스 APK가 생성되지 않았습니다."
    fi

    if [[ -f "$FRONT_DIR/integration_test/performance_test.dart" ]]; then
      export QUALITY_REPORT_DIR="$REPORT_DIR"
      FRAME_MAX_SLOW_PERCENT="$QUALITY_MAX_SLOW_FRAME_PERCENT"
      if [[ "$DEVICE_ID" == emulator-* ]]; then
        FRAME_MAX_SLOW_PERCENT="$QUALITY_EMULATOR_MAX_SLOW_FRAME_PERCENT"
      fi
      if [[ "$STARTED_EMULATOR" == "1" || ( "$DEVICE_ID" == emulator-* && "$APP_PRESENT_BEFORE_GATE" == "0" ) ]]; then
        # release와 profile 빌드의 서명이 다를 수 있으므로 자동 테스트 AVD만 초기화한다.
        # 이미 실행 중이던 AVD에서는 이번 검사로 처음 설치한 앱만 초기화할 수 있다.
        adb -s "$DEVICE_ID" uninstall "$ANDROID_PACKAGE" >/dev/null 2>&1 || true
      fi
      FLUTTER_TOOL_PATH="$PATH"
      if [[ "${FLUTTER[0]}" == /* ]]; then
        FLUTTER_TOOL_PATH="$(dirname "${FLUTTER[0]}"):$PATH"
      fi
      run_step "Flutter 화면 프레임 벤치마크" flutter-performance "$FRONT_DIR" \
        env PATH="$FLUTTER_TOOL_PATH" \
        ORG_GRADLE_PROJECT_appIdOverride="$ANDROID_PACKAGE" \
        ORG_GRADLE_PROJECT_appLabelOverride='엄지 Dev' \
        ORG_GRADLE_PROJECT_cleartextOverride=true \
        QUALITY_MAX_SLOW_FRAME_PERCENT="$FRAME_MAX_SLOW_PERCENT" \
        QUALITY_MAX_FROZEN_FRAMES="$QUALITY_MAX_FROZEN_FRAMES" \
        "${FLUTTER[@]}" drive --profile --no-enable-impeller --timeout=120 -d "$DEVICE_ID" \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/performance_test.dart \
        --dart-define-from-file=config/dev.json \
        --dart-define="QUALITY_FRAME_BUDGET_MS=$QUALITY_FRAME_BUDGET_MS" \
        --dart-define="QUALITY_MAX_SLOW_FRAME_PERCENT=$FRAME_MAX_SLOW_PERCENT" \
        --dart-define="QUALITY_FROZEN_FRAME_MS=$QUALITY_FROZEN_FRAME_MS" \
        --dart-define="QUALITY_MAX_FROZEN_FRAMES=$QUALITY_MAX_FROZEN_FRAMES"
    else
      add_result FAIL "Flutter 화면 프레임 벤치마크" "integration_test/performance_test.dart 없음"
    fi
  else
    add_result FAIL "Android 기기 성능 검사" "ADB 기기가 없고 자동 시작 가능한 AVD도 없습니다."
  fi
else
  add_result FAIL "Android 기기 성능 검사" "ADB 또는 Flutter를 찾지 못했습니다."
fi

if [[ -n "${QUALITY_API_URL:-}" ]]; then
  if command -v k6 >/dev/null 2>&1; then
    run_step "API k6 부하 검사" api-load "$FRONT_DIR" env \
      QUALITY_API_URL="$QUALITY_API_URL" \
      QUALITY_API_P95_MS="$QUALITY_API_P95_MS" \
      QUALITY_API_ERROR_RATE_PERCENT="$QUALITY_API_ERROR_RATE_PERCENT" \
      k6 run "$SCRIPT_DIR/k6/api-smoke.js"
  else
    add_result FAIL "API k6 부하 검사" "QUALITY_API_URL은 지정됐지만 k6가 설치되지 않았습니다."
  fi
else
  echo "외부 API k6 검사는 QUALITY_API_URL을 지정한 경우에만 추가 실행합니다."
fi

write_report

printf '\n품질 게이트 완료: PASS %d / FAIL %d / WARN %d / SKIP %d\n' \
  "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT" "$SKIP_COUNT"
echo "보고서: $REPORT_FILE"

if (( FAIL_COUNT > 0 )); then
  exit 1
fi
