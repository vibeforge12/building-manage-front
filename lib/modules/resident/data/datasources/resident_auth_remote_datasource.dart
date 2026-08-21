import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ResidentAuthRemoteDataSource {
  final ApiClient _apiClient;

  ResidentAuthRemoteDataSource(this._apiClient);

  /// 입주민 로그인
  /// POST /api/v1/auth/resident/login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {

      final requestData = {
        'username': username,
        'password': password,
      };

      final response = await _apiClient.post(
        '/auth/resident/login',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {

      if (e.statusCode == 401) {
        final data = e.responseData;
        final message = (data is Map) ? data['message'] as String? : null;
        throw Exception(message ?? '아이디 또는 비밀번호가 일치하지 않습니다.');
      }

      throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('로그인 중 오류가 발생했습니다: $e');
    }
  }

  /// 입주민 회원가입
  /// POST /api/v1/auth/resident/register
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String name,
    required String phoneNumber,
    required String dong,
    required String hosu,
    required String buildingId,
  }) async {
    try {

      final requestData = {
        'username': username,
        'password': password,
        'name': name,
        'phoneNumber': phoneNumber,
        'dong': dong,
        'hosu': hosu,
        'buildingId': buildingId,
      };

      final response = await _apiClient.post(
        '/auth/resident/register',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {

      // 409: 아이디 또는 전화번호 중복 → 서버 안내 메시지를 그대로 노출
      if (e.statusCode == 409) {
        final serverMessage = (e.responseData is Map)
            ? (e.responseData as Map)['message'] as String?
            : null;
        throw Exception(serverMessage ?? '이미 가입된 정보입니다.');
      }

      throw Exception('회원가입 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  /// 입주민 비밀번호 변경
  /// POST /api/v1/auth/resident/change-password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {

      final requestData = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final response = await _apiClient.post(
        '/auth/resident/change-password',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {

      if (e.statusCode == 401 || e.statusCode == 400) {
        throw Exception('CURRENT_PASSWORD_WRONG');
      }

      throw Exception('비밀번호 변경 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('비밀번호 변경 중 오류가 발생했습니다: $e');
    }
  }

  /// 비밀번호 재설정 인증번호 요청
  /// POST /api/v1/auth/password-reset/request
  Future<Map<String, dynamic>> requestPasswordReset({
    required String username,
    required String phoneNumber,
  }) async {
    try {

      final requestData = {
        'username': username,
        'phoneNumber': phoneNumber,
      };

      final response = await _apiClient.post(
        '/auth/password-reset/request',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {

      if (e.statusCode == 404) {
        throw Exception('USER_NOT_FOUND');
      }
      if (e.statusCode == 400) {
        throw Exception('INVALID_REQUEST');
      }

      throw Exception('인증번호 요청 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('인증번호 요청 중 오류가 발생했습니다: $e');
    }
  }

  /// 비밀번호 재설정 인증번호 확인
  /// POST /api/v1/auth/password-reset/verify
  Future<Map<String, dynamic>> verifyPasswordReset({
    required String phoneNumber,
    required String code,
  }) async {
    try {

      final requestData = {
        'phoneNumber': phoneNumber,
        'code': code,
      };

      final response = await _apiClient.post(
        '/auth/password-reset/verify',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {

      if (e.statusCode == 400) {
        throw Exception('INVALID_CODE');
      }

      throw Exception('인증번호 확인 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('인증번호 확인 중 오류가 발생했습니다: $e');
    }
  }

  /// 비밀번호 재설정
  /// POST /api/v1/auth/password-reset/reset
  Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    try {

      final requestData = {
        'phoneNumber': phoneNumber,
        'code': code,
        'newPassword': newPassword,
      };

      final response = await _apiClient.post(
        '/auth/password-reset/reset',
        data: requestData,
      );
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {

      throw Exception('비밀번호 재설정 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('비밀번호 재설정 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final residentAuthRemoteDataSourceProvider = Provider<ResidentAuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ResidentAuthRemoteDataSource(apiClient);
});