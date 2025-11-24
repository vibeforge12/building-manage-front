import 'package:building_manage_front/modules/headquarters/domain/repositories/building_repository.dart';
import 'package:building_manage_front/modules/headquarters/domain/entities/building.dart';

/// 건물 등록 UseCase
///
/// 비즈니스 로직:
/// 1. 입력값 유효성 검증
/// 2. Repository를 통한 건물 등록
/// 3. Building 엔티티 반환
class CreateBuildingUseCase {
  final BuildingRepository _repository;

  CreateBuildingUseCase(this._repository);

  /// 건물 등록 실행
  ///
  /// [name] 건물 이름
  /// [address] 건물 주소
  /// [imageUrl] 건물 이미지 URL (S3에 업로드된 URL, 선택)
  /// [memo] 메모 (선택)
  ///
  /// Returns: 생성된 Building 엔티티
  /// Throws: Exception if validation or creation fails
  Future<Building> execute({
    required String name,
    required String address,
    String? imageUrl,
    String? memo,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (name.trim().isEmpty) {
      throw Exception('건물 이름을 입력해주세요.');
    }

    if (address.trim().isEmpty) {
      throw Exception('건물 주소를 입력해주세요.');
    }

    try {
      final building = await _repository.createBuilding(
        name: name.trim(),
        address: address.trim(),
        imageUrl: imageUrl,
        memo: memo?.trim(),
      );
      return building;
    } catch (e) {
      rethrow;
    }
  }
}
