/// Revoke this device's push registration while authentication is still valid.
/// A failed server cleanup keeps the session available for a safe retry.
class LogoutUseCase {
  const LogoutUseCase({
    required this.clearPushRegistration,
    required this.clearCredentials,
  });

  final Future<void> Function() clearPushRegistration;
  final Future<void> Function() clearCredentials;

  Future<void> call() async {
    await clearPushRegistration();
    await clearCredentials();
  }
}
