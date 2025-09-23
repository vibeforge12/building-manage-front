/// Defines the supported user roles in the building management application.
///
/// These values must stay in sync with the backend contract to ensure that
/// login responses map correctly onto the client-side experience.
enum UserRole { headquarters, buildingManager, buildingStaff, resident }

extension UserRoleParsing on UserRole {
  /// Machine-readable identifier shared with the backend.
  String get code {
    switch (this) {
      case UserRole.headquarters:
        return 'HEADQUARTERS';
      case UserRole.buildingManager:
        return 'BUILDING_MANAGER';
      case UserRole.buildingStaff:
        return 'BUILDING_STAFF';
      case UserRole.resident:
        return 'RESIDENT';
    }
  }

  /// Human-friendly label for UI presentation.
  String get label {
    switch (this) {
      case UserRole.headquarters:
        return 'Headquarters';
      case UserRole.buildingManager:
        return 'Building Manager';
      case UserRole.buildingStaff:
        return 'Building Staff';
      case UserRole.resident:
        return 'Resident';
    }
  }

  /// Whether the role has elevated management permissions.
  bool get hasManagementPrivileges {
    switch (this) {
      case UserRole.headquarters:
      case UserRole.buildingManager:
        return true;
      case UserRole.buildingStaff:
      case UserRole.resident:
        return false;
    }
  }

  /// Parses a backend code into a [UserRole]. Returns `null` if unknown.
  static UserRole? fromCode(String? code) {
    if (code == null) return null;
    final normalized = code.toUpperCase();
    for (final role in UserRole.values) {
      if (role.code == normalized) {
        return role;
      }
    }
    return null;
  }
}
