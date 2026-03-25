import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';

void main() {
  group('AttendanceRecord 타임존 파싱', () {
    test('UTC 시간(Z 접미사) 파싱 시 isUtc = true 확인', () {
      // 서버가 UTC로 오전 9시 보낸 경우 (한국 시간 오후 6시)
      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': '2026-03-25T09:00:00Z',
      });

      // DateTime.parse('...Z')는 UTC로 파싱됨
      expect(record.createdAt.isUtc, true);

      // toLocal() 없이 포맷하면 UTC 시간 그대로 표시 → 09:00
      final utcFormatted = DateFormat('HH:mm').format(record.createdAt);

      // toLocal() 적용 시 KST (+9) → 18:00
      final localFormatted = DateFormat('HH:mm').format(record.createdAt.toLocal());

      print('UTC 포맷: $utcFormatted');       // 09:00 (틀린 값)
      print('Local 포맷: $localFormatted');   // 18:00 (맞는 값)

      // UTC와 로컬이 다름 → toLocal() 필요함을 증명
      expect(utcFormatted, isNot(equals(localFormatted)));
      expect(localFormatted, '18:00');
    });

    test('KST 명시(+09:00) 파싱 시 toLocal() 불필요 확인', () {
      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': '2026-03-25T18:00:00+09:00',
      });

      final formatted = DateFormat('HH:mm').format(record.createdAt.toLocal());
      print('KST 명시 포맷: $formatted');

      // +09:00으로 오면 toLocal() 후에도 18:00 그대로
      expect(formatted, '18:00');
    });

    test('Z 없는 ISO 문자열 파싱 시 로컬 시간으로 취급', () {
      // Z 없으면 로컬 시간으로 파싱됨 (서버가 이미 KST로 보내는 경우)
      final record = AttendanceRecord.fromJson({
        'id': '1',
        'type': 'CHECK_IN',
        'createdAt': '2026-03-25T18:00:00',
      });

      expect(record.createdAt.isUtc, false);

      final formatted = DateFormat('HH:mm').format(record.createdAt);
      print('Z없는 ISO 포맷: $formatted'); // 18:00 그대로

      expect(formatted, '18:00');
    });

    test('오늘 날짜 필터링 - UTC 시간일 때 toLocal() 없으면 날짜 비교 오류 발생', () {
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

      // toLocal() 없이 날짜 비교 → 어제 날짜로 판단 (버그)
      final withoutLocal = record.createdAt;
      final isToday_wrongWay = withoutLocal.day == now.day &&
          withoutLocal.month == now.month &&
          withoutLocal.year == now.year;

      // toLocal() 사용 날짜 비교 → 오늘 날짜로 정확히 판단 (정상)
      final withLocal = record.createdAt.toLocal();
      final isToday_rightWay = withLocal.day == now.day &&
          withLocal.month == now.month &&
          withLocal.year == now.year;

      print('toLocal() 없이: $isToday_wrongWay'); // false (버그)
      print('toLocal() 있이: $isToday_rightWay'); // true (정상)

      // UTC 기준 날짜와 로컬 기준 날짜가 다름을 증명
      expect(isToday_wrongWay, false);
      expect(isToday_rightWay, true);
    });
  });
}
