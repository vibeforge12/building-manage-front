import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';

final complaintRemoteDataSourceProvider =
    Provider<ComplaintRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ComplaintRemoteDataSource(apiClient);
});

class ComplaintRemoteDataSource {
  final ApiClient _apiClient;

  ComplaintRemoteDataSource(this._apiClient);

  /// 민원 등록
  Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String content,
    required String departmentId,
    String? imageUrl,
  }) async {
    final response = await _apiClient.post(
      '/users/complaints',
      data: {
        'title': title,
        'content': content,
        'departmentId': departmentId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
    return response.data;
  }

  /// 내 민원 목록 조회
  /// GET /api/v1/users/complaints
  /// Parameters: page, limit, sortBy, sortOrder, isResolved, departmentId
  Future<Map<String, dynamic>> getMyComplaints({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String sortOrder = 'DESC',
    bool? isResolved,
    String? departmentId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortOrder': sortOrder,
    };
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (isResolved != null) queryParams['isResolved'] = isResolved;
    if (departmentId != null) queryParams['departmentId'] = departmentId;

    final response = await _apiClient.get(
      '/users/complaints',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// 민원 상세 조회
  Future<Map<String, dynamic>> getComplaintById(String id) async {
    final response = await _apiClient.get('/users/complaints/$id');
    return response.data;
  }
}
