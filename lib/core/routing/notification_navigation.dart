import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../constants/user_types.dart';

/// Notification destinations always have exactly one role dashboard beneath
/// them. A new tap replaces the old stack, including an already-open detail.
class NotificationNavigation {
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
    router.go(home);
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
