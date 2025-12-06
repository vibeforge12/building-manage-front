import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';

/// 스플래시 화면 - 자동 로그인 체크 후 직접 대시보드 또는 홈으로 이동
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    print('🚀 스플래시: _checkAutoLogin 시작');

    // 최소 스플래시 표시 시간 (UX 향상)
    await Future.delayed(const Duration(milliseconds: 500));
    print('🕐 스플래시: 500ms 딜레이 완료');

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final authDataSource = ref.read(authRemoteDataSourceProvider);
      print('📦 스플래시: Provider 읽기 완료');

      // 자동 로그인 체크
      print('🔄 스플래시: checkAutoLogin 호출...');
      await authNotifier.checkAutoLogin(authDataSource);
      print('✅ 스플래시: checkAutoLogin 완료');

      if (!mounted) {
        print('⚠️ 스플래시: mounted=false, 종료');
        return;
      }

      // 결과에 따라 화면 이동
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);
      print('📊 스플래시: authState=$authState, currentUser=${currentUser?.name ?? 'null'}');

      if (authState == AuthState.authenticated && currentUser != null) {
        // 자동 로그인 성공 → 대시보드로 이동
        final dashboardPath = _getDashboardPath(currentUser.userType);
        print('✅ 스플래시: 자동 로그인 성공 → $dashboardPath');
        context.go(dashboardPath);
      } else {
        // 자동 로그인 실패 → 홈 화면으로 이동
        print('⚠️ 스플래시: 자동 로그인 실패 → 홈 화면 (authState=$authState, user=${currentUser == null ? 'null' : 'exists'})');
        context.go('/');
      }
    } catch (e, stackTrace) {
      print('❌ 스플래시: 자동 로그인 중 오류 - $e');
      print('📜 스택트레이스: $stackTrace');
      if (mounted) {
        context.go('/');
      }
    }
  }

  String _getDashboardPath(UserType? userType) {
    switch (userType) {
      case UserType.user:
        return '/user/dashboard';
      case UserType.admin:
        return '/admin/dashboard';
      case UserType.manager:
        return '/manager/dashboard';
      case UserType.headquarters:
        return '/headquarters/dashboard';
      default:
        return '/';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_icon.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.apartment,
                  size: 100,
                  color: Color(0xFF006FFF),
                );
              },
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
            ),
          ],
        ),
      ),
    );
  }
}
