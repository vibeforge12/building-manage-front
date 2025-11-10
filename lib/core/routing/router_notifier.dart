import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/main_home_screen.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/admin_login_selection_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/resident_signup_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_login_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/admin_login_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_account_issuance_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_management_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/manager_dashboard_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/manager_staff_login_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/attendance_history_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_login_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_dashboard_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_management_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_registration_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_list_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/department_creation_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/admin_account_issuance_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/manager_list_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/manager_detail_screen.dart';

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
      '/manager/attendance-history',
      '/headquarters/dashboard',
      '/headquarters/building-management',
      '/headquarters/building-registration',
      '/headquarters/building-list',
      '/headquarters/department-creation',
      '/headquarters/admin-account-issuance',
    ];

    final isProtectedRoute = protectedRoutes.any((route) => path?.startsWith(route) == true);

    // 보호된 경로에 접근하려는데 인증되지 않은 경우
    if (isProtectedRoute && authState != AuthState.authenticated) {
      // 경로에 따라 적절한 로그인 화면으로 리다이렉트
      if (path?.startsWith('/user/') == true) {
        return '/user-login';
      } else if (path?.startsWith('/admin/') == true) {
        return '/admin-login';
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
      builder: (context, state) => const AdminDashboardScreen(),
    ),

    // 담당자 관리 (보호된 경로)
    GoRoute(
      path: '/admin/staff-management',
      name: 'staffManagement',
      builder: (context, state) => const StaffManagementScreen(),
    ),

    // 담당자 대시보드 (보호된 경로)
    GoRoute(
      path: '/manager/dashboard',
      name: 'managerDashboard',
      builder: (context, state) => const ManagerDashboardScreen(),
    ),

    // 출퇴근 조회 (담당자 전용)
    GoRoute(
      path: '/manager/attendance-history',
      name: 'attendanceHistory',
      builder: (context, state) => const AttendanceHistoryScreen(),
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

    // 건물 목록 (보호된 경로)
    GoRoute(
      path: '/headquarters/building-list',
      name: 'buildingList',
      builder: (context, state) => const BuildingListScreen(),
    ),

    // 관리자 목록 (보호된 경로)
    GoRoute(
      path: '/headquarters/manager-list',
      name: 'managerList',
      builder: (context, state) => const ManagerListScreen(),
    ),

    // 관리자 상세 (보호된 경로)
    GoRoute(
      path: '/headquarters/manager-detail/:managerId',
      name: 'managerDetail',
      builder: (context, state) {
        final managerId = state.pathParameters['managerId']!;
        return ManagerDetailScreen(managerId: managerId);
      },
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
