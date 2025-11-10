import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/routing/router_notifier.dart';
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

// Test Ref wrapper for ProviderContainer
class _TestRef implements Ref {
  final ProviderContainer _container;

  _TestRef(this._container);

  @override
  T read<T>(ProviderListenable<T> provider) {
    return _container.read(provider);
  }

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _container.listen<T>(provider, listener, onError: onError);
  }

  @override
  T watch<T>(ProviderListenable<T> provider) {
    return _container.read(provider);
  }

  @override
  void invalidate(ProviderOrFamily provider) {
    _container.invalidate(provider);
  }

  @override
  void onDispose(void Function() cb) {}

  @override
  bool exists(ProviderBase<Object?> provider) {
    return _container.exists(provider);
  }

  @override
  void Function() listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    final sub = _container.listen<T>(
      provider,
      listener,
      onError: onError,
      fireImmediately: fireImmediately,
    );
    return sub.close;
  }

  @override
  T refresh<T>(Refreshable<T> provider) {
    return _container.refresh(provider);
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

      final ref = _TestRef(container);
      final router = RouterNotifier(ref).router;

      // Try navigating to each protected path and verify redirected location
      Future<void> expectRedirect(String target, String expectedPrefix) async {
        await tester.pumpWidget(UncontrolledProviderScope(container: container, child: _TestApp(router: router)));
        router.go(target);
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.fullPath?.startsWith(expectedPrefix), isTrue,
            reason: 'Expected redirect to $expectedPrefix for $target, but was ${router.routerDelegate.currentConfiguration.fullPath}');
      }

      await expectRedirect('/user/dashboard', '/user-login');
      await expectRedirect('/admin/dashboard', '/admin-login');
      await expectRedirect('/manager/dashboard', '/manager-login');
      await expectRedirect('/headquarters/dashboard', '/headquarters-login');
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

      final ref = _TestRef(container);
      final router = RouterNotifier(ref).router;

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: _TestApp(router: router)));

      // Navigate to another role's protected route
      router.go('/user/dashboard');
      await tester.pumpAndSettle();

      // Should be redirected to admin dashboard
      expect(router.routerDelegate.currentConfiguration.fullPath, '/admin/dashboard');
    });
  });
}

