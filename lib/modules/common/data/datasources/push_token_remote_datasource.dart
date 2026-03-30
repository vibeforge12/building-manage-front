import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// FCM 푸시 토큰을 서버에 등록/업데이트하는 데이터소스
class PushTokenRemoteDataSource {
  final ApiClient _apiClient;

  PushTokenRemoteDataSource(this._apiClient);

  /// 요청 바디 생성 (디바이스 정보가 있으면 포함)
  Map<String, dynamic> _buildRequestBody({
    required String pushToken,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) {
    return {
      'pushToken': pushToken,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (platform != null) 'platform': platform,
    };
  }

  /// 입주민(User)의 FCM 푸시 토큰 등록
  Future<void> registerUserPushToken({
    required String pushToken,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.userPushToken,
        data: _buildRequestBody(
          pushToken: pushToken,
          deviceId: deviceId,
          deviceName: deviceName,
          platform: platform,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 담당자(Staff)의 FCM 푸시 토큰 등록
  Future<void> registerStaffPushToken({
    required String pushToken,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.staffPushToken,
        data: _buildRequestBody(
          pushToken: pushToken,
          deviceId: deviceId,
          deviceName: deviceName,
          platform: platform,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 관리자(Manager)의 FCM 푸시 토큰 등록
  Future<void> registerManagerPushToken({
    required String pushToken,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.managerPushToken,
        data: _buildRequestBody(
          pushToken: pushToken,
          deviceId: deviceId,
          deviceName: deviceName,
          platform: platform,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 본사(Headquarters)의 FCM 푸시 토큰 등록
  Future<void> registerHeadquartersPushToken({
    required String pushToken,
    String? deviceId,
    String? deviceName,
    String? platform,
  }) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.headquartersPushToken,
        data: _buildRequestBody(
          pushToken: pushToken,
          deviceId: deviceId,
          deviceName: deviceName,
          platform: platform,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
