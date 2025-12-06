import 'package:equatable/equatable.dart';
import 'package:building_manage_front/core/constants/user_types.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.buildingId,
    this.buildingName,
    this.buildingImageUrl,
    this.dong,
    this.ho,
    this.phoneNumber,
    this.permissions = const {},
    this.profileImageUrl,
    this.approvalStatus,
  });

  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String? buildingId;
  final String? buildingName;
  final String? buildingImageUrl;
  final String? dong;
  final String? ho;
  final String? phoneNumber;
  final Map<String, dynamic> permissions;
  final String? profileImageUrl;
  final String? approvalStatus; // PENDING, APPROVED, REJECTED

  // API 응답에서 User 객체 생성
  factory User.fromJson(Map<String, dynamic> json) {
    print('🔍 User.fromJson - Raw JSON: $json');

    UserType userType;

    // role 필드를 UserType enum으로 변환
    // 서버 role 매핑: manager=관리자, staff=담당자
    // 클라이언트에서 강제 설정하는 경우: admin, manager (legacy)
    switch (json['role'] as String?) {
      case 'headquarters':
        userType = UserType.headquarters;
        break;
      case 'admin':        // 클라이언트에서 강제 설정 (AdminLoginScreen)
      case 'manager':      // 서버 role: 'manager' → 플러터 관리자
        userType = UserType.admin;
        break;
      case 'staff':        // 서버 role: 'staff' → 플러터 담당자
        userType = UserType.manager;
        break;
      case 'resident':
      case 'user':
        userType = UserType.user;
        break;
      default:
        userType = UserType.user;
    }

    final phoneNumber = json['phoneNumber'] as String?;
    print('📞 User.fromJson - Extracted phoneNumber: $phoneNumber');

    // building 객체에서 buildingId, buildingName, buildingImageUrl 추출
    String? buildingId = json['buildingId'] as String?;
    String? buildingName;
    String? buildingImageUrl;
    if (json['building'] is Map<String, dynamic>) {
      final building = json['building'] as Map<String, dynamic>;
      buildingId ??= building['id'] as String?;
      buildingName = building['name'] as String?;
      buildingImageUrl = building['imageUrl'] as String?;
    }

    final user = User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String,
      userType: userType,
      buildingId: buildingId,
      buildingName: buildingName,
      buildingImageUrl: buildingImageUrl,
      dong: json['dong'] as String?,
      ho: json['ho'] as String?,
      phoneNumber: phoneNumber,
      permissions: (json['permissions'] as Map<String, dynamic>?) ?? {},
      profileImageUrl: json['profileImageUrl'] as String?,
      approvalStatus: json['approvalStatus'] as String?,
    );

    print('✅ User.fromJson - Created user with phoneNumber: ${user.phoneNumber}');
    return user;
  }

  // User 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': _userTypeToString(userType),
      'buildingId': buildingId,
      'buildingName': buildingName,
      'buildingImageUrl': buildingImageUrl,
      'dong': dong,
      'ho': ho,
      'phoneNumber': phoneNumber,
      'permissions': permissions,
      'profileImageUrl': profileImageUrl,
      'approvalStatus': approvalStatus,
    };
  }

  String _userTypeToString(UserType userType) {
    switch (userType) {
      case UserType.headquarters:
        return 'headquarters';
      case UserType.admin:
        return 'admin';
      case UserType.manager:
        return 'manager';
      case UserType.user:
        return 'user';
    }
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
    String? buildingId,
    String? buildingName,
    String? buildingImageUrl,
    String? dong,
    String? ho,
    String? phoneNumber,
    Map<String, dynamic>? permissions,
    String? profileImageUrl,
    String? approvalStatus,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      buildingImageUrl: buildingImageUrl ?? this.buildingImageUrl,
      dong: dong ?? this.dong,
      ho: ho ?? this.ho,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      permissions: permissions ?? this.permissions,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        userType,
        buildingId,
        buildingName,
        buildingImageUrl,
        dong,
        ho,
        phoneNumber,
        permissions,
        profileImageUrl,
        approvalStatus,
      ];
}