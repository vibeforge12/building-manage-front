import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

class BuildingRemoteDataSource {
  final ApiClient _apiClient;

  BuildingRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> createBuilding({
    required String name,
    required String address,
    String? imageUrl,
    String? memo,
  }) async {
    try {

      if (imageUrl != null) {
      }

      final requestData = {
        'name': name,
        'address': address,
        'imageUrl': imageUrl ?? '',
        if (memo != null && memo.isNotEmpty) 'memo': memo,
      };

      final response = await _apiClient.post(
        ApiEndpoints.headquartersBuildings,
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception('건물 등록 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물 등록 중 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> getBuildings({
    String? keyword,
    int? headquartersId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.commonBuildings,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (headquartersId != null) 'headquartersId': headquartersId,
        },
      );

      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> updateBuilding({
    required String buildingId,
    required String name,
    required String address,
    String? imageUrl,
    String? memo,
  }) async {
    try {

      final requestData = {
        'name': name,
        'address': address,
        'imageUrl': imageUrl ?? '',
        if (memo != null && memo.isNotEmpty) 'memo': memo,
      };

      final response = await _apiClient.patch(
        '${ApiEndpoints.headquartersBuildings}/$buildingId',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception('건물 수정 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물 수정 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final buildingRemoteDataSourceProvider = Provider<BuildingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BuildingRemoteDataSource(apiClient);
});