import '../entities/life_service.dart';
import '../repositories/life_service_repository.dart';
import 'dart:typed_data';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class LifeServiceUseCases {
  const LifeServiceUseCases(this._repository);
  final LifeServiceRepository _repository;
  static const maxImages = 5;
  static const maxImageBytes = 10 * 1024 * 1024;

  Future<String> uploadImage(Uint8List bytes, String fileName) {
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw const ApiException(
        message: '사진 한 장은 10MB 이하로 첨부해 주세요.',
        errorCode: 'INVALID_IMAGE_SIZE',
      );
    }
    return _repository.uploadImage(bytes, fileName);
  }

  Future<List<LifeService>> list({String tab = 'active', int limit = 100}) =>
      _repository.list(tab: tab, limit: limit);
  Future<List<LifeService>> history() => _repository.history();

  /// Use the server's per-resident eligibility, not just the display status:
  /// recruiting can still mean already applied, not started, or full.
  Future<List<LifeService>> availableForHome() async =>
      (await list()).where((service) => service.canApply).toList();
  Future<LifeService> detail(String id) => _repository.detail(id);
  Future<void> create(Map<String, dynamic> data) => _repository.create(data);
  Future<void> update(String id, Map<String, dynamic> data) =>
      _repository.update(id, data);
  Future<void> close(String id) => _repository.close(id);
  Future<List<Map<String, dynamic>>> applicants(String id, {String? keyword}) =>
      _repository.applicants(id, keyword: keyword);
  Future<void> apply(String id) => _repository.apply(id);
  Future<void> cancel(String id) => _repository.cancel(id);
}
