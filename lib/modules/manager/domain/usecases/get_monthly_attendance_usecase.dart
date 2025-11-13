import 'package:building_manage_front/modules/manager/domain/repositories/attendance_repository.dart';
import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';

/// 월별 출퇴근 기록 조회 UseCase
///
/// 비즈니스 로직:
/// 1. 입력값 유효성 검증
/// 2. Repository를 통한 데이터 조회
/// 3. 결과 반환
class GetMonthlyAttendanceUseCase {
  final AttendanceRepository _repository;

  GetMonthlyAttendanceUseCase(this._repository);

  /// 월별 출퇴근 기록 조회 실행
  ///
  /// [year] 조회할 연도
  /// [month] 조회할 월 (1-12)
  ///
  /// Returns: 월별 출퇴근 기록
  /// Throws: Exception if validation or fetch fails
  Future<MonthlyAttendanceResponse> execute({
    required int year,
    required int month,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (month < 1 || month > 12) {
      throw Exception('월은 1에서 12 사이여야 합니다.');
    }

    if (year < 2000 || year > 2100) {
      throw Exception('연도가 유효하지 않습니다.');
    }

    try {
      final result = await _repository.getMonthlyAttendance(
        year: year,
        month: month,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
