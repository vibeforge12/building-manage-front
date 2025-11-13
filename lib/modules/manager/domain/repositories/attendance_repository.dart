import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';

/// 출퇴근 관리 Repository 인터페이스
///
/// Manager 모듈에서 출퇴근 작업을 위한 추상 계층
abstract class AttendanceRepository {
  /// 출근 처리
  ///
  /// Returns: 출근 기록 정보
  /// Throws: Exception if check-in fails
  Future<Map<String, dynamic>> checkIn();

  /// 퇴근 처리
  ///
  /// Returns: 퇴근 기록 정보
  /// Throws: Exception if check-out fails
  Future<Map<String, dynamic>> checkOut();

  /// 월별 출퇴근 기록 조회
  ///
  /// [year] 조회할 연도
  /// [month] 조회할 월 (1-12)
  ///
  /// Returns: 월별 출퇴근 기록
  /// Throws: Exception if fetch fails
  Future<MonthlyAttendanceResponse> getMonthlyAttendance({
    required int year,
    required int month,
  });
}
