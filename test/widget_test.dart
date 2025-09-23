import 'package:flutter_test/flutter_test.dart';
import 'package:building_manage_front/app/app.dart';

void main() {
  testWidgets('Main home screen shows primary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BuildingManageApp());

    expect(find.text('유저 로그인'), findsOneWidget);
    expect(find.text('관리자 로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });
}
