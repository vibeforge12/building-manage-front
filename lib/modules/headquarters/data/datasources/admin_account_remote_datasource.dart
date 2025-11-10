import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

class AdminAccountRemoteDataSource {
  final ApiClient _apiClient;

  AdminAccountRemoteDataSource(this._apiClient);

  /// 관리자 계정 발급
  /// POST /api/v1/headquarters/managers
  Future<Map<String, dynamic>> createAdminAccount({
    required String name,
    required String phoneNumber,
    required String buildingId,
    String? imageUrl,
  }) async {
    try {
      print('🔐 관리자 계정 발급 시작');
      print('📤 요청 데이터: {name: $name, phoneNumber: $phoneNumber, buildingId: $buildingId}');

      final requestData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'buildingId': buildingId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      print('📤 API 호출: POST /api/v1/headquarters/managers');

      final response = await _apiClient.post(
        '/headquarters/managers',
        data: requestData,
      );

      print('✅ 관리자 계정 발급 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');

      if (e.response?.statusCode == 400) {
        throw Exception('잘못된 요청입니다. 입력값을 확인해주세요.');
      }

      if (e.response?.statusCode == 409) {
        throw Exception('이미 존재하는 관리자입니다.');
      }

      throw Exception('관리자 계정 발급 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('관리자 계정 발급 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final adminAccountRemoteDataSourceProvider = Provider<AdminAccountRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminAccountRemoteDataSource(apiClient);
});
