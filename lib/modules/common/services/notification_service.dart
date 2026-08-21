import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/exceptions/api_exception.dart';
import '../../../core/utils/device_info_helper.dart';
import '../data/datasources/push_token_remote_datasource.dart';

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

    // 로컬 알림 설정 초기화 (한 번만)
    if (!_isMessageListenersRegistered) {
      try {
        await _initializeLocalNotifications();
      } catch (e) {
        // Local notification initialization failed
      }

      // 포그라운드 메시지 핸들러 (한 번만 등록)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 백그라운드에서 포그라운드로 전환될 때 메시지 처리 (한 번만 등록)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageTap(message);
      });

      // 앱이 종료된 상태에서 푸시 알림 클릭으로 앱이 시작된 경우 처리
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _isMessageListenersRegistered = true;
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
  /// [userType]: 사용자 유형 (user, manager, staff, headquarters)
  Future<void> registerPushToken({required String userType}) async {
    try {
      // 현재 사용자 타입 저장 (토큰 리프레시 시 사용)
      _currentUserType = userType;

      // 1. FCM 토큰 획득 (시뮬레이터에서는 실패할 수 있음)
      String? token;
      try {
        token = await _messaging.getToken();
      } catch (e) {
        // Token acquisition failed (simulator/emulator may not support FCM)
        return;
      }

      if (token == null) {
        // Token is null (possible causes: no Google Play Services, Firebase not initialized)
        return;
      }

      // 2. 토큰 변경 감지 (토큰이 새로 생성되면 자동 등록) - 중복 등록 방지
      if (!_isTokenListenerRegistered) {
        _messaging.onTokenRefresh.listen((newToken) {
          // _currentUserType 사용 (재로그인 시 업데이트된 값 사용)
          final currentType = _currentUserType ?? 'user';
          _registerTokenToServer(newToken, currentType);
        });
        _isTokenListenerRegistered = true;
      }

      // 3. 서버에 초기 토큰 등록
      await _registerTokenToServer(token, userType);
    } catch (e) {
      // FCM token registration failed
    }
  }

  /// 서버에 FCM 토큰 등록 (401 에러 시 최대 2회 재시도)
  Future<void> _registerTokenToServer(String token, String userType, {int retryCount = 0}) async {
    const int maxRetries = 2;

    try {
      // 데이터소스 체크
      if (_pushTokenDataSource == null) {
        return;
      }

      // 디바이스 정보 수집 (실패해도 토큰 등록은 진행)
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      final deviceId = deviceInfo['deviceId'];
      final deviceName = deviceInfo['deviceName'];
      final platform = deviceInfo['platform'];

      final lowerUserType = userType.toLowerCase();

      switch (lowerUserType) {
        case 'user':
          await _pushTokenDataSource!.registerUserPushToken(
            pushToken: token,
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
          );
          break;
        case 'manager':
          await _pushTokenDataSource!.registerManagerPushToken(
            pushToken: token,
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
          );
          break;
        case 'staff':
          await _pushTokenDataSource!.registerStaffPushToken(
            pushToken: token,
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
          );
          break;
        case 'headquarters':
          await _pushTokenDataSource!.registerHeadquartersPushToken(
            pushToken: token,
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
          );
          break;
        default:
          break;
      }
    } on ApiException catch (e) {
      final statusCode = e.statusCode;

      // 401 Unauthorized 에러 시 재시도
      if (statusCode == 401 && retryCount < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _registerTokenToServer(token, userType, retryCount: retryCount + 1);
      }
    } catch (e) {
      // Token registration to server failed
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
      payload: payload?.toString(),
    );
  }

  /// 로그아웃 시 호출 - FCM 토큰 무효화 (선택사항)
  /// 서버에서 토큰을 삭제하거나 비활성화
  Future<void> clearPushToken() async {
    try {
      // 로컬에서 FCM 토큰 삭제
      await _messaging.deleteToken();
    } catch (e) {
      // FCM token deletion failed
    }
  }

  /// FCM 권한 요청 (iOS 13+, Android 13+)
  Future<bool> requestPermissions() async {
    try {
      // Android 13+ 에서는 flutter_local_notifications를 통해 권한 요청
      // (firebase_messaging.requestPermission()이 Android에서 불안정할 수 있음)
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      // Firebase Messaging 권한 요청 (iOS 필수, Android 보조)
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
        return true;
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
