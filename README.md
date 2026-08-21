# Building Manage Front

다중 역할 기반 건물 관리 서비스의 Flutter 애플리케이션입니다. 하나의 코드베이스에서
**입주민 / 관리자 / 담당자 / 본사** 4가지 역할을 지원하며, 로그인한 역할에 따라 라우팅과 권한이 분기됩니다.

- 앱 버전: `1.0.12+33` (`pubspec.yaml`)
- Dart SDK: `^3.8.1`
- 문서 최종 갱신: **2026-08-21**

---

## ⚠️ 역할 폴더명 주의 (가장 먼저 읽을 것)

영어 폴더명을 한국어로 **직역하지 마세요.** 백엔드 경로와 명칭이 뒤집혀 있습니다.

| 폴더 | 한국어 역할 | `UserType` | 서버 `role` 값 | 서버 API prefix |
|---|---|---|---|---|
| `lib/modules/resident/` | **입주민** (일반 거주자) | `UserType.user` | `USER` | `/users`, `/auth/resident` |
| `lib/modules/admin/` | **관리자** (건물 관리자, 사무직) | `UserType.admin` | **`MANAGER`** | **`/managers`** |
| `lib/modules/manager/` | **담당자** (유지보수 직원, 출퇴근 있음) | `UserType.manager` | **`STAFF`** | **`/staffs`** |
| `lib/modules/headquarters/` | **본사** | `UserType.headquarters` | `HEADQUARTERS` | `/headquarters` |

> `manager` 는 "매니저" 가 아니라 **담당자**입니다. 정의는 `lib/core/constants/user_types.dart` 를 보세요.

---

## 디렉터리 구조 (실제)

```
lib/                                # Dart 파일 176개 (2026-08-21 실측)
├─ main.dart                        # 진입점: dotenv → Firebase → ApiClient → ProviderScope
├─ app/app.dart                     # MaterialApp.router 구성
│
├─ core/                            # 앱 전역 인프라
│  ├─ config/app_config.dart        # .env 래퍼 (apiBaseUrl = {API_BASE_URL}/api/{API_VERSION})
│  ├─ constants/                    # api_endpoints, auth_states, user_types
│  ├─ network/
│  │  ├─ api_client.dart            # Dio 싱글톤 + _guard() 예외 정규화
│  │  ├─ exceptions/api_exception.dart
│  │  └─ interceptors/              # auth / error / logging
│  ├─ providers/                    # router_provider, app_providers
│  ├─ routing/router_notifier.dart  # GoRouter 정의 + 권한 리다이렉트 (GoRoute 59개)
│  └─ utils/                        # device_info_helper, error_message(userMessageOf)
│
├─ modules/                         # 역할별 모듈 (6개)
│  ├─ resident/       (45 files)    # 입주민   — data / domain / presentation
│  ├─ admin/          (43 files)    # 관리자   — data / domain / presentation
│  ├─ manager/        (25 files)    # 담당자   — data / domain / presentation
│  ├─ headquarters/   (22 files)    # 본사     — data / domain / presentation
│  ├─ common/         ( 6 files)    # 공용 datasource + services (업로드, FCM)
│  └─ auth/           ( 4 files)    # 인증 상태 + 스플래시/홈/로그인선택 (presentation only)
│
├─ shared/
│  ├─ widgets/                      # 공유 위젯 11개 (showErrorAlert, PrimaryActionButton 등)
│  └─ constants/legal_documents.dart
│
├─ domain/entities/user.dart        # 전역 User 엔티티
└─ data/datasources/                # 전역 auth_remote_datasource
```

`lib/features/` 디렉터리는 **존재하지 않습니다.** (구 README 의 오기)

### Clean Architecture 적용 범위 (부분 적용)

| 모듈 | data | domain | presentation |
|---|:---:|:---:|:---:|
| `resident`, `admin`, `manager`, `headquarters` | ✅ | ✅ | ✅ |
| `auth` | ❌ | ❌ | ✅ |
| `common` | ✅ | ❌ | ❌ (services 만) |

`auth` 의 데이터 레이어는 모듈 밖 `lib/data/datasources/auth_remote_datasource.dart` 에 있습니다.

---

## 기술 스택

| 영역 | 패키지 |
|---|---|
| 상태 관리 / DI | `flutter_riverpod ^2.6.1` |
| 라우팅 | `go_router ^14.6.2` |
| HTTP | `dio ^5.7.0` |
| 보안 저장소 | `flutter_secure_storage ^9.2.2` (토큰 전용) |
| 로컬 플래그 | `shared_preferences ^2.3.3` (앱 버전 · 승인완료 1회 노출) |
| 푸시 | `firebase_core ^4.2.0`, `firebase_messaging ^16.0.3`, `flutter_local_notifications ^19.0.0` |
| UI | Material 3, `flutter_svg`, `cached_network_image`, `image_picker`, `table_calendar` |
| 기타 | `equatable`, `intl ^0.20.0`, `flutter_dotenv ^5.1.0`, `package_info_plus`, `device_info_plus` |
| 개발 | `flutter_lints ^5.0.0`, `mockito`, `build_runner` |

---

## 시작하기

### 1. 환경 변수 (`.env`)

프로젝트 루트에 `.env` 파일이 **반드시** 있어야 합니다 (`pubspec.yaml` 의 asset 으로 번들됩니다).

```env
API_BASE_URL=http://<서버 호스트>
API_VERSION=v1
ENVIRONMENT=staging          # development | staging | production
API_CONNECT_TIMEOUT=30000
API_RECEIVE_TIMEOUT=30000
API_DEBUG=true               # true 면 LoggingInterceptor 활성화
```

> ⚠️ `.env` 는 `.gitignore` 에 추가되어 있지만 **아직 git 에 추적 중**입니다.
> `git rm --cached .env` 로 추적 해제 예정입니다. 그 전까지 `.env` 변경이 커밋에 섞이지 않도록 주의하세요.

### 2. 의존성 설치 및 실행

```bash
flutter pub get
flutter run                  # 연결된 기기/에뮬레이터
flutter run -d chrome        # Web
```

### 3. 품질 관리

```bash
flutter analyze              # 정적 분석
flutter test                 # 테스트 (현재 5개 파일)
```

---

## 아키텍처 핵심

### 인증 · 토큰

- 토큰(`access_token` / `refresh_token`)은 **`flutter_secure_storage`** 에만 저장됩니다.
  `SharedPreferences` 는 앱 버전 플래그와 승인완료 1회 노출 플래그 전용입니다.
- `AuthInterceptor` (`lib/core/network/interceptors/auth_interceptor.dart`)가
  요청에 Bearer 토큰을 붙이고, 401 발생 시 **refresh → 원 요청 재시도**까지 자동 처리합니다.
  - 동시 401 은 하나의 갱신 Future 를 공유 (요청 폭주 방지)
  - 요청당 갱신 1회 제한 (무한 루프 방지)
  - **갱신에 실패한 경우에만** 토큰 삭제

### 라우팅 · 권한

`lib/core/routing/router_notifier.dart` 가 GoRouter 를 소유하며, 보호 경로는 **접두어로 판정**합니다.

| 접두어 | 필요 역할 |
|---|---|
| `/user/` | 입주민 |
| `/admin/` | 관리자 |
| `/manager/` | 담당자 |
| `/headquarters/` | 본사 |

예외 1건: `/manager/add-general-manager` 는 경로만 담당자 접두어일 뿐 **관리자 전용**이며
`_routeOwnerOverrides` 로 처리됩니다. 접두어 방식이므로 새 라우트는 자동으로 보호됩니다.

### 에러 처리 계약

`ErrorInterceptor` 가 `ApiException` 을 `DioException.error` 에 실어 보내고,
`ApiClient._guard()` 가 이를 언랩합니다. 따라서 **상위 계층에는 `ApiException` 만 전파**됩니다.

```dart
// datasource
try { ... } on ApiException { rethrow; } catch (_) { throw const ApiException(...); }

// screen
} catch (e) {
  if (!mounted) return;
  await showErrorAlert(context, title: '...', error: e, fallback: '...');
}
```

- `on DioException catch` 를 새로 쓰지 마세요 (도달하지 않습니다).
- 빈 `catch {}` 금지. `e.toString()` 을 다이얼로그에 직접 넣지 마세요 —
  `showErrorAlert` / `userMessageOf` 를 사용합니다.

---

## UI 가이드 요약

- 헤더 텍스트는 `PageHeaderText` 위젯 사용 (색상 `#464A4D`, 크기 16, 굵기 700)
- 확인/취소 다이얼로그는 `showCustomConfirmationDialog`, 실패 안내는 `showErrorAlert`
- 배경/버튼/구분선은 `lib/shared/widgets/` 의 공용 위젯 재사용
- Material 3 (`useMaterial3: true`)

---

## 문서

| 문서 | 용도 |
|---|---|
| `CLAUDE.md` | 개발 규약 · 아키텍처 상세 · 에러 처리 규칙 · 백엔드 계약 (가장 상세) |
| `AGENTS.md` | AI 에이전트/신규 기여자용 작업 규칙 요약 |
| `docs/프론트엔드_구조_및_문제점_분석.md` | 코드 실측 분석 및 이슈 트래킹 (P0~P3) |
| `docs/배포_가이드.md` | Fastlane 기반 스토어 배포 절차 |
| `docs/FCM_INTEGRATION_GUIDE.md` | 푸시 알림 연동 (일부 개정 필요) |

`docs/` 하위에는 **폐기 예정 문서 13개**가 남아 있습니다. 파일 상단에
`⚠️ 폐기 예정 문서` 배너가 있으면 참고하지 마세요.

---

## 배포

모든 스토어 배포는 **Fastlane** 으로 수행합니다. 상세 절차는 `docs/배포_가이드.md` 를 따르세요.
