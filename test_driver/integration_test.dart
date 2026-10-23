import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      if (data == null) {
        throw StateError('프레임 성능 결과가 비어 있습니다.');
      }

      final reportDirectory = Platform.environment['QUALITY_REPORT_DIR'];
      if (reportDirectory != null && reportDirectory.isNotEmpty) {
        final file = File('$reportDirectory/flutter-frame-performance.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(data),
        );
      }
      final slowFramePercent = data['slowFramePercent'] as num;
      final frozenFrameCount = data['frozenFrameCount'] as num;
      final maxSlowFramePercent = double.parse(
        Platform.environment['QUALITY_MAX_SLOW_FRAME_PERCENT'] ?? '1',
      );
      final maxFrozenFrames = int.parse(
        Platform.environment['QUALITY_MAX_FROZEN_FRAMES'] ?? '0',
      );
      if (slowFramePercent > maxSlowFramePercent ||
          frozenFrameCount > maxFrozenFrames) {
        throw StateError(
          '프레임 성능 기준 초과: 느린 프레임 '
          '$slowFramePercent%/$maxSlowFramePercent%, frozen frame '
          '$frozenFrameCount/$maxFrozenFrames',
        );
      }
    },
  );
}
