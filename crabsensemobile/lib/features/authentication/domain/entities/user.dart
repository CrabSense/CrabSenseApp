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

/// Canonical BE role names. Unknown is a local deny-all sentinel.
enum UserRole {
  systemAdministrator('SystemAdministrator'),
  farmAdministrator('FarmAdministrator'),
  farmManager('FarmManager'),
  farmStaff('FarmStaff'),
  unknown('Unknown');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole parse(Object? raw) => values.firstWhere(
    (role) => role != unknown && role.apiValue == raw,
    orElse: () => unknown,
  );

  // Transitional source aliases only; never accepted as wire values.
  static const admin = systemAdministrator;
  static const fieldOperator = farmStaff;
  static const viewer = unknown;
  static const sales = farmManager;
}

extension UserRoleExtension on UserRole {
  String get displayName => switch (this) {
    UserRole.systemAdministrator => 'System Administrator',
    UserRole.farmAdministrator => 'Farm Administrator',
    UserRole.farmManager => 'Farm Manager',
    UserRole.farmStaff => 'Farm Staff',
    UserRole.unknown => 'Unknown',
  };

  bool get canUseMobile => this == UserRole.farmStaff;
  bool get isAdmin => this == UserRole.systemAdministrator || this == UserRole.farmAdministrator;
  bool get canManageUsers => isAdmin || this == UserRole.farmManager;
  bool get canPerformFieldOperations => isAdmin || this == UserRole.farmManager || this == UserRole.farmStaff;
  bool get canManageSales => isAdmin || this == UserRole.farmManager;
  bool get hasWriteAccess => this != UserRole.unknown;
}
