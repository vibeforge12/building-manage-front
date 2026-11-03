import 'update_policy.dart';

abstract class UpdateRepository {
  Future<UpdatePolicy?> cached(String platform);
  Future<UpdatePolicy> fetch(String platform);
  Future<void> save(String platform, UpdatePolicy policy);
}
