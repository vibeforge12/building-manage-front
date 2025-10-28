import 'package:dio/dio.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _handleError(err);

    // DioException을 ApiException으로 변환
    final convertedException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
      message: apiException.message,
    );

    super.onError(convertedException, handler);
  }

  ApiException _handleError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: '연결 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.',
          statusCode: null,
          errorCode: 'CONNECTION_TIMEOUT',
        );

      case DioExceptionType.sendTimeout:
        return ApiException(
          message: '요청 전송 시간이 초과되었습니다.',
          statusCode: null,
          errorCode: 'SEND_TIMEOUT',
        );

      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: '응답 수신 시간이 초과되었습니다.',
          statusCode: null,
          errorCode: 'RECEIVE_TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(err.response!);

      case DioExceptionType.cancel:
        return ApiException(
          message: '요청이 취소되었습니다.',
          statusCode: null,
          errorCode: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: '인터넷 연결을 확인해주세요.',
          statusCode: null,
          errorCode: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          message: '보안 인증서 오류가 발생했습니다.',
          statusCode: null,
          errorCode: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          statusCode: null,
          errorCode: 'UNKNOWN_ERROR',
        );
    }
  }

  ApiException _handleBadResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final responseData = response.data;

    String message;
    String errorCode;

    // 서버에서 전달한 에러 메시지가 있는지 확인
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ??
                responseData['error'] ??
                responseData['detail'] ??
                _getDefaultErrorMessage(statusCode);

      errorCode = responseData['errorCode'] ??
                  responseData['code'] ??
                  'HTTP_$statusCode';
    } else {
      message = _getDefaultErrorMessage(statusCode);
      errorCode = 'HTTP_$statusCode';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      responseData: responseData,
    );
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다. 입력 정보를 확인해주세요.';
      case 401:
        return '인증이 필요합니다. 다시 로그인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 409:
        return '이미 존재하는 데이터입니다.';
      case 422:
        return '입력 데이터가 올바르지 않습니다.';
      case 429:
        return '너무 많은 요청입니다. 잠시 후 다시 시도해주세요.';
      case 500:
        return '서버 내부 오류가 발생했습니다. 관리자에게 문의해주세요.';
      case 502:
        return '서버 게이트웨이 오류입니다.';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다.';
      case 504:
        return '서버 응답 시간이 초과되었습니다.';
      default:
        return '알 수 없는 오류가 발생했습니다. (오류 코드: $statusCode)';
    }
  }
}