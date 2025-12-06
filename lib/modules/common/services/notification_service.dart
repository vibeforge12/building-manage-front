import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/push_token_remote_datasource.dart';
import '../../../modules/auth/presentation/providers/auth_state_provider.dart';
import '../../../domain/entities/user.dart';

/// FCM 푸시 알림을 관리하는 싱글톤 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  PushTokenRemoteDataSource? _pushTokenDataSource;

  // 메시지 리스너 초기화 상태 추적 (한 번만 등록)
  bool _isMessageListenersRegistered = false;
  // 토큰 리스너 등록 상태 추적 (중복 리스너 방지)
  bool _isTokenListenerRegistered = false;
  // 현재 등록된 사용자 타입 (토큰 리프레시 시 사용)
  String? _currentUserType;

  /// 서비스 초기화
  /// 매번 호출되어도 안전 - 메시지 리스너만 한 번 등록
  Future<void> initialize(ApiClient apiClient) async {
    // 항상 새로운 apiClient로 데이터소스 갱신 (로그인 시 토큰 변경 반영)
    _pushTokenDataSource = PushTokenRemoteDataSource(apiClient);
    print('📱 NotificationService: 데이터소스 갱신됨');

    // 로컬 알림 설정 초기화 (한 번만)
    if (!_isMessageListenersRegistered) {
      try {
        await _initializeLocalNotifications();
        print('✅ 로컬 알림 초기화 성공');
      } catch (e) {
        print('⚠️ 로컬 알림 초기화 실패 (계속 진행): $e');
      }

      // 포그라운드 메시지 핸들러 (한 번만 등록)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📢 포그라운드 메시지 수신: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // 백그라운드에서 포그라운드로 전환될 때 메시지 처리 (한 번만 등록)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 알림 클릭 (백그라운드→포그라운드): ${message.notification?.title}');
        _handleMessageTap(message);
      });

      // 앱이 종료된 상태에서 푸시 알림 클릭으로 앱이 시작된 경우 처리
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 앱 시작 알림 (종료 상태에서 클릭): ${initialMessage.notification?.title}');
        _handleMessageTap(initialMessage);
      }

      _isMessageListenersRegistered = true;
      print('✅ NotificationService 메시지 리스너 등록 완료');
    }
  }

  /// 로컬 알림 플러그인 초기화
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  /// FCM 토큰 획득 및 서버 등록
  /// [userType]: 사용자 유형 (user, staff, manager)
  Future<void> registerPushToken({required String userType}) async {
    try {
      // 현재 사용자 타입 저장 (토큰 리프레시 시 사용)
      _currentUserType = userType;

      // 1. FCM 토큰 획득 (시뮬레이터에서는 실패할 수 있음)
      String? token;
      try {
        token = await _messaging.getToken();
      } catch (e) {
        print('⚠️ FCM 토큰 획득 실패 (시뮬레이터 환경): $e');
        print('💡 실제 기기에서는 정상 작동합니다.');
        // 시뮬레이터에서는 토큰 없이 계속 진행
        return;
      }

      if (token == null) {
        print('❌ FCM 토큰을 획득할 수 없습니다.');
        return;
      }

      // 토큰 출력 (Firebase Console 테스트용)
      print('🔑 ===== FCM TOKEN =====');
      print('📱 토큰: $token');
      print('👤 사용자 타입: $userType');
      print('⏰ 시간: ${DateTime.now()}');
      print('=======================');

      // 2. 토큰 변경 감지 (토큰이 새로 생성되면 자동 등록) - 중복 등록 방지
      if (!_isTokenListenerRegistered) {
        _messaging.onTokenRefresh.listen((newToken) {
          // _currentUserType 사용 (재로그인 시 업데이트된 값 사용)
          final currentType = _currentUserType ?? 'user';
          print('🔄 FCM 토큰 새로 발급됨. 서버에 업데이트... (userType: $currentType)');
          _registerTokenToServer(newToken, currentType);
        });
        _isTokenListenerRegistered = true;
      }

      // 3. 서버에 초기 토큰 등록
      await _registerTokenToServer(token, userType);
    } catch (e) {
      print('❌ FCM 토큰 등록 중 오류: $e');
    }
  }

  /// 서버에 FCM 토큰 등록
  Future<void> _registerTokenToServer(String token, String userType) async {
    try {
      // 데이터소스 체크
      if (_pushTokenDataSource == null) {
        print('❌ FCM 토큰 등록 실패: 데이터소스가 초기화되지 않았습니다.');
        return;
      }

      // 토큰 출력 (Firebase Console 테스트용)
      print('🔑 ===== FCM TOKEN =====');
      print('📱 토큰: $token');
      print('👤 사용자 타입: $userType');
      print('⏰ 시간: ${DateTime.now()}');
      print('=======================');

      switch (userType.toLowerCase()) {
        case 'user':
          await _pushTokenDataSource!.registerUserPushToken(pushToken: token);
          print('✅ 사용자(user) FCM 토큰 서버 등록 완료');
          break;
        case 'admin':
          // 관리자 = staff API 사용
          await _pushTokenDataSource!.registerStaffPushToken(pushToken: token);
          print('✅ 관리자(admin) FCM 토큰 서버 등록 완료');
          break;
        case 'staff':
          await _pushTokenDataSource!.registerStaffPushToken(pushToken: token);
          print('✅ 담당자(staff) FCM 토큰 서버 등록 완료');
          break;
        case 'manager':
          await _pushTokenDataSource!.registerManagerPushToken(pushToken: token);
          print('✅ 매니저(manager) FCM 토큰 서버 등록 완료');
          break;
        case 'headquarters':
          // 본사 = manager API 사용 (또는 별도 API가 있다면 교체)
          await _pushTokenDataSource!.registerManagerPushToken(pushToken: token);
          print('✅ 본사(headquarters) FCM 토큰 서버 등록 완료');
          break;
        default:
          print('⚠️ 알 수 없는 사용자 타입: $userType - FCM 토큰 등록 건너뜀');
      }
    } catch (e) {
      print('❌ 서버 토큰 등록 실패: $e');
    }
  }

  /// 포그라운드에서 메시지 수신 처리
  void _handleForegroundMessage(RemoteMessage message) {
    // 알림 정보가 있으면 로컬 알림으로 표시
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? '알림',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }
  }

  /// 알림 클릭 처리
  void _handleMessageTap(RemoteMessage message) {
    print('데이터: ${message.data}');
    // TODO: 알림 데이터에 따라 네비게이션 처리
    // 예: 민원 알림이면 민원 상세화면으로 이동
    // GoRouter를 사용하여 네비게이션 수행
  }

  /// 로컬 알림 표시
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'building_manage_channel',
      '건물 관리 알림',
      channelDescription: '건물 관리 시스템 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload != null ? payload.toString() : null,
    );
  }

  /// 로그아웃 시 호출 - FCM 토큰 무효화 (선택사항)
  /// 서버에서 토큰을 삭제하거나 비활성화
  Future<void> clearPushToken() async {
    try {
      // 로컬에서 FCM 토큰 삭제
      await _messaging.deleteToken();
      print('✅ FCM 토큰 삭제 완료');
    } catch (e) {
      print('❌ FCM 토큰 삭제 실패: $e');
    }
  }

  /// FCM 권한 요청 (iOS 13+, Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final NotificationSettings settings =
          await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ 푸시 알림 권한 승인됨');
        return true;
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ 푸시 알림 권한 임시 승인됨');
        return true;
      } else {
        print('❌ 푸시 알림 권한 거부됨');
        return false;
      }
    } catch (e) {
      print('❌ 권한 요청 중 오류: $e');
      return false;
    }
  }
}

/// Riverpod Provider
final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

/// 현재 사용자 정보를 기반으로 FCM 토큰 등록
/// 로그인 후 호출
final pushTokenRegistrationProvider =
    FutureProvider.family<void, (String userType, ApiClient)>((ref, args) async {
  final (userType, apiClient) = args;
  final notificationService = ref.read(notificationServiceProvider);

  // 서비스 초기화 (처음 한 번만)
  await notificationService.initialize(apiClient);

  // 권한 요청
  await notificationService.requestPermissions();

  // 토큰 등록
  await notificationService.registerPushToken(userType: userType);
});
