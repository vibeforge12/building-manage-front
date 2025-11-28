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
      print('👥 관리자 목록 조회 시작 - 페이지: $page, 키워드: ${keyword ?? "없음"}');

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

      print('📤 API 호출: GET /api/v1/headquarters/managers');

      final response = await _apiClient.get(
        '/headquarters/managers',
        queryParameters: queryParameters,
      );

      print('✅ 관리자 목록 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('관리자 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('관리자 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 관리자 상세 조회
  /// GET /api/v1/headquarters/managers/{managerId}
  Future<Map<String, dynamic>> getManagerDetail(String managerId) async {
    try {
      print('👤 관리자 상세 조회 시작 - managerId: $managerId');
      print('📤 API 호출: GET /api/v1/headquarters/managers/$managerId');

      final response = await _apiClient.get(
        '/headquarters/managers/$managerId',
      );

      print('✅ 관리자 상세 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('관리자 상세 정보를 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
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
      print('✏️ 관리자 정보 수정 시작 - managerId: $managerId');

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (status != null) data['status'] = status;

      print('📤 API 호출: PATCH /api/v1/headquarters/managers/$managerId');
      print('📝 요청 데이터: $data');

      final response = await _apiClient.patch(
        '/headquarters/managers/$managerId',
        data: data,
      );

      print('✅ 관리자 수정 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('관리자 정보 수정 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('관리자 정보 수정 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final managerListRemoteDataSourceProvider = Provider<ManagerListRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ManagerListRemoteDataSource(apiClient);
});
