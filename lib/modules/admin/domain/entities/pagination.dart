import 'package:equatable/equatable.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';

/// 페이지네이션 응답 모델
class PaginatedComplaintResponse extends Equatable {
  final List<AdminComplaint> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedComplaintResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  /// JSON에서 생성
  factory PaginatedComplaintResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
        ?.map((item) => AdminComplaint.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    return PaginatedComplaintResponse(
      data: dataList,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [data, page, limit, total, totalPages];
}
