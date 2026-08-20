import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // 토큰 갱신 후 재시도한 요청 표시 (요청당 갱신 1회 → 무한 루프 방지)
  static const String _retriedKey = 'auth_interceptor_retried';

  // 진행 중인 토큰 갱신 Future
  // 동시에 여러 요청이 401을 받아도 갱신은 1회만 수행하고 결과를 공유한다.
  static Future<String?>? _refreshFuture;

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
    if (err.response?.statusCode != 401) {
      super.onError(err, handler);
      return;
    }

    final requestOptions = err.requestOptions;
    final path = requestOptions.path;

    // 로그인 엔드포인트의 401은 "로그인 실패"이므로 토큰 삭제/갱신 대상이 아님
    // (기존 로그인 세션을 유지해야 함)
    final isLoginEndpoint = path.contains('/login') || path.contains('/register');

    if (isLoginEndpoint) {
      super.onError(err, handler);
      return;
    }

    // 갱신 요청 자체의 401 = refresh token 만료
    // 여기서 다시 갱신을 시도하면 무한 루프가 되므로 토큰만 제거한다.
    if (path.contains(ApiEndpoints.refreshToken)) {
      await _clearToken();
      super.onError(err, handler);
      return;
    }

    // 이미 갱신 후 재시도한 요청이 또 401이면 재갱신하지 않는다. (요청당 1회)
    if (requestOptions.extra[_retriedKey] == true) {
      super.onError(err, handler);
      return;
    }

    // 저장된 refresh token으로 갱신 시도 (동시 401은 하나의 Future를 공유)
    final newAccessToken = await _refreshAccessToken(requestOptions);

    if (newAccessToken == null) {
      // 갱신까지 실패한 경우에만 토큰 제거 후 401을 그대로 전달
      await _clearToken();
      super.onError(err, handler);
      return;
    }

    // 새 토큰으로 원래 실패한 요청을 재시도하고 그 결과를 호출자에게 반환
    try {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra[_retriedKey] = true;

      final response = await _createPlainDio(requestOptions).fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      // 재시도 실패는 재갱신 없이 그대로 전달 (ErrorInterceptor가 변환)
      super.onError(retryError, handler);
    } catch (e) {
      super.onError(err, handler);
    }
  }

  // 토큰 갱신 (동시 요청은 진행 중인 Future를 공유하여 갱신 1회만 수행)
  Future<String?> _refreshAccessToken(RequestOptions options) {
    final ongoingRefresh = _refreshFuture;
    if (ongoingRefresh != null) {
      return ongoingRefresh;
    }

    final refreshFuture = _performRefresh(options).whenComplete(() {
      _refreshFuture = null;
    });
    _refreshFuture = refreshFuture;

    return refreshFuture;
  }

  // 실제 갱신 요청 - 성공 시 새 access token, 실패 시 null 반환
  Future<String?> _performRefresh(RequestOptions options) async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await _createPlainDio(options).post(
        ApiEndpoints.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final tokenData = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      final newAccessToken = tokenData['accessToken'];
      final newRefreshToken = tokenData['refreshToken'];

      if (newAccessToken is! String || newAccessToken.isEmpty) {
        return null;
      }

      await _secureStorage.write(key: _tokenKey, value: newAccessToken);

      if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
      }

      return newAccessToken;
    } catch (e) {
      // 갱신 실패 (refresh token 만료, 네트워크 오류 등)
      return null;
    }
  }

  // 인터셉터가 없는 Dio 생성
  // 갱신/재시도 요청이 AuthInterceptor를 다시 타지 않도록 분리한다.
  Dio _createPlainDio(RequestOptions options) {
    return Dio(BaseOptions(
      baseUrl: options.baseUrl,
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
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
