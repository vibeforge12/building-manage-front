import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/providers/router_provider.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// A lightweight harness to drive GoRouter with Riverpod providers in tests
class _TestApp extends ConsumerWidget {
  final GoRouter router;
  const _TestApp({required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: router);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouterNotifier redirect', () {
    testWidgets('Unauthenticated user redirected to role login for protected paths', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Ensure unauthenticated state
      container.read(authStateProvider.notifier).setUnauthenticated();

      final router = container.read(routerProvider);

      // Try navigating to each protected path and verify redirected location
      Future<void> expectRedirect(String target, String expectedPrefix) async {
        await tester.pumpWidget(UncontrolledProviderScope(container: container, child: _TestApp(router: router)));
        router.go(target);
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.fullPath.startsWith(expectedPrefix), isTrue,
            reason: 'Expected redirect to $expectedPrefix for $target, but was ${router.routerDelegate.currentConfiguration.fullPath}');
      }

      await expectRedirect('/user/dashboard', '/user-login');
      await expectRedirect('/admin/dashboard', '/admin-login');
      await expectRedirect('/manager/dashboard', '/manager-login');
      await expectRedirect('/headquarters/dashboard', '/headquarters-login');

      // 접두어 기반 보호: 목록에 없던 경로들도 보호돼야 한다
      await expectRedirect('/admin/staff-management', '/admin-login');
      await expectRedirect('/admin/resident-management', '/admin-login');
      await expectRedirect('/admin/notice-management', '/admin-login');
      await expectRedirect('/admin/staff-account-issuance', '/admin-login');
      await expectRedirect('/manager/complaints', '/manager-login');
      await expectRedirect('/manager/notices', '/manager-login');
      await expectRedirect('/headquarters/manager-list', '/headquarters-login');

      // 경로는 /manager/ 이지만 실제 소유자는 관리자(admin)인 예외 경로
      await expectRedirect('/manager/add-general-manager', '/admin-login');
    });

    testWidgets('Authenticated but mismatched role redirected to own dashboard', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set authenticated state with UserType.admin
      final auth = container.read(authStateProvider.notifier);
      final adminUser = User(
        id: '1',
        email: 'admin@test.com',
        name: 'Admin',
        userType: UserType.admin,
        buildingId: 'B1',
        dong: null,
        ho: null,
        permissions: const {},
      );
      auth.setAuthenticated(adminUser, 'dummy');

      final router = container.read(routerProvider);

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: _TestApp(router: router)));

      // Navigate to another role's protected route
      router.go('/user/dashboard');
      await tester.pumpAndSettle();

      // Should be redirected to admin dashboard
      expect(router.routerDelegate.currentConfiguration.fullPath, '/admin/dashboard');
    });

    testWidgets('Admin can reach the admin-owned route under the /manager/ prefix', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adminUser = User(
        id: '1',
        email: 'admin@test.com',
        name: 'Admin',
        userType: UserType.admin,
        buildingId: 'B1',
        dong: null,
        ho: null,
        permissions: const {},
      );
      container.read(authStateProvider.notifier).setAuthenticated(adminUser, 'dummy');

      final router = container.read(routerProvider);

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: _TestApp(router: router)));
      // 스플래시의 지연 네비게이션이 끝난 뒤에 이동해야 결과가 덮어써지지 않는다.
      await tester.pumpAndSettle();

      router.go('/manager/add-general-manager');
      await tester.pump();

      expect(router.routerDelegate.currentConfiguration.fullPath, '/manager/add-general-manager');
    });
  });
}
