import 'package:building_manage_front/modules/admin/domain/entities/resident_info.dart';

/// 입주민 관리 Repository 인터페이스
///
/// Admin 모듈에서 입주민 조회/승인/거절 작업을 위한 추상 계층
abstract class ResidentManagementRepository {
  /// 입주민 목록 조회
  ///
  /// [page] 페이지 번호 (기본값: 1)
  /// [limit] 페이지당 항목 수 (기본값: 20)
  /// [sortOrder] 정렬 순서 (기본값: 'DESC')
  /// [isVerified] 승인 여부 필터 (null이면 전체 조회)
  /// [status] 상태 필터 (null이면 전체 조회)
  /// [keyword] 검색 키워드 (null이면 검색 없음)
  ///
  /// Returns: ResidentInfo 엔티티 리스트
  /// Throws: Exception if fetch fails
  Future<List<ResidentInfo>> getResidents({
    int page = 1,
    int limit = 20,
    String sortOrder = 'DESC',
    bool? isVerified,
    String? status,
    String? keyword,
  });

  /// 입주민 승인
  ///
  /// [residentId] 입주민 ID
  ///
  /// Returns: 승인된 ResidentInfo 엔티티
  /// Throws: Exception if verification fails
  Future<ResidentInfo> verifyResident({required String residentId});

  /// 입주민 거절 (삭제)
  ///
  /// [residentId] 입주민 ID
  ///
  /// Throws: Exception if rejection fails
  Future<void> rejectResident({required String residentId});
}
