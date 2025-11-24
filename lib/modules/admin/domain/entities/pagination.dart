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
    // API 응답 구조: { success, data: { items, meta } }
    final responseData = json['data'] as Map<String, dynamic>?;
    final items = (responseData?['items'] as List<dynamic>?)
        ?.map((item) => AdminComplaint.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    final meta = responseData?['meta'] as Map<String, dynamic>? ?? {};

    final page = meta['page'] as int? ?? 1;
    final limit = meta['limit'] as int? ?? 20;
    final total = meta['total'] as int? ?? 0;
    final totalPages = (total / limit).ceil();

    return PaginatedComplaintResponse(
      data: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  @override
  List<Object?> get props => [data, page, limit, total, totalPages];
}
