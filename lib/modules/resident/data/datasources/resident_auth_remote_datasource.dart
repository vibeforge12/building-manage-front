import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

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
      print('🔐 입주민 로그인 시작');
      print('📤 요청 데이터: {username: $username}');

      final requestData = {
        'username': username,
        'password': password,
      };

      print('📤 API 호출: POST /api/v1/auth/resident/login');

      final response = await _apiClient.post(
        '/auth/resident/login',
        data: requestData,
      );

      print('✅ 로그인 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        throw Exception('아이디 또는 비밀번호가 일치하지 않습니다.');
      }

      throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
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
      print('🔐 입주민 회원가입 시작');
      print('📤 요청 데이터: {username: $username, name: $name, phoneNumber: $phoneNumber, dong: $dong, hosu: $hosu, buildingId: $buildingId}');

      final requestData = {
        'username': username,
        'password': password,
        'name': name,
        'phoneNumber': phoneNumber,
        'dong': dong,
        'hosu': hosu,
        'buildingId': buildingId,
      };

      print('📤 API 호출: POST /api/v1/auth/resident/register');

      final response = await _apiClient.post(
        '/auth/resident/register',
        data: requestData,
      );

      print('✅ 회원가입 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');

      if (e.response?.statusCode == 409) {
        throw Exception('이미 존재하는 아이디입니다.');
      }

      throw Exception('회원가입 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('회원가입 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final residentAuthRemoteDataSourceProvider = Provider<ResidentAuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ResidentAuthRemoteDataSource(apiClient);
});