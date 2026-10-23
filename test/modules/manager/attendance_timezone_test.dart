import 'package:flutter_test/flutter_test.dart';
import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';

void main() {
  group('AttendanceRecord 타임존 파싱', () {
    test('UTC 시간은 파싱 직후 기기 로컬 시간으로 정규화한다', () {
      const value = '2026-03-25T09:00:00Z';
      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': value,
      });

      expect(DateTime.parse(value).isUtc, true);
      expect(record.createdAt.isUtc, false);
      expect(record.createdAt, DateTime.parse(value).toLocal());
    });

    test('오프셋이 있는 시간도 같은 시각의 로컬 시간으로 정규화한다', () {
      const value = '2026-03-25T18:00:00+09:00';
      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': value,
      });

      expect(record.createdAt.isUtc, false);
      expect(record.createdAt, DateTime.parse(value).toLocal());
    });

    test('Z 없는 ISO 문자열 파싱 시 로컬 시간으로 취급', () {
      // Z 없으면 로컬 시간으로 파싱됨 (서버가 이미 KST로 보내는 경우)
      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': '2026-03-25T18:00:00',
      });

      expect(record.createdAt.isUtc, false);

      expect(record.createdAt, DateTime(2026, 3, 25, 18));
    });

    test('UTC 입력도 로컬 기준 오늘 날짜로 비교할 수 있다', () {
      final now = DateTime.now();

      // 한국 자정(00:00 KST) = 전날 UTC 15:00
      // 서버가 UTC로 "어제 15:00Z" 전송 → 실제로는 오늘 00:00 KST
      final kstMidnight = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final utcEquivalent = kstMidnight.toUtc();

      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': utcEquivalent.toIso8601String(), // UTC 시간
      });

      expect(record.createdAt.isUtc, false);
      expect(record.createdAt.year, now.year);
      expect(record.createdAt.month, now.month);
      expect(record.createdAt.day, now.day);
    });
  });
}
