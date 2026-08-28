import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

final adminBulletinRemoteDataSourceProvider =
    Provider<AdminBulletinRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AdminBulletinRemoteDataSource(apiClient);
});

/// 공고문 등록·수정·삭제.
///
/// 본사·관리자·담당자가 같은 엔드포인트를 쓴다. 서버가 토큰의 역할을 보고
/// 게시 대상 건물과 권한을 정하므로, 앱은 역할별로 다른 경로를 호출하지 않는다.
/// (공지사항이 /managers/notices 처럼 역할별로 갈린 것과 다르다)
class AdminBulletinRemoteDataSource {
  final ApiClient _apiClient;

  AdminBulletinRemoteDataSource(this._apiClient);

  /// 관리용 목록. [includeInactive] 를 켜면 숨김·기간만료 공고문까지 받는다.
  Future<Map<String, dynamic>> getBulletins({
    int page = 1,
    int limit = 100,
    String? buildingId,
    String? keyword,
    bool includeInactive = true,
    String sortOrder = 'DESC',
  }) async {
    final response = await _apiClient.get(
      '/bulletins',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortOrder': sortOrder,
        if (buildingId != null) 'buildingId': buildingId,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (includeInactive) 'includeInactive': true,
      },
    );
    return response.data;
  }

  /// 공고문을 올릴 수 있는 건물 목록.
  ///
  /// /common/buildings 를 쓰지 않는다. 그것은 회원가입(로그인 전)에서 호출하려고
  /// 공개해 둔 엔드포인트라 토큰이 없고, 따라서 본사별로 좁혀지지 않는다.
  /// 실제로 본사A 의 건물 선택기에 다른 본사의 건물이 그대로 보였다.
  Future<Map<String, dynamic>> getTargetBuildings() async {
    final response = await _apiClient.get('/bulletins/target-buildings');
    return response.data;
  }

  Future<Map<String, dynamic>> getBulletinDetail(String bulletinId) async {
    final response = await _apiClient.get('/bulletins/$bulletinId');
    return response.data;
  }

  /// 공고문 등록.
  ///
  /// [buildingIds] 는 본사만 보낸다. 관리자·담당자가 보내면 서버가 400 을 준다
  /// (조용히 무시하면 등록자가 엉뚱한 건물에 올라간 것을 알 수 없다).
  Future<Map<String, dynamic>> createBulletin({
    required String title,
    String? content,
    List<String>? imageUrls,
    List<String>? buildingIds,
    String? postedFrom,
    String? postedUntil,
    bool sendPush = false,
  }) async {
    final response = await _apiClient.post(
      '/bulletins',
      data: {
        'title': title,
        if (content != null && content.trim().isNotEmpty) 'content': content,
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        if (buildingIds != null && buildingIds.isNotEmpty)
          'buildingIds': buildingIds,
        if (postedFrom != null) 'postedFrom': postedFrom,
        if (postedUntil != null) 'postedUntil': postedUntil,
        'sendPush': sendPush,
      },
    );
    return response.data;
  }

  /// 공고문 수정.
  ///
  /// 건물 변경과 푸시 재발송은 서버가 지원하지 않는다.
  /// 게시 기간을 "제한 없음" 으로 되돌리려면 null 을 명시적으로 보내야 한다.
  /// 필드를 아예 빼면 기존 값이 유지된다.
  Future<Map<String, dynamic>> updateBulletin({
    required String bulletinId,
    String? title,
    String? content,
    List<String>? imageUrls,
    required bool clearPostedFrom,
    String? postedFrom,
    required bool clearPostedUntil,
    String? postedUntil,
    String? status,
  }) async {
    final response = await _apiClient.patch(
      '/bulletins/$bulletinId',
      data: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (clearPostedFrom) 'postedFrom': null,
        if (!clearPostedFrom && postedFrom != null) 'postedFrom': postedFrom,
        if (clearPostedUntil) 'postedUntil': null,
        if (!clearPostedUntil && postedUntil != null) 'postedUntil': postedUntil,
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteBulletin(String bulletinId) async {
    final response = await _apiClient.delete('/bulletins/$bulletinId');
    return response.data;
  }
}
