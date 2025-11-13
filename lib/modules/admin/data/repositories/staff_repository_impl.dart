import 'package:building_manage_front/modules/admin/domain/entities/staff.dart';
import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_remote_datasource.dart';

/// 담당자 Repository 구현
///
/// DataSource를 통해 API 호출 후 Entity로 변환
class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource _dataSource;

  StaffRepositoryImpl(this._dataSource);

  @override
  Future<List<Staff>> getStaffs() async {
    try {
      final response = await _dataSource.getStaffs();

      if (response['success'] != true) {
        throw Exception('담당자 목록 조회 실패');
      }

      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];

      return data
          .map((item) => Staff.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Staff> getStaffDetail({required String staffId}) async {
    try {
      final response = await _dataSource.getStaffDetail(staffId: staffId);

      if (response['success'] != true) {
        throw Exception('담당자 상세 조회 실패');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('담당자 정보가 없습니다.');
      }

      return Staff.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Staff> createStaff({
    required String name,
    required String phoneNumber,
    required String departmentId,
    String? imageUrl,
  }) async {
    try {
      final response = await _dataSource.createStaff(
        name: name,
        phoneNumber: phoneNumber,
        departmentId: departmentId,
        imageUrl: imageUrl,
      );

      if (response['success'] != true) {
        throw Exception('담당자 계정 발급 실패');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('담당자 정보가 반환되지 않았습니다.');
      }

      return Staff.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Staff> updateStaff({
    required String staffId,
    required String name,
    required String phoneNumber,
    required String departmentId,
    required String status,
    String? imageUrl,
    String? password,
  }) async {
    try {
      final response = await _dataSource.updateStaff(
        staffId: staffId,
        name: name,
        phoneNumber: phoneNumber,
        departmentId: departmentId,
        status: status,
        imageUrl: imageUrl,
        password: password,
      );

      if (response['success'] != true) {
        throw Exception('담당자 정보 수정 실패');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('담당자 정보가 반환되지 않았습니다.');
      }

      return Staff.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteStaff({required String staffId}) async {
    try {
      final response = await _dataSource.deleteStaff(staffId: staffId);

      if (response['success'] != true) {
        throw Exception('담당자 삭제 실패');
      }
    } catch (e) {
      rethrow;
    }
  }
}
