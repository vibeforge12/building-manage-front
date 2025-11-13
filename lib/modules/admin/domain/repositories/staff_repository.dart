import 'package:building_manage_front/modules/admin/domain/entities/staff.dart';

/// 담당자 관리 Repository 인터페이스
///
/// Admin 모듈에서 담당자 CRUD 작업을 위한 추상 계층
abstract class StaffRepository {
  /// 담당자 목록 조회
  ///
  /// Returns: Staff 엔티티 리스트
  /// Throws: Exception if fetch fails
  Future<List<Staff>> getStaffs();

  /// 담당자 상세 조회
  ///
  /// [staffId] 담당자 ID
  ///
  /// Returns: Staff 엔티티
  /// Throws: Exception if not found or fetch fails
  Future<Staff> getStaffDetail({required String staffId});

  /// 담당자 계정 발급 (생성)
  ///
  /// [name] 담당자 이름
  /// [phoneNumber] 전화번호
  /// [departmentId] 부서 ID
  /// [imageUrl] 프로필 이미지 URL (선택)
  ///
  /// Returns: 생성된 Staff 엔티티
  /// Throws: Exception if creation fails
  Future<Staff> createStaff({
    required String name,
    required String phoneNumber,
    required String departmentId,
    String? imageUrl,
  });

  /// 담당자 정보 수정
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
  /// Throws: Exception if update fails
  Future<Staff> updateStaff({
    required String staffId,
    required String name,
    required String phoneNumber,
    required String departmentId,
    required String status,
    String? imageUrl,
    String? password,
  });

  /// 담당자 삭제
  ///
  /// [staffId] 담당자 ID
  ///
  /// Throws: Exception if deletion fails
  Future<void> deleteStaff({required String staffId});
}
