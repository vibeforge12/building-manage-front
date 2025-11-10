import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffRemoteDataSource {
  final ApiClient _apiClient;

  StaffRemoteDataSource(this._apiClient);

  /// 담당자 계정 발급
  /// POST /api/v1/managers/staffs
  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String phoneNumber,
    required String departmentId,
    String? imageUrl,
  }) async {
    try {
      print('📤 담당자 계정 발급 요청 시작');
      print('   이름: $name');
      print('   전화번호: $phoneNumber');
      print('   부서 ID: $departmentId');
      print('   이미지 URL: ${imageUrl ?? "(없음)"}');

      final data = {
        'name': name,
        'phoneNumber': phoneNumber,
        'departmentId': departmentId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      print('📋 요청 데이터: $data');

      final response = await _apiClient.post(
        '/managers/staffs',
        data: data,
      );

      print('✅ 담당자 계정 발급 성공');
      print('📦 응답 데이터: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('   상태 코드: ${e.response?.statusCode}');
      print('   응답 데이터: ${e.response?.data}');

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '담당자 계정 발급에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'STAFF_CREATE_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '담당자 계정 발급 중 오류가 발생했습니다.',
        errorCode: 'STAFF_CREATE_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw ApiException(
        message: '담당자 계정 발급 중 오류가 발생했습니다.',
        errorCode: 'STAFF_CREATE_FAILED',
      );
    }
  }
}

// Riverpod Provider
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StaffRemoteDataSource(apiClient);
});
