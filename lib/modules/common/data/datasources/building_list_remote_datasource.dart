import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

class BuildingListRemoteDataSource {
  final ApiClient _apiClient;

  BuildingListRemoteDataSource(this._apiClient);

  /// 건물 목록 조회
  /// GET /api/v1/common/buildings
  Future<Map<String, dynamic>> getBuildings({
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    String? keyword,
    String? status,
  }) async {
    try {
      print('🏢 건물 목록 조회 시작 - 페이지: $page, 키워드: ${keyword ?? "없음"}');

      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      print('📤 API 호출: GET /api/v1/common/buildings');

      final response = await _apiClient.get(
        '/common/buildings',
        queryParameters: queryParameters,
      );

      print('✅ 건물 목록 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final buildingListRemoteDataSourceProvider = Provider<BuildingListRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BuildingListRemoteDataSource(apiClient);
});