# AGENTS.md

> **관례 파일** · 여러 AI 도구가 이 이름을 찾으므로 메타 블록 없이 둔다.
> **역할 분담**: 이 문서는 *진입점*(규칙 요약·금지사항), [`CLAUDE.md`](CLAUDE.md) 는 *상세*(아키텍처·예제 코드).
> 규칙이 바뀌면 **둘 다** 고친다. 상세만 필요하면 CLAUDE.md 로 바로 가도 된다.

이 저장소(`building-manage-front/`)에서 작업하는 AI 에이전트 및 신규 기여자를 위한 **작업 규칙 요약본**입니다.
아키텍처 상세와 예제 코드는 `CLAUDE.md`, 코드 구조는 `docs/코드지도.md`, 미해결 이슈는 `../docs/3-할일/부채.md` 를 보세요.
문서 규칙은 `../docs/문서체계.md`, 전체 문서 목록은 `../docs/README.md` 에 있습니다.

> 최종 갱신: **2026-08-21** (전면 재작성. 이전 버전은 제목이 `# CLAUDE.md` 였고 내용이
> "기본적인 Flutter 카운터 데모" 로 되어 있어 사실과 전혀 달랐습니다.)

---

## 0. 작업 범위

- 이 폴더(`building-manage-front/`) **밖은 읽지도 수정하지도 마세요.**
  특히 백엔드 저장소(`Building-Manager-BackEnd/`)는 범위 밖입니다.
- 사용자 미커밋 변경이 있을 수 있는 파일은 지시 없이 건드리지 마세요:
  `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `.env`

---

## 1. 프로젝트가 실제로 무엇인가

프로덕션 운영 중인 **다중 역할 건물 관리 Flutter 앱** (`v1.0.12+33`, Dart `^3.8.1`).
카운터 데모가 아닙니다. Riverpod + GoRouter + Dio 기반이며 백엔드 API 와 실제로 연동됩니다.

- `lib/` Dart 파일 **176개**, 화면 **58개**, 테스트 **5개** (2026-08-21 실측)
- 라우트 `GoRoute` **59개**, 역할 기반 리다이렉트 적용

### ⚠️ 역할 폴더명 (매번 확인할 것)

| 폴더 | 한국어 | `UserType` | 서버 role | 서버 API prefix |
|---|---|---|---|---|
| `modules/resident/` | **입주민** | `user` | `USER` | `/users`, `/auth/resident` |
| `modules/admin/` | **관리자** | `admin` | **`MANAGER`** | **`/managers`** |
| `modules/manager/` | **담당자** (유지보수 직원) | `manager` | **`STAFF`** | **`/staffs`** |
| `modules/headquarters/` | **본사** | `headquarters` | `HEADQUARTERS` | `/headquarters` |

`manager` 를 "매니저" 로 번역하지 마세요. **담당자**입니다.
프론트 폴더명과 백엔드 경로가 뒤집혀 있으니 API 를 추측하지 말고 `lib/core/constants/api_endpoints.dart` 를 확인하세요.

---

## 2. 개발 명령어

```bash
flutter pub get                       # 의존성 설치
flutter run                           # 실행 (기기/에뮬레이터)
flutter run -d chrome                 # Web
flutter analyze                       # 정적 분석 (커밋 전 필수)
flutter test                          # 테스트
flutter test test/router_notifier_test.dart
```

- `.env` 가 루트에 없으면 앱이 API 를 못 붙습니다 (`AppConfig` 가 dotenv 로 읽음).
- 코드 생성(`build_runner`)은 **현재 실사용되지 않습니다** — `lib/` 에 `.g.dart` 0개.

---

## 3. 반드시 지켜야 할 코드 규칙

### 3.1 레이어 (UI 에 비즈니스 로직 금지)

```
화면(Widget) → Provider/Notifier → UseCase → Repository → RemoteDataSource → ApiClient
```

- 화면에서 `ApiClient` 를 직접 호출하지 마세요. (기존 위반 1건: `headquarters_change_password_screen.dart:39`)
- 새 기능은 `modules/<역할>/domain/usecases/` 를 거치게 만드세요.
- 상태 관리는 **Riverpod 단일 체계**입니다. `ProviderContainer()` 를 화면에서 새로 만들지 마세요.
  (전부 제거되었습니다. 다시 넣지 마세요.)

### 3.2 에러 처리 (단일 계약)

`ApiClient` 는 **`ApiException` 만** 던집니다.
(`ErrorInterceptor` → `DioException.error` 에 실음 → `ApiClient._guard()` 가 언랩)

```dart
// datasource
try {
  final res = await _apiClient.get(ApiEndpoints.xxx);
  return res.data as Map<String, dynamic>;
} on ApiException {
  rethrow;                       // 서버 메시지/상태코드 보존
} catch (_) {
  throw const ApiException(message: '...', errorCode: 'XXX_FAILED');
}

// 화면
} catch (e) {
  if (!mounted) return;          // await 뒤 context/setState 사용 전 필수
  await showErrorAlert(context, title: '삭제 실패', error: e,
      fallback: '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.');
}
```

금지 사항:
- `on DioException catch` 신규 작성 (도달하지 않는 죽은 분기가 됩니다)
- 빈 `catch (e) { }` — 실패를 조용히 삼키면 사용자는 성공한 줄 압니다
- `Text(e.toString())`, `e.toString().replaceAll('Exception: ', '')` 를 다이얼로그에 직접 넣기
  → `ApiException(message: ..., statusCode: 401, ...)` 이 그대로 노출됩니다.
  `showErrorAlert` / `userMessageOf` 를 쓰세요.

### 3.3 비동기 · 생명주기

- `await` 뒤에 `setState`/`context` 를 쓰면 앞에 `if (!mounted) return;`
  (`State` 가 없는 곳은 `if (!context.mounted) return;`)
- `finally { setState(...) }` 도 예외 없이 `if (mounted) { setState(...) }`
- `Future.wait` 은 하나만 실패해도 전체가 실패합니다. 부분 실패를 허용해야 하면 개별 `catch` 로 감싸세요.

### 3.4 렌더링 성능

- 가능한 모든 위젯에 `const` 생성자 사용
- 거대 화면 파일(현재 최대 1,091줄)은 하위 위젯으로 쪼개서 리빌드 범위를 좁힐 것
- 리스트는 `ListView.builder`, 네트워크 이미지는 `cached_network_image`
- `FutureProvider.family` 는 `.autoDispose` 를 붙여 캐시 누적을 막을 것

### 3.5 로깅 · 보안

- **`print()` 금지.** 현재 `lib/` 에 0건입니다. 필요하면 `debugPrint`.
- 개인정보(이름/전화번호/응답 전문)를 로그에 남기지 마세요.
- 토큰은 `flutter_secure_storage` (`AuthInterceptor` 단독 소유).
  `SharedPreferences` 는 앱 버전 플래그와 승인완료 1회 노출 플래그 전용입니다.
- 토큰 갱신 로직을 직접 구현하지 마세요. `AuthInterceptor` 가 401 → refresh → 원 요청 재시도까지 처리합니다.

### 3.6 라우팅

- 보호 경로는 **접두어**로 판정됩니다 (`/user/`, `/admin/`, `/manager/`, `/headquarters/`).
  새 라우트를 추가하면 자동으로 보호되므로 **목록에 등록하는 작업은 필요 없습니다.**
- 접두어와 실제 소유 역할이 다른 경우에만 `_routeOwnerOverrides` 에 추가하세요.
  현재 예외는 `/manager/add-general-manager` → `UserType.admin` 1건뿐입니다.

### 3.7 Dart 스타일

- `flutter_lints ^5.0.0` (`analysis_options.yaml`) 준수, 커밋 전 `flutter analyze`
- 파일/디렉터리 `snake_case`, 클래스 `UpperCamelCase`, 변수/함수 `lowerCamelCase`
- Provider 이름은 `xxxProvider` 접미사
- API 경로는 `lib/core/constants/api_endpoints.dart` 에 정의 (하드코딩 금지)

---

## 4. 백엔드 계약 메모

- `/common/departments` 는 이름과 달리 **인증 필수**이며, **호출자 역할에 따라 결과가 다릅니다.**
  본사가 부르면 본사 부서, 관리자가 부르면 해당 건물 부서가 내려옵니다.
  → 역할 간에 캐시를 공유하지 마세요. 로그인 전 화면에서는 사용할 수 없습니다.
- `AuthInterceptor` 의 public 엔드포인트 화이트리스트는 `/auth/...` 계열뿐입니다.
  그 외 모든 경로에는 `Authorization` 헤더가 붙습니다.

---

## 5. 커밋

```
<type>: <한글 설명>

feat / fix / refactor / style / test / docs / chore
```

예: `fix: 401 토큰 갱신 후 원요청 재시도 처리`

---

## 6. 현재 알려진 미해결 이슈 (2026-08-21)

작업 전 `../docs/3-할일/부채.md` 3장을 확인하세요. 우선순위 상위 항목:

| ID | 내용 |
|---|---|
| **P1-6** | 약관 동의(`agreements`)가 서버로 전송되지 않음. `signup_form_provider.submitSignup()` 은 dead code 이고 실제 가입 경로는 `resident_signup_screen._submitSignup()` → `RegisterResidentUseCase` |
| **P1-8** | FCM 알림 탭 시 네비게이션 없음 (`notification_service.dart:198-202` TODO) |
| **P1-3** | 원시 에러 문자열 노출 6곳 잔존 |
| **P1-4** | 로그인 화면 2곳이 모든 예외를 "아이디/비밀번호 오류" 로 표시 |
| **P2-1** | 화면 33개가 DataSource 직행 (UseCase 미경유) |

---

## 7. 문서 상태

- **유효**: `CLAUDE.md`, `README.md`, `AGENTS.md`, `docs/코드지도.md`, `docs/배포절차.md`, `docs/FCM연동.md`
- **부분 개정 필요**: `docs/FCM연동.md`(공고문 푸시 미반영), `PRIVACY_CONSENT_PLAN.md`
- **보관됨**: `docs/7-보관/` 15개 — 참고하지 마세요
- **폐기 예정 (13개)**: 파일 상단에 `⚠️ 폐기 예정 문서` 배너가 있는 문서는 **참고하지 마세요.**
  아직 삭제되지 않았을 뿐입니다.

문서를 갱신할 때는 **해결된 항목을 지우지 말고 "해결됨" 표시로 남겨** 이력을 추적할 수 있게 하세요.
숫자는 추측하지 말고 `find` / `wc -l` / `grep` 으로 실측하세요.
