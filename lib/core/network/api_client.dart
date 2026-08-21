import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/config/app_config.dart';
import 'package:building_manage_front/core/network/interceptors/auth_interceptor.dart';
import 'package:building_manage_front/core/network/interceptors/logging_interceptor.dart';
import 'package:building_manage_front/core/network/interceptors/error_interceptor.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptors 추가
    if (AppConfig.isDebug) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
  }

  /// Dio가 던지는 [DioException]을 앱 표준 예외인 [ApiException]으로 정규화한다.
  ///
  /// 이 래퍼 덕분에 상위 계층(datasource/provider/screen)은
  /// `on ApiException catch` 한 가지 계약만 다루면 된다.
  Future<Response<T>> _guard<T>(Future<Response<T>> Function() send) async {
    try {
      return await send();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // GET 요청
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(() => _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }

  // POST 요청
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(() => _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }

  // PUT 요청
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(() => _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }

  // DELETE 요청
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(() => _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }

  // PATCH 요청
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(() => _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ));
  }
}

// Riverpod Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});