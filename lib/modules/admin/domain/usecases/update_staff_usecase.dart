import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff.dart';

/// 담당자 정보 수정 UseCase
///
/// 비즈니스 로직:
/// 1. 담당자 데이터 유효성 검증
/// 2. Repository를 통한 담당자 정보 수정
/// 3. 수정된 Staff 엔티티 반환
class UpdateStaffUseCase {
  final StaffRepository _repository;

  UpdateStaffUseCase(this._repository);

  /// 담당자 정보 수정 실행
  ///
  /// [staffId] 담당자 ID
  /// [name] 담당자 이름
  /// [phoneNumber] 전화번호
  /// [departmentId] 부서 ID
  /// [status] 상태
  /// [imageUrl] 프로필 이미지 URL (선택)
  /// [password] 비밀번호 (변경 시에만)
  ///
  /// Returns: 수정된 Staff 엔티티
  /// Throws: Exception if validation or update fails
  Future<Staff> execute({
    required String staffId,
    required String name,
    required String phoneNumber,
    required String departmentId,
    required String status,
    String? imageUrl,
    String? password,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (staffId.trim().isEmpty) {
      throw Exception('담당자 ID가 유효하지 않습니다.');
    }

    if (name.trim().isEmpty) {
      throw Exception('담당자 이름을 입력해 주세요.');
    }

    if (name.length < 2) {
      throw Exception('담당자 이름은 최소 2자 이상이어야 합니다.');
    }

    if (name.length > 50) {
      throw Exception('담당자 이름은 50자를 초과할 수 없습니다.');
    }

    if (phoneNumber.trim().isEmpty) {
      throw Exception('전화번호를 입력해 주세요.');
    }

    // 전화번호 형식 검증
    final phoneRegex = RegExp(r'^\d{10,11}$');
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      throw Exception('올바른 전화번호 형식이 아닙니다.');
    }

    if (departmentId.trim().isEmpty) {
      throw Exception('부서를 선택해 주세요.');
    }

    if (status.trim().isEmpty) {
      throw Exception('상태를 선택해 주세요.');
    }

    // 비밀번호 변경 시 유효성 검증
    if (password != null && password.isNotEmpty) {
      if (password.length < 6) {
        throw Exception('비밀번호는 최소 6자 이상이어야 합니다.');
      }
    }

    // Repository를 통한 담당자 정보 수정
    try {
      final staff = await _repository.updateStaff(
        staffId: staffId.trim(),
        name: name.trim(),
        phoneNumber: cleanedPhone,
        departmentId: departmentId.trim(),
        status: status.trim(),
        imageUrl: imageUrl,
        password: password,
      );

      return staff;
    } catch (e) {
      rethrow;
    }
  }
}
