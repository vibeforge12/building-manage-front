import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';

class DepartmentRemoteDataSource {
  final ApiClient _apiClient;
  final ImageUploadService? _imageUploadService;

  DepartmentRemoteDataSource(this._apiClient, [this._imageUploadService]);

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

  /// POST /api/v1/headquarters/departments
  /// Presigned URL을 사용하여 S3에 직접 업로드하는 방식으로 변경
  Future<Map<String, dynamic>> createHeadquartersDepartment({
    required String name,
    File? iconFile,
  }) async {
    try {
      print('🏢 부서 생성 시작 - 이름: $name');

      String? iconUrl;

      // 아이콘 파일이 있는 경우 S3에 업로드
      if (iconFile != null && _imageUploadService != null) {
        print('📷 이미지 업로드 시작');

        // 파일을 바이트로 읽기
        final Uint8List fileBytes = await iconFile.readAsBytes();
        final String fileName = iconFile.path.split('/').last;
        final String contentType = ImageUploadService.getContentType(fileName);

        // Presigned URL 방식으로 S3에 업로드
        iconUrl = await _imageUploadService!.uploadImage(
          fileBytes: fileBytes,
          fileName: fileName,
          contentType: contentType,
          folder: 'departments',
        );

        print('✅ 이미지 업로드 완료: $iconUrl');
      } else {
        print('📷 아이콘 없음 또는 이미지 업로드 서비스 없음');
      }

      // 부서 생성 API 호출 (iconUrl 포함)
      final data = <String, dynamic>{
        'name': name,
      };

      if (iconUrl != null) {
        data['iconUrl'] = iconUrl;
      }

      print('📤 API 호출: POST ${ApiEndpoints.headquarters}/departments');
      print('📦 데이터: $data');

      final response = await _apiClient.post(
        '${ApiEndpoints.headquarters}/departments',
        data: data,
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
  final imageUploadService = ref.watch(imageUploadServiceProvider);
  return DepartmentRemoteDataSource(apiClient, imageUploadService);
});