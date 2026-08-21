import 'package:dio/dio.dart';

/// 앱 전역에서 사용하는 단일 네트워크 예외 타입.
///
/// `ApiClient`의 모든 요청 메서드는 실패 시 이 예외만 던진다.
/// (`DioException`은 `ApiClient` 경계를 넘어오지 않는다.)
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String errorCode;
  final dynamic responseData;

  const ApiException({
    required this.message,
    this.statusCode,
    required this.errorCode,
    this.responseData,
  });

  /// 임의의 오류 객체를 [ApiException]으로 정규화한다.
  ///
  /// `ErrorInterceptor`가 만들어 [DioException.error]에 실어 보낸 인스턴스가 있으면
  /// 그대로 꺼내 쓰고, 없으면 가능한 정보만으로 새로 만든다.
  factory ApiException.from(Object? error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner;

      final statusCode = error.response?.statusCode;
      return ApiException(
        message: error.message ?? '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        statusCode: statusCode,
        errorCode: statusCode != null ? 'HTTP_$statusCode' : 'UNKNOWN_ERROR',
        responseData: error.response?.data,
      );
    }

    return const ApiException(
      message: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      errorCode: 'UNKNOWN_ERROR',
    );
  }

  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, errorCode: $errorCode)';
  }

  // 사용자에게 보여줄 친화적인 메시지
  String get userFriendlyMessage {
    // 특정 에러 코드에 따른 커스텀 메시지
    switch (errorCode) {
      case 'CONNECTION_TIMEOUT':
      case 'CONNECTION_ERROR':
        return '인터넷 연결을 확인하고 다시 시도해주세요.';
      case 'INVALID_CREDENTIALS':
        return '아이디 또는 비밀번호가 올바르지 않습니다.';
      case 'USER_NOT_FOUND':
        return '등록되지 않은 사용자입니다.';
      case 'DUPLICATE_EMAIL':
        return '이미 사용 중인 이메일입니다.';
      case 'WEAK_PASSWORD':
        return '비밀번호는 8자 이상이어야 합니다.';
      case 'SERVER_ERROR':
        return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return message;
    }
  }

  // 에러가 네트워크 관련인지 확인
  bool get isNetworkError {
    return [
      'CONNECTION_TIMEOUT',
      'CONNECTION_ERROR',
      'SEND_TIMEOUT',
      'RECEIVE_TIMEOUT',
    ].contains(errorCode);
  }

  // 에러가 인증 관련인지 확인
  bool get isAuthError {
    return statusCode == 401 || [
      'INVALID_CREDENTIALS',
      'TOKEN_EXPIRED',
      'UNAUTHORIZED',
    ].contains(errorCode);
  }

  // 에러가 권한 관련인지 확인
  bool get isPermissionError {
    return statusCode == 403;
  }

  // 에러가 서버 오류인지 확인
  bool get isServerError {
    return statusCode != null && statusCode! >= 500;
  }

  // 에러가 클라이언트 오류인지 확인
  bool get isClientError {
    return statusCode != null && statusCode! >= 400 && statusCode! < 500;
  }
}