import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff_attendance.dart';

class StaffAttendanceRemoteDataSource {
  final ApiClient _apiClient;

  StaffAttendanceRemoteDataSource(this._apiClient);

  /// 월별 직원 출퇴근 조회 (캘린더용)
  /// GET /managers/staffs/attendance/monthly?year={year}&month={month}
  Future<StaffAttendanceMonthly> getMonthlyStaffAttendance({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.managerStaffAttendanceMonthly,
        queryParameters: {'year': year, 'month': month},
      );
      return StaffAttendanceMonthly.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '월별 출퇴근 조회에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'FETCH_MONTHLY_FAILED',
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(
        message: '월별 출퇴근 조회 중 오류가 발생했습니다.',
        errorCode: 'FETCH_MONTHLY_FAILED',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// 일별 직원 출퇴근 현황 조회
  /// GET /managers/staffs/attendance/daily?year={year}&month={month}&day={day}
  Future<StaffAttendanceDaily> getDailyStaffAttendance({
    required int year,
    required int month,
    required int day,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.managerStaffAttendanceDaily,
        queryParameters: {'year': year, 'month': month, 'day': day},
      );
      return StaffAttendanceDaily.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '일별 출퇴근 조회에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'FETCH_DAILY_FAILED',
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(
        message: '일별 출퇴근 조회 중 오류가 발생했습니다.',
        errorCode: 'FETCH_DAILY_FAILED',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final staffAttendanceRemoteDataSourceProvider =
    Provider<StaffAttendanceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StaffAttendanceRemoteDataSource(apiClient);
});
