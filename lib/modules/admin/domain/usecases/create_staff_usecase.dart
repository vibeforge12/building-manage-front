import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff.dart';

/// 담당자 계정 발급 UseCase
///
/// 비즈니스 로직:
/// 1. 담당자 데이터 유효성 검증
/// 2. Repository를 통한 담당자 계정 생성
/// 3. 생성된 Staff 엔티티 반환
class CreateStaffUseCase {
  final StaffRepository _repository;

  CreateStaffUseCase(this._repository);

  /// 담당자 계정 발급 실행
  ///
  /// [name] 담당자 이름
  /// [phoneNumber] 전화번호
  /// [departmentId] 부서 ID
  /// [imageUrl] 프로필 이미지 URL (선택)
  ///
  /// Returns: 생성된 Staff 엔티티
  /// Throws: Exception if validation or creation fails
  Future<Staff> execute({
    required String name,
    required String phoneNumber,
    required String departmentId,
    String? imageUrl,
  }) async {
    // 비즈니스 규칙: 유효성 검증
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
    final phoneRegex = RegExp(r'^\\d{10,11}$');
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      throw Exception('올바른 전화번호 형식이 아닙니다.');
    }

    if (departmentId.trim().isEmpty) {
      throw Exception('부서를 선택해 주세요.');
    }

    // Repository를 통한 담당자 계정 생성
    try {
      final staff = await _repository.createStaff(
        name: name.trim(),
        phoneNumber: cleanedPhone,
        departmentId: departmentId.trim(),
        imageUrl: imageUrl,
      );

      return staff;
    } catch (e) {
      rethrow;
    }
  }
}
