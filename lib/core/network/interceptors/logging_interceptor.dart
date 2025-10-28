import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logRequest(options);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logResponse(response);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logError(err);
    super.onError(err, handler);
  }

  void _logRequest(RequestOptions options) {
    print('\n🚀 API REQUEST');
    print('📍 ${options.method} ${options.baseUrl}${options.path}');

    if (options.queryParameters.isNotEmpty) {
      print('📊 Query Parameters: ${options.queryParameters}');
    }

    if (options.headers.isNotEmpty) {
      print('📋 Headers: ${_sanitizeHeaders(options.headers)}');
    }

    if (options.data != null) {
      print('📦 Request Data: ${_sanitizeData(options.data)}');
    }
    print('───────────────────────────────────');
  }

  void _logResponse(Response response) {
    print('\n✅ API RESPONSE');
    print('📍 ${response.requestOptions.method} ${response.requestOptions.path}');
    print('📊 Status Code: ${response.statusCode}');
    print('⏱️  Response Time: ${DateTime.now()}');

    if (response.headers.map.isNotEmpty) {
      print('📋 Response Headers: ${response.headers.map}');
    }

    if (response.data != null) {
      print('📦 Response Data: ${_formatResponseData(response.data)}');
    }
    print('───────────────────────────────────');
  }

  void _logError(DioException err) {
    print('\n❌ API ERROR');
    print('📍 ${err.requestOptions.method} ${err.requestOptions.path}');
    print('🚨 Error Type: ${err.type}');
    print('💬 Error Message: ${err.message}');

    if (err.response != null) {
      print('📊 Status Code: ${err.response?.statusCode}');
      print('📦 Error Data: ${err.response?.data}');
    }

    if (err.stackTrace != null) {
      print('🔍 Stack Trace: ${err.stackTrace}');
    }
    print('───────────────────────────────────');
  }

  // 민감한 정보를 제거한 헤더 반환
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    // Authorization 헤더가 있으면 일부만 표시
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'] as String;
      if (auth.startsWith('Bearer ')) {
        final token = auth.substring(7);
        sanitized['Authorization'] = 'Bearer ${token.substring(0, 10)}...';
      }
    }

    return sanitized;
  }

  // 민감한 정보를 제거한 데이터 반환
  dynamic _sanitizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final sanitized = Map<String, dynamic>.from(data);

      // 비밀번호 필드들 마스킹
      const sensitiveFields = ['password', 'confirmPassword', 'oldPassword', 'newPassword'];
      for (final field in sensitiveFields) {
        if (sanitized.containsKey(field)) {
          sanitized[field] = '***';
        }
      }

      return sanitized;
    }

    return data;
  }

  // 응답 데이터 포맷팅
  String _formatResponseData(dynamic data) {
    try {
      if (data is String) {
        return data.length > 1000 ? '${data.substring(0, 1000)}...' : data;
      } else {
        final jsonString = data.toString();
        return jsonString.length > 1000 ? '${jsonString.substring(0, 1000)}...' : jsonString;
      }
    } catch (e) {
      return 'Unable to format response data: $e';
    }
  }
}