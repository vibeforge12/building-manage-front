import 'dart:async';

import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _close = find.widgetWithText(FilledButton, '신청 마감');

void main() {
  testWidgets('만석 표시여도 canClose=true면 마감 확인창을 열고 아니요로 유지한다', (tester) async {
    final api = _Api();
    await _pump(tester, api);
    expect(find.text('1명 / 1명'), findsOneWidget);
    expect(tester.widget<FilledButton>(_close).onPressed, isNotNull);
    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(find.text('신청을 마감할까요?'), findsOneWidget);
    await tester.tap(find.text('아니요'));
    await tester.pumpAndSettle();
    expect(api.closes, 0);
    expect(tester.widget<FilledButton>(_close).onPressed, isNotNull);
  });

  testWidgets('만석 수동 마감은 한 번만 요청하고 새 응답으로 버튼을 잠근다', (tester) async {
    final api = _Api()..pending = Completer<void>();
    await _pump(tester, api);
    await tester.tap(_close);
    await tester.pumpAndSettle();
    await tester.tap(find.text('마감'));
    await tester.pumpAndSettle();
    expect(api.closes, 1);
    expect(tester.widget<FilledButton>(_close).onPressed, isNull);
    api.pending!.complete();
    await tester.pumpAndSettle();
    expect(api.reads, 2);
    expect(api.closes, 1);
    expect(find.text('1명 / 1명'), findsOneWidget);
    expect(tester.widget<FilledButton>(_close).onPressed, isNull);
  });

  testWidgets('마감 실패를 안내하고 재시도 가능하게 잠금을 해제한다', (tester) async {
    final api = _Api()..fail = true;
    await _pump(tester, api);
    await tester.tap(_close);
    await tester.pumpAndSettle();
    await tester.tap(find.text('마감'));
    await tester.pumpAndSettle();
    expect(find.text('마감 실패'), findsOneWidget);
    expect(find.text('마감 요청 실패'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(_close).onPressed, isNotNull);
  });

  for (final state in ['closed', 'unauthorized', 'missing']) {
    testWidgets('$state 상태에서는 마감 버튼을 활성화하지 않는다', (tester) async {
      final api = _Api()
        ..canClose = state == 'unauthorized'
        ..canManage = state != 'unauthorized'
        ..omitCanClose = state == 'missing';
      await _pump(tester, api);
      expect(tester.widget<FilledButton>(_close).onPressed, isNull);
      expect(api.closes, 0);
    });
  }
}

Future<void> _pump(WidgetTester tester, _Api api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        currentUserProvider.overrideWithValue(
          const User(
            id: 'staff',
            email: '',
            name: '담당자',
            userType: UserType.manager,
          ),
        ),
      ],
      child: const MaterialApp(
        home: LifeServiceDetailScreen(lifeServiceId: 'full'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Api implements ApiClient {
  bool canClose = true;
  bool canManage = true;
  bool omitCanClose = false;
  bool fail = false;
  int closes = 0;
  int reads = 0;
  Completer<void>? pending;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    reads++;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data:
          {
                'success': true,
                'data': {
                  'id': 'full',
                  'title': '만석 테스트',
                  'description': '안내',
                  'applicationStartAt': '2026-10-20T00:00:00Z',
                  'applicationEndAt': '2026-10-30T00:00:00Z',
                  'serviceStartAt': '2026-10-31T00:00:00Z',
                  'serviceEndAt': '2026-10-31T01:00:00Z',
                  'status': 'CLOSED',
                  'applicantCount': 1,
                  'capacity': 1,
                  'canManage': canManage,
                  if (!omitCanClose) 'canClose': canClose,
                },
              }
              as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    expect(path, '/life-services/full/close');
    closes++;
    if (fail) throw const ApiException(message: '마감 요청 실패', errorCode: 'TEST');
    if (pending != null) await pending!.future;
    canClose = false;
    return Response<T>(requestOptions: RequestOptions(path: path));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
