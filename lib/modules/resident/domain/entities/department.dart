import 'package:equatable/equatable.dart';

/// 부서 엔티티
class Department extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String buildingId;
  final DateTime createdAt;

  const Department({
    required this.id,
    required this.name,
    this.description,
    required this.buildingId,
    required this.createdAt,
  });

  /// JSON에서 엔티티 생성
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      buildingId: json['buildingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'buildingId': buildingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, description, buildingId, createdAt];
}
