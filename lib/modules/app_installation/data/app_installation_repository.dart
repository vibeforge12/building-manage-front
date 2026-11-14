import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:building_manage_front/core/config/app_config.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import '../domain/report_app_installation.dart';

class StoredAppInstallationRepository implements AppInstallationRepository {
  StoredAppInstallationRepository(this.api);
  final ApiClient api;
  Future<AppInstallation?>? _identity;

  @override
  Future<AppInstallation?> identity() async {
    try {
      return await (_identity ??= _loadIdentity());
    } catch (_) {
      _identity = null;
      rethrow;
    }
  }

  Future<AppInstallation?> _loadIdentity() async {
    if (kIsWeb) return null;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => '',
    };
    if (platform.isEmpty) return null;
    final info = await PackageInfo.fromPlatform();
    final preferences = await SharedPreferences.getInstance();
    final key = 'app_installation:${AppConfig.environment}:${info.packageName}';
    var id = preferences.getString(key);
    if (id == null) {
      final random = Random.secure();
      final bytes = List.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 0x0f) | 0x40;
      bytes[8] = (bytes[8] & 0x3f) | 0x80;
      final hex = bytes
          .map((value) => value.toRadixString(16).padLeft(2, '0'))
          .join();
      id =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      if (!await preferences.setString(key, id)) {
        throw StateError('Could not persist installation identity');
      }
    }
    return AppInstallation(
      id: id,
      platform: platform,
      version: info.version,
      buildNumber: int.parse(info.buildNumber),
    );
  }

  @override
  Future<void> record(
    String accountId,
    String role,
    AppInstallation installation,
  ) async {
    await api.post(
      ApiEndpoints.appInstallation,
      data: {
        'accountId': accountId,
        'accountRole': role,
        'installationId': installation.id,
        'platform': installation.platform,
        'appVersion': installation.version,
        'buildNumber': installation.buildNumber,
      },
    );
  }
}
