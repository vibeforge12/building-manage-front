import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';

/// 스플래시 화면 - 자동 로그인 체크 후 GoRouter redirect가 처리
///
/// 이 화면은 자동 로그인 체크만 수행하고, 실제 네비게이션은
/// GoRouter의 redirect 함수에서 authState를 확인하여 처리합니다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    // 최소 스플래시 표시 시간 (UX 향상)
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final authDataSource = ref.read(authRemoteDataSourceProvider);

      // 자동 로그인 체크 (이후 authState 변경으로 GoRouter redirect가 처리)
      await authNotifier.checkAutoLogin(authDataSource);

      if (!mounted) return;

      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      print('✅ 스플래시: 자동 로그인 체크 완료 - authState: $authState, user: ${currentUser?.name}');

      // 체크 완료 표시 → GoRouter redirect가 처리
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      print('❌ 스플래시: 자동 로그인 중 오류 - $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // authState를 watch하여 변경 시 리빌드 → GoRouter가 redirect 처리
    final authState = ref.watch(authStateProvider);

    // 체크가 완료되었는데도 아직 splash에 있다면,
    // GoRouter redirect가 처리할 때까지 잠시 대기
    // (authState가 authenticated 또는 unauthenticated로 변경되면 redirect가 트리거됨)

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
