import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool get fcmEnabled =>
      !isDevelopment ||
      const bool.fromEnvironment('FCM_ENABLED', defaultValue: false);
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _environmentOverride = String.fromEnvironment(
    'ENVIRONMENT',
  );

  static String get baseUrl => _baseUrlOverride.isNotEmpty
      ? _baseUrlOverride
      : dotenv.env['API_BASE_URL'] ?? '';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  static String get environment => _environmentOverride.isNotEmpty
      ? _environmentOverride
      : dotenv.env['ENVIRONMENT'] ?? 'staging';

  // Timeout 설정
  static int get connectTimeout =>
      int.tryParse(dotenv.env['API_CONNECT_TIMEOUT'] ?? '') ?? 30000;
  static int get receiveTimeout =>
      int.tryParse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '') ?? 30000;

  // Debug 설정
  static bool get isDebug => dotenv.env['API_DEBUG']?.toLowerCase() == 'true';

  // 전체 API URL
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // 환경별 설정
  static bool get isDevelopment =>
      environment == 'dev' || environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction =>
      environment == 'prod' || environment == 'production';
}
