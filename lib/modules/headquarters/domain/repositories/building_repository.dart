import 'package:building_manage_front/modules/headquarters/domain/entities/building.dart';

/// 건물 관리 Repository 인터페이스
///
/// Headquarters 모듈에서 건물 CRUD 작업을 위한 추상 계층
abstract class BuildingRepository {
  /// 건물 등록
  ///
  /// [name] 건물 이름
  /// [address] 건물 주소
  /// [imageUrl] 건물 이미지 URL (S3에 업로드된 URL, 선택)
  /// [memo] 메모 (선택)
  ///
  /// Returns: 생성된 Building 엔티티
  /// Throws: Exception if creation fails
  Future<Building> createBuilding({
    required String name,
    required String address,
    String? imageUrl,
    String? memo,
  });

  /// 건물 목록 조회
  ///
  /// Returns: Building 엔티티 리스트
  /// Throws: Exception if fetch fails
  Future<List<Building>> getBuildings();

  /// 건물 상세 조회
  ///
  /// [buildingId] 건물 ID
  ///
  /// Returns: Building 엔티티
  /// Throws: Exception if not found or fetch fails
  Future<Building> getBuildingDetail({required String buildingId});
}
