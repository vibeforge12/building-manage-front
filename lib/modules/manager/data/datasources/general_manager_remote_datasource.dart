import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

/// 총관리자(HEAD)가 자신의 건물에 일반관리자(GENERAL)를 추가하는 데이터소스.
class GeneralManagerRemoteDataSource {
  final ApiClient _apiClient;

  GeneralManagerRemoteDataSource(this._apiClient);

  /// 일반관리자 추가
  /// POST /api/v1/managers/general-managers
  Future<Map<String, dynamic>> createGeneralManager({
    required String name,
    required String phoneNumber,
    String? imageUrl,
  }) async {
    try {
      final requestData = {
        'name': name,
        'phoneNumber': phoneNumber,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      final response = await _apiClient.post(
        '/managers/general-managers',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('잘못된 요청입니다. 입력값을 확인해주세요.');
      }
      // 403: 총관리자만 일반관리자를 추가할 수 있음
      if (e.response?.statusCode == 403) {
        throw Exception('총관리자만 일반관리자를 추가할 수 있습니다.');
      }
      // 409: 전화번호 중복 등 → 서버 메시지 노출
      if (e.response?.statusCode == 409) {
        final serverMessage = (e.response?.data is Map)
            ? (e.response?.data as Map)['message'] as String?
            : null;
        throw Exception(serverMessage ?? '이미 등록된 전화번호의 관리자가 있습니다.');
      }
      throw Exception('일반관리자 추가 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('일반관리자 추가 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final generalManagerRemoteDataSourceProvider =
    Provider<GeneralManagerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeneralManagerRemoteDataSource(apiClient);
});
