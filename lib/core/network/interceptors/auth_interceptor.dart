import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Secure Storage 인스턴스 (싱글톤 패턴)
  // Android: 패키지명 변경 시에도 데이터 유지를 위해 sharedPreferencesName 고정
  // iOS: first_unlock은 디바이스 재시작 후에도 접근 가능 (앱 재시작 시 크래시 방지)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'building_manage_secure_prefs',
      preferencesKeyPrefix: 'building_manage_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 토큰이 필요없는 엔드포인트들
    final publicEndpoints = [
      '/auth/resident/register',
      '/auth/manager/register',
      '/auth/resident/login',
      '/auth/manager/login',
      '/auth/staff/login',
      '/auth/headquarters/login',
      '/auth/refresh',
    ];

    // public 엔드포인트인지 확인
    final isPublicEndpoint = publicEndpoints.any((endpoint) =>
        options.path.contains(endpoint));

    if (!isPublicEndpoint) {
      // 저장된 토큰 가져오기 (Secure Storage)
      final token = await _secureStorage.read(key: _tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print('🔐 AuthInterceptor: Token attached to request');
      } else {
        print('⚠️ AuthInterceptor: No token found in SecureStorage');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 로그인 성공 시 토큰 저장
    if (response.requestOptions.path.contains('/login') &&
        response.statusCode == 200) {
      _saveTokenFromResponse(response);
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 Unauthorized 처리
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;

      // 로그인 엔드포인트의 401은 "로그인 실패"이므로 토큰 삭제하지 않음
      // (기존 로그인 세션을 유지해야 함)
      final isLoginEndpoint = path.contains('/login') || path.contains('/register');

      if (!isLoginEndpoint) {
        // 인증된 API 요청의 401만 토큰 제거
        print('🔐 AuthInterceptor: 401 에러 - 토큰 삭제 ($path)');
        await _clearToken();
      } else {
        print('🔐 AuthInterceptor: 401 에러 - 로그인 실패, 토큰 유지 ($path)');
      }
    }

    super.onError(err, handler);
  }

  // 응답에서 토큰 추출 및 저장 (Secure Storage 사용)
  Future<void> _saveTokenFromResponse(Response response) async {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final accessToken = data['data']?['accessToken'] ??
                           data['accessToken'] ??
                           data['token'];

        final refreshToken = data['data']?['refreshToken'] ??
                            data['refreshToken'];

        if (accessToken != null) {
          await _secureStorage.write(key: _tokenKey, value: accessToken);
        }

        if (refreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        }
      }
    } catch (e) {
      // 토큰 저장 실패 시 로그 (실제 앱에서는 로깅 시스템 사용)
      print('Failed to save tokens: $e');
    }
  }

  // 토큰 제거 (Secure Storage)
  Future<void> _clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      print('Failed to clear tokens: $e');
    }
  }

  // 현재 토큰 가져오기 (외부에서 사용 가능)
  static Future<String?> getCurrentToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      print('Failed to get current token: $e');
      return null;
    }
  }

  // 토큰 수동 저장 (외부에서 사용 가능)
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      print('Failed to save token manually: $e');
    }
  }

  // Refresh 토큰 수동 저장 (외부에서 사용 가능)
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      print('Failed to save refresh token manually: $e');
    }
  }

  // 현재 refresh token 가져오기 (외부에서 사용 가능)
  static Future<String?> getCurrentRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      print('Failed to get current refresh token: $e');
      return null;
    }
  }

  // 토큰 수동 제거 (외부에서 사용 가능)
  static Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      print('Failed to clear tokens manually: $e');
    }
  }
}
