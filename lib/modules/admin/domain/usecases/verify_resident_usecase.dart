import 'package:building_manage_front/modules/admin/domain/repositories/resident_management_repository.dart';
import 'package:building_manage_front/modules/admin/domain/entities/resident_info.dart';

/// 입주민 승인 UseCase
///
/// 비즈니스 로직:
/// 1. residentId 유효성 검증
/// 2. Repository를 통한 입주민 승인
/// 3. 승인된 ResidentInfo 엔티티 반환
class VerifyResidentUseCase {
  final ResidentManagementRepository _repository;

  VerifyResidentUseCase(this._repository);

  /// 입주민 승인 실행
  ///
  /// [residentId] 입주민 ID
  ///
  /// Returns: 승인된 ResidentInfo 엔티티
  /// Throws: Exception if validation or verification fails
  Future<ResidentInfo> execute({required String residentId}) async {
    // 비즈니스 규칙: 유효성 검증
    if (residentId.trim().isEmpty) {
      throw Exception('입주민 ID가 유효하지 않습니다.');
    }

    try {
      final resident = await _repository.verifyResident(residentId: residentId.trim());
      return resident;
    } catch (e) {
      rethrow;
    }
  }
}
