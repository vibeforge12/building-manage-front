import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_applicant_list_screen.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_detail_screen.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_history_screen.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_list_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _screens = <String, Widget>{
  '상세': const LifeServiceDetailScreen(lifeServiceId: 'service-1'),
  '목록': const LifeServiceListScreen(),
  '내역': const LifeServiceHistoryScreen(),
  '명단': const LifeServiceApplicantListScreen(lifeServiceId: 'service-1'),
};

void main() {
  for (final screen in _screens.entries) {
    testWidgets('${screen.key} 내용이 짧아도 당겨서 최신 응답을 표시한다', (tester) async {
      final api = _Api();
      await _pump(tester, api, screen.value);
      expect(api.calls, hasLength(1));
      api.version = 2;
      await _pull(tester);
      expect(api.calls, hasLength(2));
      expect(find.text('갱신 2'), findsOneWidget);
      if (screen.key == '상세') {
        expect(find.text('1명 / 2명'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, '신청 완료'), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, '신청 완료'),
              )
              .onPressed,
          isNull,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('${screen.key} 오류 상태에서도 당겨서 복구한다', (tester) async {
      final api = _Api()..fail = true;
      await _pump(tester, api, screen.value);
      expect(find.text('연결 실패'), findsOneWidget);
      api.fail = false;
      api.version = 2;
      await _pull(tester);
      expect(api.calls, hasLength(2));
      expect(find.text('갱신 2'), findsOneWidget);
      expect(find.text('연결 실패'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    if (screen.key != '상세') {
      testWidgets('${screen.key} 빈 상태에서도 당겨서 새 항목을 불러온다', (tester) async {
        final api = _Api()..empty = true;
        await _pump(tester, api, screen.value);
        api.empty = false;
        api.version = 2;
        await _pull(tester);
        expect(api.calls, hasLength(2));
        expect(find.text('갱신 2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('신청자 명단 새로고침은 검색어를 유지한다', (tester) async {
    final api = _Api();
    await _pump(tester, api, _screens['명단']!);
    await tester.enterText(find.byType(TextField), '101');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await _pull(tester);
    expect(api.calls.last, {'keyword': '101'});
    expect(find.text('101'), findsOneWidget);
  });

  for (final key in ['목록', '내역']) {
    testWidgets('$key 상세에서 돌아오면 최신 내역을 다시 조회한다', (tester) async {
      final api = _Api();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => _screens[key]!),
          GoRoute(
            path: '/detail/:lifeServiceId',
            name: 'lifeServiceDetail',
            builder: (_, __) => const Scaffold(body: Text('상세 테스트')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await _pump(tester, api, _screens[key]!, router: router);
      await tester.tap(find.text('갱신 1'));
      await tester.pumpAndSettle();
      api.version = 2;
      router.pop();
      await tester.pumpAndSettle();
      expect(api.calls, hasLength(2));
      expect(find.text('갱신 2'), findsOneWidget);
    });
  }
}

Future<void> _pull(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, 500));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Api api,
  Widget screen, {
  GoRouter? router,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        currentUserProvider.overrideWithValue(
          const User(
            id: 'resident',
            email: '',
            name: '테스트',
            userType: UserType.user,
          ),
        ),
      ],
      child: router == null
          ? MaterialApp(home: screen)
          : MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Exercise the actual datasource/repository/use case, without a live server.
class _Api implements ApiClient {
  int version = 1;
  bool empty = false;
  bool fail = false;
  final calls = <Map<String, dynamic>?>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls.add(queryParameters);
    if (fail) {
      throw const ApiException(message: '연결 실패', errorCode: 'TEST_ERROR');
    }
    final detail = {
      'id': 'service-1',
      'title': '갱신 $version',
      'description': '안내',
      'applicationStartAt': '2026-10-20T00:00:00Z',
      'applicationEndAt': '2026-10-30T00:00:00Z',
      'serviceStartAt': '2026-10-31T00:00:00Z',
      'serviceEndAt': '2026-10-31T01:00:00Z',
      'status': version == 1 ? 'RECRUITING' : 'CLOSED',
      'capacity': 2,
      'applicantCount': version == 1 ? 0 : 1,
      'applicationStatus': version == 1 ? null : 'APPLIED',
      'canApply': version == 1,
      'canCancel': false,
    };
    final dynamic data;
    if (path.endsWith('/applicants')) {
      data = {
        'data': empty
            ? []
            : [
                {'name': '갱신 $version', 'dong': '101', 'hosu': '102'},
              ],
      };
    } else if (path == ApiEndpoints.lifeServices || path.endsWith('/history')) {
      data = {
        'data': empty ? [] : [detail],
      };
    } else if (path == '${ApiEndpoints.lifeServices}/service-1') {
      data = detail;
    } else {
      throw StateError('Unexpected test request: $path');
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'success': true, 'data': data} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected API operation: ${invocation.memberName}',
  );
}
