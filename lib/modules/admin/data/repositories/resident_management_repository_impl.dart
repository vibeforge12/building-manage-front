import 'package:building_manage_front/modules/admin/domain/entities/resident_info.dart';
import 'package:building_manage_front/modules/admin/domain/repositories/resident_management_repository.dart';
import 'package:building_manage_front/modules/admin/data/datasources/resident_remote_datasource.dart';

/// 입주민 관리 Repository 구현
///
/// DataSource를 통해 API 호출 후 Entity로 변환
class ResidentManagementRepositoryImpl implements ResidentManagementRepository {
  final ResidentRemoteDataSource _dataSource;

  ResidentManagementRepositoryImpl(this._dataSource);

  @override
  Future<List<ResidentInfo>> getResidents({
    int page = 1,
    int limit = 20,
    String sortOrder = 'DESC',
    bool? isVerified,
    String? status,
    String? keyword,
  }) async {
    try {
      final response = await _dataSource.getResidents(
        page: page,
        limit: limit,
        sortOrder: sortOrder,
        isVerified: isVerified,
        status: status,
        keyword: keyword,
      );

      if (response['success'] != true) {
        throw Exception('입주민 목록 조회 실패');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('입주민 데이터가 없습니다.');
      }

      final List<dynamic> items = data['items'] as List<dynamic>? ?? [];

      return items
          .map((item) => ResidentInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ResidentInfo> verifyResident({required String residentId}) async {
    try {
      final response = await _dataSource.verifyResident(residentId: residentId);

      if (response['success'] != true) {
        throw Exception('입주민 승인 실패');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('입주민 정보가 반환되지 않았습니다.');
      }

      return ResidentInfo.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> rejectResident({required String residentId}) async {
    try {
      final response = await _dataSource.rejectResident(residentId: residentId);

      if (response['success'] != true) {
        throw Exception('입주민 거절 실패');
      }
    } catch (e) {
      rethrow;
    }
  }
}
