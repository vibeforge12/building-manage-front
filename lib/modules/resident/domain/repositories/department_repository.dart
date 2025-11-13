import 'package:building_manage_front/modules/resident/domain/entities/department.dart';

/// 부서 Repository 인터페이스
abstract class DepartmentRepository {
  /// 부서 목록 조회
  ///
  /// Returns: Department 리스트
  /// Throws: Exception if fetch fails
  Future<List<Department>> getDepartments();

  /// 부서 상세 조회
  ///
  /// [id] 부서 ID
  ///
  /// Returns: Department 엔티티
  /// Throws: Exception if not found
  Future<Department> getDepartmentById(String id);
}
