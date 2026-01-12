import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffRemoteDataSource {
  final ApiClient _apiClient;

  StaffRemoteDataSource(this._apiClient);

  /// 담당자 목록 조회
  /// GET /api/v1/managers/staffs
  Future<Map<String, dynamic>> getStaffs() async {
    try {

      final response = await _apiClient.get('/managers/staffs');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('담당자 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('담당자 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 담당자 계정 발급
  /// POST /api/v1/managers/staffs
  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String phoneNumber,
    required String departmentId,
    String? imageUrl,
  }) async {
    try {

      final data = {
        'name': name,
        'phoneNumber': phoneNumber,
        'departmentId': departmentId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      final response = await _apiClient.post(
        '/managers/staffs',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '담당자 계정 발급에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'STAFF_CREATE_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '담당자 계정 발급 중 오류가 발생했습니다.',
        errorCode: 'STAFF_CREATE_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(
        message: '담당자 계정 발급 중 오류가 발생했습니다.',
        errorCode: 'STAFF_CREATE_FAILED',
      );
    }
  }

  /// 담당자 상세 조회
  /// GET /api/v1/managers/staffs/{staffId}
  Future<Map<String, dynamic>> getStaffDetail({
    required String staffId,
  }) async {
    try {

      final response = await _apiClient.get('/managers/staffs/$staffId');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('담당자 상세 정보를 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('담당자 상세 정보를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 담당자 정보 수정
  /// PATCH /api/v1/managers/staffs/{staffId}
  Future<Map<String, dynamic>> updateStaff({
    required String staffId,
    required String name,
    required String phoneNumber,
    String? imageUrl,
    required String departmentId,
    required String status,
    String? password,
  }) async {
    try {

      final data = {
        'name': name,
        'phoneNumber': phoneNumber,
        'departmentId': departmentId,
        'status': status,
      };

      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }

      final response = await _apiClient.patch(
        '/managers/staffs/$staffId',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '담당자 정보 수정에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'STAFF_UPDATE_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '담당자 정보 수정 중 오류가 발생했습니다.',
        errorCode: 'STAFF_UPDATE_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(
        message: '담당자 정보 수정 중 오류가 발생했습니다.',
        errorCode: 'STAFF_UPDATE_FAILED',
      );
    }
  }

  /// 담당자 삭제
  /// DELETE /api/v1/managers/staffs/{staffId}
  Future<Map<String, dynamic>> deleteStaff({
    required String staffId,
  }) async {
    try {

      final response = await _apiClient.delete('/managers/staffs/$staffId');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {

      if (e.response?.data != null && e.response!.data is Map) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] ?? '담당자 삭제에 실패했습니다.',
          errorCode: errorData['errorCode'] ?? 'STAFF_DELETE_FAILED',
          statusCode: e.response?.statusCode,
        );
      }

      throw ApiException(
        message: '담당자 삭제 중 오류가 발생했습니다.',
        errorCode: 'STAFF_DELETE_FAILED',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(
        message: '담당자 삭제 중 오류가 발생했습니다.',
        errorCode: 'STAFF_DELETE_FAILED',
      );
    }
  }
}

// Riverpod Provider
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StaffRemoteDataSource(apiClient);
});
