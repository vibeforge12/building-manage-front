import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

class AttendanceAlertRemoteDataSource {
  final ApiClient _apiClient;

  AttendanceAlertRemoteDataSource(this._apiClient);

  /// 출퇴근/민원 알림 조회
  /// GET /api/v1/managers/dashboard/alerts
  /// 소속 건물 담당자 출퇴근 기록과 미완료 민원 리스트를 제공합니다.
  Future<Map<String, dynamic>> getDashboardAlerts() async {
    try {

      final response = await _apiClient.get(
        ApiEndpoints.managerDashboardAlerts,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception('출퇴근 알림을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('출퇴근 알림을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final attendanceAlertRemoteDataSourceProvider = Provider<AttendanceAlertRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceAlertRemoteDataSource(apiClient);
});
