import 'package:building_manage_front/modules/resident/domain/entities/complaint.dart';

/// 민원 Repository 인터페이스
abstract class ComplaintRepository {
  /// 민원 생성
  ///
  /// [departmentId] 부서 ID
  /// [title] 민원 제목
  /// [content] 민원 내용
  /// [imageUrl] 첨부 이미지 URL (선택)
  ///
  /// Returns: 생성된 Complaint 엔티티
  /// Throws: Exception if creation fails
  Future<Complaint> createComplaint({
    required String departmentId,
    required String title,
    required String content,
    String? imageUrl,
  });

  /// 내 민원 목록 조회
  ///
  /// Returns: Complaint 리스트
  /// Throws: Exception if fetch fails
  Future<List<Complaint>> getMyComplaints();

  /// 민원 상세 조회
  ///
  /// [id] 민원 ID
  ///
  /// Returns: Complaint 엔티티
  /// Throws: Exception if not found
  Future<Complaint> getComplaintById(String id);
}
