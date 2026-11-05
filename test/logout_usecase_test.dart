import 'dart:async';

import 'package:building_manage_front/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인증은 현재 기기 푸시 해제가 끝날 때까지 유지된다', () async {
    final server = Completer<void>();
    final events = <String>[];
    final logout = LogoutUseCase(
      clearPushRegistration: () async {
        events.add('server-start');
        await server.future;
        events.add('server-done');
      },
      clearCredentials: () async => events.add('credentials-cleared'),
    );
    final pending = logout();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['server-start']);
    server.complete();
    await pending;
    expect(events, ['server-start', 'server-done', 'credentials-cleared']);
  });

  test('서버 해제 실패 시 인증을 보존하고 재시도할 수 있다', () async {
    var fail = true;
    var cleared = false;
    final logout = LogoutUseCase(
      clearPushRegistration: () async {
        if (fail) throw StateError('offline');
      },
      clearCredentials: () async => cleared = true,
    );
    await expectLater(logout(), throwsStateError);
    expect(cleared, isFalse);
    fail = false;
    await logout();
    expect(cleared, isTrue);
  });
}
