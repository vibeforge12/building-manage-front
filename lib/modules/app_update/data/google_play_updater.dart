import 'package:in_app_update/in_app_update.dart';
import '../domain/start_app_update.dart';

/// Google Play owns consent, download, installation and restart.
class GooglePlayUpdater implements AndroidAppUpdater {
  bool _busy = false;

  @override
  Future<UpdateLaunchResult> start({
    int minimumBuild = 0,
    bool resumeOnly = false,
  }) async {
    if (_busy) return UpdateLaunchResult.busy;
    _busy = true;
    try {
      final info = await InAppUpdate.checkForUpdate().timeout(
        const Duration(seconds: 8),
      );
      final inProgress =
          info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress;
      if (resumeOnly && !inProgress) return UpdateLaunchResult.notInProgress;
      if (!inProgress &&
          (info.updateAvailability != UpdateAvailability.updateAvailable ||
              !info.immediateUpdateAllowed ||
              (info.availableVersionCode ?? 0) < minimumBuild)) {
        return UpdateLaunchResult.unavailable;
      }
      final result = await InAppUpdate.performImmediateUpdate();
      return switch (result) {
        AppUpdateResult.success => UpdateLaunchResult.started,
        AppUpdateResult.userDeniedUpdate => UpdateLaunchResult.cancelled,
        AppUpdateResult.inAppUpdateFailed => UpdateLaunchResult.unavailable,
      };
    } catch (_) {
      // Missing Play ownership, network and native failures remain retryable.
      return UpdateLaunchResult.unavailable;
    } finally {
      _busy = false;
    }
  }
}
