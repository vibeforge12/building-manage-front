import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/splash_screen.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/main_home_screen.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/admin_login_selection_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/resident_signup_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_login_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_dashboard_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/admin_login_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_account_issuance_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/manager_staff_login_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_login_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_dashboard_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_management_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_registration_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/department_creation_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/admin_account_issuance_screen.dart';

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
      initialLocation: '/splash',
      redirect: _redirect,
      routes: _routes,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final currentUser = _ref.read(currentUserProvider);
    final path = state.fullPath ?? '/';

    print('🔄 Router redirect - path: $path, authState: $authState, user: ${currentUser?.name}');

    // ========================================
    // 1. 스플래시 화면 처리 (자동 로그인 체크 중)
    // ========================================
    if (path == '/splash') {
      // 아직 체크 중 (initial 또는 loading) → 스플래시 유지
      if (authState == AuthState.initial || authState == AuthState.loading) {
        print('🔄 스플래시 유지 - 자동 로그인 체크 중...');
        return null;
      }

      // 인증됨 + 사용자 정보 있음 → 대시보드로 이동
      if (authState == AuthState.authenticated && currentUser != null) {
        final dashboard = _getDefaultDashboard(currentUser.userType);
        print('✅ 스플래시 → 대시보드: $dashboard');
        return dashboard;
      }

      // 인증됨 but 사용자 정보 없음 → 아직 동기화 중이므로 스플래시 유지
      if (authState == AuthState.authenticated && currentUser == null) {
        print('🔄 스플래시 유지 - 사용자 정보 로드 대기 중...');
        return null;
      }

      // 미인증 → 홈 화면으로 이동
      print('⚠️ 스플래시 → 홈 화면');
      return '/';
    }

    // ========================================
    // 2. 공개 경로 처리 (로그인 화면 등)
    // ========================================
    final publicRoutes = [
      '/',
      '/admin-login-selection',
      '/user-login',
      '/admin-login',
      '/manager-login',
      '/headquarters-login',
      '/resident-signup',
      '/password-reset',
      '/new-password-reset',
    ];

    final isPublicRoute = publicRoutes.any(
      (route) => path == route || (route != '/' && path.startsWith(route))
    );

    if (isPublicRoute) {
      // 이미 인증된 사용자가 로그인 화면에 접근 → 대시보드로 리다이렉트
      if (authState == AuthState.authenticated && currentUser != null) {
        final dashboard = _getDefaultDashboard(currentUser.userType);
        print('✅ 인증된 사용자 로그인 화면 접근 → 대시보드: $dashboard');
        return dashboard;
      }
      return null;
    }

    // ========================================
    // 3. 보호된 경로 처리 (대시보드 등)
    // ========================================
    // 인증되지 않았으면 로그인 화면으로 리다이렉트
    if (authState != AuthState.authenticated || currentUser == null) {
      if (path.startsWith('/resident/')) {
        return '/user-login';
      } else if (path.startsWith('/admin/')) {
        return '/admin-login';
      } else if (path.startsWith('/manager/')) {
        return '/manager-login';
      } else if (path.startsWith('/headquarters/')) {
        return '/headquarters-login';
      }
      return '/';
    }

    // 인증된 사용자: 권한 확인
    final userType = currentUser.userType;

    if (path.startsWith('/resident/') && userType != UserType.user) {
      return _getDefaultDashboard(userType);
    } else if (path.startsWith('/admin/') && userType != UserType.admin) {
      return _getDefaultDashboard(userType);
    } else if (path.startsWith('/manager/') && userType != UserType.manager) {
      return _getDefaultDashboard(userType);
    } else if (path.startsWith('/headquarters/') && userType != UserType.headquarters) {
      return _getDefaultDashboard(userType);
    }

    return null; // 리다이렉트 없음
  }

  List<RouteBase> get _routes => [
    // 스플래시 화면 (앱 시작점)
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // 메인 홈 (로그인 선택)
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainHomeScreen(),
    ),

    // 입주민 회원가입
    GoRoute(
      path: '/resident-signup',
      name: 'residentSignup',
      builder: (context, state) => const ResidentSignupScreen(),
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

    // 관리자 로그인
    GoRoute(
      path: '/admin-login',
      name: 'adminLogin',
      builder: (context, state) => const AdminLoginScreen(),
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

    // 입주민 대시보드 (보호된 경로)
    GoRoute(
      path: '/resident/dashboard',
      name: 'userDashboard',
      builder: (context, state) => const UserDashboardScreen(),
    ),

    // 관리자 대시보드 (보호된 경로)
    GoRoute(
      path: '/admin/dashboard',
      name: 'adminDashboard',
      builder: (context, state) => const AdminDashboardScreen(),
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
      builder: (context, state) => const HeadquartersDashboardScreen(),
    ),

    // 건물 관리 (보호된 경로)
    GoRoute(
      path: '/headquarters/building-management',
      name: 'buildingManagement',
      builder: (context, state) => const BuildingManagementScreen(),
    ),

    // 건물 등록 (보호된 경로)
    GoRoute(
      path: '/headquarters/building-registration',
      name: 'buildingRegistration',
      builder: (context, state) => const BuildingRegistrationScreen(),
    ),

    // 부서 생성 (보호된 경로)
    GoRoute(
      path: '/headquarters/department-creation',
      name: 'departmentCreation',
      builder: (context, state) => const DepartmentCreationScreen(),
    ),

    // 관리자 계정 발급 (보호된 경로)
    GoRoute(
      path: '/headquarters/admin-account-issuance',
      name: 'adminAccountIssuance',
      builder: (context, state) => const AdminAccountIssuanceScreen(),
    ),

    // 담당자 계정 발급 (관리자 전용)
    GoRoute(
      path: '/admin/staff-account-issuance',
      name: 'staffAccountIssuance',
      builder: (context, state) => const StaffAccountIssuanceScreen(),
    ),
  ];

  // 유저 타입별 기본 대시보드 경로 반환
  String _getDefaultDashboard(UserType userType) {
    switch (userType) {
      case UserType.user:
        return '/resident/dashboard';
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