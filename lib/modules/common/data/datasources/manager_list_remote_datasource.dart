import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

class ManagerListRemoteDataSource {
  final ApiClient _apiClient;

  ManagerListRemoteDataSource(this._apiClient);

  /// 관리자 목록 조회
  /// GET /api/v1/headquarters/managers
  Future<Map<String, dynamic>> getManagers({
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    String? status,
    String? buildingId,
    String? keyword,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      if (buildingId != null && buildingId.isNotEmpty) {
        queryParameters['buildingId'] = buildingId;
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }

      final response = await _apiClient.get(
        '/headquarters/managers',
        queryParameters: queryParameters,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('관리자 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('관리자 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 관리자 상세 조회
  /// GET /api/v1/headquarters/managers/{managerId}
  Future<Map<String, dynamic>> getManagerDetail(String managerId) async {
    try {
      final response = await _apiClient.get(
        '/headquarters/managers/$managerId',
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('관리자 상세 정보를 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('관리자 상세 정보를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 관리자 정보 수정
  /// PATCH /api/v1/headquarters/managers/{managerId}
  Future<Map<String, dynamic>> updateManager({
    required String managerId,
    String? name,
    String? phoneNumber,
    String? imageUrl,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (status != null) data['status'] = status;

      final response = await _apiClient.patch(
        '/headquarters/managers/$managerId',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('관리자 정보 수정 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('관리자 정보 수정 중 오류가 발생했습니다: $e');
    }
  }

  /// 관리자 삭제 (Soft Delete)
  /// DELETE /api/v1/headquarters/managers/{managerId}
  /// 관리자 상태를 DELETED로 변경합니다.
  Future<Map<String, dynamic>> deleteManager(String managerId) async {
    try {
      final response = await _apiClient.delete(
        '/headquarters/managers/$managerId',
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('관리자 삭제 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('관리자 삭제 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final managerListRemoteDataSourceProvider = Provider<ManagerListRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ManagerListRemoteDataSource(apiClient);
});
