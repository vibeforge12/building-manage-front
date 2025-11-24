import 'package:building_manage_front/modules/admin/data/datasources/complaint_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';
import 'package:building_manage_front/modules/admin/domain/entities/pagination.dart';
import 'package:building_manage_front/modules/admin/domain/repositories/complaint_repository.dart';

/// 관리자 민원 관리 레포지토리 구현
class ComplaintRepositoryImpl implements ComplaintRepository {
  final ComplaintRemoteDataSource _dataSource;

  ComplaintRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedComplaintResponse> getAllComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      return await _dataSource.getAllComplaints(
        page: page,
        limit: limit,
        keyword: keyword,
        departmentId: departmentId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedComplaintResponse> getPendingComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      return await _dataSource.getPendingComplaints(
        page: page,
        limit: limit,
        keyword: keyword,
        departmentId: departmentId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedComplaintResponse> getResolvedComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      return await _dataSource.getResolvedComplaints(
        page: page,
        limit: limit,
        keyword: keyword,
        departmentId: departmentId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AdminComplaint> getComplaintDetail({required String complaintId}) async {
    try {
      final response = await _dataSource.getComplaintDetail(complaintId: complaintId);
      // API 응답: { success, data: {...} }
      final complaintData = response['data'] as Map<String, dynamic>? ?? response;
      return AdminComplaint.fromJson(complaintData);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? response,
  }) async {
    try {
      await _dataSource.updateComplaintStatus(
        complaintId: complaintId,
        status: status,
        response: response,
      );
    } catch (e) {
      rethrow;
    }
  }
}
