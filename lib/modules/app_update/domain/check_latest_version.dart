import 'store_url.dart';

class InstalledAppVersion {
  const InstalledAppVersion(this.platform, this.version, this.build);
  final String platform;
  final String version;
  final int build;
}

class PublishedAppRelease {
  const PublishedAppRelease(this.version, this.build, this.storeUrl);
  final String version;
  final int build;
  final Uri storeUrl;

  factory PublishedAppRelease.fromJson(
    Map<String, dynamic> json,
    String platform,
  ) {
    final version = json['latestVersion'];
    final build = json['latestBuild'];
    final url = Uri.tryParse(json['storeUrl']?.toString() ?? '');
    if (json['platform'] != platform ||
        version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        build is! int ||
        build < 1 ||
        !isOfficialStoreUrl(url, platform)) {
      throw const FormatException('Invalid published app release');
    }
    return PublishedAppRelease(version, build, url!);
  }
}

abstract class AppReleaseRepository {
  Future<PublishedAppRelease> fetch(String platform);
}

enum AppVersionStatus { current, updateAvailable, aheadOfStore }

class LatestVersionResult {
  const LatestVersionResult(this.installed, this.release);
  final InstalledAppVersion installed;
  final PublishedAppRelease release;
  AppVersionStatus get status => installed.build < release.build
      ? AppVersionStatus.updateAvailable
      : installed.build == release.build
      ? AppVersionStatus.current
      : AppVersionStatus.aheadOfStore;
}

class CheckLatestVersion {
  const CheckLatestVersion(this.repository);
  final AppReleaseRepository repository;

  Future<LatestVersionResult> execute(InstalledAppVersion installed) async {
    if (installed.platform != 'ios' && installed.platform != 'android') {
      throw const FormatException('Unsupported platform');
    }
    // A failed/offline response must never be presented as "up to date".
    return LatestVersionResult(
      installed,
      await repository.fetch(installed.platform),
    );
  }
}
