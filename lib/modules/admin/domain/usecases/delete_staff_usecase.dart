import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';

/// 담당자 삭제 UseCase
///
/// 비즈니스 로직:
/// 1. staffId 유효성 검증
/// 2. Repository를 통한 담당자 삭제
class DeleteStaffUseCase {
  final StaffRepository _repository;

  DeleteStaffUseCase(this._repository);

  /// 담당자 삭제 실행
  ///
  /// [staffId] 담당자 ID
  ///
  /// Throws: Exception if validation or deletion fails
  Future<void> execute({required String staffId}) async {
    // 비즈니스 규칙: 유효성 검증
    if (staffId.trim().isEmpty) {
      throw Exception('담당자 ID가 유효하지 않습니다.');
    }

    try {
      await _repository.deleteStaff(staffId: staffId.trim());
    } catch (e) {
      rethrow;
    }
  }
}
