import 'package:building_manage_front/modules/admin/domain/repositories/resident_management_repository.dart';

/// 입주민 거절 UseCase
///
/// 비즈니스 로직:
/// 1. residentId 유효성 검증
/// 2. Repository를 통한 입주민 거절 (삭제)
class RejectResidentUseCase {
  final ResidentManagementRepository _repository;

  RejectResidentUseCase(this._repository);

  /// 입주민 거절 실행
  ///
  /// [residentId] 입주민 ID
  ///
  /// Throws: Exception if validation or rejection fails
  Future<void> execute({required String residentId}) async {
    print('🔷 RejectResidentUseCase.execute 호출됨');
    print('📋 residentId: $residentId');

    // 비즈니스 규칙: 유효성 검증
    if (residentId.trim().isEmpty) {
      print('❌ residentId가 비어있음');
      throw Exception('입주민 ID가 유효하지 않습니다.');
    }

    try {
      print('📤 _repository.rejectResident 호출...');
      await _repository.rejectResident(residentId: residentId.trim());
      print('✅ _repository.rejectResident 성공!');
    } catch (e) {
      print('❌ _repository.rejectResident 실패: $e');
      rethrow;
    }
  }
}
