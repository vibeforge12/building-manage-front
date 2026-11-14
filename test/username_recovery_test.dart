import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/user_login_screen.dart';
import 'package:building_manage_front/modules/resident/presentation/screens/username_recovery_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('로그인에서 이름·휴대폰 인증 후 아이디를 선택하면 로그인 폼에 채운다', (tester) async {
    final api = _Api();
    await _pump(tester, api);
    await tester.tap(find.text('아이디 찾기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '이름'), ' 홍길동 ');
    await tester.enterText(
      find.widgetWithText(TextFormField, '휴대폰 번호'),
      '01012345678',
    );
    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();
    expect(api.requestBody, {'name': '홍길동', 'phoneNumber': '01012345678'});
    expect(find.text('resident-1'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, '인증번호'),
      '123456',
    );
    await tester.tap(find.text('아이디 확인'));
    await tester.pumpAndSettle();
    expect(find.text('건물 A'), findsOneWidget);
    expect(find.text('건물 B'), findsOneWidget);
    await tester.tap(find.text('이 아이디로 로그인').last);
    await tester.pumpAndSettle();
    expect(find.text('resident-2'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);
  });

  testWidgets('조회 실패를 표시하고 재시도 후 계정 없음과 재입력을 처리한다', (tester) async {
    final api = _Api()..fail = true;
    await _pump(tester, api, recovery: true);
    await tester.enterText(find.widgetWithText(TextFormField, '이름'), '홍길동');
    await tester.enterText(
      find.widgetWithText(TextFormField, '휴대폰 번호'),
      '01012345678',
    );
    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);
    api.fail = false;
    api.empty = true;
    await tester.tap(find.text('인증번호 받기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '인증번호'),
      '123456',
    );
    await tester.tap(find.text('아이디 확인'));
    await tester.pumpAndSettle();
    expect(find.text('입력하신 정보와 일치하는 계정이 없습니다.'), findsOneWidget);
    await tester.tap(find.text('다시 찾기'));
    await tester.pumpAndSettle();
    expect(find.text('인증번호 받기'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _Api api, {
  bool recovery = false,
}) async {
  final router = GoRouter(
    initialLocation: recovery ? '/recovery' : '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const UserLoginScreen()),
      GoRoute(
        path: '/recovery',
        name: 'usernameRecovery',
        builder: (_, __) => const UsernameRecoveryScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _Api extends Fake implements ApiClient {
  bool fail = false;
  bool empty = false;
  dynamic requestBody;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (fail) {
      throw const ApiException(message: '잠시 후 다시 시도해 주세요.', errorCode: 'TEST');
    }
    final Object result;
    if (path == ApiEndpoints.usernameRecoveryRequest) {
      requestBody = data;
      result = {
        'challengeId': 'challenge',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
        'retryAfterSeconds': 60,
      };
    } else {
      expect(path, ApiEndpoints.usernameRecoveryVerify);
      expect(data, {'challengeId': 'challenge', 'code': '123456'});
      result = {
        'accounts': empty
            ? []
            : [
                {'username': 'resident-1', 'buildingName': '건물 A'},
                {'username': 'resident-2', 'buildingName': '건물 B'},
              ],
      };
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: {'success': true, 'data': result} as T,
    );
  }
}
