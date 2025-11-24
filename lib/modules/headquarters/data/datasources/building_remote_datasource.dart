import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
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
      print('🏢 건물 등록 시작 - 이름: $name, 주소: $address');

      if (imageUrl != null) {
        print('📷 이미지 URL: $imageUrl');
      }

      final requestData = {
        'name': name,
        'address': address,
        'imageUrl': imageUrl ?? '',
        if (memo != null && memo.isNotEmpty) 'memo': memo,
      };

      print('📤 API 호출: POST ${ApiEndpoints.buildings}');

      final response = await _apiClient.post(
        ApiEndpoints.buildings,
        data: requestData,
      );

      print('✅ 건물 등록 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('건물 등록 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('건물 등록 중 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> getBuildings({
    String? keyword,
    int? headquartersId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.buildings,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (headquartersId != null) 'headquartersId': headquartersId,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final buildingRemoteDataSourceProvider = Provider<BuildingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BuildingRemoteDataSource(apiClient);
});