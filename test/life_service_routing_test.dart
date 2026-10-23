import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/providers/router_provider.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _TestApp extends StatelessWidget {
  const _TestApp(this.router);
  final GoRouter router;
  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('입주민은 운영자 신청 관리 경로에 접근할 수 없다', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(authStateProvider.notifier)
        .setAuthenticated(
          const User(
            id: 'resident-1',
            email: 'resident@test.com',
            name: 'Resident',
            userType: UserType.user,
            buildingId: 'building-a',
            dong: '101',
            ho: '1001',
            permissions: {},
          ),
          'dummy',
        );
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _TestApp(router)),
    );
    await tester.pumpAndSettle();

    router.go('/operations/life-services/manage');
    await tester.pump();

    expect(
      router.routerDelegate.currentConfiguration.fullPath,
      '/user/dashboard',
    );
  });
}
