import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/network/api_client.dart';
import '../data/app_release_repository.dart';
import '../domain/check_latest_version.dart';
import 'app_update_button.dart';

final installedAppVersionProvider = FutureProvider<InstalledAppVersion>((
  ref,
) async {
  final info = await PackageInfo.fromPlatform().timeout(
    const Duration(seconds: 3),
  );
  final platform = kIsWeb
      ? ''
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => '',
        };
  return InstalledAppVersion(
    platform,
    info.version,
    int.parse(info.buildNumber),
  );
});
final checkLatestVersionProvider = Provider(
  (ref) => CheckLatestVersion(
    RemoteAppReleaseRepository(ref.watch(apiClientProvider)),
  ),
);
final latestAppVersionProvider =
    FutureProvider.autoDispose<LatestVersionResult>((ref) async {
      final check = ref.watch(checkLatestVersionProvider);
      final installed = await ref.watch(installedAppVersionProvider.future);
      return check.execute(installed);
    });

/// Shared across all role menus and the signed-out home screen.
class AppVersionSection extends ConsumerStatefulWidget {
  const AppVersionSection({super.key, this.onDarkBackground = false});
  final bool onDarkBackground;

  @override
  ConsumerState<AppVersionSection> createState() => _AppVersionSectionState();
}

class _AppVersionSectionState extends ConsumerState<AppVersionSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(installedAppVersionProvider);
      ref.invalidate(latestAppVersionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = ref.watch(installedAppVersionProvider);
    final latest = ref.watch(latestAppVersionProvider);
    final color = widget.onDarkBackground
        ? Colors.white
        : const Color(0xFF757B80);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          installed.when(
            data: (info) => Text(
              '현재 버전 ${info.version}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: color,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          latest.when(
            skipLoadingOnRefresh: false,
            data: (result) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  switch (result.status) {
                    AppVersionStatus.current => '최신 버전입니다',
                    AppVersionStatus.updateAvailable =>
                      '최신 버전 ${result.release.version}',
                    AppVersionStatus.aheadOfStore => '공개 버전보다 새로운 버전입니다',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: color,
                  ),
                ),
                if (result.status == AppVersionStatus.updateAvailable) ...[
                  const SizedBox(height: 12),
                  AppUpdateButton(
                    platform: result.installed.platform,
                    storeUrl: result.release.storeUrl,
                    targetBuild: result.release.build,
                  ),
                ],
              ],
            ),
            // Optional version checks stay silent until a fresh result exists.
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
