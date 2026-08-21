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
import 'package:building_manage_front/modules/resident/presentation/screens/user_dashboard_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/notice_detail_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/notice_list_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/event_detail_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/event_list_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/complaint_create_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/complaint_complete_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/my_complaint_list_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/resident_approval_pending_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/resident_approval_completed_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/resident_approval_rejected_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_complaint_detail_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_profile_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/change_password_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/password_reset_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/new_password_reset_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/admin_login_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_account_issuance_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_management_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_edit_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/resident_management_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/resident_detail_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/notice_management_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/notice_create_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/complaint_management_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/complaint_detail_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_attendance_list_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_attendance_calendar_screen.dart';
import 'package:building_manage_front/modules/admin/presentation/screens/staff_attendance_current_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/manager_dashboard_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/manager_staff_login_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/attendance_history_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/add_general_manager_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/staff_complaint_detail_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/staff_notice_detail_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/staff_complaints_list_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/staff_notice_list_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/complaint_resolve_screen.dart';
import 'package:building_manage_front/modules/manager/presentation/screens/complaint_resolve_complete_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_login_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_dashboard_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/management_selection_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_management_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_registration_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/building_list_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/department_creation_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/admin_account_issuance_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/manager_list_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/manager_detail_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_profile_screen.dart';
import 'package:building_manage_front/modules/headquarters/presentation/screens/headquarters_change_password_screen.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/splash_screen.dart';

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
    final path = state.fullPath;

    // 승인이 거부된 사용자는 모든 경로 접근 차단 (거부 화면으로만 접근 가능)
    if (authState == AuthState.authenticated &&
        currentUser != null &&
        currentUser.userType == UserType.user &&
        currentUser.approvalStatus == 'REJECTED' &&
        path != '/resident-approval-rejected') {
      return '/resident-approval-rejected';
    }

    // 접근 권한이 필요한 경로인지 판정 (접두어 기반)
    final requiredUserType = _requiredUserTypeFor(path);

    // 보호된 경로에 접근하려는데 인증되지 않은 경우 → 역할별 로그인 화면
    if (requiredUserType != null && authState != AuthState.authenticated) {
      return _getLoginPath(requiredUserType);
    }

    // 인증된 사용자가 잘못된 권한의 경로에 접근하는 경우 → 자기 역할 대시보드
    if (requiredUserType != null &&
        authState == AuthState.authenticated &&
        currentUser != null &&
        currentUser.userType != requiredUserType) {
      return _getDefaultDashboard(currentUser.userType);
    }

    return null; // 리다이렉트 없음
  }

  List<RouteBase> get _routes => [
    // 스플래시 화면 (자동 로그인 체크)
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

    // 비밀번호 찾기 (공개 경로)
    GoRoute(
      path: '/password-reset',
      name: 'passwordReset',
      builder: (context, state) => const PasswordResetScreen(),
    ),

    // 새 비밀번호 재설정 (공개 경로)
    GoRoute(
      path: '/new-password-reset',
      name: 'newPasswordReset',
      builder: (context, state) {
        final phoneNumber = state.uri.queryParameters['phoneNumber']!;
        final code = state.uri.queryParameters['code']!;
        return NewPasswordResetScreen(
          phoneNumber: phoneNumber,
          code: code,
        );
      },
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
      builder: (context, state) => const UserDashboardScreen(),
    ),

    // 내 정보 (보호된 경로)
    GoRoute(
      path: '/user/profile',
      name: 'userProfile',
      builder: (context, state) => const UserProfileScreen(),
    ),

    // 비밀번호 변경 (보호된 경로)
    GoRoute(
      path: '/user/change-password',
      name: 'changePassword',
      builder: (context, state) => const ChangePasswordScreen(),
    ),

    // 공지사항 목록 (보호된 경로) - 입주민용
    GoRoute(
      path: '/user/notices',
      name: 'userNoticeList',
      builder: (context, state) => const NoticeListScreen(),
    ),

    // 공지사항 상세 (보호된 경로) - 입주민용
    GoRoute(
      path: '/user/notice/:noticeId',
      name: 'userNoticeDetail',
      builder: (context, state) {
        final noticeId = state.pathParameters['noticeId']!;
        return NoticeDetailScreen(noticeId: noticeId);
      },
    ),

    // 이벤트 목록 (보호된 경로) - 입주민용
    GoRoute(
      path: '/user/events',
      name: 'userEventList',
      builder: (context, state) => const EventListScreen(),
    ),

    // 이벤트 상세 (보호된 경로) - 입주민용
    GoRoute(
      path: '/user/event/:eventId',
      name: 'userEventDetail',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        return EventDetailScreen(eventId: eventId);
      },
    ),

    // 민원 등록 (보호된 경로)
    GoRoute(
      path: '/user/complaint-create',
      name: 'complaintCreate',
      builder: (context, state) {
        final departmentId = state.uri.queryParameters['departmentId']!;
        final departmentName = state.uri.queryParameters['departmentName']!;
        return ComplaintCreateScreen(
          departmentId: departmentId,
          departmentName: departmentName,
        );
      },
    ),

    // 민원 등록 완료 (보호된 경로)
    GoRoute(
      path: '/user/complaint-complete',
      name: 'complaintComplete',
      builder: (context, state) => const ComplaintCompleteScreen(),
    ),

    // 내 민원 보기 (보호된 경로)
    GoRoute(
      path: '/user/my-complaints',
      name: 'myComplaints',
      builder: (context, state) => const MyComplaintListScreen(),
    ),

    // 민원 상세 조회 (보호된 경로)
    GoRoute(
      path: '/user/complaint/:complaintId',
      name: 'userComplaintDetail',
      builder: (context, state) {
        final complaintId = state.pathParameters['complaintId']!;
        final complaintData = state.extra as Map<String, dynamic>? ?? {};
        return UserComplaintDetailScreen(
          complaintId: complaintId,
          complaintData: complaintData,
        );
      },
    ),

    // 입주민 승인 대기 화면
    GoRoute(
      path: '/resident-approval-pending',
      name: 'residentApprovalPending',
      builder: (context, state) => const ResidentApprovalPendingScreen(),
    ),

    // 입주민 승인 완료 화면
    GoRoute(
      path: '/resident-approval-completed',
      name: 'residentApprovalCompleted',
      builder: (context, state) => const ResidentApprovalCompletedScreen(),
    ),

    // 입주민 승인 거부 화면
    GoRoute(
      path: '/resident-approval-rejected',
      name: 'residentApprovalRejected',
      builder: (context, state) {
        final reason = state.uri.queryParameters['reason'];
        return ResidentApprovalRejectedScreen(reason: reason);
      },
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

    // 담당자 수정 (보호된 경로)
    GoRoute(
      path: '/admin/staff-edit/:staffId',
      name: 'staffEdit',
      builder: (context, state) {
        final staffId = state.pathParameters['staffId']!;
        return StaffEditScreen(staffId: staffId);
      },
    ),

    // 입주민 관리 (보호된 경로)
    GoRoute(
      path: '/admin/resident-management',
      name: 'residentManagement',
      builder: (context, state) => const ResidentManagementScreen(),
    ),

    // 입주민 상세 (관리자 전용)
    GoRoute(
      path: '/admin/resident-detail',
      name: 'residentDetail',
      builder: (context, state) {
        final resident = state.extra as Map<String, dynamic>? ?? {};
        return ResidentDetailScreen(resident: resident);
      },
    ),

    // 공지사항 관리 (보호된 경로)
    GoRoute(
      path: '/admin/notice-management',
      name: 'noticeManagement',
      builder: (context, state) => const NoticeManagementScreen(),
    ),

    // 공지사항/이벤트 등록 (보호된 경로)
    GoRoute(
      path: '/admin/notice-create',
      name: 'noticeCreate',
      builder: (context, state) {
        final isEvent = state.uri.queryParameters['isEvent'] == 'true';
        return NoticeCreateScreen(isEvent: isEvent);
      },
    ),

    // 공지사항/이벤트 상세 및 수정 (보호된 경로)
    GoRoute(
      path: '/admin/notice-detail/:noticeId',
      name: 'noticeDetail',
      builder: (context, state) {
        final noticeId = state.pathParameters['noticeId']!;
        final isEvent = state.uri.queryParameters['isEvent'] == 'true';
        return NoticeCreateScreen(
          noticeId: noticeId,
          isEvent: isEvent,
        );
      },
    ),

    // 민원 관리 (보호된 경로)
    GoRoute(
      path: '/admin/complaint-management',
      name: 'complaintManagement',
      builder: (context, state) => const ComplaintManagementScreen(),
    ),

    // 담당자 출퇴근 목록 (관리자 전용)
    GoRoute(
      path: '/admin/staff-attendance-list',
      name: 'staffAttendanceList',
      builder: (context, state) => const StaffAttendanceListScreen(),
    ),

    // 직원 출퇴근 캘린더 (관리자 전용)
    GoRoute(
      path: '/admin/staff-attendance-calendar',
      name: 'staffAttendanceCalendar',
      builder: (context, state) => const StaffAttendanceCalendarScreen(),
    ),

    // 실시간 출퇴근 현황 (관리자 전용)
    GoRoute(
      path: '/admin/staff-attendance-current',
      name: 'staffAttendanceCurrent',
      builder: (context, state) => const StaffAttendanceCurrentScreen(),
    ),

    // 민원 상세 (보호된 경로)
    GoRoute(
      path: '/admin/complaint-detail/:complaintId',
      name: 'complaintDetail',
      builder: (context, state) {
        final complaintId = state.pathParameters['complaintId']!;
        return ComplaintDetailScreen(complaintId: complaintId);
      },
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

    // 일반관리자 추가 (총관리자 전용)
    GoRoute(
      path: '/manager/add-general-manager',
      name: 'addGeneralManager',
      builder: (context, state) => const AddGeneralManagerScreen(),
    ),

    // 민원 상세 조회 (담당자 전용)
    GoRoute(
      path: '/manager/complaint-detail/:complaintId',
      name: 'staffComplaintDetail',
      builder: (context, state) {
        final complaintId = state.pathParameters['complaintId']!;
        return StaffComplaintDetailScreen(complaintId: complaintId);
      },
    ),

    // 공지사항 상세 조회 (담당자 전용)
    GoRoute(
      path: '/manager/notice-detail/:noticeId',
      name: 'staffNoticeDetail',
      builder: (context, state) {
        final noticeId = state.pathParameters['noticeId']!;
        return StaffNoticeDetailScreen(noticeId: noticeId);
      },
    ),

    // 미완료 민원 목록 (담당자 전용)
    GoRoute(
      path: '/manager/complaints',
      name: 'staffComplaintsList',
      builder: (context, state) => const StaffComplaintsListScreen(),
    ),

    // 공지사항 목록 (담당자 전용)
    GoRoute(
      path: '/manager/notices',
      name: 'staffNoticesList',
      builder: (context, state) => const StaffNoticeListScreen(),
    ),

    // 민원 처리 등록 (담당자 전용)
    GoRoute(
      path: '/manager/complaint-resolve/:complaintId',
      name: 'complaintResolve',
      builder: (context, state) {
        final complaintId = state.pathParameters['complaintId']!;
        final complaintTitle = state.extra as String? ?? '민원';
        final complaintData = <String, dynamic>{};
        return ComplaintResolveScreen(
          complaintId: complaintId,
          complaintTitle: complaintTitle,
          complaintData: complaintData,
        );
      },
    ),

    // 민원 처리 완료 (담당자 전용)
    GoRoute(
      path: '/manager/complaint-resolve-complete',
      name: 'complaintResolveComplete',
      builder: (context, state) => const ComplaintResolveCompleteScreen(),
    ),

    // 본사 대시보드 (보호된 경로)
    GoRoute(
      path: '/headquarters/dashboard',
      name: 'headquartersDashboard',
      builder: (context, state) => const HeadquartersDashboardScreen(),
    ),

    // 관리 선택 (보호된 경로) - 건물/부서 선택 페이지
    GoRoute(
      path: '/headquarters/management-selection',
      name: 'managementSelection',
      builder: (context, state) => const ManagementSelectionScreen(),
    ),

    // 건물 관리 (보호된 경로) - 건물 등록/관리 페이지
    GoRoute(
      path: '/headquarters/building-management',
      name: 'buildingManagement',
      builder: (context, state) => const BuildingManagementScreen(),
    ),

    // 부서 관리 (보호된 경로) - 부서 생성/관리 페이지
    GoRoute(
      path: '/headquarters/department-management',
      name: 'departmentManagement',
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

    // 본사 마이페이지 (보호된 경로)
    GoRoute(
      path: '/headquarters/profile',
      name: 'headquartersProfile',
      builder: (context, state) => const HeadquartersProfileScreen(),
    ),

    // 본사 비밀번호 수정 (보호된 경로)
    GoRoute(
      path: '/headquarters/change-password',
      name: 'headquartersChangePassword',
      builder: (context, state) => const HeadquartersChangePasswordScreen(),
    ),

    // 담당자 계정 발급 (관리자 전용)
    GoRoute(
      path: '/admin/staff-account-issuance',
      name: 'staffAccountIssuance',
      builder: (context, state) => const StaffAccountIssuanceScreen(),
    ),
  ];

  /// 역할별 보호 경로 접두어.
  ///
  /// 접두어로 판정하므로 새 라우트를 추가해도 자동으로 보호된다.
  /// (경로를 배열에 일일이 나열하던 이전 방식은 13개 라우트가 누락돼 있었다.)
  static const Map<String, UserType> _protectedPrefixes = {
    '/user/': UserType.user,
    '/admin/': UserType.admin,
    '/manager/': UserType.manager,
    '/headquarters/': UserType.headquarters,
  };

  /// 접두어 규칙의 예외.
  ///
  /// `/manager/add-general-manager`는 경로만 담당자(manager) 접두어일 뿐,
  /// 실제로는 총관리자(관리자, admin)가 일반관리자를 추가하는 관리자 전용 기능이다.
  /// (`admin_dashboard_screen`에서 진입한다.)
  /// 근본 해결은 화면/데이터소스를 admin 모듈로 옮기고 경로를 `/admin/...`으로
  /// 바꾸는 것이지만, 경로 변경은 별도 결정 사항이라 여기서 예외로 처리한다.
  static const Map<String, UserType> _routeOwnerOverrides = {
    '/manager/add-general-manager': UserType.admin,
  };

  /// 해당 경로에 필요한 사용자 유형. 공개 경로면 null.
  UserType? _requiredUserTypeFor(String? path) {
    if (path == null) return null;

    final override = _routeOwnerOverrides[path];
    if (override != null) return override;

    for (final entry in _protectedPrefixes.entries) {
      if (path.startsWith(entry.key)) return entry.value;
    }
    return null;
  }

  String _getLoginPath(UserType userType) {
    switch (userType) {
      case UserType.user:
        return '/user-login';
      case UserType.admin:
        return '/admin-login';
      case UserType.manager:
        return '/manager-login';
      case UserType.headquarters:
        return '/headquarters-login';
    }
  }

  /// 유저 타입별 기본 대시보드 경로 반환
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
}
