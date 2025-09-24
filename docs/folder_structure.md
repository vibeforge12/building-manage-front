# 건물관리 플랫폼 - 폴더 구조 및 아키텍처 문서

## 📋 프로젝트 개요

**건물 관리 시스템**: 하나의 Flutter 앱에서 4개 유저 타입을 지원하는 멀티 플랫폼 애플리케이션

### 지원 유저 타입
- 👤 **유저** (일반 거주자): 신고, 예약, 결제 기능
- 🏢 **관리자** (건물 관리자): 거주자 관리, 시설 관리, 신고 처리
- 🔧 **담당자** (유지보수): 작업 처리, 스케줄 관리
- 🏛️ **본사** (관리 본사): 전체 통합 관리, 분석

---

## 🏗️ 완성된 폴더 구조 (Clean Architecture + 유저 타입별 분리)

```
lib/
├── main.dart                      # 앱 진입점 (ProviderScope 적용)
├── app/
│   └── app.dart                   # MaterialApp.router 설정
├── core/                          # 핵심 공통 코드
│   ├── constants/
│   │   ├── auth_states.dart       # 인증 상태 enum (initial, loading, authenticated, etc.)
│   │   └── user_types.dart        # 유저 타입 enum (user, admin, manager, headquarters)
│   ├── providers/
│   │   ├── app_providers.dart     # 전역 상태 (loading, error)
│   │   └── router_provider.dart   # go_router Provider 설정
│   └── routing/
│       └── router_notifier.dart   # 라우팅 가드 및 권한 관리
├── domain/                        # 비즈니스 로직 레이어
│   ├── entities/
│   │   └── user.dart             # 사용자 엔티티 (Equatable 사용)
│   ├── repositories/             # Repository 인터페이스 (추후 구현)
│   └── usecases/                 # 비즈니스 유스케이스 (추후 구현)
├── data/                         # 데이터 레이어
│   ├── models/                   # API 모델 (추후 구현)
│   ├── repositories/             # Repository 구현 (추후 구현)
│   └── datasources/              # API/Local 데이터 소스 (추후 구현)
└── presentation/                 # UI 레이어 (유저 타입별 분리)
    ├── auth/                     # 공통 인증 관련
    │   ├── screens/
    │   │   ├── main_home_screen.dart          # 🏠 메인 홈 (로그인 선택)
    │   │   ├── admin_login_selection_screen.dart # 👑 관리자 타입 선택
    │   │   └── sign_up_screen.dart            # ✍️ 회원가입 (준비 중)
    │   ├── widgets/              # 인증 관련 위젯
    │   └── providers/
    │       └── auth_state_provider.dart      # 🔐 인증 상태 관리 (Riverpod)
    ├── user/                     # 👤 일반 유저 (거주자) 전용
    │   ├── screens/
    │   │   └── user_login_screen.dart        # 동/호수 기반 로그인
    │   ├── widgets/              # 유저 전용 위젯 (추후 구현)
    │   └── providers/            # 유저 상태 관리 (추후 구현)
    ├── admin/                    # 🏢 관리자 전용
    │   ├── screens/              # 관리자 화면들 (추후 구현)
    │   ├── widgets/              # 관리자 전용 위젯 (추후 구현)
    │   └── providers/            # 관리자 상태 관리 (추후 구현)
    ├── manager/                  # 🔧 담당자 (유지보수) 전용
    │   ├── screens/
    │   │   └── manager_staff_login_screen.dart # 관리자 코드 기반 로그인
    │   ├── widgets/              # 담당자 전용 위젯 (추후 구현)
    │   └── providers/            # 담당자 상태 관리 (추후 구현)
    ├── headquarters/             # 🏛️ 본사 전용
    │   ├── screens/
    │   │   └── headquarters_login_screen.dart  # 이메일/비밀번호 로그인
    │   ├── widgets/              # 본사 전용 위젯 (추후 구현)
    │   └── providers/            # 본사 상태 관리 (추후 구현)
    └── common/                   # 🔧 공통 UI 컴포넌트
        └── widgets/
            ├── auth_status_widget.dart        # 인증 상태 디버그 위젯
            ├── full_screen_image_background.dart # 전체 화면 배경 이미지
            ├── page_header_text.dart          # 페이지 헤더 텍스트
            └── primary_action_button.dart     # 주요 액션 버튼
```

---

## 🔄 코드 흐름 및 아키텍처

### 1. 앱 초기화 흐름
```
main.dart
 ↓ ProviderScope 래핑
app.dart (MaterialApp.router)
 ↓ routerProvider 감시
RouterNotifier
 ↓ 인증 상태 변화 감지
AuthStateProvider
```

### 2. 라우팅 시스템 (go_router + Riverpod)

#### 라우팅 구조
```
/ → 메인 홈 (로그인 선택)
├── /user-login → 👤 유저 로그인
├── /admin-login-selection → 👑 관리자 타입 선택
│   ├── /manager-login → 🔧 담당자 로그인
│   └── /headquarters-login → 🏛️ 본사 로그인
└── /sign-up → ✍️ 회원가입

🔒 보호된 경로 (인증 필요)
├── /user/dashboard → 👤 유저 대시보드
├── /admin/dashboard → 🏢 관리자 대시보드
├── /manager/dashboard → 🔧 담당자 대시보드
└── /headquarters/dashboard → 🏛️ 본사 대시보드
```

#### 권한 기반 라우팅 가드
```dart
// RouterNotifier.dart - 핵심 로직
1. 인증 상태 변화 감지 (authStateProvider, currentUserProvider)
2. 보호된 경로 접근 시 권한 검증
3. 미인증 → 해당 로그인 페이지로 자동 리다이렉트
4. 권한 불일치 → 해당 유저 타입 대시보드로 이동
```

### 3. 상태 관리 (Riverpod)

#### AuthStateProvider 구조
```dart
class AuthStateNotifier extends StateNotifier<AuthState> {
  // 상태: initial, loading, authenticated, unauthenticated, error
  User? _currentUser;           // 현재 로그인 사용자
  String? _accessToken;         // JWT 액세스 토큰
  String? _refreshToken;        // JWT 리프레시 토큰 (추후 구현)

  // 주요 메서드
  setAuthenticated(user, token) // 로그인 성공 시
  setUnauthenticated()         // 로그아웃 시
  updateUser(user)             // 사용자 정보 업데이트
}
```

#### Provider 의존성 관계
```
routerProvider ← RouterNotifier ← authStateProvider, currentUserProvider
                                      ↑
                               AuthStateNotifier
```

### 4. 로그인 흐름별 코드 패스

#### 👤 유저 로그인 흐름
```
MainHomeScreen → context.pushNamed('userLogin')
 ↓ go_router 네비게이션
UserLoginScreen → 동/호수 입력 → _attemptLogin()
 ↓ 데모 비밀번호 검증 (1234)
context.goNamed('userDashboard') → 라우팅 가드 → 대시보드 표시
```

#### 🏛️ 본사 로그인 흐름
```
MainHomeScreen → AdminLoginSelectionScreen → 본사 로그인 선택
 ↓ context.pushNamed('headquartersLogin')
HeadquartersLoginScreen → 이메일/비밀번호 입력
 ↓ 데모 검증 (hq@example.com / hq1234)
context.goNamed('headquartersDashboard') → 라우팅 가드 → 대시보드 표시
```

### 5. 테스트 환경 설정

#### Widget Test 구조
```dart
testWidgets('테스트명', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(        // Riverpod 환경 제공
      child: BuildingManageApp(),
    ),
  );
  await tester.pumpAndSettle(); // 비동기 렌더링 완료 대기

  // 테스트 검증 로직
});
```

---

## 🎯 완성된 기능 현황

### ✅ 구현 완료된 기능
1. **🏗️ 프로젝트 기본 구조**
   - Clean Architecture + 유저 타입별 분리
   - Riverpod 상태 관리 시스템
   - go_router 권한 기반 라우팅

2. **🔐 인증 시스템 기초**
   - 4개 유저 타입별 로그인 화면
   - 권한 기반 라우팅 가드
   - 자동 리다이렉트 시스템

3. **🧪 테스트 환경**
   - Widget Test with ProviderScope
   - 기본 UI 컴포넌트 테스트

### ⏳ 다음 구현 예정
1. **JWT 기반 실제 인증 시스템**
2. **dio API 클라이언트**
3. **각 유저 타입별 대시보드**

---

## 🔧 개발 시 주의사항

### Import 경로 규칙
```dart
// ✅ 올바른 import 패턴
import 'package:building_manage_front/presentation/user/screens/user_login_screen.dart';
import 'package:building_manage_front/core/constants/user_types.dart';

// ❌ 금지된 패턴 (구 features 폴더)
import 'package:building_manage_front/features/...';
```

### 네비게이션 패턴
```dart
// ✅ go_router 사용
context.pushNamed('userDashboard');
context.goNamed('userLogin'); // replace 방식

// ❌ 구 Navigator 방식 (사용 금지)
Navigator.push(...);
```

### 상태 관리 패턴
```dart
// ✅ Riverpod Provider 사용
final authState = ref.watch(authStateProvider);
final currentUser = ref.watch(currentUserProvider);

// ❌ 직접 상태 접근 (사용 금지)
AuthStateNotifier.instance._currentUser;
```

---

## 🚀 구조의 장점

### 1. 유저 타입별 명확한 분리
- 각 유저 타입별로 독립적인 폴더 구조
- 권한별 코드 격리로 보안성 향상
- 팀 개발 시 역할별 작업 분담 용이

### 2. Clean Architecture 준수
- presentation, domain, data 레이어 분리
- 의존성 방향이 안쪽으로 향하도록 설계
- 테스트 가능하고 확장 가능한 구조

### 3. 실시간 반응형 라우팅
- Riverpod을 통한 상태 변화 감지
- 인증 상태 변화 시 자동 라우팅 업데이트
- 권한 기반 자동 리다이렉트

### 4. 유지보수성과 확장성
- 관련 코드들이 한 곳에 모여있어 수정 용이
- Import 경로가 명확하여 코드 추적 쉬움
- 새로운 유저 타입 추가 시 폴더 구조만 확장

---

## 📈 향후 확장 계획

### Phase 1: 인증 시스템 완성
```
data/
├── datasources/
│   ├── auth_remote_datasource.dart    # JWT API 연동
│   └── auth_local_datasource.dart     # 토큰 로컬 저장
├── repositories/
│   └── auth_repository_impl.dart      # 인증 Repository 구현
└── models/
    ├── login_request.dart             # 로그인 요청 모델
    └── auth_response.dart             # 인증 응답 모델
```

### Phase 2: 유저 타입별 대시보드
```
presentation/
├── user/
│   └── screens/
│       ├── user_dashboard_screen.dart      # 👤 거주자 대시보드
│       ├── complaint_screen.dart           # 신고 화면
│       └── reservation_screen.dart         # 예약 화면
├── admin/
│   └── screens/
│       ├── admin_dashboard_screen.dart     # 🏢 관리자 대시보드
│       └── resident_management_screen.dart # 거주자 관리
├── manager/
│   └── screens/
│       ├── task_dashboard_screen.dart      # 🔧 작업 대시보드
│       └── work_report_screen.dart         # 작업 보고서
└── headquarters/
    └── screens/
        ├── hq_dashboard_screen.dart        # 🏛️ 본사 통합 대시보드
        └── analytics_screen.dart           # 분석 화면
```

### Phase 3: 고급 기능
- 실시간 알림 시스템 (WebSocket/FCM)
- 오프라인 지원 (Hive 로컬 DB)
- 다국어 지원 (i18n)
- 다크 모드 지원