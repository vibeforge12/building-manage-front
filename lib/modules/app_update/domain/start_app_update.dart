import 'store_url.dart';

enum UpdateLaunchResult { started, cancelled, unavailable, busy, notInProgress }

abstract class AndroidAppUpdater {
  Future<UpdateLaunchResult> start({
    int minimumBuild = 0,
    bool resumeOnly = false,
  });
}

class StartAppUpdate {
  const StartAppUpdate(this.android, this.openStore);
  final AndroidAppUpdater android;
  final Future<bool> Function(Uri) openStore;

  Future<UpdateLaunchResult> execute(
    String platform,
    Uri storeUrl,
    int targetBuild,
  ) async {
    if (!isOfficialStoreUrl(storeUrl, platform)) {
      return UpdateLaunchResult.unavailable;
    }
    if (platform == 'android') return android.start(minimumBuild: targetBuild);
    return await openStore(storeUrl)
        ? UpdateLaunchResult.started
        : UpdateLaunchResult.unavailable;
  }
}
