import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';
import 'package:building_manage_front/modules/admin/domain/entities/pagination.dart';
import 'package:building_manage_front/modules/admin/domain/repositories/complaint_repository.dart';

/// 전체 민원 조회 UseCase
class GetAllComplaintsUseCase {
  final ComplaintRepository _repository;

  GetAllComplaintsUseCase(this._repository);

  Future<PaginatedComplaintResponse> execute({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy = 'createdAt',
    String? sortOrder = 'DESC',
  }) async {
    if (page < 1) throw Exception('페이지 번호는 1 이상이어야 합니다.');
    if (limit < 1) throw Exception('페이지 크기는 1 이상이어야 합니다.');

    return await _repository.getAllComplaints(
      page: page,
      limit: limit,
      keyword: keyword,
      departmentId: departmentId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}

/// 미완료(신규) 민원 조회 UseCase
class GetPendingComplaintsUseCase {
  final ComplaintRepository _repository;

  GetPendingComplaintsUseCase(this._repository);

  Future<PaginatedComplaintResponse> execute({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy = 'createdAt',
    String? sortOrder = 'DESC',
  }) async {
    if (page < 1) throw Exception('페이지 번호는 1 이상이어야 합니다.');
    if (limit < 1) throw Exception('페이지 크기는 1 이상이어야 합니다.');

    return await _repository.getPendingComplaints(
      page: page,
      limit: limit,
      keyword: keyword,
      departmentId: departmentId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}

/// 완료된 민원 조회 UseCase
class GetResolvedComplaintsUseCase {
  final ComplaintRepository _repository;

  GetResolvedComplaintsUseCase(this._repository);

  Future<PaginatedComplaintResponse> execute({
    required int page,
    required int limit,
    String? keyword,
    String? departmentId,
    String? sortBy = 'completedAt',
    String? sortOrder = 'DESC',
  }) async {
    if (page < 1) throw Exception('페이지 번호는 1 이상이어야 합니다.');
    if (limit < 1) throw Exception('페이지 크기는 1 이상이어야 합니다.');

    return await _repository.getResolvedComplaints(
      page: page,
      limit: limit,
      keyword: keyword,
      departmentId: departmentId,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}

/// 민원 상세 조회 UseCase
class GetComplaintDetailUseCase {
  final ComplaintRepository _repository;

  GetComplaintDetailUseCase(this._repository);

  Future<AdminComplaint> execute({required String complaintId}) async {
    if (complaintId.trim().isEmpty) {
      throw Exception('민원 ID가 유효하지 않습니다.');
    }

    return await _repository.getComplaintDetail(complaintId: complaintId);
  }
}

/// 민원 상태 업데이트 UseCase
class UpdateComplaintStatusUseCase {
  final ComplaintRepository _repository;

  UpdateComplaintStatusUseCase(this._repository);

  Future<void> execute({
    required String complaintId,
    required String status,
    String? response,
  }) async {
    if (complaintId.trim().isEmpty) {
      throw Exception('민원 ID가 유효하지 않습니다.');
    }

    final validStatuses = ['PENDING', 'PROCESSING', 'COMPLETED', 'REJECTED'];
    if (!validStatuses.contains(status.toUpperCase())) {
      throw Exception('유효하지 않은 상태입니다.');
    }

    await _repository.updateComplaintStatus(
      complaintId: complaintId,
      status: status.toUpperCase(),
      response: response,
    );
  }
}
