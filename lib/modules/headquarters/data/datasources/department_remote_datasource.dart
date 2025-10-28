import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class DepartmentRemoteDataSource {
  final ApiClient _apiClient;

  DepartmentRemoteDataSource(this._apiClient);

  /// 부서 목록 조회
  /// GET /api/v1/common/departments
  Future<Map<String, dynamic>> getDepartments({
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
    String? keyword,
    String? status,
    String? headquartersId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      if (headquartersId != null && headquartersId.isNotEmpty) {
        queryParameters['headquartersId'] = headquartersId;
      }

      final response = await _apiClient.get(
        ApiEndpoints.departments,
        queryParameters: queryParameters,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '부서 목록을 불러오는 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENTS_FETCH_FAILED',
      );
    }
  }

  /// 부서 생성
  /// POST /api/v1/common/departments
  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String description,
    String? status,
    String? headquartersId,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
      };

      if (status != null) {
        data['status'] = status;
      }
      if (headquartersId != null) {
        data['headquartersId'] = headquartersId;
      }

      final response = await _apiClient.post(
        ApiEndpoints.departments,
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '부서 생성 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENT_CREATE_FAILED',
      );
    }
  }

  /// 본사 부서 생성 (아이콘 포함)
  /// POST /api/v1/headquarters/departments
  Future<Map<String, dynamic>> createHeadquartersDepartment({
    required String name,
    File? iconFile,
  }) async {
    try {
      print('🏢 부서 생성 시작 - 이름: $name');

      FormData formData = FormData.fromMap({
        'name': name,
      });

      // 아이콘 파일이 있는 경우 FormData에 추가
      if (iconFile != null) {
        String fileName = iconFile.path.split('/').last;
        print('📷 아이콘 첨부 - 파일명: $fileName');
        formData.files.add(
          MapEntry(
            'icon',
            await MultipartFile.fromFile(
              iconFile.path,
              filename: fileName,
            ),
          ),
        );
      } else {
        print('📷 아이콘 없음');
      }

      print('📤 API 호출: POST ${ApiEndpoints.headquarters}/departments');

      final response = await _apiClient.post(
        '${ApiEndpoints.headquarters}/departments',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('✅ 부서 생성 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('부서 생성 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('부서 생성 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final departmentRemoteDataSourceProvider = Provider<DepartmentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DepartmentRemoteDataSource(apiClient);
});