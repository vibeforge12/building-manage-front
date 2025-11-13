import 'package:building_manage_front/modules/resident/domain/repositories/complaint_repository.dart';
import 'package:building_manage_front/modules/resident/domain/entities/complaint.dart';
import 'package:building_manage_front/modules/resident/data/datasources/complaint_remote_datasource.dart';

/// ComplaintRepository 구현체
class ComplaintRepositoryImpl implements ComplaintRepository {
  final ComplaintRemoteDataSource _dataSource;

  ComplaintRepositoryImpl(this._dataSource);

  @override
  Future<Complaint> createComplaint({
    required String departmentId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final result = await _dataSource.createComplaint(
        departmentId: departmentId,
        title: title,
        content: content,
        imageUrl: imageUrl,
      );

      // API 응답을 Complaint 엔티티로 변환
      return Complaint.fromJson(result['data'] ?? result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Complaint>> getMyComplaints() async {
    try {
      final result = await _dataSource.getMyComplaints();
      final complaints = result['data'] as List<dynamic>? ?? [];

      return complaints
          .map((json) => Complaint.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Complaint> getComplaintById(String id) async {
    try {
      final result = await _dataSource.getComplaintById(id);
      return Complaint.fromJson(result['data'] ?? result);
    } catch (e) {
      rethrow;
    }
  }
}
