import 'update_repository.dart';
import 'update_policy.dart';

class CheckUpdate {
  final UpdateRepository repository;
  CheckUpdate(this.repository);
  Future<UpdatePolicy?> execute(String platform) async {
    final cached = await repository.cached(platform);
    try {
      final policy = await repository.fetch(platform);
      try {
        await repository.save(platform, policy);
      } catch (_) {
        /* Current response remains authoritative if local storage fails. */
      }
      return policy;
    } catch (_) {
      return cached;
    }
  }
}
