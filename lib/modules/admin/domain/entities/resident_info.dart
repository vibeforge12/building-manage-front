import 'package:equatable/equatable.dart';

/// 입주민 상태
enum ResidentStatus {
  active,    // 활성
  inactive,  // 비활성
  pending;   // 대기

  static ResidentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return ResidentStatus.active;
      case 'INACTIVE':
        return ResidentStatus.inactive;
      case 'PENDING':
        return ResidentStatus.pending;
      default:
        return ResidentStatus.pending;
    }
  }

  String toServerString() {
    switch (this) {
      case ResidentStatus.active:
        return 'ACTIVE';
      case ResidentStatus.inactive:
        return 'INACTIVE';
      case ResidentStatus.pending:
        return 'PENDING';
    }
  }
}

/// 입주민 정보 엔티티
///
/// Admin 모듈에서 입주민 관리에 사용하는 핵심 도메인 엔티티
/// (Resident 모듈의 User 엔티티와는 별개)
class ResidentInfo extends Equatable {
  final String id;
  final String name;
  final String username;
  final String phoneNumber;
  final String dong;
  final String hosu;
  final bool isVerified;
  final ResidentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ResidentInfo({
    required this.id,
    required this.name,
    required this.username,
    required this.phoneNumber,
    required this.dong,
    required this.hosu,
    required this.isVerified,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// 호수 전체 표시 (예: "101동 1001호")
  String get fullHosu => dong.isNotEmpty ? '$dong동 $hosu호' : hosu;

  /// JSON에서 ResidentInfo 엔티티 생성
  factory ResidentInfo.fromJson(Map<String, dynamic> json) {
    return ResidentInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      dong: json['dong'] as String? ?? '',
      hosu: json['hosu'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      status: ResidentStatus.fromString(json['status'] as String? ?? 'PENDING'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// ResidentInfo 엔티티를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phoneNumber': phoneNumber,
      'dong': dong,
      'hosu': hosu,
      'isVerified': isVerified,
      'status': status.toServerString(),
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// 불변 객체 업데이트
  ResidentInfo copyWith({
    String? id,
    String? name,
    String? username,
    String? phoneNumber,
    String? dong,
    String? hosu,
    bool? isVerified,
    ResidentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResidentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dong: dong ?? this.dong,
      hosu: hosu ?? this.hosu,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        phoneNumber,
        dong,
        hosu,
        isVerified,
        status,
        createdAt,
        updatedAt,
      ];
}
