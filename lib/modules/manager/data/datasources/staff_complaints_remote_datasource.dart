import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

final staffComplaintsRemoteDataSourceProvider =
    Provider<StaffComplaintsRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return StaffComplaintsRemoteDataSource(apiClient);
});

class StaffComplaintsRemoteDataSource {
  final ApiClient _apiClient;

  StaffComplaintsRemoteDataSource(this._apiClient);

  /// 미완료 민원 하이라이트 조회
  /// GET /api/v1/staffs/complaints/pending/highlight
  Future<Map<String, dynamic>> getPendingComplaintsHighlight() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.staffComplaintsPendingHighlight,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ 미완료 민원 하이라이트 조회 실패: $e');
      rethrow;
    }
  }
}
