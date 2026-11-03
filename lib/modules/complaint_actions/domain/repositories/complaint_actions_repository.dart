import '../entities/complaint_actions.dart';

abstract class ComplaintActionsRepository {
  Future<ComplaintActions> getActions(String complaintId);
  Future<ComplaintActions> resolve(
    String complaintId,
    String content,
    String? imageKey,
  );
  Future<ComplaintActions> edit(
    String complaintId,
    String resultId,
    String content,
    int expectedRevision, {
    String? imageKey,
    bool replaceImage = false,
  });
}
