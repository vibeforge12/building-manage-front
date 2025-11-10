import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

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
      // 저장된 토큰 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print('🔐 AuthInterceptor: Token attached to request');
      } else {
        print('⚠️ AuthInterceptor: No token found in SharedPreferences');
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
    // 401 Unauthorized: 토큰 제거 후 앱 첫 화면으로 유도
    if (err.response?.statusCode == 401) {
      await _clearToken();
      // NOTE:
      // 여기서는 네트워크 레이어라 라우터/Provider에 직접 접근하지 않습니다.
      // 앱 레벨에서는 다음 앱 진입 시(스플래시 이후) 기본 홈('/')로 이동하게 됩니다.
      // 만약 즉시 리디렉트가 필요하다면, 상위 레이어에서 이 에러를 감지하여
      // 라우터(go('/')) 호출을 수행하도록 핸들링하세요.
    }

    super.onError(err, handler);
  }

  // 응답에서 토큰 추출 및 저장
  Future<void> _saveTokenFromResponse(Response response) async {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final accessToken = data['data']?['accessToken'] ??
                           data['accessToken'] ??
                           data['token'];

        final refreshToken = data['data']?['refreshToken'] ??
                            data['refreshToken'];

        final prefs = await SharedPreferences.getInstance();

        if (accessToken != null) {
          await prefs.setString(_tokenKey, accessToken);
        }

        if (refreshToken != null) {
          await prefs.setString(_refreshTokenKey, refreshToken);
        }
      }
    } catch (e) {
      // 토큰 저장 실패 시 로그 (실제 앱에서는 로깅 시스템 사용)
      print('Failed to save tokens: $e');
    }
  }

  // 토큰 제거
  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
    } catch (e) {
      print('Failed to clear tokens: $e');
    }
  }

  // 현재 토큰 가져오기 (외부에서 사용 가능)
  static Future<String?> getCurrentToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Failed to get current token: $e');
      return null;
    }
  }

  // 토큰 수동 저장 (외부에서 사용 가능)
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Failed to save token manually: $e');
    }
  }

  // 현재 refresh token 가져오기 (외부에서 사용 가능)
  static Future<String?> getCurrentRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Failed to get current refresh token: $e');
      return null;
    }
  }

  // 토큰 수동 제거 (외부에서 사용 가능)
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
    } catch (e) {
      print('Failed to clear tokens manually: $e');
    }
  }
}
