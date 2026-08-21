> ⚠️ **폐기 예정 문서 (2026-08-21)**
> 이 문서는 현재 코드와 일치하지 않습니다. 참고하지 마세요.
> 유효한 문서: `docs/프론트엔드_구조_및_문제점_분석.md`, `CLAUDE.md`

# 기술적 작업 세부 사항

## 📋 최근 완료 작업 (2025-01-14)

### ✅ 디렉토리 구조 리팩토링
- **기존**: `presentation/` 폴더에 모든 사용자 타입 혼재
- **변경**: 모듈별 완전 분리 구조로 리팩토링
```
lib/
├── modules/                       # 새로운 모듈 기반 구조
│   ├── auth/                      # 공통 인증 모듈
│   │   └── presentation/
│   ├── resident/                  # 입주민 모듈
│   │   └── presentation/
│   ├── manager/                   # 담당자 모듈
│   │   └── presentation/
│   ├── admin/                     # 관리자 모듈
│   │   └── presentation/
│   └── headquarters/              # 본사 모듈
│       ├── data/datasources/
│       └── presentation/screens/
├── shared/                        # 공통 컴포넌트
│   └── widgets/
└── core/                          # 핵심 기능
```

### ✅ JWT 토큰 기반 인증 시스템
- **본사 로그인 API 연동**: `/api/v1/auth/headquarters/login`
- **토큰 자동 관리**: AccessToken + RefreshToken
- **Auth Interceptor**: 자동 토큰 첨부 및 갱신
- **자동 로그인**: 앱 재시작시 토큰 유효성 검사
```dart
// 토큰 저장 구조
SharedPreferences:
- 'access_token': JWT access token
- 'refresh_token': JWT refresh token

// 자동 갱신
401 Error → Refresh Token 사용 → 새 토큰 발급
```

### ✅ 입주민 회원가입 2단계 폼
- **1단계**: 동/호수/비밀번호/비밀번호 재확인
- **상태 관리**: Riverpod StateNotifier로 다단계 폼 데이터 보존
- **유효성 검증**: 실시간 폼 검증
- **UI**: 진행률 표시, 단계별 네비게이션
```dart
SignupFormState:
- 1단계: dong, hosu, password, passwordConfirm
- 2단계: username, name, phoneNumber, buildingId (대기중)
```

### ✅ 본사 대시보드 화면
- **배경 이미지**: `headQuartersHome.png` 전체 화면 배경
- **UI 구성**: 타이틀, 관리자 계정발급 버튼, 관리자/건물등록 카드
- **네비게이션**: 로그아웃, 하위 화면 이동
```dart
HeadquartersDashboardScreen:
- Stack 레이아웃으로 배경이미지 + 컨텐츠
- FilledButton 스타일링 (72px 높이, 18px 텍스트)
- SafeArea + Spacer로 하단 배치
```

### ✅ 건물 등록/관리 화면
- **API 연동**: `/api/v1/common/departments` GET 요청
- **실시간 검색**: 디바운스 패턴 적용 (500ms)
- **부서 태그**: API 데이터를 태그 형태로 표시
- **상태 관리**: 로딩/에러/빈상태 처리
```dart
BuildingManagementScreen:
- 검색바 + 건물등록 버튼
- 부서섹션 + 부서생성 버튼
- Wrap 위젯으로 부서 태그들 표시
- DepartmentRemoteDataSource로 API 호출
```

### ✅ API 클라이언트 인프라
- **Dio 기반**: HTTP 클라이언트
- **Interceptor 체계**:
  - AuthInterceptor: 토큰 관리
  - LoggingInterceptor: 요청/응답 로깅
  - ErrorInterceptor: 통합 에러 처리
- **환경설정**: flutter_dotenv로 API URL 관리
```dart
API 엔드포인트:
- /auth/headquarters/login
- /auth/refresh
- /common/departments
```

### ✅ 사용자 엔티티 완성
- **User.fromJson()**: API 응답 → User 객체 변환
- **역할 매핑**: API의 'role' 필드 → UserType enum
- **JSON 직렬화**: toJson() 메서드 구현
```dart
User Entity:
- id, email, name, userType
- buildingId, dong, ho (옵셔널)
- permissions Map
- fromJson/toJson 메서드
```

### 🔧 주요 기술 패턴
1. **Clean Architecture**: modules 기반 분리
2. **Riverpod**: 상태관리 및 의존성 주입
3. **Go Router**: 선언적 라우팅 + 권한 가드
4. **Repository Pattern**: 데이터 추상화
5. **Provider Pattern**: 서비스 인젝션
6. **Interceptor Pattern**: HTTP 미들웨어

### 🎯 다음 작업 예정
- [ ] 회원가입 2단계 필드 구현 (사용자 요구사항 대기)
- [ ] 부서 생성 기능
- [ ] 관리자 계정 발급 기능
- [ ] 다른 사용자 타입 로그인 API 연동

## Phase 1: 프로젝트 기초 설정

### 1.1 의존성 설정
```yaml
dependencies:
  # 상태 관리
  flutter_riverpod: ^2.4.9

  # 라우팅
  go_router: ^12.1.3

  # HTTP 통신
  dio: ^5.4.0

  # 로컬 저장소
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI 컴포넌트
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0

  # 유틸리티
  equatable: ^2.0.5
  json_annotation: ^4.8.1

dev_dependencies:
  # 코드 생성
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1

  # 테스트
  mockito: ^5.4.4
```

### 1.2 폴더 구조 생성
- [ ] `lib/core/` - 공통 유틸리티, 상수, 에러 처리
- [ ] `lib/data/` - API, 로컬 DB, 모델
- [ ] `lib/domain/` - 엔티티, 유스케이스, 레포지토리 인터페이스
- [ ] `lib/presentation/` - UI, 위젯, 페이지
- [ ] `test/` - 테스트 코드

## Phase 2: 인증 시스템 구현

### 2.1 인증 모델 설계
```dart
// User 엔티티
class User {
  final String id;
  final String email;
  final String name;
  final UserType type;
  final String? buildingId;
  final Map<String, dynamic> permissions;
}

enum UserType {
  user,      // 일반 유저
  admin,     // 관리자
  manager,   // 담당자
  headquarters, // 본사
}
```

### 2.2 인증 상태 관리
- [ ] AuthRepository 구현
- [ ] AuthNotifier (Riverpod) 구현
- [ ] JWT 토큰 관리
- [ ] 자동 로그인 로직

### 2.3 라우팅 가드
```dart
// 권한별 라우팅 가드
class AuthGuard {
  static bool canAccess(UserType userType, String route) {
    // 권한별 접근 가능한 라우트 체크
  }
}
```

## Phase 3: UI 컴포넌트 시스템

### 3.1 디자인 시스템
- [ ] 컬러 팔레트 정의
- [ ] 타이포그래피 시스템
- [ ] 스페이싱 시스템
- [ ] 아이콘 시스템

### 3.2 공통 컴포넌트
- [ ] CustomButton
- [ ] CustomTextField
- [ ] CustomAppBar
- [ ] CustomBottomNavigationBar
- [ ] LoadingWidget
- [ ] ErrorWidget

### 3.3 유저 타입별 네비게이션
```dart
// 각 유저 타입별 네비게이션 구조
class UserNavigation extends StatelessWidget {
  final UserType userType;

  Widget build(BuildContext context) {
    return switch(userType) {
      UserType.user => UserBottomNav(),
      UserType.admin => AdminBottomNav(),
      UserType.manager => ManagerBottomNav(),
      UserType.headquarters => HeadquartersBottomNav(),
    };
  }
}
```

## Phase 4: 데이터 레이어

### 4.1 API 설계
```dart
// RESTful API 엔드포인트
class ApiEndpoints {
  static const String baseUrl = 'https://api.buildingmanage.com';

  // 인증
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  // 유저별 엔드포인트
  static const String userDashboard = '/user/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String managerDashboard = '/manager/dashboard';
  static const String hqDashboard = '/headquarters/dashboard';
}
```

### 4.2 로컬 저장소 설계
```dart
// Hive 박스 구조
@HiveType(typeId: 0)
class CachedUser extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  UserType type;
}
```

## Phase 5: 테스트 전략

### 5.1 테스트 종류
- [ ] 유닛 테스트: 비즈니스 로직, 유틸리티
- [ ] 위젯 테스트: UI 컴포넌트, 페이지
- [ ] 통합 테스트: 전체 플로우, API 연동

### 5.2 Mock 데이터
- [ ] MockAuthRepository
- [ ] MockApiClient
- [ ] 테스트용 더미 데이터

## 성능 최적화 고려사항

### 메모리 관리
- [ ] 이미지 캐싱 최적화
- [ ] 리스트 가상화 (ListView.builder)
- [ ] 불필요한 리빌드 방지

### 네트워크 최적화
- [ ] API 응답 캐싱
- [ ] 오프라인 지원
- [ ] 재시도 로직

### 보안 고려사항
- [ ] 토큰 암호화 저장
- [ ] API 통신 HTTPS 강제
- [ ] 민감 정보 로깅 방지
- [ ] 앱 백그라운드시 화면 블러 처리