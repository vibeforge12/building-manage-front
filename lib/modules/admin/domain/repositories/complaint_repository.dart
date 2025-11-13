import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';
import 'package:building_manage_front/modules/admin/domain/entities/pagination.dart';

/// 관리자 민원 관리 레포지토리 인터페이스
abstract class ComplaintRepository {
  /// 전체 민원 조회 (페이지네이션)
  Future<PaginatedComplaintResponse> getAllComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  });

  /// 미완료 민원 조회 (신규 민원)
  Future<PaginatedComplaintResponse> getPendingComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  });

  /// 완료된 민원 조회
  Future<PaginatedComplaintResponse> getResolvedComplaints({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy,
    String? sortOrder,
  });

  /// 민원 상세 조회
  Future<AdminComplaint> getComplaintDetail({required String complaintId});

  /// 민원 처리 (상태 업데이트)
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? response,
  });
}
