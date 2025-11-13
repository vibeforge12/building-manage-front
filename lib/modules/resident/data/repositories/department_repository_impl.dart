import 'package:building_manage_front/modules/resident/domain/repositories/department_repository.dart';
import 'package:building_manage_front/modules/resident/domain/entities/department.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';

/// DepartmentRepository 구현체
class DepartmentRepositoryImpl implements DepartmentRepository {
  final DepartmentRemoteDataSource _dataSource;

  DepartmentRepositoryImpl(this._dataSource);

  @override
  Future<List<Department>> getDepartments() async {
    try {
      final result = await _dataSource.getDepartments();
      final departments = result['data'] as List<dynamic>? ?? [];

      return departments
          .map((json) => Department.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Department> getDepartmentById(String id) async {
    try {
      final result = await _dataSource.getDepartmentById(id);
      return Department.fromJson(result['data'] ?? result);
    } catch (e) {
      rethrow;
    }
  }
}
