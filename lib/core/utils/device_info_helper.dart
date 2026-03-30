import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// 디바이스 정보를 수집하는 유틸리티
/// FCM 다중 디바이스 토큰 등록 시 사용
class DeviceInfoHelper {
  static Map<String, String?>? _cachedInfo;

  /// 디바이스 정보 반환: {deviceId, deviceName, platform}
  /// 앱 세션 동안 캐싱하여 한 번만 수집
  /// 실패 시 null 값 반환 (절대 throw하지 않음)
  static Future<Map<String, String?>> getDeviceInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _cachedInfo = {
          'deviceId': androidInfo.id,
          'deviceName': androidInfo.model,
          'platform': 'android',
        };
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedInfo = {
          'deviceId': iosInfo.identifierForVendor,
          'deviceName': iosInfo.name,
          'platform': 'ios',
        };
      } else {
        _cachedInfo = {
          'deviceId': null,
          'deviceName': null,
          'platform': 'unknown',
        };
      }
    } catch (e) {
      _cachedInfo = {
        'deviceId': null,
        'deviceName': null,
        'platform': 'unknown',
      };
    }

    return _cachedInfo!;
  }
}
