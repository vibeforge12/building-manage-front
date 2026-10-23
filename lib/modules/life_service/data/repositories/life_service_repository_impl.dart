import '../../domain/entities/life_service.dart';
import '../../domain/repositories/life_service_repository.dart';
import '../datasources/life_service_remote_datasource.dart';
import 'dart:typed_data';
import 'package:building_manage_front/core/config/app_config.dart';

class LifeServiceRepositoryImpl implements LifeServiceRepository {
  const LifeServiceRepositoryImpl(this._remote);
  final LifeServiceRemoteDataSource _remote;

  LifeService _service(Map<String, dynamic> json) => LifeService.fromJson({
    ...json,
    'imageUrls': (json['imageUrls'] as List? ?? const [])
        .map(
          (url) => url is String && url.startsWith('/')
              ? Uri.parse(AppConfig.apiBaseUrl).resolve(url).toString()
              : url,
        )
        .toList(),
  });

  @override
  Future<String> uploadImage(Uint8List bytes, String fileName) async =>
      (_payload(await _remote.uploadImage(bytes, fileName)) as Map)['key']
          as String;

  dynamic _payload(dynamic response) =>
      response is Map && response['success'] == true
      ? response['data']
      : response;

  List<Map<String, dynamic>> _items(dynamic response) {
    final data = _payload(response);
    final raw = data is Map ? (data['data'] ?? data['items']) : data;
    return raw is List ? raw.cast<Map<String, dynamic>>() : const [];
  }

  @override
  Future<List<LifeService>> list({
    required String tab,
    int limit = 100,
  }) async =>
      _items(await _remote.list(tab: tab, limit: limit)).map(_service).toList();
  @override
  Future<List<LifeService>> history() async =>
      _items(await _remote.history()).map(_service).toList();
  @override
  Future<LifeService> detail(String id) async => _service(
    Map<String, dynamic>.from(_payload(await _remote.detail(id)) as Map),
  );
  @override
  Future<void> create(Map<String, dynamic> data) => _remote.create(data);
  @override
  Future<void> update(String id, Map<String, dynamic> data) =>
      _remote.update(id, data);
  @override
  Future<void> close(String id) => _remote.close(id);
  @override
  Future<List<Map<String, dynamic>>> applicants(
    String id, {
    String? keyword,
  }) async => _items(await _remote.applicants(id, keyword: keyword));
  @override
  Future<void> apply(String id) => _remote.apply(id);
  @override
  Future<void> cancel(String id) => _remote.cancel(id);
}
