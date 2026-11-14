import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/exceptions/api_exception.dart';
import '../../domain/usecases/recover_username.dart';

class UsernameRecoveryRemoteDataSource {
  const UsernameRecoveryRemoteDataSource(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await api.post(path, data: body);
    final envelope = response.data as Map<String, dynamic>;
    if (envelope['success'] != true || envelope['data'] is! Map) {
      throw const ApiException(
        message: '아이디 찾기 정보를 확인하지 못했습니다.',
        errorCode: 'USERNAME_RECOVERY_FAILED',
      );
    }
    return Map<String, dynamic>.from(envelope['data'] as Map);
  }
}

class RemoteUsernameRecoveryRepository implements UsernameRecoveryRepository {
  const RemoteUsernameRecoveryRepository(this.source);
  final UsernameRecoveryRemoteDataSource source;

  @override
  Future<UsernameChallenge> request(String name, String phoneNumber) async {
    final data = await source.post(ApiEndpoints.usernameRecoveryRequest, {
      'name': name,
      'phoneNumber': phoneNumber,
    });
    return UsernameChallenge(
      data['challengeId'] as String,
      DateTime.parse(data['expiresAt'] as String),
      data['retryAfterSeconds'] as int,
    );
  }

  @override
  Future<List<RecoveredAccount>> verify(String challengeId, String code) async {
    final data = await source.post(ApiEndpoints.usernameRecoveryVerify, {
      'challengeId': challengeId,
      'code': code,
    });
    return (data['accounts'] as List)
        .map(
          (item) => RecoveredAccount(
            item['username'] as String,
            item['buildingName'] as String,
          ),
        )
        .toList();
  }
}

final recoverUsernameProvider = Provider<RecoverUsername>((ref) {
  return RecoverUsername(
    RemoteUsernameRecoveryRepository(
      UsernameRecoveryRemoteDataSource(ref.watch(apiClientProvider)),
    ),
  );
});
