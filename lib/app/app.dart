import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:building_manage_front/core/providers/router_provider.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/common/services/notification_service.dart';
import 'package:building_manage_front/core/network/api_client.dart';

import '../core/constants/auth_states.dart';
import '../core/constants/user_types.dart';

class BuildingManageApp extends ConsumerWidget {
  const BuildingManageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // FCM 토큰 등록/정리 (로그인/로그아웃 시)
    ref.listen(authStateProvider, (previous, current) {
      // 로그인 완료: FCM 토큰 등록
      if (current == AuthState.authenticated &&
          previous != AuthState.authenticated) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await _registerFcmToken(ref, user);
            } catch (e) {
              print('❌ FCM 토큰 등록 중 오류: $e');
            }
          });
        }
      } else if (current == AuthState.unauthenticated &&
                 previous != null &&
                 previous != AuthState.initial) {
        // 로그아웃 완료: FCM 토큰 정리
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
  static Future<void> _registerFcmToken(WidgetRef ref, dynamic user) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final apiClient = ref.read(apiClientProvider);

      // 사용자 타입 결정
      final userType = user.userType?.code.toLowerCase() ?? 'user';

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
