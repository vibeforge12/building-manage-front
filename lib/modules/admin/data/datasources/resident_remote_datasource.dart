import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ResidentRemoteDataSource {
  final ApiClient _apiClient;

  ResidentRemoteDataSource(this._apiClient);

  /// 입주민 목록 조회
  /// GET /api/v1/managers/residents
  Future<Map<String, dynamic>> getResidents({
    int page = 1,
    int limit = 20,
    String sortOrder = 'DESC',
    bool? isVerified,
    String? status,
    String? keyword,
  }) async {
    try {
      print('👥 입주민 목록 조회 시작');
      print('   page: $page, limit: $limit, isVerified: $isVerified');

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortOrder': sortOrder,
      };

      if (isVerified != null) {
        queryParams['isVerified'] = isVerified;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      print('📤 API 호출: GET /api/v1/managers/residents');
      print('   쿼리 파라미터: $queryParams');

      final response = await _apiClient.get(
        '/managers/residents',
        queryParameters: queryParams,
      );

      print('✅ 입주민 목록 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('입주민 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('입주민 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 입주민 승인
  /// POST /api/v1/managers/residents/{residentId}/approve
  Future<Map<String, dynamic>> verifyResident({
    required String residentId,
  }) async {
    try {
      print('✅ 입주민 승인 요청 시작');
      print('   입주민 ID: $residentId');
      print('📤 API 호출: POST /api/v1/managers/residents/$residentId/approve');

      final response = await _apiClient.post('/managers/residents/$residentId/approve');

      print('✅ 입주민 승인 성공');
      print('📦 응답 데이터: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('   상태 코드: ${e.response?.statusCode}');
      print('   응답 데이터: ${e.response?.data}');

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '입주민 승인에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'RESIDENT_VERIFY_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '입주민 승인 중 오류가 발생했습니다.',
        errorCode: 'RESIDENT_VERIFY_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw ApiException(
        message: '입주민 승인 중 오류가 발생했습니다.',
        errorCode: 'RESIDENT_VERIFY_FAILED',
      );
    }
  }

  /// 입주민 거절 (삭제)
  /// DELETE /api/v1/managers/residents/{residentId}
  Future<Map<String, dynamic>> rejectResident({
    required String residentId,
  }) async {
    try {
      print('❌ 입주민 거절 요청 시작');
      print('   입주민 ID: $residentId');
      print('📤 API 호출: DELETE /api/v1/managers/residents/$residentId');

      final response = await _apiClient.delete('/managers/residents/$residentId');

      print('✅ 입주민 거절 성공');
      print('📦 응답 데이터: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('   상태 코드: ${e.response?.statusCode}');
      print('   응답 데이터: ${e.response?.data}');

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '입주민 거절에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'RESIDENT_REJECT_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '입주민 거절 중 오류가 발생했습니다.',
        errorCode: 'RESIDENT_REJECT_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw ApiException(
        message: '입주민 거절 중 오류가 발생했습니다.',
        errorCode: 'RESIDENT_REJECT_FAILED',
      );
    }
  }
}

// Riverpod Provider
final residentRemoteDataSourceProvider = Provider<ResidentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ResidentRemoteDataSource(apiClient);
});
