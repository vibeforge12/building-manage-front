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

  // FCM 등록 진행 중 플래그 (중복 호출 방지)
  static bool _isRegistering = false;

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
      // 사용자가 있고, 새로운 사용자이거나 아직 등록 안 한 경우
      if (current != null && _lastRegisteredUserId != current.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _registerFcmToken(ref, current);
            _lastRegisteredUserId = current.id;
          } catch (e) {
            // Token registration error
          }
        });
      }
    });

    // FCM 토큰 정리 (실제 로그아웃 시만)
    // 주의: loading → unauthenticated (자동 로그인 실패)는 로그아웃이 아님
    ref.listen(authStateProvider, (previous, current) {
      // 실제 로그아웃: authenticated → unauthenticated 변경만 감지
      if (current == AuthState.unauthenticated &&
          previous == AuthState.authenticated) {
        _lastRegisteredUserId = null; // 재로그인 시 다시 등록하도록
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _clearFcmToken(ref);
          } catch (e) {
            // Token cleanup error
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
    if (currentUser != null && _lastRegisteredUserId != currentUser.id) {
      _registerFcmTokenAsync(ref, currentUser);
    }
  }

  /// FCM 토큰 비동기 등록 (static async wrapper)
  static void _registerFcmTokenAsync(WidgetRef ref, User user) {
    Future.microtask(() async {
      try {
        await _registerFcmToken(ref, user);
        _lastRegisteredUserId = user.id;
      } catch (e) {
        // Token registration error
      }
    });
  }

  /// FCM 토큰 등록
  static Future<void> _registerFcmToken(WidgetRef ref, User user) async {
    // 이미 등록 중이면 스킵 (중복 호출 방지)
    if (_isRegistering) {
      return;
    }

    // 이미 이 사용자로 등록되어 있으면 스킵
    if (_lastRegisteredUserId == user.id) {
      return;
    }

    _isRegistering = true;

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final apiClient = ref.read(apiClientProvider);

      // 사용자 타입 결정 (UserType enum의 code를 소문자로)
      final userType = user.userType.code.toLowerCase();

      // FCM 초기화 및 토큰 등록
      await notificationService.initialize(apiClient);
      await notificationService.requestPermissions();
      await notificationService.registerPushToken(userType: userType);
    } catch (e) {
      // FCM token registration failed
    } finally {
      _isRegistering = false;
    }
  }

  /// FCM 토큰 정리
  static Future<void> _clearFcmToken(WidgetRef ref) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.clearPushToken();
    } catch (e) {
      // FCM token cleanup failed
    }
  }
}
