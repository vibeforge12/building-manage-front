class AppInstallation {
  const AppInstallation({
    required this.id,
    required this.platform,
    required this.version,
    required this.buildNumber,
  });
  final String id;
  final String platform;
  final String version;
  final int buildNumber;
}

abstract class AppInstallationRepository {
  Future<AppInstallation?> identity();
  Future<void> record(
    String accountId,
    String role,
    AppInstallation installation,
  );
}

/// Reports once per session, then at most once per 15 minutes on app resume.
/// A failure remains retryable, and account changes invalidate pending work.
class ReportAppInstallation {
  ReportAppInstallation(this.repository, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final AppInstallationRepository repository;
  final DateTime Function() now;
  int _session = 0;
  String? _account;
  DateTime? _lastSuccess;
  bool _busy = false;

  void reset() {
    _session++;
    _account = null;
    _lastSuccess = null;
    _busy = false;
  }

  Future<void> execute(String accountId, String role) async {
    final account = '$role:$accountId';
    if (_account != account) {
      reset();
      _account = account;
    }
    if (_busy ||
        (_lastSuccess != null &&
            now().difference(_lastSuccess!) < const Duration(minutes: 15))) {
      return;
    }
    final session = _session;
    _busy = true;
    try {
      final installation = await repository.identity();
      if (session != _session || installation == null) return;
      await repository.record(accountId, role, installation);
      if (session == _session) _lastSuccess = now();
    } finally {
      if (session == _session) _busy = false;
    }
  }
}
