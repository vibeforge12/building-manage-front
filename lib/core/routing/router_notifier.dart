import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/presentation/auth/providers/auth_state_provider.dart';
import 'package:building_manage_front/presentation/auth/screens/main_home_screen.dart';
import 'package:building_manage_front/presentation/auth/screens/admin_login_selection_screen.dart';
import 'package:building_manage_front/presentation/auth/screens/sign_up_screen.dart';
import 'package:building_manage_front/presentation/user/screens/user_login_screen.dart';
import 'package:building_manage_front/presentation/manager/screens/manager_staff_login_screen.dart';
import 'package:building_manage_front/presentation/headquarters/screens/headquarters_login_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final GoRouter _router;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (previous, next) {
      notifyListeners();
    });

    _ref.listen<User?>(currentUserProvider, (previous, next) {
      notifyListeners();
    });

    _setupRouter();
  }

  GoRouter get router => _router;

  void _setupRouter() {
    _router = GoRouter(
      refreshListenable: this,
      initialLocation: '/',
      redirect: _redirect,
      routes: _routes,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final currentUser = _ref.read(currentUserProvider);
    final path = state.fullPath;

    // 인증이 필요한 경로들
    final protectedRoutes = [
      '/user/dashboard',
      '/admin/dashboard',
      '/manager/dashboard',
      '/headquarters/dashboard',
    ];

    final isProtectedRoute = protectedRoutes.any((route) => path?.startsWith(route) == true);

    // 보호된 경로에 접근하려는데 인증되지 않은 경우
    if (isProtectedRoute && authState != AuthState.authenticated) {
      // 경로에 따라 적절한 로그인 화면으로 리다이렉트
      if (path?.startsWith('/user/') == true) {
        return '/user-login';
      } else if (path?.startsWith('/admin/') == true) {
        return '/admin-login-selection';
      } else if (path?.startsWith('/manager/') == true) {
        return '/manager-login';
      } else if (path?.startsWith('/headquarters/') == true) {
        return '/headquarters-login';
      }
      return '/'; // 기본적으로 홈으로
    }

    // 인증된 사용자가 잘못된 권한의 경로에 접근하는 경우
    if (authState == AuthState.authenticated && currentUser != null && isProtectedRoute) {
      final userType = currentUser.userType;

      if (path?.startsWith('/user/') == true && userType != UserType.user) {
        return _getDefaultDashboard(userType);
      } else if (path?.startsWith('/admin/') == true && userType != UserType.admin) {
        return _getDefaultDashboard(userType);
      } else if (path?.startsWith('/manager/') == true && userType != UserType.manager) {
        return _getDefaultDashboard(userType);
      } else if (path?.startsWith('/headquarters/') == true && userType != UserType.headquarters) {
        return _getDefaultDashboard(userType);
      }
    }

    return null; // 리다이렉트 없음
  }

  List<RouteBase> get _routes => [
    // 메인 홈 (로그인 선택)
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainHomeScreen(),
    ),

    // 회원가입
    GoRoute(
      path: '/sign-up',
      name: 'signUp',
      builder: (context, state) => const SignUpScreen(),
    ),

    // 관리자 로그인 선택
    GoRoute(
      path: '/admin-login-selection',
      name: 'adminLoginSelection',
      builder: (context, state) => const AdminLoginSelectionScreen(),
    ),

    // 유저 로그인
    GoRoute(
      path: '/user-login',
      name: 'userLogin',
      builder: (context, state) => const UserLoginScreen(),
    ),

    // 담당자 로그인
    GoRoute(
      path: '/manager-login',
      name: 'managerLogin',
      builder: (context, state) => const ManagerStaffLoginScreen(),
    ),

    // 본사 로그인
    GoRoute(
      path: '/headquarters-login',
      name: 'headquartersLogin',
      builder: (context, state) => const HeadquartersLoginScreen(),
    ),

    // 유저 대시보드 (보호된 경로)
    GoRoute(
      path: '/user/dashboard',
      name: 'userDashboard',
      builder: (context, state) => _buildPlaceholder('User Dashboard'),
    ),

    // 관리자 대시보드 (보호된 경로)
    GoRoute(
      path: '/admin/dashboard',
      name: 'adminDashboard',
      builder: (context, state) => _buildPlaceholder('Admin Dashboard'),
    ),

    // 담당자 대시보드 (보호된 경로)
    GoRoute(
      path: '/manager/dashboard',
      name: 'managerDashboard',
      builder: (context, state) => _buildPlaceholder('Manager Dashboard'),
    ),

    // 본사 대시보드 (보호된 경로)
    GoRoute(
      path: '/headquarters/dashboard',
      name: 'headquartersDashboard',
      builder: (context, state) => _buildPlaceholder('Headquarters Dashboard'),
    ),
  ];

  // 유저 타입별 기본 대시보드 경로 반환
  String _getDefaultDashboard(UserType userType) {
    switch (userType) {
      case UserType.user:
        return '/user/dashboard';
      case UserType.admin:
        return '/admin/dashboard';
      case UserType.manager:
        return '/manager/dashboard';
      case UserType.headquarters:
        return '/headquarters/dashboard';
    }
  }

  // 임시 플레이스홀더 위젯 생성
  Widget _buildPlaceholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('대시보드 화면이 여기에 구현될 예정입니다.'),
          ],
        ),
      ),
    );
  }
}