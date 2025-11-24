# 역할 기반 분기 계획

이 문서는 건물관리 애플리케이션에서 네 가지 사용자 역할(본사, 건물관리자, 건물담당자, 일반유저)에 따라 화면과 기능을 분기 처리하기 위한 계획을 정리한다.

## 단계별 계획

1. **사용자 타입 정의** *(진행 완료)*
   - 회원가입 및 로그인 과정에서 부여되는 역할을 열거형(`UserRole`) 등으로 명시적으로 관리한다.
   - 서버/백엔드와의 역할 동기화 방법을 문서화하여 프론트와 일관성을 유지한다.
   - 구현 참고: `lib/core/auth/user_role.dart`

2. **인증 상태 및 역할 저장**
   - 로그인 성공 시 사용자 토큰과 함께 역할 정보를 상태관리 솔루션(Provider, Riverpod, BLoC 등)으로 보관한다.
   - 자동 로그인 및 앱 재시작 시를 대비해 안전한 스토리지(secure storage 등)에 역할을 영속화하는 전략을 수립한다.

3. **초기 라우팅 분기**
   - 앱 시작 시 저장된 역할을 읽어 적절한 진입 라우트로 이동시키는 부트스트랩 로직을 설계한다.
   - 인증 토큰 만료 또는 미로그인 상태에서는 공통 로그인 화면으로 리다이렉트한다.

4. **공용 로그인 → 역할별 홈 전환**
   - 로그인 화면에서 역할 정보를 수신한 뒤, 라우팅 솔루션(예: GoRouter, Router 2.0)을 통해 역할별 홈 화면으로 이동시키는 흐름을 정의한다.
   - 역할 미확인 혹은 부적합한 경우 예외 처리 시나리오를 마련한다.

5. **역할별 내비게이션 구성**
   - 각 역할이 접근해야 하는 탭, 메뉴, 주요 기능을 목록화한다.
   - 공통 레이아웃(`HomeScaffold`)은 유지하되 역할에 따라 내부 위젯을 조건부로 구성할 수 있는 구조를 설계한다.

6. **권한 가드 및 미들웨어**
   - 라우트 진입 시 현재 역할을 검증하는 가드 로직을 구현할 계획을 세운다.
   - 권한이 없는 화면 접근 시 대체 경로(예: 역할별 홈)로 리다이렉트하거나 접근 불가 메시지를 표시한다.

7. **역할 간 공유 컴포넌트 정리**
   - 공통으로 사용하는 UI와 비즈니스 로직을 모듈화하고, 역할 전용 기능은 별도 모듈로 분리하는 아키텍처를 구상한다.
   - 설정, 프로필 등 공용 기능이 역할별로 어떻게 변형되는지 정의한다.

8. **테스트 전략 수립**
   - 역할 분기 로직에 대해 단위 테스트(상태관리, 라우팅 결정)와 통합 테스트(로그인 → 특정 홈 진입) 케이스를 목록화한다.
   - 권한 가드가 올바르게 동작하는지 시뮬레이션하기 위한 테스트 더블/목 전략을 정한다.

## 향후 작업

- 역할별 세부 기능 요구사항을 도출하여 각 단계의 구현 범위를 확정한다.
- 인증 및 라우팅 구현 시 사용할 패키지 선정(예: firebase_auth, go_router 등)을 검토한다.

---

## 🔔 FCM (Firebase Cloud Messaging) 통합

### 개요

Firebase Cloud Messaging을 통해 역할별 사용자에게 푸시 알림을 전송하는 시스템을 구축했습니다.

**상태**: ✅ **구현 완료** (2025-11-24)

### 구현 내용

#### 1. 자동 토큰 등록/정리 시스템
- 사용자 로그인 시 자동으로 FCM 토큰을 서버에 등록
- 사용자 로그아웃 시 자동으로 토큰을 정리/삭제
- 토큰 갱신 시 자동 감지 및 재등록

#### 2. 역할별 토큰 관리
세 가지 사용자 유형별 별도 엔드포인트로 토큰 관리:
- **입주민 (user)**: `PATCH /api/v1/users/push-token`
- **담당자 (staff)**: `PATCH /api/v1/staffs/push-token`
- **관리자 (manager)**: `PATCH /api/v1/managers/push-token`

#### 3. 메시지 수신 방식
- **포그라운드**: 앱이 실행 중일 때 로컬 알림으로 표시
- **백그라운드**: 앱이 백그라운드/종료 상태일 때 시스템 알림으로 표시

### 구현된 파일

```
lib/
├── firebase_options.dart                    # Firebase 초기화 설정 (자동 생성)
├── main.dart                               # 앱 진입점 + 백그라운드 핸들러
├── app/app.dart                           # 자동 토큰 등록/정리 로직
├── modules/common/
│   ├── services/
│   │   └── notification_service.dart       # 싱글톤 FCM 서비스
│   └── data/datasources/
│       └── push_token_remote_datasource.dart  # 토큰 API 호출
└── core/constants/
    └── api_endpoints.dart                 # FCM 엔드포인트 추가

ios/
└── Runner/
    ├── GoogleService-Info.plist           # Firebase iOS 설정
    ├── Info.plist                         # UIBackgroundModes 추가
    └── Runner.entitlements                # aps-environment 설정

android/
└── app/
    ├── google-services.json               # Firebase Android 설정
    └── src/main/AndroidManifest.xml       # POST_NOTIFICATIONS 권한 추가
```

### 라이프사이클 흐름

```
1. 앱 시작
   ↓
2. main.dart - Firebase 초기화 + 백그라운드 핸들러 등록
   ↓
3. 사용자 로그인
   ↓
4. app.dart - currentUserProvider 변화 감지
   ↓
5. NotificationService.initialize() - FCM 리스너 설정
   ↓
6. NotificationService.registerPushToken(userType) - 토큰 등록
   ↓
7. PushTokenRemoteDataSource - API 호출 (PATCH 요청)
   ↓
8. 서버에서 토큰 저장
   ↓
9. 콘솔 로그: ✅ FCM 토큰 등록 완료: [userType]
```

### 로그아웃 흐름

```
1. 사용자 로그아웃 클릭
   ↓
2. app.dart - authStateProvider 변화 감지
   ↓
3. NotificationService.clearPushToken() - 토큰 삭제
   ↓
4. FirebaseMessaging.instance.deleteToken() 호출
   ↓
5. 콘솔 로그: ✅ FCM 토큰 정리 완료
```

### 주요 기술 스택

| 구성 | 패키지 | 버전 |
|------|--------|------|
| Firebase Core | firebase_core | ^4.2.0 |
| Cloud Messaging | firebase_messaging | ^16.0.3 |
| Local Notifications | flutter_local_notifications | ^16.3.0 |
| 상태관리 | flutter_riverpod | ^2.6.1 |
| 로컬화 | intl | ^0.20.0 |

### 테스트 방법

#### 로컬 테스트
```bash
cd /Users/gimseon-u/Desktop/vibeforge/building_manage_front

# 의존성 설치
flutter pub get

# 코드 생성
flutter pub run build_runner build

# 앱 실행
flutter run
```

**기대 로그:**
```
✅ FCM 토큰 등록 완료: user   (로그인 시)
✅ FCM 토큰 정리 완료         (로그아웃 시)
```

#### Firebase Console 테스트
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "Building Management" 프로젝트 → Cloud Messaging
3. "Send your first message" 또는 "Create campaign"
4. 메시지 제목, 내용 입력
5. 대상: iOS/Android 앱 선택
6. "Send test message" 클릭
7. 앱에서 알림 수신 확인

### 배포 체크리스트

#### iOS
- [ ] APNs 인증서가 Apple Developer에서 생성됨
- [ ] Firebase Console에 APNs 인증서 업로드됨
- [ ] Xcode에서 "Push Notifications" capability 활성화
- [ ] Bundle ID가 Firebase와 일치 (com.example.buildingManageFront)

#### Android
- [ ] google-services.json이 android/app/ 위치에 있음
- [ ] AndroidManifest.xml에 POST_NOTIFICATIONS 권한 추가됨
- [ ] Release 빌드로 테스트 완료 (flutter run --release)

### 문제 해결

| 증상 | 해결책 |
|------|--------|
| "❌ FCM 토큰 등록 실패" 로그 | `.env` 파일 확인, API 엔드포인트 재확인 |
| iOS에서 알림 미수신 | APNs 인증서 확인, entitlements 파일 확인 |
| Android에서 알림 미수신 | google-services.json 최신화, 권한 확인 |
| 앱 시작 시 크래시 | firebase_options.dart의 Bundle ID 확인 |

### 참고 문서

- 📖 [FCM_INTEGRATION_GUIDE.md](./FCM_INTEGRATION_GUIDE.md) - 상세 구현 가이드
- 📚 [Firebase 공식 문서](https://firebase.flutter.dev/)
- 📝 [CLAUDE.md](../CLAUDE.md) - 프로젝트 전체 문서
