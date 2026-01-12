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

      final requestData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'buildingId': buildingId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      final response = await _apiClient.post(
        '/headquarters/managers',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {

      if (e.response?.statusCode == 400) {
        throw Exception('잘못된 요청입니다. 입력값을 확인해주세요.');
      }

      if (e.response?.statusCode == 409) {
        throw Exception('이미 존재하는 관리자입니다.');
      }

      throw Exception('관리자 계정 발급 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('관리자 계정 발급 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final adminAccountRemoteDataSourceProvider = Provider<AdminAccountRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminAccountRemoteDataSource(apiClient);
});
