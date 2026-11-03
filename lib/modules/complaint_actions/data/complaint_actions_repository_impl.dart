import '../domain/entities/complaint_actions.dart';
import '../domain/repositories/complaint_actions_repository.dart';
import 'complaint_actions_remote_datasource.dart';

class ComplaintActionsRepositoryImpl implements ComplaintActionsRepository {
  final ComplaintActionsRemoteDataSource _source;
  ComplaintActionsRepositoryImpl(this._source);

  @override
  Future<ComplaintActions> getActions(String complaintId) =>
      _source.request(complaintId);

  @override
  Future<ComplaintActions> resolve(
    String complaintId,
    String content,
    String? imageKey,
  ) => _source.request(
    complaintId,
    body: {'content': content, if (imageKey != null) 'imageUrl': imageKey},
  );

  @override
  Future<ComplaintActions> edit(
    String complaintId,
    String resultId,
    String content,
    int expectedRevision, {
    String? imageKey,
    bool replaceImage = false,
  }) => _source.request(
    complaintId,
    resultId: resultId,
    body: {
      'content': content,
      'expectedRevision': expectedRevision,
      if (replaceImage) 'imageUrl': imageKey,
    },
  );
}
