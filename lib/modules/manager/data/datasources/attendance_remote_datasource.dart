import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';

class AttendanceRemoteDataSource {
  final ApiClient _apiClient;

  AttendanceRemoteDataSource(this._apiClient);

  /// 출근 처리
  /// POST /staffs/attendance/check-in
  Future<Map<String, dynamic>> checkIn() async {
    try {
      print('🏢 출근 처리 시작');

      final response = await _apiClient.post(
        '/staffs/attendance/check-in',
      );

      print('✅ 출근 처리 성공');
      print('📦 응답 데이터: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('   상태 코드: ${e.response?.statusCode}');
      print('   응답 데이터: ${e.response?.data}');

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '출근 처리에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'CHECK_IN_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '출근 처리 중 오류가 발생했습니다.',
        errorCode: 'CHECK_IN_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw ApiException(
        message: '출근 처리 중 오류가 발생했습니다.',
        errorCode: 'CHECK_IN_FAILED',
      );
    }
  }

  /// 퇴근 처리
  /// POST /staffs/attendance/check-out
  Future<Map<String, dynamic>> checkOut() async {
    try {
      print('🏃 퇴근 처리 시작');

      final response = await _apiClient.post(
        '/staffs/attendance/check-out',
      );

      print('✅ 퇴근 처리 성공');
      print('📦 응답 데이터: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('   상태 코드: ${e.response?.statusCode}');
      print('   응답 데이터: ${e.response?.data}');

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '퇴근 처리에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'CHECK_OUT_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '퇴근 처리 중 오류가 발생했습니다.',
        errorCode: 'CHECK_OUT_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw ApiException(
        message: '퇴근 처리 중 오류가 발생했습니다.',
        errorCode: 'CHECK_OUT_FAILED',
      );
    }
  }

  /// 월별 출퇴근 기록 조회
  /// GET /staffs/attendance?year={year}&month={month}
  Future<MonthlyAttendanceResponse> getMonthlyAttendance({
    required int year,
    required int month,
  }) async {
    try {
      print('📅 월별 출퇴근 기록 조회 시작: $year년 $month월');

      final response = await _apiClient.get(
        '/staffs/attendance',
        queryParameters: {
          'year': year,
          'month': month,
        },
      );

      print('✅ 월별 출퇴근 기록 조회 성공');
      print('📦 응답 데이터: ${response.data}');

      return MonthlyAttendanceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('   상태 코드: ${e.response?.statusCode}');
      print('   응답 데이터: ${e.response?.data}');

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '출퇴근 기록 조회에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'FETCH_ATTENDANCE_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '출퇴근 기록 조회 중 오류가 발생했습니다.',
        errorCode: 'FETCH_ATTENDANCE_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw ApiException(
        message: '출퇴근 기록 조회 중 오류가 발생했습니다.',
        errorCode: 'FETCH_ATTENDANCE_FAILED',
      );
    }
  }
}

// Riverpod Provider
final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AttendanceRemoteDataSource(apiClient);
});
