import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';

class DepartmentRemoteDataSource {
  final ApiClient _apiClient;
  final ImageUploadService _imageUploadService;

  DepartmentRemoteDataSource(this._apiClient, this._imageUploadService);

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
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '부서 목록을 불러오는 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENTS_FETCH_FAILED',
      );
    }
  }

  /// 부서 상세 조회
  /// GET /api/v1/common/departments/{departmentId}
  Future<Map<String, dynamic>> getDepartmentById(String departmentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.departments}/$departmentId',
      );

      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '부서 정보를 불러오는 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENT_FETCH_FAILED',
      );
    }
  }

  /// 부서 생성 (기본)
  /// POST /api/v1/common/departments
  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String iconUrl,
    String? status,
    String? headquartersId,
  }) async {
    try {
      final data = {
        'name': name,
        'iconUrl': iconUrl,
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
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '부서 생성 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENT_CREATE_FAILED',
      );
    }
  }

  /// 본사용 부서 생성 (이미지 업로드 포함)
  /// POST /api/v1/headquarters/departments
  Future<Map<String, dynamic>> createHeadquartersDepartment({
    required String name,
    File? iconFile,
  }) async {
    try {
      String? iconUrl;

      // 아이콘 파일이 있으면 S3에 업로드
      if (iconFile != null) {
        final bytes = await iconFile.readAsBytes();
        final fileName = iconFile.path.split('/').last;
        final contentType = ImageUploadService.getContentType(fileName);

        iconUrl = await _imageUploadService.uploadImage(
          fileBytes: bytes,
          fileName: fileName,
          contentType: contentType,
          folder: 'departments',
        );
      }

      final data = <String, dynamic>{
        'name': name,
      };

      if (iconUrl != null) {
        data['iconUrl'] = iconUrl;
      }

      final response = await _apiClient.post(
        '${ApiEndpoints.headquarters}/departments',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '부서 생성 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENT_CREATE_FAILED',
      );
    }
  }

  /// 부서 수정
  /// PATCH /api/v1/headquarters/departments/{departmentId}
  Future<Map<String, dynamic>> updateDepartment({
    required String departmentId,
    String? name,
    File? iconFile,
    String? status,
  }) async {
    try {
      String? iconUrl;

      // 아이콘 파일이 있으면 S3에 업로드
      if (iconFile != null) {
        final bytes = await iconFile.readAsBytes();
        final fileName = iconFile.path.split('/').last;
        final contentType = ImageUploadService.getContentType(fileName);

        iconUrl = await _imageUploadService.uploadImage(
          fileBytes: bytes,
          fileName: fileName,
          contentType: contentType,
          folder: 'departments',
        );
      }

      final data = <String, dynamic>{};

      if (name != null) {
        data['name'] = name;
      }
      if (iconUrl != null) {
        data['iconUrl'] = iconUrl;
      }
      if (status != null) {
        data['status'] = status;
      }

      final response = await _apiClient.patch(
        '${ApiEndpoints.headquarters}/departments/$departmentId',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '부서 수정 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENT_UPDATE_FAILED',
      );
    }
  }

  /// 부서 삭제
  /// DELETE /api/v1/headquarters/departments/{departmentId}
  Future<Map<String, dynamic>> deleteDepartment(String departmentId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiEndpoints.headquarters}/departments/$departmentId',
      );

      return response.data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '부서 삭제 중 오류가 발생했습니다.',
        errorCode: 'DEPARTMENT_DELETE_FAILED',
      );
    }
  }
}

// Riverpod Provider
final departmentRemoteDataSourceProvider = Provider<DepartmentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final imageUploadService = ref.watch(imageUploadServiceProvider);
  return DepartmentRemoteDataSource(apiClient, imageUploadService);
});
