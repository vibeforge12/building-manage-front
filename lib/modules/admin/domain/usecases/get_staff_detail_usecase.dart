import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff.dart';

/// 담당자 상세 조회 UseCase
///
/// 비즈니스 로직:
/// 1. staffId 유효성 검증
/// 2. Repository를 통한 담당자 상세 조회
/// 3. Staff 엔티티 반환
class GetStaffDetailUseCase {
  final StaffRepository _repository;

  GetStaffDetailUseCase(this._repository);

  /// 담당자 상세 조회 실행
  ///
  /// [staffId] 담당자 ID
  ///
  /// Returns: Staff 엔티티
  /// Throws: Exception if validation or fetch fails
  Future<Staff> execute({required String staffId}) async {
    // 비즈니스 규칙: 유효성 검증
    if (staffId.trim().isEmpty) {
      throw Exception('담당자 ID가 유효하지 않습니다.');
    }

    try {
      final staff = await _repository.getStaffDetail(staffId: staffId.trim());
      return staff;
    } catch (e) {
      rethrow;
    }
  }
}
