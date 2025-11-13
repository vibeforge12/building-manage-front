import 'package:building_manage_front/modules/manager/domain/repositories/attendance_repository.dart';

/// 퇴근 처리 UseCase
///
/// 비즈니스 로직:
/// 1. Repository를 통한 퇴근 처리
/// 2. 결과 반환
class CheckOutUseCase {
  final AttendanceRepository _repository;

  CheckOutUseCase(this._repository);

  /// 퇴근 처리 실행
  ///
  /// Returns: 퇴근 기록 정보
  /// Throws: Exception if check-out fails
  Future<Map<String, dynamic>> execute() async {
    try {
      final result = await _repository.checkOut();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
