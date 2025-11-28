import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

class AttendanceAlertRemoteDataSource {
  final ApiClient _apiClient;

  AttendanceAlertRemoteDataSource(this._apiClient);

  /// 출퇴근/민원 알림 조회
  /// GET /api/v1/managers/dashboard/alerts
  /// 소속 건물 담당자 출퇴근 기록과 미완료 민원 리스트를 제공합니다.
  Future<Map<String, dynamic>> getDashboardAlerts() async {
    try {
      print('📋 출퇴근/민원 알림 조회 시작');
      print('📤 API 호출: GET ${ApiEndpoints.managerDashboardAlerts}');

      final response = await _apiClient.get(
        ApiEndpoints.managerDashboardAlerts,
      );

      print('✅ 출퇴근/민원 알림 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('출퇴근 알림을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('출퇴근 알림을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final attendanceAlertRemoteDataSourceProvider = Provider<AttendanceAlertRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceAlertRemoteDataSource(apiClient);
});
