import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/exceptions/api_exception.dart';
import '../domain/entities/complaint_actions.dart';

class ComplaintActionsRemoteDataSource {
  final ApiClient _api;
  ComplaintActionsRemoteDataSource(this._api);

  Future<ComplaintActions> request(
    String complaintId, {
    String? resultId,
    Map<String, dynamic>? body,
  }) async {
    try {
      final path =
          '${ApiEndpoints.complaintActions}/${Uri.encodeComponent(complaintId)}';
      final response = body == null
          ? await _api.get(path)
          : resultId == null
          ? await _api.post('$path/resolve', data: body)
          : await _api.patch(
              '$path/results/${Uri.encodeComponent(resultId)}',
              data: body,
            );
      final envelope = Map<String, dynamic>.from(response.data as Map);
      final data = envelope['data'] is Map
          ? Map<String, dynamic>.from(envelope['data'] as Map)
          : envelope;
      return ComplaintActions.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: '민원 처리 정보를 불러오지 못했습니다.',
        errorCode: 'COMPLAINT_ACTION_FAILED',
      );
    }
  }
}
