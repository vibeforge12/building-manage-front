import 'package:building_manage_front/modules/manager/domain/repositories/attendance_repository.dart';

/// 출근 처리 UseCase
///
/// 비즈니스 로직:
/// 1. Repository를 통한 출근 처리
/// 2. 결과 반환
class CheckInUseCase {
  final AttendanceRepository _repository;

  CheckInUseCase(this._repository);

  /// 출근 처리 실행
  ///
  /// Returns: 출근 기록 정보
  /// Throws: Exception if check-in fails
  Future<Map<String, dynamic>> execute() async {
    try {
      final result = await _repository.checkIn();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
