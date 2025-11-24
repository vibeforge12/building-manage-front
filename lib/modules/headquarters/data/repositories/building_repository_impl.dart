import 'package:building_manage_front/modules/headquarters/domain/entities/building.dart';
import 'package:building_manage_front/modules/headquarters/domain/repositories/building_repository.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/building_remote_datasource.dart';

/// 건물 Repository 구현
///
/// DataSource를 통해 API 호출 후 Entity로 변환
class BuildingRepositoryImpl implements BuildingRepository {
  final BuildingRemoteDataSource _dataSource;

  BuildingRepositoryImpl(this._dataSource);

  @override
  Future<Building> createBuilding({
    required String name,
    required String address,
    String? imageUrl,
    String? memo,
  }) async {
    try {
      final response = await _dataSource.createBuilding(
        name: name,
        address: address,
        imageUrl: imageUrl,
        memo: memo,
      );

      if (response['success'] != true) {
        throw Exception('건물 등록 실패');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('건물 정보가 반환되지 않았습니다.');
      }

      return Building.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Building>> getBuildings() async {
    // TODO: BuildingRemoteDataSource에 getBuildings 메서드 추가 필요
    throw UnimplementedError('getBuildings 메서드가 아직 구현되지 않았습니다.');
  }

  @override
  Future<Building> getBuildingDetail({required String buildingId}) async {
    // TODO: BuildingRemoteDataSource에 getBuildingDetail 메서드 추가 필요
    throw UnimplementedError('getBuildingDetail 메서드가 아직 구현되지 않았습니다.');
  }
}
