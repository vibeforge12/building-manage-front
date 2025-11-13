import 'package:equatable/equatable.dart';

/// 민원 상태
enum ComplaintStatus {
  pending,    // 대기중
  processing, // 처리중
  completed,  // 완료
  rejected,   // 반려
}

/// 민원 엔티티
class Complaint extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final ComplaintStatus status;
  final String departmentId;
  final String departmentName;
  final String residentId;
  final String? response;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Complaint({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.status,
    required this.departmentId,
    required this.departmentName,
    required this.residentId,
    this.response,
    required this.createdAt,
    this.updatedAt,
  });

  /// JSON에서 엔티티 생성
  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      status: _parseStatus(json['status'] as String),
      departmentId: json['departmentId'] as String,
      departmentName: json['departmentName'] as String? ?? '',
      residentId: json['residentId'] as String,
      response: json['response'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 상태 문자열을 enum으로 변환
  static ComplaintStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return ComplaintStatus.pending;
      case 'PROCESSING':
        return ComplaintStatus.processing;
      case 'COMPLETED':
        return ComplaintStatus.completed;
      case 'REJECTED':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.pending;
    }
  }

  /// enum을 문자열로 변환
  String _statusToString() {
    switch (status) {
      case ComplaintStatus.pending:
        return 'PENDING';
      case ComplaintStatus.processing:
        return 'PROCESSING';
      case ComplaintStatus.completed:
        return 'COMPLETED';
      case ComplaintStatus.rejected:
        return 'REJECTED';
    }
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'status': _statusToString(),
      'departmentId': departmentId,
      'departmentName': departmentName,
      'residentId': residentId,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 복사본 생성
  Complaint copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    ComplaintStatus? status,
    String? departmentId,
    String? departmentName,
    String? residentId,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      residentId: residentId ?? this.residentId,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        imageUrl,
        status,
        departmentId,
        departmentName,
        residentId,
        response,
        createdAt,
        updatedAt,
      ];
}
