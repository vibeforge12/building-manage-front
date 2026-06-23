import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/constants/api_endpoints.dart';
import 'package:building_manage_front/modules/admin/domain/entities/pagination.dart';

/// 관리자 민원 관리 RemoteDataSource
class ComplaintRemoteDataSource {
  final ApiClient _apiClient;

  ComplaintRemoteDataSource(this._apiClient);

  /// 전체 민원 조회 (페이지네이션)
  Future<PaginatedComplaintResponse> getAllComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };

      final response = await _apiClient.get(
        ApiEndpoints.managerComplaints,
        queryParameters: queryParams,
      );

      return PaginatedComplaintResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 미완료(신규) 민원 조회
  Future<PaginatedComplaintResponse> getPendingComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };

      final response = await _apiClient.get(
        ApiEndpoints.managerComplaintsPending,
        queryParameters: queryParams,
      );

      return PaginatedComplaintResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 완료된 민원 조회
  Future<PaginatedComplaintResponse> getResolvedComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };

      final response = await _apiClient.get(
        ApiEndpoints.managerComplaintsResolved,
        queryParameters: queryParams,
      );

      return PaginatedComplaintResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 민원 상세 조회
  Future<Map<String, dynamic>> getComplaintDetail({required String complaintId}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.managerComplaints}/$complaintId',
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// 이관 가능 부서 목록 조회 (본사 소속 + 해당 건물 담당자 존재)
  Future<List<Map<String, dynamic>>> getTransferableDepartments() async {
    try {
      final response = await _apiClient.get('/managers/departments');
      final data = response.data['data'] ?? response.data;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      rethrow;
    }
  }

  /// 민원 이관 (다른 부서로)
  Future<void> transferComplaint({
    required String complaintId,
    required String departmentId,
  }) async {
    try {
      await _apiClient.patch(
        '${ApiEndpoints.managerComplaints}/$complaintId/transfer',
        data: {'departmentId': departmentId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 민원 상태 업데이트
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? response,
  }) async {
    try {
      await _apiClient.put(
        '${ApiEndpoints.managerComplaints}/$complaintId/status',
        data: {
          'status': status,
          if (response != null && response.isNotEmpty) 'response': response,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// ComplaintRemoteDataSource Provider
final complaintRemoteDataSourceProvider = Provider<ComplaintRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplaintRemoteDataSource(apiClient);
});
