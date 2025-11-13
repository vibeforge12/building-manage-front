import 'package:building_manage_front/modules/admin/domain/repositories/resident_management_repository.dart';
import 'package:building_manage_front/modules/admin/domain/entities/resident_info.dart';

/// 입주민 목록 조회 UseCase
///
/// 비즈니스 로직:
/// 1. Repository를 통한 입주민 목록 조회
/// 2. ResidentInfo 엔티티 리스트 반환
class GetResidentsUseCase {
  final ResidentManagementRepository _repository;

  GetResidentsUseCase(this._repository);

  /// 입주민 목록 조회 실행
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
  Future<List<ResidentInfo>> execute({
    int page = 1,
    int limit = 20,
    String sortOrder = 'DESC',
    bool? isVerified,
    String? status,
    String? keyword,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (page < 1) {
      throw Exception('페이지 번호는 1 이상이어야 합니다.');
    }

    if (limit < 1 || limit > 100) {
      throw Exception('페이지당 항목 수는 1~100 사이여야 합니다.');
    }

    try {
      final residents = await _repository.getResidents(
        page: page,
        limit: limit,
        sortOrder: sortOrder,
        isVerified: isVerified,
        status: status,
        keyword: keyword,
      );

      return residents;
    } catch (e) {
      rethrow;
    }
  }
}
