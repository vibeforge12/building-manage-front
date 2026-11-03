import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../constants/user_types.dart';

/// A notification resets the stack and the resident home's cached API snapshot.
Key notificationHomeKey(Object? extra) =>
    ValueKey(extra is Map ? extra['notificationHomeRevision'] : null);

/// 입주민 상세는 목록의 민원 데이터가 필요하므로 기존 목록 진입을 유지한다.
/// 관리자·담당자는 식별자로 직접 조회하는 각 역할의 상세를 연다.
String? complaintResultDestination(UserType? userType, String? complaintId) {
  final id = complaintId == null || complaintId.isEmpty
      ? null
      : Uri.encodeComponent(complaintId);
  return switch (userType) {
    UserType.user => '/user/my-complaints',
    UserType.admin =>
      id == null
          ? '/admin/complaint-management'
          : '/admin/complaint-detail/$id',
    UserType.manager =>
      id == null ? '/manager/complaints' : '/manager/complaint-detail/$id',
    _ => null,
  };
}

/// Notification destinations always have exactly one role dashboard beneath
/// them. A new tap replaces the old stack, including an already-open detail.
class NotificationNavigation {
  static int _homeRevision = 0;
  int _request = 0;

  void open({
    required GoRouter router,
    required UserType userType,
    required String destination,
    required bool Function() isCurrentSession,
  }) {
    final request = ++_request;
    final home = switch (userType) {
      UserType.user => '/user/dashboard',
      UserType.admin => '/admin/dashboard',
      UserType.manager => '/manager/dashboard',
      UserType.headquarters => '/headquarters/dashboard',
    };
    router.go(home, extra: {'notificationHomeRevision': ++_homeRevision});
    // Commit the reset before pushing. Last tap wins when several arrive in
    // one frame, and an account change must not open the old account's target.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (request != _request || !isCurrentSession()) return;
      if (router.routeInformationProvider.value.uri.path != home) return;
      if (destination != home) router.push(destination);
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}
