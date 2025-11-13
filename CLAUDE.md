# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

다중 역할 기반의 건물 관리 Flutter 애플리케이션입니다. 4가지 사용자 타입(입주민/유저, 관리자, 담당자, 본사)을 지원하며, 각 역할에 맞는 독립적인 기능과 권한 체계를 제공합니다.

## 개발 명령어

### 환경 설정
```bash
flutter pub get                           # 의존성 설치
flutter pub run build_runner build        # 코드 생성 (JSON serialization, Hive 등)
flutter pub run build_runner watch        # 자동 코드 생성 모드 (개발 중 파일 변경 감지)
flutter pub run build_runner build --delete-conflicting-outputs  # 충돌 파일 삭제 후 빌드
```

### 개발 및 실행
```bash
flutter run                               # 기본 기기에서 실행
flutter run -d chrome                     # 웹에서 실행
flutter run -d macos                      # macOS에서 실행
flutter run --hot                         # 핫 리로드 활성화 (기본값)
flutter run --release                     # 릴리스 모드로 실행
```

### 빌드
```bash
flutter build apk                         # Android APK 빌드 (debug)
flutter build apk --release               # Android APK 빌드 (release)
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
flutter analyze                           # 정적 분석 (Lint 검사)
flutter clean                             # 빌드 캐시 정리
flutter doctor                            # Flutter 환경 점검
flutter pub outdated                      # 오래된 패키지 확인
```

## 아키텍처

### 모듈 기반 구조
코드베이스는 **모듈별 완전 분리 구조**를 채택하고 있으며, 각 사용자 타입별로 독립적인 모듈을 가집니다:

```
lib/
├── modules/                    # 사용자 타입별 독립 모듈 (Clean Architecture)
│   ├── auth/                   # 공통 인증 (로그인, 토큰 관리, 인증 상태)
│   │   ├── data/               # 인증 데이터 레이어
│   │   │   ├── datasources/    # AuthRemoteDataSource
│   │   │   ├── models/         # 인증 관련 모델
│   │   │   └── repositories/   # 인증 레포지토리 구현
│   │   ├── domain/             # 인증 도메인 레이어
│   │   │   ├── entities/       # 인증 엔티티
│   │   │   ├── repositories/   # 인증 레포지토리 인터페이스
│   │   │   └── usecases/       # 로그인, 로그아웃 등 유스케이스
│   │   └── presentation/       # 인증 UI 레이어
│   │       ├── providers/      # authStateProvider, currentUserProvider
│   │       ├── screens/        # MainHomeScreen, AdminLoginSelectionScreen
│   │       └── widgets/        # 인증 관련 위젯
│   │
│   ├── resident/               # 입주민/유저 모듈
│   │   ├── data/
│   │   │   ├── datasources/    # ResidentAuthRemoteDataSource
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/      # signupFormProvider
│   │       ├── screens/        # ResidentSignupScreen, UserLoginScreen
│   │       └── widgets/        # resident_signup_step1/2/3
│   │
│   ├── admin/                  # 관리자 모듈
│   │   ├── data/
│   │   │   ├── datasources/    # StaffRemoteDataSource
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/      # staffProvider
│   │       ├── screens/        # AdminDashboardScreen, AdminLoginScreen
│   │       │                   # StaffAccountIssuanceScreen
│   │       └── widgets/
│   │
│   ├── manager/                # 담당자 모듈
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/        # ManagerStaffLoginScreen
│   │       └── widgets/
│   │
│   ├── headquarters/           # 본사 모듈
│   │   ├── data/
│   │   │   ├── datasources/    # BuildingRemoteDataSource, DepartmentRemoteDataSource
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/        # HeadquartersDashboardScreen, BuildingManagementScreen
│   │       │                   # BuildingRegistrationScreen, DepartmentCreationScreen
│   │       │                   # AdminAccountIssuanceScreen, HeadquartersLoginScreen
│   │       └── widgets/
│   │
│   └── common/                 # 모듈 간 공통 데이터소스
│       └── data/
│           └── datasources/    # 공통 API 데이터소스
│
├── core/                       # 앱 전역 핵심 기능
│   ├── config/                 # AppConfig (환경 변수 로드, .env 파일 관리)
│   ├── constants/              # UserType, AuthState, ApiEndpoints
│   ├── network/                # ApiClient, HTTP 통신
│   │   ├── interceptors/       # AuthInterceptor, LoggingInterceptor, ErrorInterceptor
│   │   └── exceptions/         # ApiException
│   ├── routing/                # RouterNotifier (GoRouter 통합, 권한 기반 라우팅)
│   ├── providers/              # 전역 Riverpod providers (loadingProvider, errorMessageProvider)
│   ├── auth/                   # UserRole 등 인증 관련 유틸리티
│   ├── theme/                  # 테마 설정
│   └── utils/                  # 유틸리티 함수
│
├── shared/                     # 모든 모듈에서 공통 사용
│   ├── widgets/                # 재사용 가능한 UI 컴포넌트
│   │                           # FullScreenImageBackground, PageHeaderText
│   │                           # PrimaryActionButton, SectionDivider, SeparatorWidget
│   │                           # CommonNavigationBar, AuthStatusWidget, ApiTestWidget
│   ├── constants/              # 공통 상수
│   ├── themes/                 # 공통 테마
│   └── utils/                  # 공통 유틸리티
│
├── domain/                     # 전역 도메인 레이어
│   ├── entities/               # User 등 핵심 엔티티
│   ├── repositories/           # 전역 레포지토리 인터페이스
│   └── usecases/               # 전역 유스케이스
│
├── data/                       # 전역 데이터 레이어
│   ├── datasources/            # AuthRemoteDataSource 등 공통 데이터소스
│   ├── models/                 # 데이터 모델
│   └── repositories/           # 레포지토리 구현
│
├── app/                        # 앱 진입점
│   └── app.dart                # BuildingManageApp (MaterialApp 설정)
│
└── main.dart                   # 앱 시작점 (환경 초기화, ProviderScope)
```

### 각 모듈 내부 구조 (Clean Architecture)
각 `modules/` 하위 모듈은 **완전한 Clean Architecture 레이어**를 가집니다:

- **data/** - 데이터 레이어
  - `datasources/` - API 통신, 로컬 DB 등 외부 데이터 소스
  - `models/` - DTO(Data Transfer Object), API 응답 모델
  - `repositories/` - 레포지토리 구현 (도메인 레포지토리 인터페이스 구현)

- **domain/** - 도메인 레이어 (비즈니스 로직)
  - `entities/` - 핵심 비즈니스 엔티티
  - `repositories/` - 레포지토리 인터페이스 (추상화)
  - `usecases/` - 비즈니스 로직, 유스케이스

- **presentation/** - UI 레이어
  - `providers/` - Riverpod 상태 관리 (StateNotifier, Provider 등)
  - `screens/` - 화면 위젯 (페이지)
  - `widgets/` - 해당 모듈 전용 재사용 위젯

- **routing/** - 모듈별 라우팅 설정 (선택적)

### 상태 관리 및 의존성 주입
- **Riverpod 2.6.1**: 모든 상태 관리 및 의존성 주입에 사용
- **Provider 위치**: 각 모듈의 `presentation/providers/` 또는 `core/providers/`
- **주요 전역 Provider** (`lib/modules/auth/presentation/providers/auth_state_provider.dart`):
  - `authStateProvider`: StateNotifierProvider<AuthStateNotifier, AuthState> - 인증 상태 관리
  - `currentUserProvider`: Provider<User?> - 현재 로그인 사용자 정보
  - `isAuthenticatedProvider`: Provider<bool> - 인증 여부 확인
- **기타 전역 Provider**:
  - `routerProvider`: GoRouter 인스턴스 (`lib/core/providers/router_provider.dart`)
  - `apiClientProvider`: Dio 기반 API 클라이언트 (`lib/core/network/api_client.dart`)
  - `loadingProvider`, `errorMessageProvider`: 전역 로딩/에러 상태 (`lib/core/providers/app_providers.dart`)
  - `authRemoteDataSourceProvider`: 인증 API 데이터소스 (`lib/data/datasources/auth_remote_datasource.dart`)

### 라우팅 시스템
- **GoRouter 14.6.2**: 선언적 라우팅 및 권한 기반 리다이렉트
- **RouterNotifier** (`lib/core/routing/router_notifier.dart`):
  - `ChangeNotifier`를 상속받아 GoRouter와 연동
  - `authStateProvider`와 `currentUserProvider`를 감시하여 자동 리다이렉트
  - 보호된 경로는 인증 상태 및 사용자 타입 검증 후 접근 허용
  - 잘못된 권한 접근 시 해당 사용자의 기본 대시보드로 리다이렉트

- **경로 규칙**:
  - **공개 경로**:
    - `/` - 메인 홈 (역할 선택, MainHomeScreen)
    - `/admin-login-selection` - 관리자 로그인 선택
    - `/user-login` - 입주민 로그인
    - `/admin-login` - 관리자 로그인
    - `/manager-login` - 담당자 로그인
    - `/headquarters-login` - 본사 로그인
    - `/resident-signup` - 입주민 회원가입

  - **보호된 경로 (인증 필요)**:
    - `/user/dashboard` - 입주민 대시보드
    - `/admin/dashboard` - 관리자 대시보드 (AdminDashboardScreen)
    - `/admin/staff-account-issuance` - 담당자 계정 발급
    - `/manager/dashboard` - 담당자 대시보드
    - `/headquarters/dashboard` - 본사 대시보드 (HeadquartersDashboardScreen)
    - `/headquarters/building-management` - 건물 관리
    - `/headquarters/building-registration` - 건물 등록
    - `/headquarters/department-creation` - 부서 생성
    - `/headquarters/admin-account-issuance` - 관리자 계정 발급

- **리다이렉트 로직**:
  - 미인증 사용자가 보호된 경로 접근 시 → 해당 역할의 로그인 화면으로 리다이렉트
  - 인증된 사용자가 다른 역할의 경로 접근 시 → 자신의 기본 대시보드로 리다이렉트

### API 통신
- **ApiClient** (`lib/core/network/api_client.dart`):
  - **Dio 5.7.0** 기반 싱글톤 HTTP 클라이언트
  - `main.dart`에서 `ApiClient().initialize()` 호출하여 초기화
  - BaseOptions 설정: baseUrl, connectTimeout, receiveTimeout, headers
  - 모든 HTTP 메서드 지원: GET, POST, PUT, DELETE, PATCH

- **환경 설정** (`lib/core/config/app_config.dart`):
  - `.env` 파일에서 환경 변수 로드 (flutter_dotenv 5.1.0 사용)
  - `AppConfig.apiBaseUrl`: 전체 API URL (`{baseUrl}/api/{version}`)
  - 설정 가능 항목: API_BASE_URL, API_VERSION, ENVIRONMENT, 타임아웃, 디버그 모드

- **Interceptor 체계** (`lib/core/network/interceptors/`):
  - **AuthInterceptor**:
    - 모든 요청에 자동으로 JWT Access Token 첨부 (Authorization: Bearer)
    - 401 에러 시 Refresh Token으로 자동 갱신 후 재요청
    - SharedPreferences에 토큰 저장/로드 (`access_token`, `refresh_token`)
  - **LoggingInterceptor**:
    - `AppConfig.isDebug`가 true일 때만 활성화
    - 요청/응답 전체 로깅 (URL, headers, body, status code)
  - **ErrorInterceptor**:
    - API 에러 통합 처리 및 사용자 친화적 에러 메시지 변환
    - `ApiException` 클래스로 에러 타입 분류

- **API 엔드포인트** (`lib/core/constants/api_endpoints.dart`):
  - 모든 API 경로를 상수로 관리
  - 주요 엔드포인트 그룹: auth, user, admin, manager, headquarters, common
  - 예시: `ApiEndpoints.residentLogin`, `ApiEndpoints.departments`

- **토큰 관리**:
  - SharedPreferences 2.3.3 사용
  - 저장: `access_token`, `refresh_token`
  - `AuthInterceptor`에서 자동 토큰 첨부 및 갱신
  - `AuthStateNotifier.checkAutoLogin()`에서 앱 시작 시 토큰 유효성 검사

### 인증 시스템
- **JWT 기반 인증**:
  - Access Token + Refresh Token 구조
  - `AuthInterceptor`가 401 에러 시 자동으로 Refresh Token으로 갱신
  - 토큰은 SharedPreferences에 영구 저장

- **AuthStateNotifier** (`lib/modules/auth/presentation/providers/auth_state_provider.dart`):
  - `StateNotifier<AuthState>`를 상속받아 인증 상태 관리
  - 주요 메서드:
    - `setAuthenticated(User, accessToken, [refreshToken])`: 로그인 성공 처리
    - `setUnauthenticated()`: 로그아웃 처리
    - `loginSuccess(userData, accessToken)`: API 응답을 User 엔티티로 변환
    - `checkAutoLogin(authDataSource)`: 앱 시작 시 저장된 토큰으로 자동 로그인 시도
    - `logout()`: 토큰 삭제 및 미인증 상태로 전환

- **AuthState** enum (`lib/core/constants/auth_states.dart`):
  - `initial`: 초기 상태
  - `loading`: 인증 처리 중
  - `authenticated`: 인증 완료
  - `unauthenticated`: 미인증
  - `error`: 인증 에러

- **UserType** enum (`lib/core/constants/user_types.dart`):
  - `user`: 입주민/유저
  - `admin`: 관리자 (건물별)
  - `manager`: 담당자 (관리자가 발급)
  - `headquarters`: 본사 (최상위 권한)

- **User 엔티티** (`lib/domain/entities/user.dart`):
  - Equatable 상속으로 불변성 보장
  - 주요 필드: id, email, name, userType, buildingId, dong, ho, permissions
  - `fromJson()`: API 응답(role 필드)을 User 엔티티로 변환
  - `toJson()`: User 엔티티를 JSON으로 직렬화
  - `copyWith()`: 불변 객체 업데이트

- **자동 로그인 흐름** (`main.dart`):
  1. 앱 시작 시 `checkAutoLogin()` 호출
  2. 저장된 Access/Refresh Token 확인
  3. Refresh Token으로 새 Access Token 발급 시도
  4. 성공 시 `authenticated` 상태로 전환, 실패 시 `unauthenticated`

### UI 컴포넌트 시스템
- **Material 3**: 전체 앱에서 Material Design 3 사용 (`useMaterial3: true`)
- **Shared Widgets** (`lib/shared/widgets/`):
  - `FullScreenImageBackground`: 전체 화면 배경 이미지 위젯
  - `PageHeaderText`: 표준 헤더 텍스트 (#464A4D, 16px, 굵기 700)
  - `PrimaryActionButton`: 주요 액션 버튼 (로그인, 가입 등)
  - `SectionDivider`: 섹션 구분선
  - `SeparatorWidget`: Figma 디자인 시스템의 Separator 컴포넌트 (배경색 #F2F8FC)
  - `CommonNavigationBar`: 공통 네비게이션 바
  - `AuthStatusWidget`: 인증 상태 표시 위젯 (디버깅용)
  - `ApiTestWidget`: API 연결 테스트 위젯 (디버깅용)

- **UI 라이브러리**:
  - `flutter_svg 2.0.16`: SVG 이미지 렌더링
  - `cached_network_image 3.4.1`: 네트워크 이미지 캐싱
  - `image_picker 1.0.7`: 이미지 선택 (프로필 사진 등)

- **Assets**:
  - `assets/home.png`: 메인 홈 배경
  - `assets/headQuartersHome.png`: 본사 대시보드 배경
  - `assets/icons/`: 아이콘 리소스

## 주요 기술 스택

### Core
- **Flutter** 3.x (Dart SDK ^3.8.1)
- **cupertino_icons** ^1.0.8

### 상태 관리 및 라우팅
- **flutter_riverpod** ^2.6.1 - 의존성 주입 및 상태 관리
- **go_router** ^14.6.2 - 선언적 라우팅
- **equatable** ^2.0.7 - 불변 객체 비교

### 네트워크 및 데이터
- **dio** ^5.7.0 - HTTP 클라이언트
- **shared_preferences** ^2.3.3 - 로컬 키-값 저장소
- **hive** ^2.2.3 - NoSQL 로컬 데이터베이스
- **hive_flutter** ^1.1.0 - Hive Flutter 통합

### UI 컴포넌트
- **flutter_svg** ^2.0.16 - SVG 렌더링
- **cached_network_image** ^3.4.1 - 네트워크 이미지 캐싱
- **image_picker** ^1.0.7 - 이미지 선택
- **table_calendar** ^3.1.2 - 캘린더 UI (출퇴근 기록 조회 등)

### 환경 설정 및 유틸리티
- **flutter_dotenv** ^5.1.0 - 환경 변수 관리
- **json_annotation** ^4.9.0 - JSON 직렬화 어노테이션
- **firebase_core** ^4.2.0 - Firebase 초기화
- **intl** - 날짜/시간 포맷팅 (flutter_localizations SDK 포함)

### 보안
- **flutter_secure_storage** ^9.2.2 - 민감한 데이터 암호화 저장

### 개발 의존성 (dev_dependencies)
- **flutter_test** - Flutter 테스트 프레임워크
- **flutter_lints** ^5.0.0 - Flutter 권장 Lint 규칙
- **build_runner** ^2.4.13 - 코드 생성 러너
- **json_serializable** ^6.8.0 - JSON 직렬화 코드 생성
- **hive_generator** ^2.0.1 - Hive 타입 어댑터 생성
- **mockito** ^5.4.4 - 테스트용 Mock 객체 생성

## 코드 생성 및 직렬화
- **build_runner 2.4.13**: JSON 직렬화, Hive 타입 어댑터 자동 생성
- **json_serializable 6.8.0**: `@JsonSerializable()` 어노테이션으로 JSON 변환 코드 생성
- **hive_generator 2.0.1**: `@HiveType()` 어노테이션으로 Hive 타입 어댑터 생성

### 사용법
1. 엔티티/모델 클래스에 어노테이션 추가:
```dart
import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';  // 생성될 파일

@JsonSerializable()
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

2. 코드 생성 실행:
```bash
flutter pub run build_runner build                        # 일회성 빌드
flutter pub run build_runner build --delete-conflicting-outputs  # 충돌 파일 삭제 후 빌드
flutter pub run build_runner watch                        # 자동 감지 모드
```

## 환경 변수 (.env)
프로젝트 루트에 `.env` 파일 필수 (`.gitignore`에 포함):

```env
# API Configuration
API_BASE_URL=http://building-manager-staging-env.eba-bn9wmcht.ap-northeast-2.elasticbeanstalk.com
API_VERSION=v1

# Environment
ENVIRONMENT=staging  # development, staging, production

# Timeout settings (milliseconds)
API_CONNECT_TIMEOUT=30000
API_RECEIVE_TIMEOUT=30000

# Debug settings
API_DEBUG=true  # true이면 LoggingInterceptor 활성화
```

### 환경별 설정
- `ENVIRONMENT=development`: 개발 환경
- `ENVIRONMENT=staging`: 스테이징 환경 (현재 기본값)
- `ENVIRONMENT=production`: 프로덕션 환경

`AppConfig` 클래스에서 `isDevelopment`, `isStaging`, `isProduction` 메서드로 확인 가능

## 주요 비즈니스 로직

### 입주민 회원가입 (`ResidentSignupScreen`)
- **3단계 폼 구조**:
  - Step 1 (`resident_signup_step1.dart`): 동/호수 입력 및 검증
  - Step 2 (`resident_signup_step2.dart`): 비밀번호 설정
  - Step 3 (`resident_signup_step3.dart`): 사용자 정보 (이름, 전화번호 등)
- **상태 관리**: `SignupFormProvider` (Riverpod StateNotifier)
  - 각 단계의 폼 데이터를 중앙에서 관리하여 단계 간 데이터 보존
  - 다음 단계로 진행 전 유효성 검사
- **API**: `ApiEndpoints.residentRegister` (POST)
- **데이터소스**: `ResidentAuthRemoteDataSource`

### 관리자 대시보드 (`AdminDashboardScreen`)
- 로그인 후 진입하는 관리자 메인 화면
- 주요 기능:
  - 담당자 계정 발급 (StaffAccountIssuanceScreen으로 이동)
  - 입주민 관리
  - 건물별 공지사항 관리
  - 시설물 관리

### 담당자 계정 발급 (`StaffAccountIssuanceScreen`)
- 관리자가 담당자 계정을 생성하는 화면
- **상태 관리**: `staffProvider` (Riverpod)
- **API**: `ApiEndpoints.managerRegister` (POST)
- **데이터소스**: `StaffRemoteDataSource`

### 본사 대시보드 (`HeadquartersDashboardScreen`)
- 로그인 후 진입하는 본사 메인 화면
- 배경 이미지: `assets/headQuartersHome.png`
- 주요 기능:
  - 건물 관리 (BuildingManagementScreen)
  - 건물 등록 (BuildingRegistrationScreen)
  - 부서 생성 (DepartmentCreationScreen)
  - 관리자 계정 발급 (AdminAccountIssuanceScreen)

### 건물 관리 (`BuildingManagementScreen`)
- 본사에서 모든 건물 및 부서를 조회/관리하는 화면
- 주요 기능:
  - 부서 목록 표시 (리스트뷰)
  - 실시간 검색 (디바운스 500ms)
  - 부서별 상세 정보 표시
- **API**: `ApiEndpoints.departments` (`/common/departments`, GET)
- **데이터소스**: `DepartmentRemoteDataSource`

### 건물 등록 (`BuildingRegistrationScreen`)
- 본사에서 새로운 건물을 등록하는 화면
- **API**: `ApiEndpoints.buildings` (POST)
- **데이터소스**: `BuildingRemoteDataSource`

### 부서 생성 (`DepartmentCreationScreen`)
- 건물 내 부서를 생성하는 화면
- **API**: `ApiEndpoints.departments` (POST)

### 관리자 계정 발급 (`AdminAccountIssuanceScreen` - headquarters)
- 본사에서 건물별 관리자 계정을 발급하는 화면
- **API**: `ApiEndpoints.adminRegister` (POST)

### 담당자 출퇴근 관리 (Manager Module)
- **출퇴근 기록** (`AttendanceHistoryScreen`):
  - table_calendar 위젯으로 월별 출퇴근 기록 표시
  - 일별 출근/퇴근 시간 확인
  - **API**: `ApiEndpoints.attendanceHistory` (GET)
  - **데이터소스**: `AttendanceRemoteDataSource`
- **출퇴근 체크** (`ManagerDashboardScreen`):
  - 출근/퇴근 버튼으로 실시간 기록
  - **API**: `ApiEndpoints.checkIn`, `ApiEndpoints.checkOut` (POST)

### 입주민 기능 (Resident Module)
- **공지사항 조회**:
  - 건물별 공지사항 목록 및 상세 조회
  - **API**: `ApiEndpoints.notices` (GET)
  - **데이터소스**: `NoticeRemoteDataSource`
- **민원 등록** (`ComplaintCreateScreen` → `ComplaintCompleteScreen`):
  - 부서 선택, 민원 내용 작성, 이미지 첨부
  - **API**: `ApiEndpoints.complaints` (POST)
  - **데이터소스**: `ComplaintRemoteDataSource`, `DepartmentRemoteDataSource`

### 관리자 기능 (Admin Module)
- **담당자 관리**:
  - 담당자 목록 조회 (`StaffManagementScreen`)
  - 담당자 정보 수정 (`StaffEditScreen`)
  - 담당자 계정 발급 (`StaffAccountIssuanceScreen`)
  - **데이터소스**: `StaffRemoteDataSource`
- **입주민 관리**:
  - 입주민 목록 조회 및 관리 (`ResidentManagementScreen`)
  - **데이터소스**: `ResidentRemoteDataSource`
- **공지사항 관리**:
  - 공지사항 작성 (`NoticeCreateScreen`)
  - 공지사항 목록 관리 (`NoticeManagementScreen`)

### 이미지 업로드 시스템
- **ImageUploadService** (`lib/modules/common/services/image_upload_service.dart`):
  - S3 Presigned URL 방식으로 이미지 업로드
  - 2단계 프로세스: 1) Presigned URL 요청 → 2) S3 직접 업로드
  - 사용 예시: 부서 로고, 프로필 사진, 민원 첨부 이미지
- **UploadRemoteDataSource**:
  - `getPresignedUrl()`: 업로드 URL 및 최종 파일 URL 반환
  - `uploadToS3()`: 바이너리 데이터를 S3에 직접 업로드
- **Provider**: `imageUploadServiceProvider`
- **지원 포맷**: JPEG, PNG, GIF, WebP

## 코딩 규칙 및 컨벤션

### Lint 및 분석
- **flutter_lints 5.0.0**: Flutter 팀 권장 Lint 규칙 적용
- `analysis_options.yaml`에서 Lint 규칙 설정
- `flutter analyze` 명령으로 정적 분석 수행
- 코드 커밋 전 Lint 에러 0개 유지

### 명명 규칙 (Dart 표준)
- **클래스/Enum/타입**: PascalCase (예: `UserType`, `AuthState`, `ApiClient`)
- **변수/메서드/함수**: camelCase (예: `currentUser`, `checkAutoLogin()`)
- **상수**: lowerCamelCase (예: `apiClientProvider`) 또는 SCREAMING_SNAKE_CASE (예: `MAX_RETRY_COUNT`)
- **파일명**: snake_case (예: `user_login_screen.dart`, `auth_state_provider.dart`)
- **Private 멤버**: 언더스코어(_) 접두사 (예: `_currentUser`, `_setupRouter()`)

### Provider 명명 규칙
- Provider는 항상 `xxxProvider` 형식으로 명명
- 예시:
  - `authStateProvider`: StateNotifierProvider
  - `currentUserProvider`: Provider
  - `apiClientProvider`: Provider
  - `signupFormProvider`: StateNotifierProvider

### 위젯 및 성능 최적화
- **const 생성자**: 가능한 모든 위젯에 `const` 키워드 사용하여 불필요한 리빌드 방지
  ```dart
  const Text('Hello')  // Good
  Text('Hello')        // Avoid
  ```
- **StatelessWidget vs StatefulWidget**: 상태가 없으면 StatelessWidget 사용
- **Riverpod ConsumerWidget**: 상태 감시가 필요한 경우 ConsumerWidget 사용

### 파일 구조
- 한 파일에 하나의 주요 클래스만 정의 (유틸리티 제외)
- part/part of 사용 시 생성 파일은 `.g.dart` 확장자
- import 순서:
  1. Dart SDK imports (`dart:xxx`)
  2. Flutter imports (`package:flutter/xxx`)
  3. 외부 패키지 imports (`package:xxx`)
  4. 프로젝트 내부 imports (상대 경로 또는 절대 경로)

### Clean Architecture 규칙
- **의존성 방향**: presentation → domain ← data
- domain 레이어는 외부 패키지 의존성 최소화 (Equatable 정도만 허용)
- data 레이어는 domain의 repository 인터페이스를 구현
- presentation 레이어는 domain의 usecase를 호출

### 주석 및 문서화
- 공개 API에는 dartdoc 주석(`///`) 작성
- 복잡한 로직에는 설명 주석 추가
- TODO 주석은 `// TODO:` 형식으로 작성하고 이슈 번호 첨부

## 일반적인 개발 패턴

### 새로운 화면 추가하기
1. 해당 모듈의 `presentation/screens/` 폴더에 화면 파일 생성
2. `lib/core/providers/router_provider.dart`에 라우트 추가
3. 필요한 경우 `presentation/providers/`에 상태 관리 Provider 생성
4. API 통신이 필요한 경우:
   - `data/datasources/`에 RemoteDataSource 생성
   - `lib/core/constants/api_endpoints.dart`에 엔드포인트 추가
5. 공통 경로 보호가 필요한 경우 `RouterNotifier`에 리다이렉트 로직 추가

### API 연동 패턴
```dart
// 1. API 엔드포인트 정의 (lib/core/constants/api_endpoints.dart)
static const String myEndpoint = '/my/endpoint';

// 2. RemoteDataSource 생성 (lib/modules/[module]/data/datasources/)
class MyRemoteDataSource {
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchData() async {
    final response = await _apiClient.get(ApiEndpoints.myEndpoint);
    return response.data;
  }
}

// 3. Provider 등록
final myRemoteDataSourceProvider = Provider((ref) {
  return MyRemoteDataSource(ref.watch(apiClientProvider));
});

// 4. 화면에서 사용 (ConsumerWidget)
final dataSource = ref.read(myRemoteDataSourceProvider);
final result = await dataSource.fetchData();
```

### 이미지 업로드 패턴
```dart
// 1. ImageUploadService 사용
final imageUploadService = ref.read(imageUploadServiceProvider);

// 2. 파일 선택 (image_picker)
final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
final bytes = await pickedFile!.readAsBytes();

// 3. S3 업로드
final imageUrl = await imageUploadService.uploadImage(
  fileBytes: bytes,
  fileName: 'my-image.jpg',
  contentType: 'image/jpeg',
  folder: 'my-folder',
);
```

### 날짜/시간 포맷팅 패턴
```dart
// intl 패키지 사용 (flutter_localizations 포함)
import 'package:intl/intl.dart';

// 날짜 포맷
final formatter = DateFormat('yyyy-MM-dd');
final dateString = formatter.format(DateTime.now());

// 시간 포맷
final timeFormatter = DateFormat('HH:mm');
final timeString = timeFormatter.format(DateTime.now());
```

## 주의 사항 및 베스트 프랙티스

### 모듈 구조
- 새 모듈 추가 시 `modules/` 아래 독립 폴더 생성
- 각 모듈은 data/domain/presentation 레이어를 완전하게 구성
- 모듈 간 의존성은 최소화하고, 필요시 `modules/common/`을 통해 공유

### API 개발
- API 엔드포인트는 반드시 `lib/core/constants/api_endpoints.dart`에 정의
- 하드코딩된 URL 사용 금지
- 모든 API 호출은 try-catch로 에러 처리
- `ApiClient` 인스턴스를 직접 생성하지 말고 `apiClientProvider` 사용

### UI 컴포넌트
- 공통 UI 컴포넌트는 `shared/widgets/`에 배치
- 특정 모듈 전용 위젯은 해당 모듈의 `presentation/widgets/`에 배치
- 재사용 가능성을 고려하여 위젯 설계
- 하드코딩된 색상/크기 대신 테마 또는 상수 사용

### 상태 관리
- 전역 상태는 `core/providers/`에, 모듈별 상태는 `modules/[module]/presentation/providers/`에 배치
- Provider는 가능한 작게 유지하여 불필요한 리빌드 방지
- `watch`, `read`, `listen`의 차이를 이해하고 적절히 사용

### 인증 및 보안
- 토큰 갱신은 `AuthInterceptor`가 자동 처리하므로 직접 구현하지 말 것
- **민감한 정보 저장**:
  - 일반 설정: SharedPreferences 사용
  - 보안 정보: flutter_secure_storage 사용 (암호화된 저장소)
- `.env` 파일은 절대 Git에 커밋하지 말 것 (`.gitignore`에 포함됨)
- S3 업로드 시 Presigned URL 방식 사용으로 AWS 자격증명 노출 방지

### 에러 처리
- 모든 API 호출은 try-catch로 감싸기
- 사용자에게 친화적인 에러 메시지 표시
- 개발 모드에서는 자세한 에러 로그 출력, 프로덕션에서는 최소화

### 테스트
- 중요한 비즈니스 로직은 반드시 유닛 테스트 작성
- Widget 테스트로 UI 동작 검증
- Mockito를 사용하여 외부 의존성 모킹

### 성능 최적화
- 리스트는 `ListView.builder` 사용 (대량 데이터)
- 이미지는 `cached_network_image` 사용
- 불필요한 `setState()` 호출 최소화
- 무거운 연산은 별도 Isolate에서 실행 고려

## 디버깅 및 문제 해결

### API 통신 디버깅
- **LoggingInterceptor**: `.env` 파일에서 `API_DEBUG=true` 설정 시 모든 HTTP 요청/응답 로깅
- **ApiTestWidget**: 개발 중 API 연결 테스트용 위젯 (`lib/shared/widgets/`)
- **AuthStatusWidget**: 인증 상태 실시간 확인 위젯 (디버깅용)

### 일반적인 문제 및 해결
1. **"401 Unauthorized" 에러**:
   - AuthInterceptor가 자동으로 토큰 갱신 시도
   - 갱신 실패 시 로그아웃 처리됨
   - SharedPreferences에서 토큰 확인: `access_token`, `refresh_token`

2. **코드 생성 관련 에러**:
   - `*.g.dart` 파일 충돌 시: `flutter pub run build_runner build --delete-conflicting-outputs`
   - part/part of 구문 확인

3. **환경 변수 로드 실패**:
   - `.env` 파일이 프로젝트 루트에 있는지 확인
   - `pubspec.yaml`의 assets에 `.env` 포함 확인
   - `main.dart`에서 `await dotenv.load()` 호출 확인

4. **라우팅 에러**:
   - `RouterNotifier`의 리다이렉트 로직 확인
   - `authStateProvider`와 `currentUserProvider` 상태 확인
   - GoRouter 경로 정의가 정확한지 확인

5. **이미지 업로드 실패**:
   - Presigned URL 응답 구조 확인 (`uploadUrl`, `fileUrl` 필드)
   - S3 CORS 설정 확인
   - Content-Type이 올바른지 확인

## Clean Architecture 적용 현황 (2025-11-13 업데이트)

### 모듈별 Clean Architecture 적용 상태

모든 주요 모듈에 Clean Architecture가 완전히 적용되었습니다:

#### ✅ Admin 모듈 (완료)
- **Domain Layer**: Staff, ResidentInfo 엔티티, Repository 인터페이스, UseCase 구현 완료
- **Data Layer**: StaffRemoteDataSource, ResidentRemoteDataSource, Repository 구현 완료
- **Presentation Layer**: UseCase를 통한 비즈니스 로직 호출
- **주요 파일**:
  - `lib/modules/admin/domain/entities/staff.dart` - Staff 엔티티 (staffCode 필드 포함)
  - `lib/modules/admin/domain/usecases/get_staff_detail_usecase.dart`
  - `lib/modules/admin/data/repositories/staff_repository_impl.dart`
  - `lib/modules/admin/presentation/providers/admin_providers.dart`

#### ✅ Resident 모듈 (완료)
- **Domain Layer**: Complaint, Notice, Department 엔티티, Repository 인터페이스, UseCase 구현 완료
- **Data Layer**: ResidentAuthRemoteDataSource, ComplaintRemoteDataSource 등, Repository 구현 완료
- **Presentation Layer**: UseCase를 통한 비즈니스 로직 호출
- **주요 파일**:
  - `lib/modules/resident/domain/usecases/create_complaint_usecase.dart`
  - `lib/modules/resident/data/repositories/complaint_repository_impl.dart`
  - `lib/modules/resident/presentation/providers/resident_providers.dart`

#### ✅ Manager 모듈 (2025-11-13 완료)
- **Domain Layer**:
  - 엔티티: `AttendanceRecord`, `MonthlyAttendanceResponse`
  - 레포지토리: `AttendanceRepository` 인터페이스
  - 유스케이스: `CheckInUseCase`, `CheckOutUseCase`, `GetMonthlyAttendanceUseCase`
- **Data Layer**:
  - 데이터소스: `AttendanceRemoteDataSource`
  - 레포지토리 구현: `AttendanceRepositoryImpl`
- **Presentation Layer**:
  - Providers: `manager_providers.dart` (UseCase DI 설정)
  - UseCase 통합: `attendance_provider.dart`, `attendance_history_provider.dart`
- **주요 기능**: 출퇴근 관리 (체크인/체크아웃, 월별 기록 조회)
- **주요 파일**:
  - `lib/modules/manager/domain/repositories/attendance_repository.dart`
  - `lib/modules/manager/domain/usecases/check_in_usecase.dart`
  - `lib/modules/manager/data/repositories/attendance_repository_impl.dart`
  - `lib/modules/manager/presentation/providers/manager_providers.dart`

#### ✅ Headquarters 모듈 (2025-11-13 완료)
- **Domain Layer**:
  - 엔티티: `Building`
  - 레포지토리: `BuildingRepository` 인터페이스
  - 유스케이스: `CreateBuildingUseCase`, `GetBuildingsUseCase`
- **Data Layer**:
  - 데이터소스: `BuildingRemoteDataSource`, `DepartmentRemoteDataSource`, `AdminAccountRemoteDataSource`
  - 레포지토리 구현: `BuildingRepositoryImpl`
- **Presentation Layer**:
  - Providers: `headquarters_providers.dart` (UseCase DI 설정)
- **주요 기능**: 건물 관리, 부서 생성, 관리자 계정 발급
- **확장 가능**: Department, AdminAccount 관련 UseCase는 동일한 패턴으로 추가 가능
- **주요 파일**:
  - `lib/modules/headquarters/domain/entities/building.dart`
  - `lib/modules/headquarters/domain/repositories/building_repository.dart`
  - `lib/modules/headquarters/domain/usecases/create_building_usecase.dart`
  - `lib/modules/headquarters/data/repositories/building_repository_impl.dart`
  - `lib/modules/headquarters/presentation/providers/headquarters_providers.dart`

### Clean Architecture 적용 패턴

#### 1. Domain Layer (비즈니스 로직 중심)
```dart
// 1. Entity - 핵심 비즈니스 엔티티
class Staff extends Equatable {
  final String id;
  final String staffCode;
  final String name;
  // ...
}

// 2. Repository Interface - 추상화된 데이터 접근 계층
abstract class StaffRepository {
  Future<Staff> getStaffDetail({required String staffId});
  Future<List<Staff>> getStaffs();
  // ...
}

// 3. UseCase - 비즈니스 로직 캡슐화
class GetStaffDetailUseCase {
  final StaffRepository _repository;

  Future<Staff> execute({required String staffId}) async {
    if (staffId.trim().isEmpty) {
      throw Exception('담당자 ID가 유효하지 않습니다.');
    }
    return await _repository.getStaffDetail(staffId: staffId);
  }
}
```

#### 2. Data Layer (데이터 접근)
```dart
// 1. RemoteDataSource - API 통신
class StaffRemoteDataSource {
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getStaffDetail({required String staffId}) async {
    final response = await _apiClient.get('/staffs/$staffId');
    return response.data;
  }
}

// 2. Repository Implementation - 인터페이스 구현
class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource _dataSource;

  @override
  Future<Staff> getStaffDetail({required String staffId}) async {
    final response = await _dataSource.getStaffDetail(staffId: staffId);
    return Staff.fromJson(response['data']);
  }
}
```

#### 3. Presentation Layer (UI 및 상태 관리)
```dart
// 1. Providers - Riverpod DI 설정
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final dataSource = ref.watch(staffRemoteDataSourceProvider);
  return StaffRepositoryImpl(dataSource);
});

final getStaffDetailUseCaseProvider = Provider<GetStaffDetailUseCase>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return GetStaffDetailUseCase(repository);
});

// 2. 화면에서 UseCase 사용
final getStaffDetailUseCase = ref.read(getStaffDetailUseCaseProvider);
final staff = await getStaffDetailUseCase.execute(staffId: widget.staffId);
```

### 의존성 방향

```
Presentation Layer (UI, Providers)
    ↓ (의존)
Domain Layer (Entities, Repositories Interface, UseCases)
    ↑ (구현)
Data Layer (DataSources, Repositories Implementation)
```

- **Domain Layer**는 외부 의존성이 없음 (순수 비즈니스 로직)
- **Data Layer**는 Domain의 Repository 인터페이스를 구현
- **Presentation Layer**는 Domain의 UseCase를 사용

### 새로운 기능 추가 시 권장 절차

1. **Domain Layer 먼저 구축**:
   - Entity 정의
   - Repository Interface 정의
   - UseCase 작성 (비즈니스 로직 포함)

2. **Data Layer 구현**:
   - RemoteDataSource 작성 (API 호출)
   - Repository Implementation 작성

3. **Presentation Layer 연동**:
   - Provider 설정 (DI)
   - 화면에서 UseCase 호출

4. **테스트**:
   - UseCase 단위 테스트
   - Repository Mock을 사용한 테스트
