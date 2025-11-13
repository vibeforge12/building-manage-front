import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

final noticeRemoteDataSourceProvider = Provider<NoticeRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return NoticeRemoteDataSource(apiClient);
});

class NoticeRemoteDataSource {
  final ApiClient _apiClient;

  NoticeRemoteDataSource(this._apiClient);

  /// 공지사항 목록 조회 (관리자)
  /// GET /api/v1/notices
  /// Parameters: page, limit, sortBy, sortOrder, departmentId, keyword
  Future<Map<String, dynamic>> getNotices({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String sortOrder = 'DESC',
    String? departmentId,
    String? keyword,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
    };
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (departmentId != null) queryParams['departmentId'] = departmentId;
    if (keyword != null) queryParams['keyword'] = keyword;

    final response = await _apiClient.get(
      ApiEndpoints.notices,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// 공지사항 생성 (관리자)
  /// POST /api/v1/managers/notices
  Future<Map<String, dynamic>> createNotice({
    required String title,
    required String content,
    required String target, // BOTH, RESIDENT, STAFF
    String? departmentId,
    String? imageUrl,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'target': target,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (departmentId != null) 'departmentId': departmentId,
    };

    final response = await _apiClient.post(
      ApiEndpoints.managerNotices,
      data: data,
    );
    return response.data;
  }

  /// 이벤트 목록 조회 (관리자)
  /// GET /api/v1/notices (공지사항과 동일한 API, target으로 구분)
  /// Parameters: page, limit, sortBy, sortOrder, departmentId, keyword
  Future<Map<String, dynamic>> getEvents({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String sortOrder = 'DESC',
    String? departmentId,
    String? keyword,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
    };
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (departmentId != null) queryParams['departmentId'] = departmentId;
    if (keyword != null) queryParams['keyword'] = keyword;

    final response = await _apiClient.get(
      ApiEndpoints.notices,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// 이벤트 생성 (관리자)
  /// POST /api/v1/managers/events
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String content,
    required String target, // BOTH, RESIDENT, STAFF
    String? departmentId,
    String? imageUrl,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'target': target,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (departmentId != null) 'departmentId': departmentId,
    };

    final response = await _apiClient.post(
      ApiEndpoints.managerEvents,
      data: data,
    );
    return response.data;
  }
}
