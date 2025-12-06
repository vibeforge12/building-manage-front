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
  static bool _fcmRegistered = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // FCM 토큰 등록 (사용자 정보가 설정되면)
    ref.listen(currentUserProvider, (previous, current) {
      // 사용자가 로그인 됨 (current가 있고, 아직 등록 안 했으면)
      // previous 조건 제거 - 자동 로그인 시에도 트리거되도록
      if (current != null && !_fcmRegistered) {
        print('📱 FCM: 사용자 감지 (${current.name}) → 토큰 등록 시작');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _registerFcmToken(ref, current);
            _fcmRegistered = true;
          } catch (e) {
            print('❌ FCM 토큰 등록 중 오류: $e');
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
        print('📱 FCM: 로그아웃 감지 (authenticated→unauthenticated) → 토큰 정리 시작');
        _fcmRegistered = false; // 재로그인 시 다시 등록하도록
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _clearFcmToken(ref);
          } catch (e) {
            print('❌ FCM 토큰 정리 중 오류: $e');
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

  /// FCM 토큰 등록
  static Future<void> _registerFcmToken(WidgetRef ref, User user) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final apiClient = ref.read(apiClientProvider);

      // 사용자 타입 결정 (UserType enum의 code를 소문자로)
      // user, admin, manager, headquarters 중 하나
      final userType = user.userType.code.toLowerCase();
      print('📱 FCM 등록 시작 - userType: $userType, userName: ${user.name}');

      // FCM 초기화 및 토큰 등록
      await notificationService.initialize(apiClient);
      await notificationService.requestPermissions();
      await notificationService.registerPushToken(userType: userType);

      print('✅ FCM 토큰 등록 완료: $userType');
    } catch (e) {
      print('❌ FCM 토큰 등록 실패: $e');
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
