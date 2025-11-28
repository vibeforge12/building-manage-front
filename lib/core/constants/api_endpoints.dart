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

  // 비밀번호 변경
  static const String residentChangePassword = '$auth/resident/change-password';

  // 비밀번호 재설정 (비밀번호 찾기)
  static const String passwordResetRequest = '$auth/password-reset/request';
  static const String passwordResetVerify = '$auth/password-reset/verify';

  // User endpoints - 유저 관련
  static const String user = '/user';
  static const String userProfile = '$user/profile';
  static const String userDashboard = '$user/dashboard';
  static const String userPushToken = '/users/push-token';  // FCM 토큰 등록 (입주민)

  // Admin endpoints - 관리자 관련
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String residents = '$admin/residents';

  // Manager endpoints - 담당자 관련
  static const String manager = '/manager';
  static const String managerDashboard = '$manager/dashboard';
  static const String tasks = '$manager/tasks';
  static const String staffPushToken = '/staffs/push-token';      // FCM 토큰 등록 (담당자)
  static const String managerPushToken = '/managers/push-token';  // FCM 토큰 등록 (관리자)
  static const String managerDashboardAlerts = '/managers/dashboard/alerts';  // 출퇴근/민원 알림 조회

  // Headquarters endpoints - 본사 관련
  static const String headquarters = '/headquarters';
  static const String headquartersDashboard = '$headquarters/dashboard';
  static const String headquartersMe = '$headquarters/me';  // 본사 정보 조회/수정

  // Common endpoints - 공통
  static const String common = '/common';
  static const String commonBuildings = '$common/buildings';
  static const String notifications = '/notifications';
  static const String announcements = '/announcements';
  static const String facilities = '/facilities';

  // Headquarters buildings endpoints
  static const String headquartersBuildings = '$headquarters/buildings';

  // Departments - 부서 관련
  static const String departments = '$common/departments';

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

  // Upload - 파일 업로드
  static const String uploadPresignedUrl = '/upload/presigned-url';
  static const String uploadPresignedUrls = '/upload/presigned-urls';  // 다중 파일용
}
