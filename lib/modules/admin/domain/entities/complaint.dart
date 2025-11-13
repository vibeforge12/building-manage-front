import 'package:equatable/equatable.dart';

/// 관리자가 조회하는 민원 엔티티
class AdminComplaint extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String status; // PENDING, PROCESSING, COMPLETED, REJECTED
  final String departmentId;
  final String departmentName;
  final String residentId;
  final String residentName; // 민원자 이름
  final String residentUnit; // 민원자 동/호
  final String? response; // 처리 내용
  final String? handledBy; // 처리자 ID
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const AdminComplaint({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.status,
    required this.departmentId,
    required this.departmentName,
    required this.residentId,
    required this.residentName,
    required this.residentUnit,
    this.response,
    this.handledBy,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// JSON에서 엔티티 생성
  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    return AdminComplaint(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      departmentId: json['departmentId'] as String,
      departmentName: json['departmentName'] as String? ?? '',
      residentId: json['residentId'] as String,
      residentName: json['residentName'] as String? ?? '',
      residentUnit: json['residentUnit'] as String? ?? '',
      response: json['response'] as String?,
      handledBy: json['handledBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'status': status,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'residentId': residentId,
      'residentName': residentName,
      'residentUnit': residentUnit,
      'response': response,
      'handledBy': handledBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// 상태 문자열을 한글로 변환
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '신규';
      case 'PROCESSING':
        return '처리중';
      case 'COMPLETED':
        return '완료';
      case 'REJECTED':
        return '반려';
      default:
        return '신규';
    }
  }

  /// 완료 여부 확인
  bool get isResolved => status.toUpperCase() == 'COMPLETED';

  /// 복사본 생성
  AdminComplaint copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? status,
    String? departmentId,
    String? departmentName,
    String? residentId,
    String? residentName,
    String? residentUnit,
    String? response,
    String? handledBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return AdminComplaint(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      residentId: residentId ?? this.residentId,
      residentName: residentName ?? this.residentName,
      residentUnit: residentUnit ?? this.residentUnit,
      response: response ?? this.response,
      handledBy: handledBy ?? this.handledBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
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
        residentName,
        residentUnit,
        response,
        handledBy,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
