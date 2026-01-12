import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Secure Storage 인스턴스 (싱글톤 패턴)
  // ⚠️ 중요: 앱 재설치 감지 및 토큰 삭제
  // - Android: resetOnError로 에러 시 데이터 초기화
  // - iOS/Android: main.dart의 _clearTokensOnFirstRun()에서 앱 버전 체크로 첫 설치 감지 후 토큰 삭제
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
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
        await _clearToken();
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
      // Token save failed
    }
  }

  // 토큰 제거 (Secure Storage)
  Future<void> _clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      // Token clear failed
    }
  }

  // 현재 토큰 가져오기 (외부에서 사용 가능)
  static Future<String?> getCurrentToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  // 토큰 수동 저장 (외부에서 사용 가능)
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      // Token save failed
    }
  }

  // Refresh 토큰 수동 저장 (외부에서 사용 가능)
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      // Refresh token save failed
    }
  }

  // 현재 refresh token 가져오기 (외부에서 사용 가능)
  static Future<String?> getCurrentRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  // 토큰 수동 제거 (외부에서 사용 가능)
  static Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      // Token clear failed
    }
  }
}
