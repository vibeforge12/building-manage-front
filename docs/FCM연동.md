# Firebase Cloud Messaging (FCM) 연동 가이드

## 2026-11-05 로그아웃 서버 해제

명시적 로그아웃은 `LogoutUseCase`에서 서버 푸시 해제 → 클라이언트 인증 삭제 순서로 실행한다. JWT가 유효한 상태로 `POST /api/v1/auth/logout`에 `{ "pushToken": "현재 FCM 토큰" }`을 보내며 응답은 204다. 이미 해제된 토큰도 성공한다. 토큰 생략은 삭제할 등록이 없는 경우에 사용한다.

서버는 JWT의 사용자 ID·역할과 정확한 토큰을 모두 대조한다. 입주민·관리자·담당자·본사 공통으로 다른 기기·계정의 등록을 보존한다. 서버 해제에 실패하면 오류를 표시하고 로그인을 유지해 재시도한다. 성공 후 Firebase 토큰과 표시된 알림을 정리한다. JWT 전체를 서버에서 폐기하는 API는 아니다.

새 앱 출시 전 백엔드 API를 먼저 배포해야 한다. `make quality`에 로그아웃 순서·실패 재시도·백엔드 소유권 검사를 추가했다. 2026-11-05 C폰 Dev에서 답변 작성·수정 알림과 로그아웃 자동 해제를 별도로 검증했다. 현재 공개된 스토어 앱은 이번 보완을 포함하지 않는다.

> **기준 문서** · 푸시 알림 연동 방법의 출처입니다
> 갱신 트리거: `lib/core/services/fcm*` · FCM 페이로드 타입 추가 시
> 최종 확인: 2026-08-29 — Front `dev@48d72a3`
> 공고문 푸시는 아래 "공고문 알림" 절 참고.
## 📋 개요

이 문서는 건물관리 애플리케이션에 Firebase Cloud Messaging (FCM)을 통한 푸시 알림 시스템을 연동하는 방법을 설명합니다.

## 🎯 구현 목표

- ✅ 사용자 로그인 시 자동으로 FCM 토큰 등록
- ✅ 사용자 로그아웃 시 자동으로 토큰 정리
- ✅ 세 가지 사용자 유형(입주민/담당자/관리자) 지원
- ✅ 포그라운드 및 백그라운드 메시지 수신
- ✅ 로컬 알림 표시

## 🏗️ 아키텍처

### 계층 구조

```
┌─────────────────────────────────────────┐
│         main.dart (Entry Point)         │
│  • Firebase 초기화                      │
│  • 백그라운드 메시지 핸들러 등록       │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│     BuildingManageApp (app.dart)        │
│  • 인증 상태 변화 감시                 │
│  • 로그인 시 토큰 등록                 │
│  • 로그아웃 시 토큰 정리               │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│   NotificationService (싱글톤)         │
│  • Firebase Messaging 초기화            │
│  • 포그라운드 메시지 처리              │
│  • 토큰 등록/정리                      │
│  • 토큰 갱신 리스너                    │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  PushTokenRemoteDataSource (API)        │
│  • registerUserPushToken()              │
│  • registerStaffPushToken()             │
│  • registerManagerPushToken()           │
└─────────────────────────────────────────┘
```

## 📁 파일 구조

### 생성된 파일

```
lib/
├── firebase_options.dart                    # Firebase 설정 (자동 생성)
├── main.dart                               # 앱 진입점 수정
├── app/app.dart                           # FCM 자동 등록/정리 로직
├── modules/
│   └── common/
│       ├── services/
│       │   └── notification_service.dart   # FCM 라이프사이클 관리
│       └── data/datasources/
│           └── push_token_remote_datasource.dart  # API 통신
└── core/
    └── constants/
        └── api_endpoints.dart             # FCM 토큰 엔드포인트 추가

ios/
└── Runner/
    ├── GoogleService-Info.plist           # Firebase iOS 설정
    └── Runner.entitlements                # 푸시 알림 권한 설정

android/
└── app/
    └── google-services.json               # Firebase Android 설정
```

## 🔧 구현 상세

### 1. main.dart - Firebase 초기화

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드/종료 상태에서 메시지 처리
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 백그라운드 메시지: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 앱 실행
    runApp(const ProviderScope(child: BuildingManageApp()));
  } catch (e) {
    // 초기화 실패 시 에러 표시
  }
}
```

### 2. app.dart - 자동 토큰 관리

```dart
class BuildingManageApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그인 시 토큰 등록
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && previous == null) {
        _registerFcmToken(ref, next);
      }
    });

    // 로그아웃 시 토큰 정리
    ref.listen(authStateProvider, (previous, current) {
      if (current == AuthState.unauthenticated && previous != null) {
        _clearFcmToken(ref);
      }
    });

    return MaterialApp.router(
      // ... 앱 설정
    );
  }

  static void _registerFcmToken(WidgetRef ref, dynamic user) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final apiClient = ref.read(apiClientProvider);
      final userType = user.userType?.value ?? 'user';

      await notificationService.initialize(apiClient);
      await notificationService.requestPermissions();
      await notificationService.registerPushToken(userType: userType);

      print('✅ FCM 토큰 등록 완료: $userType');
    } catch (e) {
      print('❌ FCM 토큰 등록 실패: $e');
    }
  }

  static void _clearFcmToken(WidgetRef ref) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.clearPushToken();
      print('✅ FCM 토큰 정리 완료');
    } catch (e) {
      print('❌ FCM 토큰 정리 실패: $e');
    }
  }
}
```

### 3. NotificationService - 라이프사이클 관리

```dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late ApiClient _apiClient;
  late FlutterLocalNotificationsPlugin _localNotifications;

  // 초기화
  Future<void> initialize(ApiClient apiClient) async {
    _apiClient = apiClient;
    _localNotifications = FlutterLocalNotificationsPlugin();

    // 초기화 설정
    const androidSetting = AndroidInitializationSettings('app_icon');
    const iosSetting = DarwinInitializationSettings();

    await _localNotifications.initialize(
      InitializationSettings(android: androidSetting, iOS: iosSetting),
    );

    // 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 토큰 갱신 리스너
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔄 FCM 토큰 갱신: ${newToken.substring(0, 20)}...');
    });
  }

  // 권한 요청
  Future<void> requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // 토큰 등록 (사용자별)
  Future<void> registerPushToken({required String userType}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) throw Exception('FCM 토큰을 가져올 수 없습니다.');

      final dataSource = PushTokenRemoteDataSource(_apiClient);

      switch (userType) {
        case 'user':
          await dataSource.registerUserPushToken(token);
          break;
        case 'staff':
          await dataSource.registerStaffPushToken(token);
          break;
        case 'manager':
          await dataSource.registerManagerPushToken(token);
          break;
        default:
          throw Exception('알 수 없는 사용자 유형: $userType');
      }

      print('✅ 토큰 등록 완료 ($userType): ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ 토큰 등록 실패: $e');
      rethrow;
    }
  }

  // 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 포그라운드 메시지: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title,
        body: message.notification!.body,
        payload: jsonEncode(message.data),
      );
    }
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String? title,
    required String? body,
    required String payload,
  }) async {
    const androidDetail = AndroidNotificationDetails(
      'building_manage_notifications',
      'Building Manage Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetail = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(android: androidDetail, iOS: iosDetail),
      payload: payload,
    );
  }

  // 토큰 정리
  Future<void> clearPushToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      print('✅ FCM 토큰 삭제 완료');
    } catch (e) {
      print('❌ FCM 토큰 삭제 실패: $e');
    }
  }
}
```

### 4. API 엔드포인트 설정

```dart
// lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  // FCM 토큰 등록 엔드포인트
  static const String userPushToken = '/users/push-token';       // PATCH - 입주민
  static const String staffPushToken = '/staffs/push-token';     // PATCH - 담당자
  static const String managerPushToken = '/managers/push-token'; // PATCH - 관리자
}
```

### 5. PushTokenRemoteDataSource - API 호출

```dart
class PushTokenRemoteDataSource {
  final ApiClient _apiClient;

  PushTokenRemoteDataSource(this._apiClient);

  // 입주민 토큰 등록
  Future<void> registerUserPushToken(String token) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.userPushToken,
        data: {'pushToken': token},
      );
    } catch (e) {
      print('❌ 입주민 토큰 등록 실패: $e');
      rethrow;
    }
  }

  // 담당자 토큰 등록
  Future<void> registerStaffPushToken(String token) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.staffPushToken,
        data: {'pushToken': token},
      );
    } catch (e) {
      print('❌ 담당자 토큰 등록 실패: $e');
      rethrow;
    }
  }

  // 관리자 토큰 등록
  Future<void> registerManagerPushToken(String token) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.managerPushToken,
        data: {'pushToken': token},
      );
    } catch (e) {
      print('❌ 관리자 토큰 등록 실패: $e');
      rethrow;
    }
  }
}
```

## 🔐 플랫폼 설정

### iOS 설정

#### 1. Info.plist 추가 항목

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>

<key>NSLocalNotificationPermission</key>
<true/>
```

#### 2. Runner.entitlements 파일

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>aps-environment</key>
  <string>development</string>
</dict>
</plist>
```

#### 3. Xcode 빌드 설정

- 프로젝트 → Target "Runner" → Build Settings
- "CODE_SIGN_ENTITLEMENTS" = "Runner/Runner.entitlements"
- All Configurations (Debug, Release, Profile)에 적용

### Android 설정

#### 1. AndroidManifest.xml 권한

```xml
<!-- FCM 권한 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- 인터넷 권한 -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- SMS 권한 (향후 SMS 알림 기능) -->
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.SEND_SMS" />
```

#### 2. build.gradle.kts 설정

```gradle
plugins {
  id("com.google.gms.google-services")  // Google Services 플러그인
}

dependencies {
  // Firebase 의존성은 google-services.json으로 자동 관리
}
```

## 📦 의존성

### pubspec.yaml

```yaml
dependencies:
  # Firebase & Cloud Messaging
  firebase_core: ^4.2.0
  firebase_messaging: ^16.0.3

  # Local & Remote Notifications
  flutter_local_notifications: ^16.3.0

  # Localization (for intl messages)
  intl: ^0.20.0
```

## 🧪 테스트 가이드

### 1. 로컬 테스트

```bash
# 프로젝트 루트에서
flutter pub get
flutter pub run build_runner build

# 앱 실행
flutter run
```

**예상 콘솔 출력:**
```
✅ FCM 토큰 등록 완료: user
✅ FCM 토큰 정리 완료  (로그아웃 시)
```

### 2. Firebase Console 테스트 메시지

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "Building Management" 프로젝트 선택
3. Cloud Messaging 탭
4. "Send your first message" 또는 "Create campaign"
5. 다음 정보 입력:
   - **Notification title**: "테스트"
   - **Notification text**: "FCM 테스트 메시지입니다"
   - **Target**: 앱 선택 (iOS/Android)
6. "Send test message" 클릭
7. 앱에서 알림 수신 확인

### 3. 포그라운드 메시지 테스트

앱을 열어둔 상태로 Firebase Console에서 메시지 발송:
- 앱 내 로컬 알림이 표시되어야 함
- 콘솔에 "📨 포그라운드 메시지" 로그 출력

### 4. 백그라운드 메시지 테스트

앱을 백그라운드로 보낸 상태로 Firebase Console에서 메시지 발송:
- 시스템 알림이 표시되어야 함
- 앱 탭하면 포그라운드로 진입

## 🔍 문제 해결

| 증상 | 원인 | 해결책 |
|------|------|--------|
| "❌ FCM 토큰 등록 실패" | API 엔드포인트 오류 | `.env` 파일 확인, ApiClient 설정 검토 |
| 알림 미수신 (iOS) | APNs 인증서 부재 | Apple Developer에서 APNs 인증서 생성 및 업로드 |
| 알림 미수신 (Android) | google-services.json 오류 | Firebase Console에서 다시 다운로드 |
| 앱 크래시 (시작 시) | firebase_options.dart 오류 | Bundle ID 일치 여부 확인 |
| "entitlements 에러" (iOS) | Runner.entitlements 미설정 | Xcode 빌드 설정 재확인 |

## 📋 체크리스트

### 초기 설정
- [ ] Firebase 프로젝트 생성 (Firebase Console)
- [ ] iOS 앱 등록 및 GoogleService-Info.plist 다운로드
- [ ] Android 앱 등록 및 google-services.json 다운로드
- [ ] `flutterfire configure` 실행 (`firebase_options.dart` 생성)
- [ ] `flutter pub get` 실행

### iOS 설정
- [ ] Info.plist에 UIBackgroundModes 추가
- [ ] Runner.entitlements 파일 생성
- [ ] Xcode 빌드 설정에 entitlements 경로 추가
- [ ] `pod install` 실행 (ios/ 디렉토리에서)
- [ ] Apple Developer에서 APNs 인증서 생성
- [ ] Firebase Console에 APNs 인증서 업로드

### Android 설정
- [ ] AndroidManifest.xml에 권한 추가
- [ ] google-services.json이 android/app/ 위치에 있음 확인
- [ ] build.gradle.kts에 Google Services 플러그인 적용 확인

### 테스트
- [ ] 로컬에서 `flutter run` 실행
- [ ] 로그인 시 "✅ FCM 토큰 등록 완료" 확인
- [ ] Firebase Console에서 테스트 메시지 발송
- [ ] 알림 수신 확인 (포그라운드/백그라운드)

## 🚀 배포 전 확인사항

### iOS 배포
- [ ] APNs 인증서가 유효한지 확인
- [ ] Signing & Capabilities에서 "Push Notifications" 활성화
- [ ] Bundle ID가 Firebase와 일치하는지 확인

### Android 배포
- [ ] google-services.json이 최신 버전인지 확인
- [ ] Release 빌드에서 테스트 (flutter run --release)
- [ ] ProGuard 규칙이 Firebase를 제외했는지 확인

## 📚 참고 자료

- [Firebase Cloud Messaging 공식 문서](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase 플러그인](https://firebase.flutter.dev/)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

## 📝 향후 개선 사항

- [ ] SMS 알림 기능 추가 (SMS 권한 이미 설정됨)
- [ ] 웹훅 기반 알림 추적 시스템
- [ ] 알림 설정 UI (알림 ON/OFF, 카테고리별 필터링)
- [ ] 배치 알림 처리 (서버에서 여러 대상에게 동시 발송)
- [ ] 알림 이력 저장 및 조회 기능

---

## 공고문 알림 (2026-08-29 추가)

| 항목 | 값 |
|---|---|
| `data.type` | `BULLETIN_PUBLISHED` |
| `data.bulletinId` | 공고문 ID |
| 알림 제목 | `새로운 공고문` (고정) |
| 알림 본문 | **공고문 제목** |
| 발신 | `libs/fcm/src/fcm.service.ts` `notifyBulletinPublished()` |
| 이동 경로 | `/user/bulletin/:bulletinId` |

**발송 조건이 다른 알림과 다르다.** 등록 화면의 체크박스를 켠 경우에만 나간다(기본 꺼짐).
공고문은 게시판을 옮긴 것이라 공지보다 훨씬 자주 올라오므로, 전부 푸시하면 알림 피로로
앱 알림 자체를 꺼버린다. 긴급할 때만 켜는 스위치다.

- 수신자: 해당 건물의 **활성·승인 완료 입주민**
- **수정은 푸시를 다시 보내지 않는다**
- 예약 게시(`postedFrom` 이 미래)는 등록 시점에 푸시하지 않는다. 예약 시점 자동 발송은 **미구현**(스케줄러 필요)
- 이미지는 알림에 실리지 않는다 — 제목만 전달되므로 제목을 내용이 드러나게 써야 한다

---

## 서비스 신청 알림 (2026-10-21 추가)

| `data.type` | 발송 시점 | 수신자 | 이동 경로 |
|---|---|---|---|
| `LIFE_SERVICE_PUBLISHED` | 신규 등록에서 알림 발송을 선택 | 같은 건물의 승인된 활성 입주민 | `/life-services/:lifeServiceId` |
| `LIFE_SERVICE_UPDATED` | 신청 기간·서비스 일정·장소가 실제로 변경 | 현재 신청자 | `/life-services/:lifeServiceId` |
| `LIFE_SERVICE_CLOSED` | 최초 마감 | 현재 신청자 | `/life-services/:lifeServiceId` |

- 신규 등록 화면의 `입주민에게 알림 보내기`는 기본으로 켜져 있으며 운영자가 끌 수 있다.
- 제목·안내 문구만 수정하거나 입주민이 신청·취소한 경우에는 발송하지 않는다.
- 페이로드에는 알림 종류와 `lifeServiceId`만 포함하고 개인정보는 포함하지 않는다.
- 대상 조회와 FCM 발송은 저장 성공 후 비동기로 실행되며, 실패해도 등록·수정·마감 결과를 되돌리지 않는다.
- 같은 서비스에 마감 요청이 반복돼도 마감 알림은 최초 상태 전환에서만 발송한다.

## 알림 탭 화면 스택 (2026-10-23 수정)

- 백그라운드 FCM, 종료 상태의 초기 FCM, Android 포그라운드 로컬 알림의 탭은 같은 이동 처리를 사용한다.
- 기존 화면 스택을 정리한 뒤 로그인 역할의 홈과 대상 화면 하나만 남긴다. 한 번 뒤로 가면 홈이다.
- 같은 상세를 다시 눌러도 새로 열어 최신 데이터를 조회하며, 한 프레임 안의 연속 탭은 마지막 대상만 연다.
- 이동 대기 중 계정이 바뀌거나 홈 접근이 리다이렉트되면 이전 대상 이동을 중단한다. 기존 역할별 접근 제어는 유지한다.
- 회귀 테스트: `test/notification_navigation_test.dart`. 실제 플랫폼별 알림 실수신·탭 검증은 별도로 기록한다.

