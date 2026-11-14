import 'dart:async';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/app_installation/domain/report_app_installation.dart';
import 'package:building_manage_front/modules/app_installation/presentation/app_installation_reporter.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('성공한 동일 세션의 복귀 기록은 15분 간격이고 실패는 다시 시도한다', () async {
    final repo = _Repository();
    var now = DateTime(2026, 11, 14);
    final reporter = ReportAppInstallation(repo, now: () => now);
    await reporter.execute('a', 'resident');
    await reporter.execute('a', 'resident');
    expect(repo.accounts, ['resident:a']);
    now = now.add(const Duration(minutes: 15));
    repo.fail = true;
    await expectLater(reporter.execute('a', 'resident'), throwsStateError);
    repo.fail = false;
    await reporter.execute('a', 'resident');
    expect(repo.accounts, hasLength(3));
  });

  test('로그아웃·계정 전환 중 대기하던 기록은 이전 계정으로 전송하지 않는다', () async {
    final repo = _Repository()..pending = Completer<AppInstallation?>();
    final reporter = ReportAppInstallation(repo);
    final first = reporter.execute('a', 'resident');
    reporter.reset();
    final next = reporter.execute('b', 'manager');
    repo.pending!.complete(_identity);
    await Future.wait([first, next]);
    expect(repo.accounts, ['manager:b']);
  });

  testWidgets('자동 로그인·신규 로그인·앱 복귀로 기록하고 같은 계정 재로그인도 기록한다', (tester) async {
    final repo = _Repository();
    var now = DateTime(2026, 11, 14);
    final container = ProviderContainer(
      overrides: [
        reportAppInstallationProvider.overrideWithValue(
          ReportAppInstallation(repo, now: () => now),
        ),
      ],
    );
    addTearDown(container.dispose);
    final auth = container.read(authStateProvider.notifier);
    const resident = User(
      id: 'a',
      email: '',
      name: '입주민',
      userType: UserType.user,
    );
    auth.setAuthenticated(resident, 'test');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppInstallationReporter(child: Text('본문')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.accounts, ['resident:a']);
    now = now.add(const Duration(minutes: 16));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.accounts, hasLength(2));
    auth.setUnauthenticated();
    await tester.pumpAndSettle();
    auth.setAuthenticated(resident, 'test2');
    await tester.pumpAndSettle();
    expect(repo.accounts, hasLength(3));
  });
}

const _identity = AppInstallation(
  id: 'install',
  platform: 'ios',
  version: '1.0.16',
  buildNumber: 37,
);

class _Repository implements AppInstallationRepository {
  final accounts = <String>[];
  bool fail = false;
  Completer<AppInstallation?>? pending;
  @override
  Future<AppInstallation?> identity() =>
      pending?.future ?? Future.value(_identity);
  @override
  Future<void> record(
    String accountId,
    String role,
    AppInstallation installation,
  ) async {
    accounts.add('$role:$accountId');
    if (fail) throw StateError('network');
  }
}
