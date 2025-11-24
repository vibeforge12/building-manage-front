import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// FCM 푸시 토큰을 서버에 등록/업데이트하는 데이터소스
class PushTokenRemoteDataSource {
  final ApiClient _apiClient;

  PushTokenRemoteDataSource(this._apiClient);

  /// 입주민(User)의 FCM 푸시 토큰 등록
  Future<void> registerUserPushToken({required String pushToken}) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.userPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ User FCM 토큰 등록 성공: ${pushToken.substring(0, 20)}...');
    } catch (e) {
      print('❌ User FCM 토큰 등록 실패: $e');
      rethrow;
    }
  }

  /// 담당자(Staff)의 FCM 푸시 토큰 등록
  Future<void> registerStaffPushToken({required String pushToken}) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.staffPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ Staff FCM 토큰 등록 성공: ${pushToken.substring(0, 20)}...');
    } catch (e) {
      print('❌ Staff FCM 토큰 등록 실패: $e');
      rethrow;
    }
  }

  /// 관리자(Manager)의 FCM 푸시 토큰 등록
  Future<void> registerManagerPushToken({required String pushToken}) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.managerPushToken,
        data: {'pushToken': pushToken},
      );
      print('✅ Manager FCM 토큰 등록 성공: ${pushToken.substring(0, 20)}...');
    } catch (e) {
      print('❌ Manager FCM 토큰 등록 실패: $e');
      rethrow;
    }
  }
}
