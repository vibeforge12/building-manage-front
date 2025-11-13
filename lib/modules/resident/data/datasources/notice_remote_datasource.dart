import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

final noticeRemoteDataSourceProvider = Provider<NoticeRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return NoticeRemoteDataSource(apiClient);
});

class NoticeRemoteDataSource {
  final ApiClient _apiClient;

  NoticeRemoteDataSource(this._apiClient);

  /// 공지사항 하이라이트 조회
  Future<Map<String, dynamic>> getNoticeHighlights() async {
    final response = await _apiClient.get('/users/notices/highlight');
    return response.data;
  }

  /// 이벤트 하이라이트 조회
  Future<Map<String, dynamic>> getEventHighlights() async {
    final response = await _apiClient.get('/users/events/highlight');
    return response.data;
  }

  /// 공지사항 목록 조회
  Future<Map<String, dynamic>> getNotices() async {
    final response = await _apiClient.get('/users/notices');
    return response.data;
  }

  /// 이벤트 목록 조회
  Future<Map<String, dynamic>> getEvents() async {
    final response = await _apiClient.get('/users/events');
    return response.data;
  }

  /// 공지사항 상세 조회
  Future<Map<String, dynamic>> getNoticeById(String id) async {
    final response = await _apiClient.get('/users/notices/$id');
    return response.data;
  }
}
