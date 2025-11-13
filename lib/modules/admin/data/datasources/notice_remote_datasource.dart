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
  /// GET /api/v1/events
  /// 역할과 소속 건물에 따라 접근 가능한 이벤트를 페이지네이션하여 조회
  /// Parameters: page, limit, sortBy, sortOrder, target, keyword
  Future<Map<String, dynamic>> getEvents({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String sortOrder = 'DESC',
    String? target,
    String? keyword,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
    };
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (target != null) queryParams['target'] = target;
    if (keyword != null) queryParams['keyword'] = keyword;

    final response = await _apiClient.get(
      ApiEndpoints.events,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// 이벤트 생성 (관리자)
  /// POST /api/v1/managers/events
  /// 이벤트는 모든 사용자를 대상으로 하므로 target과 departmentId 불필요
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    final data = {
      'title': title,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
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
      'imageUrl': imageUrl, // null값도 포함하여 기존 이미지 삭제 지원
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
  /// GET /api/v1/events/{eventId}
  Future<Map<String, dynamic>> getEventDetail(String eventId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.events}/$eventId',
    );
    return response.data;
  }

  /// 이벤트 수정
  /// PATCH /api/v1/managers/events/{eventId}
  /// 이벤트는 모든 사용자를 대상으로 하므로 target과 departmentId 불필요
  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required String content,
    String? imageUrl,
    String? status,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'imageUrl': imageUrl, // null값도 포함하여 기존 이미지 삭제 지원
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
