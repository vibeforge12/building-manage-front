import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/life_service/domain/entities/life_service.dart';
import 'package:building_manage_front/modules/life_service/presentation/widgets/resident_life_service_section.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_list_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_dashboard_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('신청 가능한 홈 카드에서 상세로 이동할 수 있다', (tester) async {
    String? openedId;
    await _pumpSection(
      tester,
      services: [_service(id: 'available', title: '신청 가능한 테스트 행사')],
      onOpen: (id) => openedId = id,
    );

    expect(find.text('서비스 신청'), findsOneWidget);
    expect(find.text('전체보기'), findsOneWidget);
    expect(find.text('신청 가능한 테스트 행사'), findsOneWidget);
    expect(find.text('신청 가능'), findsOneWidget);

    await tester.tap(find.text('신청 가능한 테스트 행사'));
    expect(openedId, 'available');
  });

  testWidgets('신청 항목이 없어도 전체 목록 진입 경로를 유지한다', (tester) async {
    var viewAllCount = 0;
    await _pumpSection(tester, onViewAll: () => viewAllCount++);

    expect(find.text('서비스 신청'), findsOneWidget);
    expect(find.text('현재 신청 가능한 항목이 없습니다.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '전체보기'), findsOneWidget);
    await tester.tap(find.text('전체보기'));
    expect(viewAllCount, 1);
  });

  testWidgets('불러오는 중에도 전체 목록으로 이동할 수 있다', (tester) async {
    var viewAllCount = 0;
    await _pumpSection(
      tester,
      isLoading: true,
      onViewAll: () => viewAllCount++,
    );

    expect(find.text('서비스 신청'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('현재 신청 가능한 항목이 없습니다.'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, '전체보기'));
    expect(viewAllCount, 1);
  });

  testWidgets('조회 실패 안내에서 다시 시도하거나 전체 목록을 열 수 있다', (tester) async {
    var retryCount = 0;
    var viewAllCount = 0;
    await _pumpSection(
      tester,
      error: '신청 항목을 불러오지 못했습니다.',
      onRetry: () => retryCount++,
      onViewAll: () => viewAllCount++,
    );

    expect(find.text('서비스 신청'), findsOneWidget);
    expect(find.text('신청 항목을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('현재 신청 가능한 항목이 없습니다.'), findsNothing);
    await tester.tap(find.text('다시 시도'));
    expect(retryCount, 1);
    await tester.tap(find.widgetWithText(TextButton, '전체보기'));
    expect(viewAllCount, 1);
  });

  testWidgets('홈에는 두 항목까지만 표시하고 전체보기 경로를 제공한다', (tester) async {
    String? openedId;
    var viewAllCount = 0;
    await _pumpSection(
      tester,
      services: [
        _service(id: 'first', title: '첫 번째 신청'),
        _service(id: 'second', title: '두 번째 신청'),
        _service(id: 'third', title: '세 번째 신청'),
      ],
      onOpen: (id) => openedId = id,
      onViewAll: () => viewAllCount++,
    );

    expect(find.text('첫 번째 신청'), findsOneWidget);
    expect(find.text('두 번째 신청'), findsOneWidget);
    expect(find.text('세 번째 신청'), findsNothing);
    await tester.tap(find.text('두 번째 신청'));
    expect(openedId, 'second');
    await tester.tap(find.text('전체보기'));
    expect(viewAllCount, 1);
  });

  final statusCases = [
    (
      status: LifeServiceDisplayStatus.closed,
      applicationStatus: LifeServiceApplicationStatus.applied,
      label: '신청 완료 · 신청 마감',
    ),
    (
      status: LifeServiceDisplayStatus.closed,
      applicationStatus: null,
      label: '신청 마감',
    ),
    (
      status: LifeServiceDisplayStatus.recruiting,
      applicationStatus: LifeServiceApplicationStatus.applied,
      label: '신청 완료',
    ),
    (
      status: LifeServiceDisplayStatus.recruiting,
      applicationStatus: null,
      label: '신청 가능',
    ),
  ];
  for (final statusCase in statusCases) {
    testWidgets('모집 상태와 개인 신청 상태를 구분해 ${statusCase.label} 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LifeServiceCard(
              service: _service(
                status: statusCase.status,
                applicationStatus: statusCase.applicationStatus,
              ),
              residentMode: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text(statusCase.label), findsOneWidget);
      for (final otherCase in statusCases) {
        if (otherCase.label != statusCase.label) {
          expect(find.text(otherCase.label), findsNothing);
        }
      }
    });
  }

  testWidgets('좁은 화면과 큰 글자에서도 신청 카드와 전체보기가 넘치지 않는다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var viewAllCount = 0;
    await _pumpSection(
      tester,
      textScaler: const TextScaler.linear(2),
      services: [_service(title: '입주민과 함께하는 주말 문화 행사 및 공동시설 이용 신청')],
      onViewAll: () => viewAllCount++,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('신청 가능'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '전체보기'));
    expect(viewAllCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('대시보드는 신청 가능 항목을 표시하고 상세와 목록에서 돌아오면 다시 조회한다', (tester) async {
    String? routedId;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const UserDashboardScreen(),
        ),
        GoRoute(
          path: '/life-services/:lifeServiceId',
          name: 'lifeServiceDetail',
          builder: (context, state) {
            routedId = state.pathParameters['lifeServiceId'];
            return Scaffold(body: Text('상세 화면: $routedId'));
          },
        ),
        GoRoute(
          path: '/user/life-services',
          name: 'residentLifeServices',
          builder: (context, state) =>
              const Scaffold(body: Text('신청 전체 목록 화면')),
        ),
      ],
    );
    addTearDown(router.dispose);
    final apiClient = _DashboardApiClient(
      lifeServices: [
        {
          'id': 'available-from-api',
          'title': '서버에서 받은 신청 가능 항목',
          'description': '신청 가능한 항목입니다.',
          'applicationStartAt': '2026-10-23T00:00:00Z',
          'applicationEndAt': '2026-10-24T09:00:00Z',
          'serviceStartAt': '2026-10-25T05:00:00Z',
          'serviceEndAt': '2026-10-25T06:00:00Z',
          'status': 'RECRUITING',
          'applicationStatus': null,
          'applicantCount': 1,
          'capacity': 2,
          'canApply': true,
          'canCancel': false,
          'canManage': false,
        },
      ],
    );
    await _pumpDashboard(tester, apiClient, router: router);

    final section = find.byType(ResidentLifeServiceSection);
    expect(section, findsOneWidget);
    final widget = tester.widget<ResidentLifeServiceSection>(section);
    expect(widget.services.single.id, 'available-from-api');
    expect(widget.services.single.status, LifeServiceDisplayStatus.recruiting);
    expect(widget.isLoading, isFalse);
    expect(widget.error, isNull);
    expect(apiClient.lifeServiceTabs, ['active']);
    expect(
      find.descendant(of: section, matching: find.text('서버에서 받은 신청 가능 항목')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('신청 가능')),
      findsOneWidget,
    );

    final availableCardTitle = find.descendant(
      of: section,
      matching: find.text('서버에서 받은 신청 가능 항목'),
    );
    await tester.ensureVisible(availableCardTitle);
    await tester.pumpAndSettle();
    await tester.tap(availableCardTitle);
    await tester.pumpAndSettle();
    expect(routedId, 'available-from-api');
    expect(find.text('상세 화면: available-from-api'), findsOneWidget);

    // Model the server state after an application. Returning to home must
    // remove the card even though its display status is still recruiting.
    apiClient.lifeServices.single['canApply'] = false;
    apiClient.lifeServices.single['applicationStatus'] = 'APPLIED';
    router.pop();
    await tester.pumpAndSettle();
    expect(apiClient.lifeServiceTabs, ['active', 'active']);
    expect(find.byType(ResidentLifeServiceSection), findsOneWidget);
    expect(
      tester.widget<ResidentLifeServiceSection>(section).services,
      isEmpty,
    );

    final viewAll = find.descendant(
      of: section,
      matching: find.widgetWithText(TextButton, '전체보기'),
    );
    await tester.ensureVisible(viewAll);
    await tester.pumpAndSettle();
    await tester.tap(viewAll);
    await tester.pumpAndSettle();
    expect(find.text('신청 전체 목록 화면'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(apiClient.lifeServiceTabs, ['active', 'active', 'active']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('홈은 서버 canApply가 참인 항목만 필터한 뒤 두 개까지 표시한다', (tester) async {
    final api = _DashboardApiClient(
      lifeServices: [
        _response('closed', canApply: false, status: 'CLOSED'),
        _response('applied', canApply: false, applicationStatus: 'APPLIED'),
        _response('full', canApply: false),
        _response('not-started', canApply: false),
        _response('completed', canApply: false, status: 'COMPLETED'),
        _response('available-1', canApply: true),
        _response('reapply', canApply: true, applicationStatus: 'CANCELED'),
        _response('available-3', canApply: true),
      ],
    );
    await _pumpDashboard(tester, api);
    final section = find.byType(ResidentLifeServiceSection);
    expect(
      tester
          .widget<ResidentLifeServiceSection>(section)
          .services
          .map((s) => s.id),
      ['available-1', 'reapply', 'available-3'],
    );
    expect(
      find.descendant(of: section, matching: find.text('available-1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('reapply')),
      findsOneWidget,
    );
    for (final hidden in [
      'closed',
      'applied',
      'full',
      'not-started',
      'completed',
      'available-3',
    ]) {
      expect(
        find.descendant(of: section, matching: find.text(hidden)),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('마감 항목만 있으면 홈 카드는 숨기되 전체보기에서 상세로 진입한다', (tester) async {
    final api = _DashboardApiClient(
      lifeServices: [
        _response(
          'closed-only',
          canApply: false,
          status: 'CLOSED',
          applicationStatus: 'APPLIED',
        ),
      ],
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const UserDashboardScreen()),
        GoRoute(
          path: '/user/life-services',
          name: 'residentLifeServices',
          builder: (_, __) => const LifeServiceListScreen(),
        ),
        GoRoute(
          path: '/life-services/:lifeServiceId',
          name: 'lifeServiceDetail',
          builder: (_, state) => Scaffold(
            body: Text('상세: ${state.pathParameters['lifeServiceId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pumpDashboard(tester, api, router: router);
    final section = find.byType(ResidentLifeServiceSection);
    expect(
      tester.widget<ResidentLifeServiceSection>(section).services,
      isEmpty,
    );
    expect(find.text('closed-only'), findsNothing);
    final viewAll = find.descendant(of: section, matching: find.text('전체보기'));
    await tester.ensureVisible(viewAll);
    await tester.pumpAndSettle();
    await tester.tap(viewAll);
    await tester.pumpAndSettle();
    expect(find.text('closed-only'), findsOneWidget);
    await tester.tap(find.text('closed-only'));
    await tester.pumpAndSettle();
    expect(find.text('상세: closed-only'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(
      tester.widget<ResidentLifeServiceSection>(section).services,
      isEmpty,
    );
    expect(find.text('현재 신청 가능한 항목이 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('대시보드는 빈 서버 응답에서도 서비스 신청과 전체보기를 유지한다', (tester) async {
    await _pumpDashboard(tester, _DashboardApiClient(lifeServices: const []));

    final section = find.byType(ResidentLifeServiceSection);
    expect(section, findsOneWidget);
    expect(
      find.descendant(of: section, matching: find.text('서비스 신청')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: section,
        matching: find.widgetWithText(TextButton, '전체보기'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: section, matching: find.text('현재 신청 가능한 항목이 없습니다.')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _response(
  String id, {
  required bool canApply,
  String status = 'RECRUITING',
  String? applicationStatus,
}) => {
  'id': id,
  'title': id,
  'description': '홈 노출 확인',
  'applicationStartAt': '2026-10-23T00:00:00Z',
  'applicationEndAt': '2026-10-30T09:00:00Z',
  'serviceStartAt': '2026-10-31T05:00:00Z',
  'serviceEndAt': '2026-10-31T06:00:00Z',
  'status': status,
  'applicationStatus': applicationStatus,
  'canApply': canApply,
  'canCancel': false,
  'canManage': false,
};

LifeService _service({
  String id = 'test-service',
  String title = '테스트 신청 항목',
  LifeServiceDisplayStatus status = LifeServiceDisplayStatus.recruiting,
  LifeServiceApplicationStatus? applicationStatus,
}) {
  final recruiting = status == LifeServiceDisplayStatus.recruiting;
  final applied = applicationStatus == LifeServiceApplicationStatus.applied;
  return LifeService(
    id: id,
    title: title,
    description: '홈 신청 영역 확인용 항목입니다.',
    applicationStartAt: DateTime(2026, 10, 23, 9),
    applicationEndAt: DateTime(2026, 10, 24, 18),
    serviceStartAt: DateTime(2026, 10, 25, 14),
    serviceEndAt: DateTime(2026, 10, 25, 15),
    location: '테스트 건물 공용 공간',
    capacity: 2,
    applicantCount: applied ? 1 : 0,
    status: status,
    applicationStatus: applicationStatus,
    canApply: recruiting && !applied,
    canCancel: recruiting && applied,
    canManage: false,
  );
}

Future<void> _pumpSection(
  WidgetTester tester, {
  List<LifeService> services = const [],
  bool isLoading = false,
  String? error,
  VoidCallback? onViewAll,
  ValueChanged<String>? onOpen,
  VoidCallback? onRetry,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResidentLifeServiceSection(
            services: services,
            isLoading: isLoading,
            error: error,
            onViewAll: onViewAll ?? () {},
            onOpen: onOpen ?? (_) {},
            onRetry: onRetry ?? () {},
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  _DashboardApiClient apiClient, {
  GoRouter? router,
}) async {
  PackageInfo.setMockInitialValues(
    appName: '엄지 Dev',
    packageName: 'com.example.building_manage_front',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        currentUserProvider.overrideWithValue(null),
      ],
      child: router == null
          ? const MaterialApp(home: UserDashboardScreen())
          : MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Keep dashboard integration tests entirely local while exercising the real
/// datasource, repository, use case and widget wiring.
class _DashboardApiClient implements ApiClient {
  _DashboardApiClient({required this.lifeServices});

  final List<Map<String, dynamic>> lifeServices;
  final List<String?> lifeServiceTabs = [];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final Map<String, dynamic> payload;
    if (path == ApiEndpoints.lifeServices) {
      lifeServiceTabs.add(queryParameters?['tab'] as String?);
      payload = {
        'success': true,
        'data': {'data': lifeServices},
      };
    } else if (path == ApiEndpoints.departments || path == '/bulletins') {
      payload = {
        'success': true,
        'data': {'items': <Map<String, dynamic>>[]},
      };
    } else {
      throw StateError('Unexpected dashboard request: $path');
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: payload as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected API operation: ${invocation.memberName}',
  );
}
