import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import '../data/app_installation_repository.dart';
import '../domain/report_app_installation.dart';

final reportAppInstallationProvider = Provider<ReportAppInstallation>((ref) {
  final reporter = ReportAppInstallation(
    StoredAppInstallationRepository(ref.watch(apiClientProvider)),
  );
  ref.onDispose(reporter.reset);
  return reporter;
});

class AppInstallationReporter extends ConsumerStatefulWidget {
  const AppInstallationReporter({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppInstallationReporter> createState() =>
      _AppInstallationReporterState();
}

class _AppInstallationReporterState
    extends ConsumerState<AppInstallationReporter>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_report);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_report());
  }

  Future<void> _report() async {
    if (!mounted) return;
    final reporter = ref.read(reportAppInstallationProvider);
    final user = ref.read(currentUserProvider);
    if (ref.read(authStateProvider) != AuthState.authenticated ||
        user == null) {
      reporter.reset();
      return;
    }
    final role = switch (user.userType) {
      UserType.user => 'resident',
      UserType.admin => 'manager',
      UserType.manager => 'staff',
      UserType.headquarters => 'headquarters',
    };
    try {
      await reporter.execute(user.id, role);
    } catch (_) {
      // Telemetry failure is retried on the next foreground event.
      debugPrint('앱 버전 기록을 완료하지 못했습니다. 다음 앱 복귀 시 재시도합니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (_, __) => unawaited(_report()));
    ref.listen(authStateProvider, (_, __) => unawaited(_report()));
    return widget.child;
  }
}
