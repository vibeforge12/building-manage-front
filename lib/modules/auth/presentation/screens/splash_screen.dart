import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // 최소 스플래시 표시 시간 (UX 향상)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final authDataSource = ref.read(authRemoteDataSourceProvider);

      // 자동 로그인 체크 (저장된 토큰이 있을 때만 시도)
      await authNotifier.checkAutoLogin(authDataSource);

      if (!mounted) {
        return;
      }

      // 결과에 따라 화면 이동
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      if (authState == AuthState.authenticated && currentUser != null) {
        // 자동 로그인 성공 → 승인 상태 확인 후 적절한 화면으로 이동
        if (currentUser.userType == UserType.user) {
          // 입주민의 경우 승인 상태 체크
          final approvalStatus = currentUser.approvalStatus;

          if (approvalStatus == 'PENDING') {
            // 승인 대기 중
            context.go('/resident-approval-pending');
            return;
          } else if (approvalStatus == 'REJECTED') {
            // 승인 거부됨
            context.go('/resident-approval-rejected');
            return;
          } else if (approvalStatus == 'APPROVED') {
            // 승인 완료 - 최초 1회만 승인 완료 화면 표시
            final prefs = await SharedPreferences.getInstance();
            final approvalShownKey = 'approval_shown_${currentUser.id}';
            final hasShownApproval = prefs.getBool(approvalShownKey) ?? false;

            if (!hasShownApproval) {
              // 첫 로그인: 승인 완료 화면 표시
              context.go('/resident-approval-completed');
              return;
            }
            // 이미 승인 완료 화면을 본 경우: 대시보드로 직접 이동
          }
        }

        // 일반 로그인 → 대시보드로 이동
        final dashboardPath = _getDashboardPath(currentUser.userType);
        context.go(dashboardPath);
      } else {
        // 자동 로그인 실패 또는 토큰 없음 → 홈 화면으로 이동
        context.go('/');
      }
    } catch (e) {
      // 에러 발생 시 홈 화면으로 이동
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
