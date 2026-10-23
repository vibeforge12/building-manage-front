import 'dart:math' as math;
import 'dart:ui' show FrameTiming, Offset;

import 'package:building_manage_front/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final _frameBudgetMs = double.parse(
  const String.fromEnvironment(
    'QUALITY_FRAME_BUDGET_MS',
    defaultValue: '16.67',
  ),
);
final _maxSlowFramePercent = double.parse(
  const String.fromEnvironment(
    'QUALITY_MAX_SLOW_FRAME_PERCENT',
    defaultValue: '1',
  ),
);
final _frozenFrameMs = double.parse(
  const String.fromEnvironment('QUALITY_FROZEN_FRAME_MS', defaultValue: '700'),
);
const _maxFrozenFrames = int.fromEnvironment(
  'QUALITY_MAX_FROZEN_FRAMES',
  defaultValue: 0,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('현재 진입 화면의 스크롤·렌더링 성능이 기준을 만족한다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BuildingManageApp()),
    );

    // 네트워크나 지속 애니메이션 때문에 pumpAndSettle이 끝나지 않는 상황을 피한다.
    for (var index = 0; index < 120; index++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final timings = <FrameTiming>[];
    void collectTimings(List<FrameTiming> values) => timings.addAll(values);
    SchedulerBinding.instance.addTimingsCallback(collectTimings);

    final scrollable = find.byType(Scrollable).hitTestable();
    if (scrollable.evaluate().isNotEmpty) {
      for (var index = 0; index < 4; index++) {
        await tester.fling(scrollable.first, const Offset(0, -300), 900);
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.fling(scrollable.first, const Offset(0, 300), 900);
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    } else {
      // 스크롤이 없는 화면도 120개 프레임을 만들어 렌더링 회귀를 감시한다.
      for (var frame = 0; frame < 120; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    SchedulerBinding.instance.removeTimingsCallback(collectTimings);
    expect(timings, isNotEmpty, reason: '실기기 FrameTiming을 수집하지 못했습니다.');

    final frameTimes = timings
        .map(
          (timing) =>
              math.max(
                timing.buildDuration.inMicroseconds,
                timing.rasterDuration.inMicroseconds,
              ) /
              1000,
        )
        .toList()
      ..sort();
    final slowFrames =
        frameTimes.where((value) => value > _frameBudgetMs).length;
    final frozenFrames =
        frameTimes.where((value) => value >= _frozenFrameMs).length;
    final slowPercent = slowFrames / frameTimes.length * 100;
    final p95Index = ((frameTimes.length - 1) * 0.95).ceil();
    final p95 = frameTimes[p95Index];

    final reportData = {
      'frameCount': frameTimes.length,
      'p95FrameMs': p95,
      'slowFrameCount': slowFrames,
      'slowFramePercent': slowPercent,
      'frozenFrameCount': frozenFrames,
      'frameBudgetMs': _frameBudgetMs,
      'maxSlowFramePercent': _maxSlowFramePercent,
      'maxFrozenFrames': _maxFrozenFrames,
    };
    addTearDown(() => binding.reportData = reportData);
  });
}
