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
  final String? responseImageUrl; // 담당자가 첨부한 응답 이미지
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
    this.responseImageUrl,
    this.handledBy,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// JSON에서 엔티티 생성
  /// API 응답 구조: { id, title, content, imageUrl, isResolved, department, resident, results, createdAt, updatedAt }
  factory AdminComplaint.fromJson(Map<String, dynamic> json) {
    // 중첩된 department 객체에서 정보 추출
    final department = json['department'] as Map<String, dynamic>? ?? {};
    final departmentId = department['id'] as String? ?? '';
    final departmentName = department['name'] as String? ?? '';

    // 중첩된 resident 객체에서 정보 추출
    final resident = json['resident'] as Map<String, dynamic>? ?? {};
    final residentId = resident['id'] as String? ?? '';
    final residentName = resident['name'] as String? ?? '';

    // 동/호수 조합 (dong: "101", hosu: "1003" → "101-1003")
    final dong = resident['dong'] as String? ?? '';
    final hosu = resident['hosu'] as String? ?? '';
    final residentUnit = [dong, hosu].where((e) => e.isNotEmpty).join('-');

    // isResolved 값으로 status 결정
    final isResolved = json['isResolved'] as bool? ?? false;
    final status = isResolved ? 'COMPLETED' : 'PENDING';

    // results 배열에서 처리 내용 추출 (가장 최신 것)
    final results = json['results'] as List<dynamic>? ?? [];
    String? response;
    String? responseImageUrl;
    if (results.isNotEmpty) {
      final latestResult = results.last as Map<String, dynamic>?;
      response = latestResult?['content'] as String?;
      responseImageUrl = latestResult?['imageUrl'] as String?;
    }

    print('✅ AdminComplaint.fromJson() 파싱 성공');
    print('   ID: ${json['id']}');
    print('   Title: ${json['title']}');
    print('   IsResolved: ${json['isResolved']}');
    print('   Response: $response');

    return AdminComplaint(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      status: status,
      departmentId: departmentId,
      departmentName: departmentName,
      residentId: residentId,
      residentName: residentName,
      residentUnit: residentUnit,
      response: response,
      responseImageUrl: responseImageUrl,
      handledBy: null, // API 응답에 없음
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: isResolved && json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
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
      'responseImageUrl': responseImageUrl,
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
    String? responseImageUrl,
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
      responseImageUrl: responseImageUrl ?? this.responseImageUrl,
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
        responseImageUrl,
        handledBy,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
