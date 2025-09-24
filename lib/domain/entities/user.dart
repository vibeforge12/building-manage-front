import 'package:equatable/equatable.dart';
import 'package:building_manage_front/core/constants/user_types.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.buildingId,
    this.dong,
    this.ho,
    this.permissions = const {},
    this.profileImageUrl,
  });

  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String? buildingId;
  final String? dong;
  final String? ho;
  final Map<String, dynamic> permissions;
  final String? profileImageUrl;

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
    String? buildingId,
    String? dong,
    String? ho,
    Map<String, dynamic>? permissions,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      buildingId: buildingId ?? this.buildingId,
      dong: dong ?? this.dong,
      ho: ho ?? this.ho,
      permissions: permissions ?? this.permissions,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        userType,
        buildingId,
        dong,
        ho,
        permissions,
        profileImageUrl,
      ];
}