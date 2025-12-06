import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:building_manage_front/core/providers/router_provider.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/common/services/notification_service.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/domain/entities/user.dart';

import '../core/constants/auth_states.dart';

class BuildingManageApp extends ConsumerWidget {
  final String? initError;

  const BuildingManageApp({super.key, this.initError});

  // FCM 토큰 등록 여부 추적 (중복 등록 방지)
  // 주의: 마지막 등록된 사용자 ID를 저장하여, 다른 사용자 로그인 시에도 재등록
  static String? _lastRegisteredUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // 현재 사용자 정보 가져오기 (한 번만)
    final currentUser = ref.watch(currentUserProvider);

    // 앱 시작 시 FCM 초기화 시도 (ref.listen 외에 추가 안전장치)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryInitializeFcm(ref, currentUser);
    });

    // FCM 토큰 등록 (사용자 정보가 변경될 때)
    ref.listen(currentUserProvider, (previous, current) {
      print('🔔 [FCM-APP] currentUserProvider 변경 감지!');
      print('🔔 [FCM-APP] previous: ${previous?.name ?? "null"} (id: ${previous?.id ?? "null"})');
      print('🔔 [FCM-APP] current: ${current?.name ?? "null"} (id: ${current?.id ?? "null"})');
      print('🔔 [FCM-APP] _lastRegisteredUserId: $_lastRegisteredUserId');

      // 사용자가 있고, 새로운 사용자이거나 아직 등록 안 한 경우
      if (current != null) {
        final shouldRegister = _lastRegisteredUserId != current.id;
        print('🔔 [FCM-APP] shouldRegister: $shouldRegister');

        if (shouldRegister) {
          print('🔔 [FCM-APP] ✅ 조건 만족! FCM 토큰 등록 시작...');
          print('🔔 [FCM-APP] userType: ${current.userType}');
          print('🔔 [FCM-APP] userType.code: ${current.userType.code}');
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            print('🔔 [FCM-APP] PostFrameCallback 실행됨');
            try {
              await _registerFcmToken(ref, current);
              _lastRegisteredUserId = current.id;
              print('🔔 [FCM-APP] ✅ FCM 토큰 등록 완료, _lastRegisteredUserId = ${current.id}');
            } catch (e, stackTrace) {
              print('❌ [FCM-APP] FCM 토큰 등록 중 오류!');
              print('❌ [FCM-APP] 에러: $e');
              print('❌ [FCM-APP] 스택트레이스: $stackTrace');
            }
          });
        } else {
          print('🔔 [FCM-APP] ❌ 이미 해당 사용자로 등록됨 - 스킵');
        }
      } else {
        print('🔔 [FCM-APP] ❌ current가 null - 스킵');
      }
    });

    // FCM 토큰 정리 (실제 로그아웃 시만)
    // 주의: loading → unauthenticated (자동 로그인 실패)는 로그아웃이 아님
    ref.listen(authStateProvider, (previous, current) {
      print('🔔 [FCM-AUTH] authStateProvider 변경: $previous → $current');

      // 실제 로그아웃: authenticated → unauthenticated 변경만 감지
      if (current == AuthState.unauthenticated &&
          previous == AuthState.authenticated) {
        print('🔔 [FCM-AUTH] 로그아웃 감지! 토큰 정리 시작');
        _lastRegisteredUserId = null; // 재로그인 시 다시 등록하도록
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _clearFcmToken(ref);
            print('🔔 [FCM-AUTH] ✅ 토큰 정리 완료');
          } catch (e) {
            print('❌ [FCM-AUTH] 토큰 정리 중 오류: $e');
          }
        });
      }
    });

    return MaterialApp.router(
      title: 'Building Manage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006FFF)),
        useMaterial3: true,
      ),
      // 한국어 로케일 설정
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }

  /// FCM 초기화 시도 (ref.listen 외에 추가 안전장치)
  /// build() 시 사용자가 이미 존재하면 바로 FCM 등록 시도
  static void _tryInitializeFcm(WidgetRef ref, User? currentUser) {
    print('🔔 [FCM-INIT] _tryInitializeFcm 호출됨');
    print('🔔 [FCM-INIT] currentUser: ${currentUser?.name ?? "null"}');
    print('🔔 [FCM-INIT] _lastRegisteredUserId: $_lastRegisteredUserId');

    if (currentUser != null && _lastRegisteredUserId != currentUser.id) {
      print('🔔 [FCM-INIT] ✅ 사용자 있고 미등록 → FCM 등록 시작!');
      _registerFcmTokenAsync(ref, currentUser);
    } else if (currentUser == null) {
      print('🔔 [FCM-INIT] ❌ 사용자 없음 - FCM 등록 스킵');
    } else {
      print('🔔 [FCM-INIT] ❌ 이미 등록됨 - FCM 등록 스킵');
    }
  }

  /// FCM 토큰 비동기 등록 (static async wrapper)
  static void _registerFcmTokenAsync(WidgetRef ref, User user) {
    Future.microtask(() async {
      try {
        await _registerFcmToken(ref, user);
        _lastRegisteredUserId = user.id;
        print('🔔 [FCM-INIT] ✅ FCM 토큰 등록 완료 (async), _lastRegisteredUserId = ${user.id}');
      } catch (e, stackTrace) {
        print('❌ [FCM-INIT] FCM 토큰 등록 오류!');
        print('❌ [FCM-INIT] 에러: $e');
        print('❌ [FCM-INIT] 스택트레이스: $stackTrace');
      }
    });
  }

  /// FCM 토큰 등록
  static Future<void> _registerFcmToken(WidgetRef ref, User user) async {
    print('🔔 [FCM-APP] _registerFcmToken 시작');
    print('🔔 [FCM-APP] user.name: ${user.name}');
    print('🔔 [FCM-APP] user.userType: ${user.userType}');
    print('🔔 [FCM-APP] user.userType.code: ${user.userType.code}');

    try {
      print('🔔 [FCM-APP] notificationService 획득 중...');
      final notificationService = ref.read(notificationServiceProvider);
      print('🔔 [FCM-APP] ✅ notificationService 획득 완료');

      print('🔔 [FCM-APP] apiClient 획득 중...');
      final apiClient = ref.read(apiClientProvider);
      print('🔔 [FCM-APP] ✅ apiClient 획득 완료');

      // 사용자 타입 결정 (UserType enum의 code를 소문자로)
      // user, admin, manager, headquarters 중 하나
      final userType = user.userType.code.toLowerCase();
      print('🔔 [FCM-APP] userType (lowercase): $userType');

      // FCM 초기화 및 토큰 등록
      print('🔔 [FCM-APP] initialize() 호출 중...');
      await notificationService.initialize(apiClient);
      print('🔔 [FCM-APP] ✅ initialize() 완료');

      print('🔔 [FCM-APP] requestPermissions() 호출 중...');
      await notificationService.requestPermissions();
      print('🔔 [FCM-APP] ✅ requestPermissions() 완료');

      print('🔔 [FCM-APP] registerPushToken() 호출 중...');
      await notificationService.registerPushToken(userType: userType);
      print('🔔 [FCM-APP] ✅ registerPushToken() 완료');

      print('✅ [FCM-APP] FCM 토큰 등록 전체 완료: $userType');
    } catch (e, stackTrace) {
      print('❌ [FCM-APP] _registerFcmToken 실패!');
      print('❌ [FCM-APP] 에러: $e');
      print('❌ [FCM-APP] 스택트레이스: $stackTrace');
    }
  }

  /// FCM 토큰 정리
  static Future<void> _clearFcmToken(WidgetRef ref) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.clearPushToken();
      print('✅ FCM 토큰 정리 완료');
    } catch (e) {
      print('❌ FCM 토큰 정리 실패: $e');
    }
  }
}
