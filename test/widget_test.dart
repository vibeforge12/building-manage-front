import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/app/app.dart';

void main() {
  testWidgets('Main home screen shows primary actions', (
    WidgetTester tester,
  ) async {
    // Riverpod ProviderScope로 앱을 감싸서 테스트
    await tester.pumpWidget(
      const ProviderScope(
        child: BuildingManageApp(),
      ),
    );

    // 화면이 완전히 로드될 때까지 대기
    await tester.pumpAndSettle();

    expect(find.text('유저 로그인'), findsOneWidget);
    expect(find.text('관리자 로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });
}
