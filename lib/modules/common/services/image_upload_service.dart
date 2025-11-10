import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/common/data/datasources/upload_remote_datasource.dart';

/// 이미지 업로드 서비스
/// Presigned URL을 사용하여 S3에 직접 업로드하는 로직을 캡슐화
class ImageUploadService {
  final UploadRemoteDataSource _uploadDataSource;

  ImageUploadService(this._uploadDataSource);

  /// 이미지 파일을 S3에 업로드하고 최종 URL 반환
  ///
  /// [fileBytes]: 업로드할 파일의 바이트 데이터
  /// [fileName]: 파일명 (예: 'profile.jpg')
  /// [contentType]: MIME 타입 (예: 'image/jpeg')
  /// [folder]: S3 폴더 경로 (기본값: 'departments')
  ///
  /// Returns: S3에 업로드된 파일의 최종 URL
  Future<String> uploadImage({
    required Uint8List fileBytes,
    required String fileName,
    required String contentType,
    String folder = 'departments',
  }) async {
    try {
      print('🖼️ 이미지 업로드 시작: $fileName');

      // 1단계: Presigned URL 받기
      final presignedResponse = await _uploadDataSource.getPresignedUrl(
        fileName: fileName,
        contentType: contentType,
        folder: folder,
      );

      if (presignedResponse['success'] != true) {
        throw Exception('Presigned URL 생성 실패');
      }

      final data = presignedResponse['data'] as Map<String, dynamic>;
      final uploadUrl = data['uploadUrl'] as String;
      final fileUrl = data['fileUrl'] as String;

      print('📝 업로드 URL: $uploadUrl');
      print('📝 최종 파일 URL: $fileUrl');

      // 2단계: S3에 직접 업로드
      await _uploadDataSource.uploadToS3(
        uploadUrl: uploadUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );

      print('✅ 이미지 업로드 완료: $fileUrl');

      // 3단계: 최종 파일 URL 반환
      return fileUrl;
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  /// 파일 확장자로부터 Content-Type 추출
  static String getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

// Riverpod Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final uploadDataSource = ref.watch(uploadRemoteDataSourceProvider);
  return ImageUploadService(uploadDataSource);
});
