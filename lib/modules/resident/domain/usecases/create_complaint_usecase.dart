import 'package:building_manage_front/modules/resident/domain/repositories/complaint_repository.dart';
import 'package:building_manage_front/modules/resident/domain/entities/complaint.dart';

/// 민원 생성 UseCase
///
/// 비즈니스 로직:
/// 1. 민원 데이터 유효성 검증
/// 2. Repository를 통한 민원 생성
/// 3. 생성된 Complaint 엔티티 반환
class CreateComplaintUseCase {
  final ComplaintRepository _repository;

  CreateComplaintUseCase(this._repository);

  /// 민원 생성 실행
  ///
  /// [departmentId] 부서 ID
  /// [title] 민원 제목
  /// [content] 민원 내용
  /// [imageUrl] 첨부 이미지 URL (선택)
  ///
  /// Returns: 생성된 Complaint 엔티티
  /// Throws: Exception if validation or creation fails
  Future<Complaint> execute({
    required String departmentId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (departmentId.trim().isEmpty) {
      throw Exception('부서를 선택해 주세요.');
    }

    if (title.trim().isEmpty) {
      throw Exception('제목을 입력해 주세요.');
    }

    if (title.length < 3) {
      throw Exception('제목은 최소 3자 이상이어야 합니다.');
    }

    if (title.length > 500) {
      throw Exception('제목은 500자를 초과할 수 없습니다.');
    }

    if (content.trim().isEmpty) {
      throw Exception('내용을 입력해 주세요.');
    }

    // Repository를 통한 민원 생성
    try {
      final complaint = await _repository.createComplaint(
        departmentId: departmentId.trim(),
        title: title.trim(),
        content: content.trim(),
        imageUrl: imageUrl,
      );

      return complaint;
    } catch (e) {
      rethrow;
    }
  }
}
