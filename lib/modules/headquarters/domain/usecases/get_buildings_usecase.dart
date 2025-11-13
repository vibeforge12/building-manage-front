import 'package:building_manage_front/modules/headquarters/domain/repositories/building_repository.dart';
import 'package:building_manage_front/modules/headquarters/domain/entities/building.dart';

/// 건물 목록 조회 UseCase
///
/// 비즈니스 로직:
/// 1. Repository를 통한 건물 목록 조회
/// 2. Building 엔티티 리스트 반환
class GetBuildingsUseCase {
  final BuildingRepository _repository;

  GetBuildingsUseCase(this._repository);

  /// 건물 목록 조회 실행
  ///
  /// Returns: Building 엔티티 리스트
  /// Throws: Exception if fetch fails
  Future<List<Building>> execute() async {
    try {
      final buildings = await _repository.getBuildings();
      return buildings;
    } catch (e) {
      rethrow;
    }
  }
}
