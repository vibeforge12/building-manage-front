# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소의 코드로 작업할 때 지침을 제공합니다.

## 프로젝트 개요

이것은 "building_manage_front"라는 이름의 Flutter 애플리케이션으로, 건물 관리 프론트엔드 애플리케이션입니다. Android, iOS, Web, Linux, macOS, Windows를 지원하는 크로스 플랫폼 앱입니다. 단일 앱 안에서 *유저*, *건물별 관리자*, *담당자*, *본사* 등 네 가지 로그인 역할을 지원하며, 로그인 유형에 따라 화면과 기능이 분기되는 구조를 목표로 합니다.

## 개발 명령어

### 설정
```bash
flutter pub get                    # 의존성 설치
```

### 개발
```bash
flutter run                       # 연결된 기기/에뮬레이터에서 실행
flutter run -d chrome             # Chrome(웹)에서 실행
flutter run -d macos              # macOS에서 실행
flutter run --hot                 # 핫 리로드 활성화하여 실행
flutter hot-reload                # 개발 중 핫 리로드 실행
flutter hot-restart               # 개발 중 핫 리스타트 실행
```

### 빌드
```bash
flutter build apk                 # Android APK 빌드
flutter build appbundle           # Android App Bundle 빌드
flutter build ios                 # iOS 앱 빌드
flutter build web                 # 웹 앱 빌드
flutter build macos               # macOS 앱 빌드
flutter build windows             # Windows 앱 빌드
flutter build linux               # Linux 앱 빌드
```

### 테스트 및 품질 관리
```bash
flutter test                      # 모든 테스트 실행
flutter test test/widget_test.dart # 특정 테스트 파일 실행
flutter analyze                   # 정적 분석 실행
flutter pub deps                  # 의존성 트리 표시
flutter pub outdated              # 오래된 의존성 확인
flutter pub upgrade               # 의존성 업그레이드
```

### 플랫폼별 명령어
```bash
flutter devices                   # 사용 가능한 기기/에뮬레이터 목록
flutter emulators                 # 사용 가능한 에뮬레이터 목록
flutter emulators --launch <id>   # 특정 에뮬레이터 실행
flutter clean                     # 빌드 캐시 정리
```

## 아키텍처

### 프로젝트 구조
- `lib/main.dart` - MyApp과 MyHomePage 위젯이 있는 메인 애플리케이션 진입점
- `test/` - 위젯 테스트와 기타 테스트 파일들 포함
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - 플랫폼별 설정
- `pubspec.yaml` - Flutter 의존성 및 프로젝트 설정
- `analysis_options.yaml` - flutter_lints를 사용한 Dart 분석기 설정

### 현재 구현 상태
현재 앱은 기본적인 Flutter 카운터 데모 애플리케이션을 포함하고 있습니다:
- 진보라색 컬러 스킴을 사용하는 Material Design 테마
- 증가 기능이 있는 상태 저장 카운터 위젯
- 표준 Flutter 프로젝트 구조 및 규칙

앞으로는 공용 로그인 화면을 통해 네 가지 역할 중 하나를 선택하거나 자동으로 인식하여 적절한 홈 화면 및 권한 세트로 이동시키는 분기 로직을 구현할 예정입니다. 이 때 역할별 대시보드와 기능 모듈(예: 시설 점검, 공지 관리, 본사 리포트 등)은 동일한 코드베이스에서 조건부로 로드되도록 설계합니다.

### 의존성
- **flutter_lints ^5.0.0** - Flutter 권장 린팅 규칙 제공
- **cupertino_icons ^1.0.8** - iOS 스타일 아이콘
- **flutter_test** - 테스팅 프레임워크

## 코드 표준
- `package:flutter_lints/flutter.yaml`을 통한 Flutter 권장 린트 사용
- Dart SDK 버전: ^3.8.1
- Flutter/Dart 명명 규칙 및 코드 스타일 준수
- 적절한 곳에서 const 생성자 사용
- 앱이 성장함에 따라 적절한 상태 관리 패턴 구현

## 플랫폼 지원
다음을 지원하는 멀티 플랫폼 Flutter 애플리케이션입니다:
- **Android** (android/ 디렉터리를 통해)
- **iOS** (ios/ 디렉터리를 통해)
- **Web** (manifest.json과 index.html이 있는 web/ 디렉터리를 통해)
- **Desktop**: Linux, macOS, Windows (각각의 디렉터리를 통해)

각 플랫폼은 플랫폼별 설정과 빌드 구성이 있는 자체 설정 디렉터리를 가지고 있습니다.

---

## Agent Planning Notes (Foundation Review)

### Current Snapshot
- Riverpod + go_router 기반의 앱 골격과 기본 로그인 플로우(UI/Stub 로직)가 구축되어 있으며, `AuthStateNotifier`와 라우터 가드가 토대만 제공하고 있습니다.
- Domain/Data 레이어, repository 인터페이스, dio 기반 API 연동, 로컬 스토리지(Hive, shared_preferences)는 구조만 존재하고 실제 구현이 비어 있습니다.
- `UserRole`(core/auth)와 `UserType`(core/constants) 두 enum이 혼재하여 역할 정보 정합성 관리가 필요합니다.
- 문서(`docs/`) 전반은 초기 설계/계획과 현 코드 구조가 뒤섞여 있어 최신 정보와 불일치하는 항목이 다수 존재합니다.
- 테스트는 메인 홈 위젯 테스트 1건에 그쳐 있고, 상태/라우팅/역할 분기 관련 검증이 부재합니다.

### Immediate Gaps & Risks
- 인증 상태가 메모리 내 스텁으로만 유지되어 실제 로그인/토큰 흐름, 자동 로그인, 에러 처리 시나리오가 전혀 다뤄지지 않습니다.
- 라우팅 플레이스홀더 대시보드는 역할별 요구사항을 전혀 반영하지 못하고 있으며, 접근권한 매트릭스에 대한 테스트/가드가 없습니다.
- 테마/디자인 토큰이 Figma 기준으로 정리되지 않아 다크 모드, 반응형, 컴포넌트 일관성 확보가 어렵습니다.
- 빌드/배포 파이프라인과 환경 분리(dev/staging/prod)가 정의되지 않아 실 서비스 준비 수준이 아닙니다.

### Figma MCP Alignment Tasks
1. `npx -y figma-developer-mcp --figma-api-key=… --stdio`로 Framelink Figma MCP 서버를 구동하고, 최신 디자인 토큰(컬러, 타입 스케일, spacing)과 컴포넌트 명세를 동기화합니다.
2. Figma에서 정의된 공통 컴포넌트(CTA 버튼, 입력 필드, 배경, 카드 등)의 속성을 추출하여 Flutter Theme extensions 및 재사용 위젯에 반영할 매핑 테이블을 작성합니다.
3. 각 역할별 핵심 플로우(유저/관리자/담당자/본사 대시보드)의 화면 구조, 네비게이션 패턴을 Figma 기준으로 캡처하여 `docs/ui_navigation_plan.md`와 라우팅 구성표를 업데이트합니다.

### Implementation Roadmap (Not Yet Executed)
1. **Foundation Hardening**
   - 의존성 버전 재점검 및 정리(`pubspec.yaml`), 중복 enum 통합 전략 수립, 공통 상수/테마 정의.
   - 정적 분석 규칙 강화(analysis_options)와 pre-commit 스크립트 초안 마련.
2. **Design System Integration**
   - Figma 토큰 기반 `ThemeData` 확장, 공통 컴포넌트 리팩토링, 반응형/접근성 가이드 수립.
   - 자주 쓰이는 레이아웃/모듈을 `presentation/common`으로 통합하고 스토리북(Widgetbook 등) 도입 검토.
3. **Authentication & Authorization Layer**
   - `data/datasources`에 dio 기반 Auth API, 토큰 로컬 보관(Hive/secure storage) 구현.
   - `AuthRepository` 및 usecase 정의, `AuthStateNotifier` 확장, 라우터 가드 및 에러 핸들링 정교화.
   - 역할별 초기 라우팅 및 세션 복구 흐름 유닛/위젯 테스트 추가.
4. **Role-Specific Dashboards**
   - 각 역할 요구사항(Figma + `docs/user_types.md`)을 기준으로 MVP 화면 목록 및 상태 프로바이더 설계.
   - 공통 모듈(공지, 신고, 예약 등)을 도메인 단위로 분리하고 Feature flag/조건 로딩 구조 마련.
5. **Data & Offline Capabilities**
   - API 에러/재시도/타임아웃 정책 수립, 응답 모델(JsonSerializable) 생성, 레포지토리 구현.
   - Hive 박스 스키마 정의와 캐싱 전략, 오프라인 모드/동기화 전략 초안 작성.
6. **Observability & Quality**
   - 로그/에러 수집(예: Sentry) 연동 계획, 퍼포먼스 모니터링 시나리오 작성.
   - 테스트 스위트 확장(Unit/Widget/Integration) 및 CI 파이프라인(Job: format → analyze → test) 설계.

### Documentation & Workflow Updates
- `docs/` 내 계획 문서들을 현 구조에 맞춰 리비전하고, 진행 상태를 체크박스/타임라인 형태로 관리합니다.
- `README.md` 구조 설명을 최신 Clean Architecture 반영 버전으로 정리하고, 실행/테스트/디자인 토큰 가이드 링크를 추가합니다.
- 에이전트 작업 시퀀스(요청 → Figma 참조 → 구현 → 테스트 → 문서화)를 `AGENTS.md`에 유지하며, 완료 여부는 PR 템플릿/체크리스트에서 관리할 예정입니다.

> 위 항목들은 **계획 초안**이며, 아직 구현에 착수하지 않았습니다. 추후 작업 요청 시 이 문서를 기준으로 우선순위와 범위를 확정합니다.
