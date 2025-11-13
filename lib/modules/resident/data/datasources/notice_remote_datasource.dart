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
    try {
      final response = await _apiClient.get('/events/highlight');
      print('✅ 이벤트 API 응답: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ 이벤트 API 에러: $e');
      rethrow;
    }
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
  Future<Map<String, dynamic>> getNoticeDetail({required String noticeId}) async {
    final response = await _apiClient.get('/notices/$noticeId');
    return response.data;
  }

  /// 공지사항 상세 조회 (구 메서드)
  @deprecated
  Future<Map<String, dynamic>> getNoticeById(String id) async {
    final response = await _apiClient.get('/users/notices/$id');
    return response.data;
  }

  /// 이벤트 상세 조회
  Future<Map<String, dynamic>> getEventDetail({required String eventId}) async {
    final response = await _apiClient.get('/events/$eventId');
    return response.data;
  }
}
