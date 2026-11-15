import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/app_update/presentation/app_version_section.dart';
import 'package:building_manage_front/modules/app_update/domain/check_latest_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:building_manage_front/modules/auth/presentation/screens/main_home_screen.dart';

void main() {
  testWidgets('Main home screen shows primary actions', (
    WidgetTester tester,
  ) async {
    // 앱 전체 부팅은 자동 로그인과 FCM 상태를 기다리므로, 이 테스트의 대상인
    // 홈 화면만 직접 렌더링해 버튼 회귀 여부를 안정적으로 확인한다.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          installedAppVersionProvider.overrideWith(
            (ref) async => const InstalledAppVersion('ios', '1.0.17', 42),
          ),
          latestAppVersionProvider.overrideWith(
            (ref) async => LatestVersionResult(
              const InstalledAppVersion('ios', '1.0.17', 42),
              PublishedAppRelease(
                '1.0.17',
                42,
                Uri.parse('https://apps.apple.com/kr/app/id6755674738'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MainHomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('입주민 로그인'), findsOneWidget);
    expect(find.text('관리자 로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });
}
