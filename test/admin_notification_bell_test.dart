import 'package:building_manage_front/modules/admin/presentation/screens/complaint_management_screen.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/core/providers/router_provider.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('관리자 종은 중간 화면 없이 민원관리를 열고 홈으로 돌아온다', (tester) async {
    final api = _Api();
    final router = await _pumpDashboard(tester, api);
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();
    expect(find.byType(ComplaintManagementScreen), findsOneWidget);
    expect(find.text('받은 민원'), findsOneWidget);
    expect(find.text('민원 1'), findsOneWidget);
    expect(find.text('미처리 민원 4건'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    api.complaints = 0;
    router.pop();
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    expect(find.byTooltip('알림'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('입주민 건수 조회 실패와 관계없이 민원관리를 바로 연다', (tester) async {
    final api = _Api()..failResidents = true;
    await _pumpDashboard(tester, api);
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();
    expect(find.byType(ComplaintManagementScreen), findsOneWidget);
    expect(find.text('민원 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<GoRouter> _pumpDashboard(WidgetTester tester, _Api api) async {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  container
      .read(authStateProvider.notifier)
      .setAuthenticated(
        const User(id: 'a', email: '', name: '관리자', userType: UserType.admin),
        'test',
      );
  final router = container.read(routerProvider)..go('/admin/dashboard');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _Api extends Fake implements ApiClient {
  int residents = 3;
  int complaints = 4;
  bool failResidents = false;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final int total;
    switch (path) {
      case '/managers/residents':
        if (failResidents) {
          throw const ApiException(message: '조회 실패', errorCode: 'TEST');
        }
        total =
            queryParameters?['isVerified'] == false &&
                queryParameters?['status'] == 'ACTIVE'
            ? residents
            : 0;
      case ApiEndpoints.managerComplaintsPending:
        total = complaints;
      default:
        throw StateError('Unexpected request: $path');
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data:
          {
                'success': true,
                'data': {
                  'items': [
                    for (
                      var i = 1;
                      i <= total && i <= (queryParameters?['limit'] as int);
                      i++
                    )
                      {'id': 'id-$i', 'name': '입주민 $i', 'title': '민원 $i'},
                  ],
                  'meta': {'page': 1, 'limit': 20, 'total': total},
                },
              }
              as T,
    );
  }
}
