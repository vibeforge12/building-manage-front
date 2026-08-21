import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

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

      final response = await _apiClient.get(
        ApiEndpoints.commonBuildings,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 건물 삭제
  /// DELETE /api/v1/headquarters/buildings/{buildingId}
  Future<Map<String, dynamic>> deleteBuilding(String buildingId) async {
    try {
      final endpoint = '${ApiEndpoints.headquartersBuildings}/$buildingId';

      final response = await _apiClient.delete(endpoint);
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception('건물을 삭제하는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물을 삭제하는 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final buildingListRemoteDataSourceProvider = Provider<BuildingListRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BuildingListRemoteDataSource(apiClient);
});