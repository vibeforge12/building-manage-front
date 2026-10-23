import 'package:building_manage_front/modules/life_service/presentation/screens/life_service_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('신규 서비스 등록 알림은 기본으로 켜지고 운영자가 끌 수 있다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LifeServiceFormScreen())),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('입주민에게 알림 보내기'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });
}
