/// User entity representing an authenticated user in the CrabSense system.
///
/// This is a pure domain entity with no external dependencies.
/// Follows Clean Architecture principles - domain layer is framework-independent.
class User {
  /// Unique identifier for the user
  final String id;

  /// User's email address (used for login)
  final String email;

  /// User's display name
  final String name;

  /// User's role determining permissions
  final UserRole role;

  /// List of farm IDs this user is assigned to
  final List<String> assignedFarmIds;

  /// Optional URL to user's profile photo
  final String? photoUrl;

  /// Timestamp when the user account was created
  final DateTime createdAt;

  /// Timestamp of the user's last login (null if never logged in)
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.assignedFarmIds,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Getter for full name (alias for name)
  String get fullName => name;

  /// Creates a copy of this user with the given fields replaced with new values
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    List<String>? assignedFarmIds,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      assignedFarmIds: assignedFarmIds ?? this.assignedFarmIds,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        _listEquals(other.assignedFarmIds, assignedFarmIds) &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      role,
      Object.hashAll(assignedFarmIds),
      photoUrl,
      createdAt,
      lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role, '
        'assignedFarmIds: $assignedFarmIds, photoUrl: $photoUrl, '
        'createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// User roles determining access permissions in the CrabSense system.
///
/// Based on Requirement 19: Role-Based Access Control
/// - Admin: Full system access to all features
/// - Farm Manager: All Field Operator features plus user management
/// - Field Operator: Scanning, video capture, inspections, operations, harvests
/// - Sales: Sales creation, harvest viewing, inventory
/// - Viewer: Read-only access to dashboard, water quality, reports
enum UserRole {
  /// Administrator with full system permissions
  admin,

  /// Farm manager with operator features plus user management
  farmManager,

  /// Field operator with field operation permissions
  fieldOperator,

  /// Sales role with sales and inventory permissions
  sales,

  /// Viewer with read-only access
  viewer,
}

/// Extension on UserRole to provide helper methods
extension UserRoleExtension on UserRole {
  /// Returns the display name for the role
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.farmManager:
        return 'Farm Manager';
      case UserRole.fieldOperator:
        return 'Field Operator';
      case UserRole.sales:
        return 'Sales';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  /// Returns true if the role has admin privileges
  bool get isAdmin => this == UserRole.admin;

  /// Returns true if the role can manage users
  bool get canManageUsers => this == UserRole.admin || this == UserRole.farmManager;

  /// Returns true if the role can perform field operations
  bool get canPerformFieldOperations =>
      this == UserRole.admin || this == UserRole.farmManager || this == UserRole.fieldOperator;

  /// Returns true if the role can manage sales
  bool get canManageSales =>
      this == UserRole.admin || this == UserRole.farmManager || this == UserRole.sales;

  /// Returns true if the role has write access
  bool get hasWriteAccess => this != UserRole.viewer;
}
