# 현재 코드베이스 분석

## 기존 구현 현황

### 1. 이미 구현된 기능
✅ **메인 홈 화면** (`MainHomeScreen`)
- 배경 이미지가 있는 랜딩 페이지
- 유저 로그인, 관리자 로그인, 회원가입 버튼

✅ **유저 로그인 화면** (`UserLoginScreen`)
- 동/호수 기반 로그인 방식
- 비밀번호 입력
- 폼 validation
- 데모 비밀번호 ('1234') 하드코딩
- 비밀번호 찾기 링크 (미구현)

✅ **관리자 로그인 선택 화면** (`AdminLoginSelectionScreen`)
- 관리자/담당자/본사 선택 화면

✅ **공통 UI 컴포넌트**
- `PageHeaderText`: 페이지 헤더 텍스트
- `PrimaryActionButton`: 주요 액션 버튼
- `FullScreenImageBackground`: 전체 화면 배경 이미지

✅ **회원가입 화면** (`SignUpScreen`)

### 2. 현재 폴더 구조
```
lib/
├── features/
│   ├── auth/presentation/screens/
│   │   ├── user_login_screen.dart
│   │   ├── admin_login_selection_screen.dart
│   │   ├── manager_staff_login_screen.dart
│   │   └── headquarters_login_screen.dart
│   ├── landing/presentation/screens/
│   │   └── main_home_screen.dart
│   ├── registration/presentation/screens/
│   │   └── sign_up_screen.dart
│   └── common/presentation/
│       ├── screens/
│       └── widgets/
└── main.dart
```

## 분석 결과

### 장점
1. **멀티 유저 타입 지원**: 이미 4개 유저 타입 구분
2. **일관된 UI**: Material 3 디자인 사용
3. **재사용 가능한 컴포넌트**: 공통 위젯들 분리
4. **폼 검증**: 입력 validation 구현

### 개선이 필요한 부분

#### 1. 아키텍처
- **현재**: Feature-first 구조 사용
- **문제점**: 비즈니스 로직과 UI가 혼재
- **개선안**: Clean Architecture 적용

#### 2. 상태 관리
- **현재**: StatefulWidget만 사용
- **문제점**: 전역 상태 관리 없음
- **개선안**: Riverpod 도입

#### 3. 인증 시스템
- **현재**: 하드코딩된 데모 로직
- **문제점**: 실제 API 연동 없음
- **개선안**: JWT 기반 인증 구현

#### 4. 라우팅
- **현재**: Navigator.push 사용
- **문제점**: 라우팅 가드, 딥링크 지원 없음
- **개선안**: go_router 도입

#### 5. 데이터 레이어
- **현재**: 없음
- **문제점**: API 연동, 로컬 저장소 없음
- **개선안**: Repository 패턴 구현

## 마이그레이션 전략

### Phase 1: 코어 인프라 구축
1. Riverpod 상태 관리 도입
2. go_router 라우팅 설정
3. dio HTTP 클라이언트 설정
4. 환경 변수 설정

### Phase 2: 인증 시스템 리팩토링
1. AuthRepository 생성
2. User 엔티티 정의
3. JWT 토큰 관리
4. 로그인 상태 관리

### Phase 3: 기존 화면 마이그레이션
1. 로그인 화면들을 새 아키텍처로 이동
2. 상태 관리 적용
3. API 연동 준비

### Phase 4: 새로운 기능 추가
1. 유저 타입별 대시보드
2. 권한 기반 네비게이션
3. 실시간 알림 시스템

## 보존할 기존 코드

### UI 컴포넌트
- `PageHeaderText`: 재사용 가능
- `PrimaryActionButton`: 재사용 가능
- `FullScreenImageBackground`: 재사용 가능

### 화면 레이아웃
- 로그인 화면 UI 디자인 유지
- 메인 홈 화면 레이아웃 유지
- 기존 Material 3 테마 활용

### 폼 검증 로직
- TextFormField validation 로직
- 에러 메시지 표시 방식

## 다음 단계

1. **의존성 추가**: pubspec.yaml에 필요한 패키지들 추가
2. **환경 설정**: 개발/운영 환경 분리
3. **상태 관리 설정**: Riverpod Provider 구조 설계
4. **라우팅 설정**: go_router 경로 정의
5. **API 클라이언트**: dio 설정 및 인터셉터 구성