import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

final bulletinRemoteDataSourceProvider = Provider<BulletinRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return BulletinRemoteDataSource(apiClient);
});

/// 공고문 조회.
///
/// 공지사항이 역할별로 엔드포인트가 갈린 것(/users/notices, /staffs/notices, /notices)과 달리
/// 공고문은 `/bulletins` 하나다. 서버가 토큰의 역할을 보고 범위를 정하고, 수정 권한도
/// canManage 로 내려준다.
class BulletinRemoteDataSource {
  final ApiClient _apiClient;

  BulletinRemoteDataSource(this._apiClient);

  /// 공고문 목록.
  ///
  /// [includeInactive] 는 관리 화면 전용이다. 숨김·기간만료 공고문까지 받아온다.
  /// 입주민이 보내도 서버가 무시하므로 안전하다.
  Future<Map<String, dynamic>> getBulletins({
    int page = 1,
    int limit = 20,
    String? buildingId,
    String? keyword,
    bool includeInactive = false,
  }) async {
    final response = await _apiClient.get(
      '/bulletins',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (buildingId != null) 'buildingId': buildingId,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (includeInactive) 'includeInactive': true,
      },
    );
    return response.data;
  }

  /// 공고문 상세.
  Future<Map<String, dynamic>> getBulletinDetail({
    required String bulletinId,
  }) async {
    final response = await _apiClient.get('/bulletins/$bulletinId');
    return response.data;
  }
}
