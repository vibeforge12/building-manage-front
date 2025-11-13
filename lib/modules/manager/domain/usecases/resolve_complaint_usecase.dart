import 'package:building_manage_front/modules/manager/domain/repositories/complaint_resolve_repository.dart';

class ResolveComplaintUseCase {
  final ComplaintResolveRepository _repository;

  ResolveComplaintUseCase(this._repository);

  /// 민원 처리 등록
  ///
  /// [complaintId]: 민원 ID
  /// [content]: 처리 내용 (필수, 최소 10자)
  /// [imageUrl]: 처리 결과 이미지 URL
  Future<Map<String, dynamic>> execute({
    required String complaintId,
    required String content,
    String? imageUrl,
  }) async {
    // 입력값 검증
    if (complaintId.trim().isEmpty) {
      throw Exception('민원 ID가 유효하지 않습니다.');
    }

    if (content.trim().length < 10) {
      throw Exception('처리 내용은 최소 10자 이상이어야 합니다.');
    }

    // 레포지토리를 통해 API 호출
    return await _repository.resolveComplaint(
      complaintId: complaintId,
      content: content.trim(),
      imageUrl: imageUrl,
    );
  }
}
