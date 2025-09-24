# 기술적 작업 세부 사항

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