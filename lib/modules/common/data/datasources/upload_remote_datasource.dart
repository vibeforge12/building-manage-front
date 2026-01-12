import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

class UploadRemoteDataSource {
  final ApiClient _apiClient;

  UploadRemoteDataSource(this._apiClient);

  /// Presigned URL 생성 (단일 파일)
  /// POST /api/v1/upload/presigned-url
  Future<Map<String, dynamic>> getPresignedUrl({
    required String fileName,
    required String contentType,
    String folder = 'departments',
  }) async {
    try {

      final response = await _apiClient.post(
        ApiEndpoints.uploadPresignedUrl,
        data: {
          'fileName': fileName,
          'contentType': contentType,
          'folder': folder,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Presigned URL을 받아오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('Presigned URL을 받아오는 중 오류가 발생했습니다: $e');
    }
  }

  /// 여러 Presigned URL 생성 (다중 파일)
  /// POST /api/v1/upload/presigned-urls
  ///
  /// [files]: 업로드할 파일 정보 리스트
  /// 각 파일은 { fileName, contentType, folder } 형태
  ///
  /// Returns: { success: true, data: { urls: [{ uploadUrl, fileUrl }, ...] } }
  Future<Map<String, dynamic>> getMultiplePresignedUrls({
    required List<Map<String, String>> files,
  }) async {
    try {

      final response = await _apiClient.post(
        ApiEndpoints.uploadPresignedUrls,
        data: {
          'files': files,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Presigned URL을 받아오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('Presigned URL을 받아오는 중 오류가 발생했습니다: $e');
    }
  }

  /// S3에 직접 파일 업로드
  /// PUT [uploadUrl]
  Future<void> uploadToS3({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    try {

      // Dio 인스턴스를 새로 생성 (interceptor 없이)
      final dio = Dio();

      // 요청 헤더 설정
      final headers = {
        'Content-Type': contentType,
      };

      final response = await dio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: headers,
          // S3 응답은 빈 응답일 수 있으므로 validateStatus 설정
          validateStatus: (status) => status! < 400,
        ),
      );
    } on DioException catch (e) {
      throw Exception('S3 업로드 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('S3 업로드 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final uploadRemoteDataSourceProvider = Provider<UploadRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UploadRemoteDataSource(apiClient);
});
