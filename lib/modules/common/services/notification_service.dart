import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/exceptions/api_exception.dart';
import '../../../core/utils/device_info_helper.dart';
import '../../../core/constants/user_types.dart';
import '../../../core/providers/router_provider.dart';
import '../../auth/presentation/providers/auth_state_provider.dart';
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

  // 알림을 눌렀을 때 화면을 옮기려면 라우터와 '지금 로그인한 사람' 이 필요하다.
  // 이 서비스는 싱글톤이라 provider 가 만들어질 때 한 번 붙여 준다.
  Ref? _ref;

  void attachRef(Ref ref) => _ref = ref;

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

    await _localNotifications.initialize(
      initSettings,
      // 앱이 떠 있는 동안 온 알림은 FCM 이 배너를 띄우지 않아 직접 띄운다(_handleForegroundMessage).
      // 그렇게 띄운 알림은 onMessageOpenedApp 을 타지 않으므로, 탭 처리도 여기서 따로 받아야 한다.
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) _navigateFor(decoded);
        } catch (_) {
          // 예전 판이 남긴 Map.toString() 페이로드는 JSON 이 아니다. 무시한다.
        }
      },
    );
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
    _navigateFor(message.data);
  }

  /// 알림 데이터로 갈 곳을 정해 이동한다.
  ///
  /// 프레임 뒤로 미루는 이유: 앱이 꺼진 상태에서 알림으로 시작하면
  /// (getInitialMessage) 라우터가 아직 첫 경로를 정하는 중이라
  /// 지금 옮겨 봐야 곧바로 덮어써진다.
  void _navigateFor(Map<String, dynamic> data) {
    final ref = _ref;
    if (ref == null) return;

    final path = _routeFor(data);
    if (path == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(routerNotifierProvider).router.go(path);
      } catch (_) {
        // 라우터가 아직 없거나 경로가 막힌 경우. 알림을 눌러 앱이 열린 것만으로도
        // 최소한의 목적은 이뤄졌으므로 여기서 조용히 멈춘다.
      }
    });
  }

  /// 알림 종류 + 지금 로그인한 사람 → 갈 경로.
  ///
  /// 같은 알림이라도 받는 사람에 따라 화면이 다르다. 민원 접수 알림은
  /// 관리자와 담당자가 서로 다른 상세 화면을 쓴다.
  /// 대상 화면을 특정할 수 없으면 null 을 돌려 아무 데도 가지 않는다.
  /// (엉뚱한 화면으로 튀는 것보다 그대로 두는 편이 낫다)
  String? _routeFor(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == null || type.isEmpty) return null;

    final userType = _ref?.read(currentUserProvider)?.userType;

    // FCM 의 data 는 값이 전부 문자열로 와서, 빈 문자열도 '없음' 으로 본다.
    String? idOf(String key) {
      final v = data[key]?.toString();
      return (v == null || v.isEmpty) ? null : v;
    }

    switch (type) {
      // ── 입주민에게만 가는 알림 ──
      case 'BULLETIN_PUBLISHED':
        final id = idOf('bulletinId');
        return id == null ? '/user/bulletins' : '/user/bulletin/$id';
      case 'NOTICE_PUBLISHED':
        final id = idOf('noticeId');
        return id == null ? '/user/notices' : '/user/notice/$id';
      case 'EVENT_PUBLISHED':
        final id = idOf('eventId');
        return id == null ? '/user/events' : '/user/event/$id';

      // 처리 결과 알림에는 민원 id 가 실리지 않아 목록으로 보낸다.
      case 'COMPLAINT_RESOLVED':
        return '/user/my-complaints';

      // ── 받는 사람에 따라 화면이 갈리는 알림 ──
      case 'COMPLAINT_REGISTERED':
      case 'COMPLAINT_TRANSFERRED':
        final id = idOf('complaintId');
        switch (userType) {
          case UserType.admin:
            return id == null
                ? '/admin/complaint-management'
                : '/admin/complaint-detail/$id';
          case UserType.manager:
            return id == null
                ? '/manager/complaints'
                : '/manager/complaint-detail/$id';
          case UserType.user:
            return id == null ? '/user/my-complaints' : '/user/complaint/$id';
          default:
            return null;
        }

      // ── 관리자에게만 가는 알림 ──
      // 둘 다 알림에 id 가 없어 목록·현황으로 보낸다.
      case 'RESIDENT_REGISTERED':
        return userType == UserType.admin ? '/admin/resident-management' : null;
      case 'STAFF_CHECK_IN':
      case 'STAFF_CHECK_OUT':
        return userType == UserType.admin
            ? '/admin/staff-attendance-current'
            : null;
    }
    return null;
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
      // toString() 은 다시 읽을 수 없다. 탭했을 때 어디로 갈지 알려면 JSON 이어야 한다.
      payload: payload == null ? null : jsonEncode(payload),
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
  // 알림을 눌렀을 때 화면을 옮기려면 라우터와 현재 사용자가 필요하다.
  // 서비스가 싱글톤이라 여러 번 붙어도 같은 ref 로 덮어쓸 뿐이다.
  return NotificationService()..attachRef(ref);
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
