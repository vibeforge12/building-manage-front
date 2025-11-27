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

  /// 여러 이미지 파일을 S3에 업로드하고 최종 URL 리스트 반환
  ///
  /// [files]: 업로드할 파일 정보 리스트 (각 항목: { bytes, fileName, contentType })
  /// [folder]: S3 폴더 경로 (기본값: 'notices')
  ///
  /// Returns: S3에 업로드된 파일들의 최종 URL 리스트
  Future<List<String>> uploadMultipleImages({
    required List<Map<String, dynamic>> files,
    String folder = 'notices',
  }) async {
    if (files.isEmpty) return [];

    try {
      print('🖼️ 다중 이미지 업로드 시작: ${files.length}개 파일');

      // 1단계: 모든 파일에 대한 Presigned URL 한 번에 받기
      final fileInfoList = files.map((file) => {
        'fileName': file['fileName'] as String,
        'contentType': file['contentType'] as String,
        'folder': folder,
      }).toList();

      final presignedResponse = await _uploadDataSource.getMultiplePresignedUrls(
        files: fileInfoList,
      );

      if (presignedResponse['success'] != true) {
        throw Exception('다중 Presigned URL 생성 실패');
      }

      // API 응답: { success: true, data: [{ uploadUrl, fileUrl, ... }, ...] }
      // data가 직접 배열로 반환됨
      final urlsList = presignedResponse['data'] as List<dynamic>;

      print('📝 ${urlsList.length}개의 Presigned URL 수신 완료');

      // 2단계: 각 파일을 병렬로 S3에 업로드
      final List<String> uploadedUrls = [];

      final uploadFutures = <Future<void>>[];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final urlInfo = urlsList[i] as Map<String, dynamic>;
        final uploadUrl = urlInfo['uploadUrl'] as String;
        final fileUrl = urlInfo['fileUrl'] as String;

        uploadFutures.add(
          _uploadDataSource.uploadToS3(
            uploadUrl: uploadUrl,
            fileBytes: file['bytes'] as List<int>,
            contentType: file['contentType'] as String,
          ).then((_) {
            uploadedUrls.add(fileUrl);
            print('✅ 이미지 ${i + 1}/${files.length} 업로드 완료: $fileUrl');
          }),
        );
      }

      // 모든 업로드 완료 대기
      await Future.wait(uploadFutures);

      print('✅ 전체 다중 이미지 업로드 완료: ${uploadedUrls.length}개');

      return uploadedUrls;
    } catch (e) {
      print('❌ 다중 이미지 업로드 실패: $e');
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
