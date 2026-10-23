import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class LifeServiceRemoteDataSource {
  const LifeServiceRemoteDataSource(this._client);
  final ApiClient _client;

  Future<dynamic> uploadImage(Uint8List bytes, String fileName) async =>
      (await _client.post(
        '${ApiEndpoints.lifeServices}/images',
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(bytes, filename: fileName),
        }),
      )).data;

  Future<dynamic> list({required String tab, required int limit}) async =>
      (await _client.get(
        ApiEndpoints.lifeServices,
        queryParameters: {'tab': tab, 'limit': limit},
      )).data;
  Future<dynamic> history() async =>
      (await _client.get('${ApiEndpoints.lifeServices}/history')).data;
  Future<dynamic> detail(String id) async =>
      (await _client.get('${ApiEndpoints.lifeServices}/$id')).data;
  Future<void> create(Map<String, dynamic> data) async =>
      _client.post(ApiEndpoints.lifeServices, data: data);
  Future<void> update(String id, Map<String, dynamic> data) async =>
      _client.patch('${ApiEndpoints.lifeServices}/$id', data: data);
  Future<void> close(String id) async =>
      _client.post('${ApiEndpoints.lifeServices}/$id/close');
  Future<dynamic> applicants(String id, {String? keyword}) async =>
      (await _client.get(
        '${ApiEndpoints.lifeServices}/$id/applicants',
        queryParameters: keyword == null || keyword.isEmpty
            ? null
            : {'keyword': keyword},
      )).data;
  Future<void> apply(String id) async =>
      _client.post('${ApiEndpoints.lifeServices}/$id/applications');
  Future<void> cancel(String id) async =>
      _client.delete('${ApiEndpoints.lifeServices}/$id/applications/me');
}
