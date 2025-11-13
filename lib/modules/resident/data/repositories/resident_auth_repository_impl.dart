import 'package:building_manage_front/modules/resident/domain/repositories/resident_auth_repository.dart';
import 'package:building_manage_front/modules/resident/data/datasources/resident_auth_remote_datasource.dart';

/// ResidentAuthRepository 구현체
///
/// DataSource를 사용하여 실제 API 호출을 수행합니다.
class ResidentAuthRepositoryImpl implements ResidentAuthRepository {
  final ResidentAuthRemoteDataSource _dataSource;

  ResidentAuthRepositoryImpl(this._dataSource);

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _dataSource.login(
        username: username,
        password: password,
      );
      return result;
    } catch (e) {
      // DataSource에서 발생한 예외를 그대로 전파
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String buildingId,
    required String dong,
    required String ho,
    required String name,
    required String phoneNumber,
    required String username,
    required String password,
  }) async {
    try {
      final result = await _dataSource.register(
        buildingId: buildingId,
        dong: dong,
        hosu: ho,
        name: name,
        phoneNumber: phoneNumber,
        username: username,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
