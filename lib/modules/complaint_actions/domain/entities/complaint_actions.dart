class ComplaintReply {
  final String id;
  final String content;
  final String? imageUrl;
  final String? imageKey;
  final int revision;
  final bool canEdit;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String authorName;
  final String authorRole;
  final String? editorName;

  const ComplaintReply({
    required this.id,
    required this.content,
    this.imageUrl,
    this.imageKey,
    required this.revision,
    required this.canEdit,
    this.createdAt,
    this.editedAt,
    required this.authorName,
    required this.authorRole,
    this.editorName,
  });

  factory ComplaintReply.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    final editor = json['lastEditor'] as Map<String, dynamic>?;
    return ComplaintReply(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      imageKey: json['imageKey'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      canEdit: json['canEdit'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      editedAt: DateTime.tryParse(json['editedAt']?.toString() ?? ''),
      authorName: author['name'] as String? ?? '',
      authorRole: author['role'] as String? ?? '',
      editorName: editor?['name'] as String?,
    );
  }

  Map<String, dynamic> toDisplayJson() => {
    'id': id,
    'content': content,
    'imageUrl': imageUrl,
    'createdAt': createdAt?.toIso8601String(),
  };
}

class ComplaintActions {
  final String complaintId;
  final bool canResolve;
  final DateTime? completedAt;
  final List<ComplaintReply> results;

  const ComplaintActions({
    required this.complaintId,
    required this.canResolve,
    this.completedAt,
    required this.results,
  });

  factory ComplaintActions.fromJson(Map<String, dynamic> json) =>
      ComplaintActions(
        complaintId: json['complaintId'] as String,
        canResolve: json['canResolve'] == true,
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
        results: List.unmodifiable(
          (json['results'] as List? ?? []).map(
            (item) =>
                ComplaintReply.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        ),
      );
}
