import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/routing/notification_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('민원 처리·수정 알림은 수신자 역할에 맞는 화면을 연다', () {
    expect(
      complaintResultDestination(UserType.admin, 'c1'),
      '/admin/complaint-detail/c1',
    );
    expect(
      complaintResultDestination(UserType.manager, 'c1'),
      '/manager/complaint-detail/c1',
    );
    expect(
      complaintResultDestination(UserType.user, 'c1'),
      '/user/my-complaints',
    );
    expect(
      complaintResultDestination(UserType.admin, null),
      '/admin/complaint-management',
    );
    expect(
      complaintResultDestination(UserType.manager, ''),
      '/manager/complaints',
    );
    expect(complaintResultDestination(UserType.headquarters, 'c1'), isNull);
    expect(complaintResultDestination(null, 'c1'), isNull);
  });

  for (final role in UserType.values) {
    testWidgets('$role 알림은 기존 스택을 정리하고 홈 위에 상세 하나만 연다', (tester) async {
      final home = '/${role.name}/dashboard';
      final router = _router(home);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push('/detail/old');
      await tester.pumpAndSettle();
      router.push('/detail/older');
      await tester.pumpAndSettle();
      final navigation = NotificationNavigation();
      navigation.open(
        router: router,
        userType: role,
        destination: '/detail/new',
        isCurrentSession: () => true,
      );
      await tester.pumpAndSettle();
      expect(find.text('new'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text(home), findsOneWidget);
      expect(router.canPop(), isFalse);
    });
  }

  testWidgets('같은 상세를 반복 열어도 새로 조회하고 한 번 뒤로 가면 홈이다', (tester) async {
    var loads = 0;
    final router = _router('/user/dashboard', onDetail: () => loads++);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final navigation = NotificationNavigation();
    for (var i = 0; i < 3; i++) {
      navigation.open(
        router: router,
        userType: UserType.user,
        destination: '/detail/same',
        isCurrentSession: () => true,
      );
      await tester.pumpAndSettle();
    }
    expect(loads, 3);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    expect(find.text('/user/dashboard'), findsOneWidget);
  });

  testWidgets('동시에 누른 알림은 마지막 대상만 열고 계정 변경 시 중단한다', (tester) async {
    final router = _router('/user/dashboard');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final navigation = NotificationNavigation();
    for (final id in ['first', 'last']) {
      navigation.open(
        router: router,
        userType: UserType.user,
        destination: '/detail/$id',
        isCurrentSession: () => true,
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('last'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    navigation.open(
      router: router,
      userType: UserType.user,
      destination: '/detail/previous-account',
      isCurrentSession: () => false,
    );
    await tester.pumpAndSettle();
    expect(find.text('/user/dashboard'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}

GoRouter _router(String home, {VoidCallback? onDetail}) => GoRouter(
  initialLocation: home,
  routes: [
    GoRoute(
      path: home,
      builder: (_, __) => Scaffold(body: Text(home)),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (_, state) =>
          _Detail(id: state.pathParameters['id']!, onLoad: onDetail),
    ),
  ],
);

class _Detail extends StatefulWidget {
  const _Detail({required this.id, this.onLoad});
  final String id;
  final VoidCallback? onLoad;
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  @override
  void initState() {
    super.initState();
    widget.onLoad?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(widget.id));
}
