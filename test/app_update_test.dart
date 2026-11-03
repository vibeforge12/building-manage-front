import 'package:building_manage_front/modules/app_update/domain/update_repository.dart';
import 'package:building_manage_front/modules/app_update/domain/check_update.dart';
import 'package:building_manage_front/modules/app_update/domain/update_policy.dart';
import 'package:building_manage_front/modules/app_update/presentation/update_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final forced = UpdatePolicy(
  enabled: true,
  minimumBuild: 35,
  storeUrl: Uri.parse('https://apps.apple.com/kr/app/id6755674738'),
);
const off = UpdatePolicy(enabled: false, minimumBuild: 0);

class FakeUpdates implements UpdateRepository {
  UpdatePolicy? stored;
  UpdatePolicy current = forced;
  bool offline = false;
  bool storageFails = false;
  int requests = 0;
  @override
  Future<UpdatePolicy?> cached(String platform) async => stored;
  @override
  Future<UpdatePolicy> fetch(String platform) async {
    requests++;
    if (offline) throw StateError('offline');
    return current;
  }

  @override
  Future<void> save(String platform, UpdatePolicy policy) async {
    if (storageFails) throw StateError('storage');
    stored = policy;
  }
}

void main() {
  test(
    'in-memory block survives offline check when cache could not be saved',
    () async {
      final repo = FakeUpdates()..storageFails = true;
      final container = ProviderContainer(
        overrides: [
          checkUpdateProvider.overrideWithValue(CheckUpdate(repo)),
          updateIdentityProvider.overrideWithValue(() async => ('ios', 34)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(updateGateProvider.notifier).check();
      expect(container.read(updateGateProvider).requiredPolicy, isNotNull);
      repo.offline = true;
      await container.read(updateGateProvider.notifier).check();
      expect(container.read(updateGateProvider).requiredPolicy, isNotNull);
    },
  );
  test('minimum build is numeric, equal/newer build is allowed', () {
    expect(forced.requiresUpdate(34), isTrue);
    expect(forced.requiresUpdate(35), isFalse);
    expect(forced.requiresUpdate(100), isFalse);
    expect(off.requiresUpdate(1), isFalse);
  });
  test('reject malformed policy, cross-platform and arbitrary store URLs', () {
    final json = forced.toJson('ios');
    expect(UpdatePolicy.fromJson(json, 'ios').minimumBuild, 35);
    for (final patch in [
      {'platform': 'android'},
      {'minimumBuild': '35'},
      {'minimumBuild': 0},
      {'storeUrl': 'https://evil.example/id6755674738'},
      {'storeUrl': 'https://apps.apple.com/kr/app/id999'},
      {'storeUrl': 'http://apps.apple.com/kr/app/id6755674738'},
    ]) {
      expect(
        () => UpdatePolicy.fromJson({...json, ...patch}, 'ios'),
        throwsFormatException,
      );
    }
  });
  test(
    'offline first run allows checking later; known mandatory policy is kept',
    () async {
      final repo = FakeUpdates()..offline = true;
      final check = CheckUpdate(repo);
      expect(await check.execute('ios'), isNull);
      repo.stored = forced;
      expect((await check.execute('ios'))!.requiresUpdate(34), isTrue);
    },
  );
  test(
    'fresh disabled policy lifts cached block even if saving fails',
    () async {
      final repo = FakeUpdates()
        ..stored = forced
        ..current = off
        ..storageFails = true;
      expect(
        (await CheckUpdate(repo).execute('ios'))!.requiresUpdate(34),
        isFalse,
      );
    },
  );
  testWidgets(
    'mandatory screen blocks content/back, opens exact store and refreshes after resume',
    (tester) async {
      final repo = FakeUpdates();
      Uri? opened;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkUpdateProvider.overrideWithValue(CheckUpdate(repo)),
            updateIdentityProvider.overrideWithValue(() async => ('ios', 34)),
            openUpdateStoreProvider.overrideWithValue((url) async {
              opened = url;
              return true;
            }),
          ],
          child: const MaterialApp(home: AppUpdateGate(child: Text('앱 본문'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('업데이트가 필요합니다'), findsOneWidget);
      expect(find.text('앱 본문'), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      await tester.tap(find.text('업데이트하기'));
      await tester.pumpAndSettle();
      expect(opened, forced.storeUrl);
      repo.offline = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('앱 본문'), findsNothing);
      repo.offline = false;
      repo.current = off;
      await tester.tap(find.text('다시 확인'));
      await tester.pumpAndSettle();
      expect(find.text('앱 본문'), findsOneWidget);
    },
  );
  testWidgets(
    'store launch failure keeps block and shows retry message at narrow width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checkUpdateProvider.overrideWithValue(CheckUpdate(FakeUpdates())),
            updateIdentityProvider.overrideWithValue(() async => ('ios', 34)),
            openUpdateStoreProvider.overrideWithValue((_) async => false),
          ],
          child: const MaterialApp(home: AppUpdateGate(child: Text('본문'))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('업데이트하기'));
      await tester.pumpAndSettle();
      expect(find.text('스토어를 열지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('본문'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
