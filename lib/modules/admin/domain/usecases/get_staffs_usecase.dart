import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff.dart';

/// 담당자 목록 조회 UseCase
///
/// 비즈니스 로직:
/// 1. Repository를 통한 담당자 목록 조회
/// 2. Staff 엔티티 리스트 반환
class GetStaffsUseCase {
  final StaffRepository _repository;

  GetStaffsUseCase(this._repository);

  /// 담당자 목록 조회 실행
  ///
  /// Returns: Staff 엔티티 리스트
  /// Throws: Exception if fetch fails
  Future<List<Staff>> execute() async {
    try {
      final staffs = await _repository.getStaffs();
      return staffs;
    } catch (e) {
      rethrow;
    }
  }
}
