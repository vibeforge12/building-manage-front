import 'dart:async';
import 'package:building_manage_front/modules/app_update/data/google_play_updater.dart';
import 'package:building_manage_front/modules/app_update/domain/check_latest_version.dart';
import 'package:building_manage_front/modules/app_update/domain/start_app_update.dart';
import 'package:building_manage_front/modules/app_update/presentation/app_version_section.dart';
import 'package:building_manage_front/modules/app_update/presentation/update_actions.dart';
import 'package:building_manage_front/shared/widgets/scrollable_menu_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final iosUrl = Uri.parse('https://apps.apple.com/kr/app/id6755674738');
final androidUrl = Uri.parse(
  'https://play.google.com/store/apps/details?id=com.j2partners.buildingManageFront',
);

class Releases implements AppReleaseRepository {
  int build = 42;
  bool offline = false;
  int requests = 0;
  @override
  Future<PublishedAppRelease> fetch(String platform) async {
    requests++;
    if (offline) throw StateError('offline');
    return PublishedAppRelease(
      '1.0.17',
      build,
      platform == 'ios' ? iosUrl : androidUrl,
    );
  }
}

class AndroidUpdates implements AndroidAppUpdater {
  UpdateLaunchResult result = UpdateLaunchResult.started;
  int starts = 0;
  int? target;
  @override
  Future<UpdateLaunchResult> start({
    int minimumBuild = 0,
    bool resumeOnly = false,
  }) async {
    starts++;
    target = minimumBuild;
    return result;
  }
}

void main() {
  test(
    'numeric builds distinguish old, current and unpublished installed builds',
    () async {
      final repo = Releases();
      for (final (build, status) in [
        (9, AppVersionStatus.updateAvailable),
        (42, AppVersionStatus.current),
        (43, AppVersionStatus.aheadOfStore),
      ]) {
        final result = await CheckLatestVersion(
          repo,
        ).execute(InstalledAppVersion('ios', '1.0.17', build));
        expect(result.status, status);
      }
      repo.offline = true;
      expect(
        CheckLatestVersion(
          repo,
        ).execute(const InstalledAppVersion('ios', '1.0.17', 42)),
        throwsStateError,
      );
    },
  );
  test(
    'release parser rejects cross-platform, malformed and arbitrary URLs',
    () {
      final json = {
        'platform': 'ios',
        'latestVersion': '1.0.17',
        'latestBuild': 42,
        'storeUrl': iosUrl.toString(),
      };
      expect(PublishedAppRelease.fromJson(json, 'ios').build, 42);
      for (final patch in [
        {'platform': 'android'},
        {'latestBuild': '42'},
        {'latestBuild': -1},
        {'latestVersion': 'bad'},
        {'storeUrl': 'https://evil.example/id6755674738'},
        {'storeUrl': 'https://apps.apple.com/kr/app/id999'},
      ]) {
        expect(
          () => PublishedAppRelease.fromJson({...json, ...patch}, 'ios'),
          throwsFormatException,
        );
      }
    },
  );

  Future<void> pump(
    WidgetTester tester,
    Releases repo,
    AndroidUpdates android, {
    String platform = 'ios',
    int installed = 41,
    Future<bool> Function(Uri)? open,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          installedAppVersionProvider.overrideWith(
            (ref) async => InstalledAppVersion(platform, '1.0.16', installed),
          ),
          checkLatestVersionProvider.overrideWithValue(
            CheckLatestVersion(repo),
          ),
          androidAppUpdaterProvider.overrideWithValue(android),
          openUpdateStoreProvider.overrideWithValue(open ?? (_) async => true),
        ],
        child: const MaterialApp(home: Scaffold(body: AppVersionSection())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('iOS opens exact App Store URL and never invokes Android', (
    tester,
  ) async {
    final android = AndroidUpdates();
    Uri? opened;
    await pump(
      tester,
      Releases(),
      android,
      open: (uri) async {
        opened = uri;
        return true;
      },
    );
    expect(find.text('현재 버전 1.0.16'), findsOneWidget);
    expect(find.text('최신 버전 1.0.17'), findsOneWidget);
    await tester.tap(find.text('업데이트하기'));
    await tester.pumpAndSettle();
    expect(opened, iosUrl);
    expect(android.starts, 0);
  });
  testWidgets(
    'Android cancel stays in app, failure offers explicit store fallback and retry',
    (tester) async {
      final android = AndroidUpdates()..result = UpdateLaunchResult.cancelled;
      var opens = 0;
      await pump(
        tester,
        Releases(),
        android,
        platform: 'android',
        open: (_) async {
          opens++;
          return true;
        },
      );
      await tester.tap(find.text('업데이트하기'));
      await tester.pumpAndSettle();
      expect(android.target, 42);
      expect(opens, 0);
      expect(find.textContaining('업데이트를 취소'), findsOneWidget);
      android.result = UpdateLaunchResult.unavailable;
      await tester.tap(find.text('업데이트하기'));
      await tester.pumpAndSettle();
      expect(opens, 0);
      expect(find.text('Play 스토어에서 확인'), findsOneWidget);
      await tester.tap(find.text('Play 스토어에서 확인'));
      await tester.pumpAndSettle();
      expect(opens, 1);
    },
  );
  testWidgets('offline check stays silent; resume fetches fresh data', (
    tester,
  ) async {
    final repo = Releases();
    await pump(tester, repo, AndroidUpdates(), installed: 42);
    expect(find.text('최신 버전입니다'), findsOneWidget);
    repo.offline = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('최신 버전입니다'), findsNothing);
    expect(find.text('버전 확인 실패'), findsNothing);
    expect(find.text('다시 확인'), findsNothing);
    expect(find.textContaining('현재 버전'), findsOneWidget);
    expect(find.text('업데이트하기'), findsNothing);
    repo.offline = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('최신 버전입니다'), findsOneWidget);
    repo.build = 43;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('업데이트하기'), findsOneWidget);
    expect(repo.requests, greaterThanOrEqualTo(4));
  });
  testWidgets(
    'small menu with larger text scrolls to update without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installedAppVersionProvider.overrideWith(
              (ref) async => const InstalledAppVersion('ios', '1.0.16', 41),
            ),
            checkLatestVersionProvider.overrideWithValue(
              CheckLatestVersion(Releases()),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: ScrollableMenuBody(
                  children: [
                    for (var i = 0; i < 8; i++)
                      const ListTile(title: Text('기존 메뉴 항목')),
                    const Spacer(),
                    const AppVersionSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('업데이트하기'));
      expect(tester.takeException(), isNull);
    },
  );

  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  group('Google Play native adapter', () {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    var availability = 2;
    var allowed = true;
    var build = 42;
    String? error;
    final calls = <String>[];
    setUp(() {
      availability = 2;
      allowed = true;
      build = 42;
      error = null;
      calls.clear();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'performImmediateUpdate') {
          if (error != null) throw PlatformException(code: error!);
          return null;
        }
        return {
          'updateAvailability': availability,
          'immediateAllowed': allowed,
          'flexibleAllowed': true,
          'availableVersionCode': build,
          'installStatus': 0,
          'packageName': 'com.j2partners.buildingManageFront',
          'updatePriority': 0,
        };
      });
    });
    tearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    test(
      'uses immediate installation only for an available allowed target',
      () async {
        final updater = GooglePlayUpdater();
        expect(
          await updater.start(minimumBuild: 42),
          UpdateLaunchResult.started,
        );
        expect(calls, ['checkForUpdate', 'performImmediateUpdate']);
        for (final scenario in [0, 1, 2]) {
          calls.clear();
          availability = scenario == 0 ? 1 : 2;
          allowed = scenario != 1;
          build = scenario == 2 ? 41 : 42;
          expect(
            await updater.start(minimumBuild: 42),
            UpdateLaunchResult.unavailable,
          );
          expect(calls, ['checkForUpdate']);
        }
      },
    );
    test(
      'resume never initiates a new offer; resumes only an in-progress update',
      () async {
        final updater = GooglePlayUpdater();
        expect(
          await updater.start(resumeOnly: true),
          UpdateLaunchResult.notInProgress,
        );
        expect(calls, ['checkForUpdate']);
        availability = 3;
        calls.clear();
        expect(
          await updater.start(resumeOnly: true),
          UpdateLaunchResult.started,
        );
        expect(calls, ['checkForUpdate', 'performImmediateUpdate']);
      },
    );
    test(
      'native cancellation and failure are retryable and distinct',
      () async {
        final updater = GooglePlayUpdater();
        error = 'USER_DENIED_UPDATE';
        expect(await updater.start(), UpdateLaunchResult.cancelled);
        error = 'IN_APP_UPDATE_FAILED';
        expect(await updater.start(), UpdateLaunchResult.unavailable);
        error = null;
        expect(await updater.start(), UpdateLaunchResult.started);
      },
    );
    test('concurrent requests cannot open two Play update flows', () async {
      final pending = Completer<dynamic>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) => pending.future,
      );
      final updater = GooglePlayUpdater();
      final first = updater.start();
      expect(await updater.start(), UpdateLaunchResult.busy);
      pending.completeError(PlatformException(code: 'network'));
      expect(await first, UpdateLaunchResult.unavailable);
    });
  });
}
