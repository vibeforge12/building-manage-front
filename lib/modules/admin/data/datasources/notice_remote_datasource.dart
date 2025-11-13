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
  /// TODO: 서버에서 이벤트 조회 API 준비 중 - GET /api/v1/managers/events (예상)
  /// 현재는 사용하지 않음 (notice_management_screen.dart에서 더미 데이터 사용)
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

    // TODO: 서버 API 준비 완료 후 아래 엔드포인트로 변경
    // final response = await _apiClient.get(
    //   ApiEndpoints.managerEvents,
    //   queryParameters: queryParams,
    // );

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

  /// 공지사항 상세 조회
  /// GET /api/v1/notices/{noticeId}
  Future<Map<String, dynamic>> getNoticeDetail(String noticeId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.notices}/$noticeId',
    );
    return response.data;
  }

  /// 공지사항 수정
  /// PATCH /api/v1/managers/notices/{noticeId}
  Future<Map<String, dynamic>> updateNotice({
    required String noticeId,
    required String title,
    required String content,
    required String target,
    String? imageUrl,
    String? departmentId,
    String? status,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'target': target,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (departmentId != null) 'departmentId': departmentId,
      if (status != null) 'status': status,
    };

    final response = await _apiClient.patch(
      '${ApiEndpoints.managerNotices}/$noticeId',
      data: data,
    );
    return response.data;
  }

  /// 이벤트 상세 조회
  /// GET /api/v1/notices/{noticeId} (공지와 동일)
  Future<Map<String, dynamic>> getEventDetail(String eventId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.notices}/$eventId',
    );
    return response.data;
  }

  /// 이벤트 수정
  /// PATCH /api/v1/managers/events/{eventId}
  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required String content,
    required String target,
    String? imageUrl,
    String? departmentId,
    String? status,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'target': target,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (departmentId != null) 'departmentId': departmentId,
      if (status != null) 'status': status,
    };

    final response = await _apiClient.patch(
      '${ApiEndpoints.managerEvents}/$eventId',
      data: data,
    );
    return response.data;
  }

  /// 공지사항 삭제
  /// DELETE /api/v1/managers/notices/{noticeId}
  Future<Map<String, dynamic>> deleteNotice(String noticeId) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.managerNotices}/$noticeId',
    );
    return response.data;
  }

  /// 이벤트 삭제
  /// DELETE /api/v1/managers/events/{eventId}
  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.managerEvents}/$eventId',
    );
    return response.data;
  }
}
