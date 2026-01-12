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

    if (options.queryParameters.isNotEmpty) {
    }

    if (options.headers.isNotEmpty) {
    }

    if (options.data != null) {
    }
  }

  void _logResponse(Response response) {

    if (response.headers.map.isNotEmpty) {
    }

    if (response.data != null) {
    }
  }

  void _logError(DioException err) {

    if (err.response != null) {
    }

    if (err.stackTrace != null) {
    }
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