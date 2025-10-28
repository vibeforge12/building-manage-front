import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

class BuildingRemoteDataSource {
  final ApiClient _apiClient;

  BuildingRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> createBuilding({
    required String name,
    required String address,
    File? image,
    String? memo,
  }) async {
    try {
      print('🏢 건물 등록 시작 - 이름: $name, 주소: $address');

      dynamic requestData;
      Options? options;

      if (image != null) {
        // 이미지가 있는 경우: FormData 사용
        String fileName = image.path.split('/').last;
        print('📷 이미지 첨부 - 파일명: $fileName');

        FormData formData = FormData.fromMap({
          'name': name,
          'address': address,
          if (memo != null && memo.isNotEmpty) 'memo': memo,
        });

        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              image.path,
              filename: fileName,
            ),
          ),
        );

        requestData = formData;
        options = Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        );
      } else {
        // 이미지가 없는 경우: JSON 사용 (스웨거와 동일)
        print('📷 이미지 없음 - JSON 요청 사용');
        requestData = {
          'name': name,
          'address': address,
          'imageUrl': '', // 빈 문자열로 설정
          if (memo != null && memo.isNotEmpty) 'memo': memo,
        };
        options = Options(
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }

      print('📤 API 호출: POST ${ApiEndpoints.buildings}');

      final response = await _apiClient.post(
        ApiEndpoints.buildings,
        data: requestData,
        options: options,
      );

      print('✅ 건물 등록 응답: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ DioException 발생: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      throw Exception('건물 등록 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('❌ 일반 예외 발생: $e');
      throw Exception('건물 등록 중 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> getBuildings({
    String? keyword,
    int? headquartersId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.buildings,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (headquartersId != null) 'headquartersId': headquartersId,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }
}

// Riverpod Provider
final buildingRemoteDataSourceProvider = Provider<BuildingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BuildingRemoteDataSource(apiClient);
});