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

      final response = await _apiClient.get(
        '/managers/residents',
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('입주민 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('입주민 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 입주민 승인
  /// POST /api/v1/managers/residents/{residentId}/approve
  Future<Map<String, dynamic>> verifyResident({
    required String residentId,
  }) async {
    try {

      final response = await _apiClient.post('/managers/residents/$residentId/approve');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {

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
      print('🔴 ResidentRemoteDataSource.rejectResident 호출됨');
      print('📋 residentId: $residentId');
      print('📤 DELETE /managers/residents/$residentId 호출...');

      final response = await _apiClient.delete('/managers/residents/$residentId');
      print('📥 응답 받음: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {

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
