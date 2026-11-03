import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/exceptions/api_exception.dart';
import '../domain/update_policy.dart';
import '../domain/update_repository.dart';

class UpdateRemoteDataSource {
  final ApiClient api;
  UpdateRemoteDataSource(this.api);
  Future<UpdatePolicy> fetch(String platform) async {
    try {
      final response = await api
          .get(
            ApiEndpoints.appUpdate,
            queryParameters: {'platform': platform},
            options: Options(receiveTimeout: const Duration(seconds: 8)),
          )
          .timeout(const Duration(seconds: 8));
      final envelope = Map<String, dynamic>.from(response.data as Map);
      return UpdatePolicy.fromJson(
        Map<String, dynamic>.from((envelope['data'] ?? envelope) as Map),
        platform,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '업데이트 정보를 확인하지 못했습니다.',
        errorCode: 'UPDATE_CHECK_FAILED',
      );
    }
  }
}

class StoredUpdateRepository implements UpdateRepository {
  final UpdateRemoteDataSource remote;
  final String environmentKey;
  StoredUpdateRepository(this.remote, this.environmentKey);
  String _key(String platform) => 'update_policy:$environmentKey:$platform';
  @override
  Future<UpdatePolicy?> cached(String platform) async {
    try {
      final value = (await SharedPreferences.getInstance()).getString(
        _key(platform),
      );
      return value == null
          ? null
          : UpdatePolicy.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
              platform,
            );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UpdatePolicy> fetch(String platform) => remote.fetch(platform);
  @override
  Future<void> save(String platform, UpdatePolicy policy) async {
    await (await SharedPreferences.getInstance()).setString(
      _key(platform),
      jsonEncode(policy.toJson(platform)),
    );
  }
}
