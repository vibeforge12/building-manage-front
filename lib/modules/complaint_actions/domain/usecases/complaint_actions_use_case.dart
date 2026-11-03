import '../../../../core/network/exceptions/api_exception.dart';
import '../entities/complaint_actions.dart';
import '../repositories/complaint_actions_repository.dart';

class ComplaintActionsUseCase {
  final ComplaintActionsRepository _repository;
  ComplaintActionsUseCase(this._repository);

  Future<ComplaintActions> load(String complaintId) =>
      _repository.getActions(complaintId);

  Future<ComplaintActions> save({
    required String complaintId,
    required String content,
    ComplaintReply? reply,
    String? imageKey,
    bool replaceImage = false,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty || trimmed.length > 10000) {
      throw const ApiException(
        message: '처리 내용은 1자 이상 10,000자 이하로 입력해 주세요.',
        errorCode: 'INVALID_COMPLAINT_REPLY',
      );
    }
    if (reply == null) {
      return _repository.resolve(complaintId, trimmed, imageKey);
    }
    return _repository.edit(
      complaintId,
      reply.id,
      trimmed,
      reply.revision,
      imageKey: imageKey,
      replaceImage: replaceImage,
    );
  }
}
