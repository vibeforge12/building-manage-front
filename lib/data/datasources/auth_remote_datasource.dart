import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// 입주민 회원가입
  /// POST /api/v1/auth/resident/register
  Future<Map<String, dynamic>> registerResident({
    required String username,
    required String password,
    required String name,
    required String phoneNumber,
    required String dong,
    required String hosu,
    required String buildingId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.residentRegister,
        data: {
          'username': username,
          'password': password,
          'name': name,
          'phoneNumber': phoneNumber,
          'dong': dong,
          'hosu': hosu,
          'buildingId': buildingId,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '입주민 회원가입 중 오류가 발생했습니다.',
        errorCode: 'RESIDENT_REGISTER_FAILED',
      );
    }
  }

  /// 관리자 회원가입
  /// POST /api/v1/auth/manager/register
  Future<Map<String, dynamic>> registerManager({
    required String managerCode,
    required String name,
    required String phoneNumber,
    required String buildingId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.managerRegister,
        data: {
          'managerCode': managerCode,
          'name': name,
          'phoneNumber': phoneNumber,
          'buildingId': buildingId,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '관리자 회원가입 중 오류가 발생했습니다.',
        errorCode: 'MANAGER_REGISTER_FAILED',
      );
    }
  }

  /// 입주민 로그인 (동/호수 기반에서 username 기반으로 변경될 가능성 고려)
  /// POST /api/v1/auth/resident/login
  Future<Map<String, dynamic>> loginResident({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.residentLogin,
        data: {
          'username': username,
          'password': password,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '입주민 로그인 중 오류가 발생했습니다.',
        errorCode: 'RESIDENT_LOGIN_FAILED',
      );
    }
  }

  /// 관리자 로그인 (비밀번호 없음, managerCode만 사용)
  /// POST /api/v1/auth/manager/login
  Future<Map<String, dynamic>> loginManager({
    required String managerCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.managerLogin,
        data: {
          'managerCode': managerCode,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '관리자 코드가 일치하지 않습니다.',
        errorCode: 'MANAGER_LOGIN_FAILED',
      );
    }
  }

  /// 담당자 로그인 (staffCode)
  /// POST /api/v1/auth/staff/login
  Future<Map<String, dynamic>> loginStaff({
    required String staffCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.staffLogin,
        data: {
          'staffCode': staffCode,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '담당자 로그인 중 오류가 발생했습니다.',
        errorCode: 'STAFF_LOGIN_FAILED',
      );
    }
  }

  /// 본사 로그인
  /// POST /api/v1/auth/headquarters/login
  Future<Map<String, dynamic>> loginHeadquarters({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.headquartersLogin,
        data: {
          'username': username,
          'password': password,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '아이디 또는 비밀번호가 일치하지 않습니다.',
        errorCode: 'HEADQUARTERS_LOGIN_FAILED',
      );
    }
  }

  /// 토큰 갱신
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '토큰 갱신 중 오류가 발생했습니다.',
        errorCode: 'TOKEN_REFRESH_FAILED',
      );
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // 로그아웃은 실패해도 로컬에서 토큰을 제거하면 됨
      print('Logout API failed: $e');
    }
  }
}

// Riverpod Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient);
});
