import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

final residentDepartmentRemoteDataSourceProvider =
    Provider<ResidentDepartmentRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ResidentDepartmentRemoteDataSource(apiClient);
});

class ResidentDepartmentRemoteDataSource {
  final ApiClient _apiClient;

  ResidentDepartmentRemoteDataSource(this._apiClient);

  /// 입주민 건물 기준 부서 조회
  Future<Map<String, dynamic>> getDepartments() async {
    final response = await _apiClient.get('/users/departments');
    return response.data;
  }

  /// 담당자 출근 여부 확인
  /// GET /api/v1/users/buildings/{buildingId}/departments/{departmentId}/attendance
  /// 특정 부서의 담당자들이 오늘 출근했는지 확인합니다.
  Future<Map<String, dynamic>> checkStaffAttendance({
    required String buildingId,
    required String departmentId,
  }) async {
    final response = await _apiClient.get(
      '/users/buildings/$buildingId/departments/$departmentId/attendance',
    );
    return response.data;
  }
}
