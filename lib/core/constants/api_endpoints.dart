class ApiEndpoints {
  // Auth endpoints - 인증 관련
  static const String auth = '/auth';

  // 회원가입 엔드포인트
  static const String residentRegister = '$auth/resident/register';
  static const String managerRegister = '$auth/manager/register';

  // 로그인 엔드포인트
  static const String residentLogin = '$auth/resident/login';
  static const String managerLogin = '$auth/manager/login';
  static const String staffLogin = '$auth/staff/login';
  static const String headquartersLogin = '$auth/headquarters/login';

  // Token 관련
  static const String refreshToken = '$auth/refresh';
  static const String logout = '$auth/logout';

  // User endpoints - 유저 관련
  static const String user = '/user';
  static const String userProfile = '$user/profile';
  static const String userDashboard = '$user/dashboard';

  // Admin endpoints - 관리자 관련
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String residents = '$admin/residents';

  // Manager endpoints - 담당자 관련
  static const String manager = '/manager';
  static const String managerDashboard = '$manager/dashboard';
  static const String tasks = '$manager/tasks';

  // Headquarters endpoints - 본사 관련
  static const String headquarters = '/headquarters';
  static const String headquartersDashboard = '$headquarters/dashboard';
  static const String buildings = '$headquarters/buildings';

  // Common endpoints - 공통
  static const String notifications = '/notifications';
  static const String announcements = '/announcements';
  static const String facilities = '/facilities';

  // Departments - 부서 관련
  static const String departments = '/common/departments';

  // Notice & Event - 공지사항 및 이벤트
  static const String notices = '/notices';
  static const String events = '/events';
  static const String managerNotices = '/managers/notices';
  static const String managerEvents = '/managers/events';

  // Manager/Staff Complaints - 담당자 민원 관리
  static const String managerComplaints = '/managers/complaints';
  static const String managerComplaintsPending = '$managerComplaints/pending';
  static const String managerComplaintsResolved = '$managerComplaints/resolved';

  // Staff Complaints - 담당자 민원
  static const String staffComplaints = '/staffs/complaints';
  static const String staffComplaintsPendingHighlight = '$staffComplaints/pending/highlight';
  static const String staffComplaintsPending = '$staffComplaints/pending';
  static const String staffComplaintsResolved = '$staffComplaints/resolved';
  static const String staffComplaintDetail = '$staffComplaints/{complaintId}';
  static const String staffComplaintResolve = '$staffComplaints/{complaintId}/resolve';

  // Staff Notices - 담당자 공지사항
  static const String staffNotices = '/staffs/notices';
  static const String staffNoticeDetail = '$staffNotices/{noticeId}';
}
