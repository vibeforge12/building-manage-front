# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

다중 역할 기반의 건물 관리 Flutter 애플리케이션입니다. 4가지 사용자 타입(입주민, 관리자, 담당자, 본사)을 지원하며, 각 역할에 맞는 독립적인 기능과 권한 체계를 제공합니다.

## 개발 명령어

### 환경 설정
```bash
flutter pub get                           # 의존성 설치
flutter pub run build_runner build        # 코드 생성 (JSON serialization, Hive 등)
flutter pub run build_runner watch        # 자동 코드 생성 모드
```

### 개발 및 실행
```bash
flutter run                               # 기본 기기에서 실행
flutter run -d chrome                     # 웹에서 실행
flutter run -d macos                      # macOS에서 실행
flutter run --hot                         # 핫 리로드 활성화
```

### 빌드
```bash
flutter build apk                         # Android APK 빌드
flutter build appbundle                   # Android App Bundle 빌드
flutter build ios                         # iOS 앱 빌드
flutter build web                         # 웹 앱 빌드
flutter build macos                       # macOS 앱 빌드
flutter build windows                     # Windows 앱 빌드
flutter build linux                       # Linux 앱 빌드
```

### 테스트 및 품질 관리
```bash
flutter test                              # 모든 테스트 실행
flutter test test/widget_test.dart        # 특정 테스트 파일 실행
flutter analyze                           # 정적 분석
flutter clean                             # 빌드 캐시 정리
```

## 아키텍처

### 모듈 기반 구조
코드베이스는 **모듈별 완전 분리 구조**를 채택하고 있으며, 각 사용자 타입별로 독립적인 모듈을 가집니다:

```
lib/
├── modules/                    # 사용자 타입별 독립 모듈
│   ├── auth/                   # 공통 인증 (로그인, 토큰 관리)
│   ├── resident/               # 입주민 모듈 (회원가입, 대시보드)
│   ├── manager/                # 담당자 모듈
│   ├── admin/                  # 관리자 모듈
│   ├── headquarters/           # 본사 모듈 (건물 관리, 부서 생성, 계정 발급)
│   └── common/                 # 모듈 공통 데이터소스
│
├── core/                       # 앱 전역 핵심 기능
│   ├── config/                 # AppConfig (환경 변수 로드)
│   ├── network/                # ApiClient, Interceptors
│   │   └── interceptors/       # Auth, Logging, Error Interceptors
│   ├── routing/                # RouterNotifier (권한 기반 라우팅)
│   ├── constants/              # UserType, AuthState, API endpoints
│   └── providers/              # 전역 Riverpod providers
│
├── shared/                     # 모든 모듈에서 공통 사용
│   └── widgets/                # 재사용 가능한 UI 컴포넌트
│
├── domain/                     # 도메인 엔티티
│   └── entities/               # User 등
│
├── data/                       # 공통 데이터 레이어
│   └── datasources/            # 공통 API 데이터소스
│
└── app/                        # 앱 진입점
    └── app.dart                # BuildingManageApp
```

### 각 모듈 내부 구조
각 `modules/` 하위 모듈은 Clean Architecture 레이어를 가질 수 있습니다:
- `data/datasources/` - API 통신 로직
- `domain/` - 엔티티, 유스케이스, 레포지토리 인터페이스
- `presentation/` - 화면(screens), 위젯(widgets), 상태관리(providers)

### 상태 관리 및 의존성 주입
- **Riverpod**: 모든 상태 관리 및 의존성 주입에 사용
- **Provider 위치**: 각 모듈의 `presentation/providers/` 또는 `core/providers/`
- **주요 전역 Provider**:
  - `authStateProvider`: 인증 상태 관리 (AuthState enum)
  - `currentUserProvider`: 현재 로그인 사용자 (User 엔티티)
  - `routerProvider`: GoRouter 인스턴스
  - `apiClientProvider`: Dio 기반 API 클라이언트

### 라우팅 시스템
- **Go Router**: 선언적 라우팅 및 권한 기반 리다이렉트
- **RouterNotifier** (`lib/core/routing/router_notifier.dart`):
  - `authStateProvider`와 `currentUserProvider`를 감시하여 자동 리다이렉트
  - 보호된 경로(대시보드 등)는 인증 상태 및 사용자 타입 검증
  - 잘못된 권한 접근 시 해당 사용자의 기본 대시보드로 리다이렉트
- **경로 규칙**:
  - `/` - 메인 홈 (역할 선택)
  - `/user-login`, `/manager-login`, `/headquarters-login` - 로그인 화면
  - `/user/dashboard`, `/admin/dashboard`, `/manager/dashboard`, `/headquarters/dashboard` - 보호된 대시보드

### API 통신
- **ApiClient** (`lib/core/network/api_client.dart`): Dio 기반 싱글톤 HTTP 클라이언트
- **환경 설정**: `.env` 파일에서 `API_BASE_URL`, `API_VERSION`, `ENVIRONMENT` 로드
- **Interceptor 체계**:
  - `AuthInterceptor`: 요청에 자동으로 JWT 토큰 첨부, 401 에러 시 RefreshToken으로 갱신
  - `LoggingInterceptor`: 디버그 모드에서 요청/응답 로깅
  - `ErrorInterceptor`: API 에러 통합 처리
- **토큰 관리**: SharedPreferences에 `access_token`, `refresh_token` 저장

### 인증 시스템
- **JWT 기반**: AccessToken + RefreshToken 자동 갱신
- **자동 로그인**: `main.dart`에서 앱 시작시 토큰 유효성 검사 (`checkAutoLogin`)
- **AuthState** enum: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`
- **UserType** enum: `user`(입주민), `admin`(관리자), `manager`(담당자), `headquarters`(본사)

### UI 컴포넌트 시스템
- **Shared Widgets** (`lib/shared/widgets/`):
  - `FullScreenImageBackground`: 전체 화면 배경 이미지
  - `PageHeaderText`: 표준 헤더 텍스트 (#464A4D, 16px, 굵기 700)
  - `PrimaryActionButton`: 주요 액션 버튼
  - `SectionDivider`: 섹션 구분선
- **Material 3**: 전체 앱에서 Material Design 3 사용

## 주요 기술 스택
- **Flutter** 3.x (Dart SDK ^3.8.1)
- **상태 관리**: flutter_riverpod ^2.6.1
- **라우팅**: go_router ^14.6.2
- **HTTP 클라이언트**: dio ^5.7.0
- **로컬 저장소**: shared_preferences ^2.3.3, hive ^2.2.3
- **코드 생성**: build_runner, json_serializable, hive_generator
- **테스트**: flutter_test, mockito ^5.4.4

## 코드 생성 및 직렬화
- **build_runner**: JSON 직렬화, Hive 타입 어댑터 자동 생성
- 엔티티/모델에 `@JsonSerializable()`, `@HiveType()` 어노테이션 사용
- 변경 후 반드시 `flutter pub run build_runner build` 실행

## 환경 변수 (.env)
프로젝트 루트에 `.env` 파일 필요:
```
API_BASE_URL=https://api.example.com
API_VERSION=v1
ENVIRONMENT=staging
API_CONNECT_TIMEOUT=30000
API_RECEIVE_TIMEOUT=30000
API_DEBUG=true
```

## 주요 비즈니스 로직

### 입주민 회원가입
- 2단계 폼 구조 (`ResidentSignupScreen`)
- Riverpod `StateNotifier`로 다단계 데이터 보존 (`SignupFormProvider`)
- 1단계: 동/호수, 비밀번호 입력 및 검증
- 2단계: 사용자 정보 (이름, 전화번호 등)

### 본사 대시보드
- 로그인 후 `HeadquartersDashboardScreen`으로 이동
- 건물 관리, 부서 생성, 관리자 계정 발급 기능 제공
- 배경 이미지: `assets/headQuartersHome.png`

### 건물 관리
- `BuildingManagementScreen`: 부서 목록 표시, 실시간 검색 (디바운스 500ms)
- API: `/api/v1/common/departments` (GET)
- `DepartmentRemoteDataSource`로 API 호출

## 코딩 규칙
- **Lint**: `package:flutter_lints/flutter.yaml` 준수
- **Naming**: Dart 표준 명명 규칙 (camelCase, PascalCase)
- **Const**: 가능한 모든 위젯에 `const` 생성자 사용하여 성능 최적화
- **Provider 명명**: `xxxProvider` (예: `authStateProvider`)
- **파일 명명**: 스네이크 케이스 (예: `user_login_screen.dart`)

## 주의 사항
- 새 모듈 추가 시 `modules/` 아래 독립 폴더 생성
- API 엔드포인트는 `lib/core/constants/api_endpoints.dart`에 정의
- 공통 UI 컴포넌트는 `shared/widgets/`에 배치
- 각 사용자 타입별 기능은 해당 모듈 내부에서만 구현
- 토큰 갱신은 `AuthInterceptor`가 자동 처리
