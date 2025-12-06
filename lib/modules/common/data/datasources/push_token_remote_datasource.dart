import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// FCM 푸시 토큰을 서버에 등록/업데이트하는 데이터소스
class PushTokenRemoteDataSource {
  final ApiClient _apiClient;

  PushTokenRemoteDataSource(this._apiClient);

  /// 입주민(User)의 FCM 푸시 토큰 등록
  Future<void> registerUserPushToken({required String pushToken}) async {
    print('📤 [FCM-API] registerUserPushToken 시작');
    print('📤 [FCM-API] 엔드포인트: ${ApiEndpoints.userPushToken}');
    print('📤 [FCM-API] 토큰 길이: ${pushToken.length}');
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.userPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ [FCM-API] User FCM 토큰 등록 성공!');
      print('✅ [FCM-API] 응답 상태: ${response.statusCode}');
      print('✅ [FCM-API] 토큰 앞 20자: ${pushToken.substring(0, 20)}...');
    } on DioException catch (e) {
      print('❌ [FCM-API] User FCM 토큰 등록 DioException!');
      print('❌ [FCM-API] 상태코드: ${e.response?.statusCode}');
      print('❌ [FCM-API] 응답: ${e.response?.data}');
      print('❌ [FCM-API] 메시지: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [FCM-API] User FCM 토큰 등록 일반 오류: $e');
      rethrow;
    }
  }

  /// 담당자(Staff)의 FCM 푸시 토큰 등록
  Future<void> registerStaffPushToken({required String pushToken}) async {
    print('📤 [FCM-API] registerStaffPushToken 시작');
    print('📤 [FCM-API] 엔드포인트: ${ApiEndpoints.staffPushToken}');
    print('📤 [FCM-API] 토큰 길이: ${pushToken.length}');
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.staffPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ [FCM-API] Staff FCM 토큰 등록 성공!');
      print('✅ [FCM-API] 응답 상태: ${response.statusCode}');
      print('✅ [FCM-API] 토큰 앞 20자: ${pushToken.substring(0, 20)}...');
    } on DioException catch (e) {
      print('❌ [FCM-API] Staff FCM 토큰 등록 DioException!');
      print('❌ [FCM-API] 상태코드: ${e.response?.statusCode}');
      print('❌ [FCM-API] 응답: ${e.response?.data}');
      print('❌ [FCM-API] 메시지: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [FCM-API] Staff FCM 토큰 등록 일반 오류: $e');
      rethrow;
    }
  }

  /// 관리자(Manager)의 FCM 푸시 토큰 등록
  Future<void> registerManagerPushToken({required String pushToken}) async {
    print('📤 [FCM-API] registerManagerPushToken 시작');
    print('📤 [FCM-API] 엔드포인트: ${ApiEndpoints.managerPushToken}');
    print('📤 [FCM-API] 토큰 길이: ${pushToken.length}');
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.managerPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ [FCM-API] Manager FCM 토큰 등록 성공!');
      print('✅ [FCM-API] 응답 상태: ${response.statusCode}');
      print('✅ [FCM-API] 토큰 앞 20자: ${pushToken.substring(0, 20)}...');
    } on DioException catch (e) {
      print('❌ [FCM-API] Manager FCM 토큰 등록 DioException!');
      print('❌ [FCM-API] 상태코드: ${e.response?.statusCode}');
      print('❌ [FCM-API] 응답: ${e.response?.data}');
      print('❌ [FCM-API] 메시지: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [FCM-API] Manager FCM 토큰 등록 일반 오류: $e');
      rethrow;
    }
  }

  /// 본사(Headquarters)의 FCM 푸시 토큰 등록
  Future<void> registerHeadquartersPushToken({required String pushToken}) async {
    print('📤 [FCM-API] registerHeadquartersPushToken 시작');
    print('📤 [FCM-API] 엔드포인트: ${ApiEndpoints.headquartersPushToken}');
    print('📤 [FCM-API] 토큰 길이: ${pushToken.length}');
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.headquartersPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ [FCM-API] Headquarters FCM 토큰 등록 성공!');
      print('✅ [FCM-API] 응답 상태: ${response.statusCode}');
      print('✅ [FCM-API] 토큰 앞 20자: ${pushToken.substring(0, 20)}...');
    } on DioException catch (e) {
      print('❌ [FCM-API] Headquarters FCM 토큰 등록 DioException!');
      print('❌ [FCM-API] 상태코드: ${e.response?.statusCode}');
      print('❌ [FCM-API] 응답: ${e.response?.data}');
      print('❌ [FCM-API] 메시지: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [FCM-API] Headquarters FCM 토큰 등록 일반 오류: $e');
      rethrow;
    }
  }
}
