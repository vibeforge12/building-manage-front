abstract class ComplaintResolveRepository {
  /// 민원을 처리 등록
  ///
  /// [complaintId]: 민원 ID
  /// [content]: 처리 내용
  /// [imageUrl]: 처리 결과 이미지 URL
  ///
  /// 성공 시 처리 결과를 반환
  Future<Map<String, dynamic>> resolveComplaint({
    required String complaintId,
    required String content,
    String? imageUrl,
  });
}
