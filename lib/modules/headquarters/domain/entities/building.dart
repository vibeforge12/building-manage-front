import 'package:equatable/equatable.dart';

/// 건물 엔티티
///
/// Headquarters 모듈에서 건물 관리에 사용하는 핵심 도메인 엔티티
class Building extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final String? memo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Building({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.memo,
    required this.createdAt,
    this.updatedAt,
  });

  /// JSON에서 Building 엔티티 생성
  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Building 엔티티를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (memo != null) 'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// 불변 객체 업데이트
  Building copyWith({
    String? id,
    String? name,
    String? address,
    String? imageUrl,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Building(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        memo,
        createdAt,
        updatedAt,
      ];
}
