import 'store_url.dart';

class UpdatePolicy {
  final bool enabled;
  final int minimumBuild;
  final Uri? storeUrl;
  const UpdatePolicy({
    required this.enabled,
    required this.minimumBuild,
    this.storeUrl,
  });
  bool requiresUpdate(int build) => enabled && build < minimumBuild;

  factory UpdatePolicy.fromJson(Map<String, dynamic> json, String platform) {
    if (json['platform'] != platform || json['enabled'] is! bool) {
      throw const FormatException('Invalid update policy');
    }
    if (json['enabled'] == false) {
      return const UpdatePolicy(enabled: false, minimumBuild: 0);
    }
    final build = json['minimumBuild'];
    final url = Uri.tryParse(json['storeUrl']?.toString() ?? '');
    final validStore = isOfficialStoreUrl(url, platform);
    if (build is! int ||
        build < 1 ||
        url?.scheme != 'https' ||
        url!.userInfo.isNotEmpty ||
        !validStore) {
      throw const FormatException('Invalid update policy');
    }
    return UpdatePolicy(enabled: true, minimumBuild: build, storeUrl: url);
  }

  Map<String, dynamic> toJson(String platform) => {
    'platform': platform,
    'enabled': enabled,
    'minimumBuild': minimumBuild,
    'storeUrl': storeUrl?.toString(),
  };
}
