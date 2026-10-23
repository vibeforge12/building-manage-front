import '../entities/life_service.dart';
import 'dart:typed_data';

abstract class LifeServiceRepository {
  Future<String> uploadImage(Uint8List bytes, String fileName);
  Future<List<LifeService>> list({required String tab, int limit = 100});
  Future<List<LifeService>> history();
  Future<LifeService> detail(String id);
  Future<void> create(Map<String, dynamic> data);
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> close(String id);
  Future<List<Map<String, dynamic>>> applicants(String id, {String? keyword});
  Future<void> apply(String id);
  Future<void> cancel(String id);
}
