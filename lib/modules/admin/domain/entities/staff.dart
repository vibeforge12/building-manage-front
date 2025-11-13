import 'package:equatable/equatable.dart';

/// 담당자 상태
enum StaffStatus {
  active,    // 활성
  inactive,  // 비활성
  suspended; // 정지

  static StaffStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return StaffStatus.active;
      case 'INACTIVE':
        return StaffStatus.inactive;
      case 'SUSPENDED':
        return StaffStatus.suspended;
      default:
        return StaffStatus.active;
    }
  }

  String toServerString() {
    switch (this) {
      case StaffStatus.active:
        return 'ACTIVE';
      case StaffStatus.inactive:
        return 'INACTIVE';
      case StaffStatus.suspended:
        return 'SUSPENDED';
    }
  }
}

/// 담당자 엔티티
///
/// Admin 모듈에서 담당자 관리에 사용하는 핵심 도메인 엔티티
class Staff extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String departmentId;
  final String departmentName;
  final String? imageUrl;
  final StaffStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Staff({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.departmentId,
    required this.departmentName,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// JSON에서 Staff 엔티티 생성
  factory Staff.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;

    return Staff(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      departmentId: department?['id']?.toString() ?? '',
      departmentName: department?['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      status: StaffStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Staff 엔티티를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      'department': {
        'id': departmentId,
        'name': departmentName,
      },
      'imageUrl': imageUrl,
      'status': status.toServerString(),
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// 불변 객체 업데이트
  Staff copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? departmentId,
    String? departmentName,
    String? imageUrl,
    StaffStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        departmentId,
        departmentName,
        imageUrl,
        status,
        createdAt,
        updatedAt,
      ];
}
