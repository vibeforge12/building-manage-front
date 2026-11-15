import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/check_latest_version.dart';

class RemoteAppReleaseRepository implements AppReleaseRepository {
  const RemoteAppReleaseRepository(this.api);
  final ApiClient api;

  @override
  Future<PublishedAppRelease> fetch(String platform) async {
    final response = await api
        .get(
          ApiEndpoints.latestAppRelease,
          queryParameters: {'platform': platform},
          options: Options(receiveTimeout: const Duration(seconds: 8)),
        )
        .timeout(const Duration(seconds: 8));
    final envelope = Map<String, dynamic>.from(response.data as Map);
    return PublishedAppRelease.fromJson(
      Map<String, dynamic>.from(envelope['data'] as Map),
      platform,
    );
  }
}
