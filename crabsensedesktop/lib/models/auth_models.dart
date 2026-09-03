/// Roles returned by CrabSenseBE (`UserRole` enum `.ToString()`).
abstract final class UserRoles {
  static const systemAdmin = 'SystemAdmin';
  static const farmOwner = 'FarmOwner';
  static const staff = 'Staff';

  static String normalize(String raw) {
    final v = raw.trim();
    switch (v.toLowerCase()) {
      case 'systemadmin':
      case 'admin':
        return systemAdmin;
      case 'farmowner':
      case 'owner':
        return farmOwner;
      case 'staff':
      case 'operator':
      case 'viewer':
      case 'sales':
        return staff;
      default:
        return v;
    }
  }

  static bool isFarmOwner(String role) => normalize(role) == farmOwner;

  static bool isSystemAdmin(String role) => normalize(role) == systemAdmin;

  static bool isStaff(String role) => normalize(role) == staff;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.username,
    this.orgId,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? username;
  final String? orgId;

  bool get isFarmOwner => UserRoles.isFarmOwner(role);
  bool get isSystemAdmin => UserRoles.isSystemAdmin(role);
  bool get isStaff => UserRoles.isStaff(role);

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final fullName = _str(json, 'fullName', 'FullName');
    final display = _str(json, 'displayName', 'DisplayName');
    final uname = _optionalStr(json, 'username', 'Username');
    return AuthUser(
      id: _str(json, 'id', 'Id'),
      email: _str(json, 'email', 'Email'),
      displayName: fullName.isNotEmpty
          ? fullName
          : (display.isNotEmpty ? display : (uname ?? 'User')),
      role: UserRoles.normalize(_str(json, 'role', 'Role', fallback: 'Staff')),
      username: uname,
      orgId: _optionalStr(json, 'orgId', 'OrgId'),
    );
  }
}

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.code,
    required this.name,
  });

  static const unassigned = FarmSummary(
    id: '',
    code: '',
    name: 'Chưa có khu nuôi',
  );

  final String id;
  final String code;
  final String name;

  bool get isUnassigned => id.isEmpty;

  factory FarmSummary.fromJson(Map<String, dynamic> json) {
    final name = _str(json, 'name', 'Name', fallback: 'Khu nuôi');
    final code = _str(json, 'code', 'Code');
    return FarmSummary(
      id: _str(json, 'id', 'Id'),
      code: code.isNotEmpty ? code : name,
      name: name,
    );
  }

  @override
  String toString() => code.isEmpty || code == name ? name : '$name ($code)';
}

class AuthMePayload {
  const AuthMePayload({
    required this.user,
    required this.farms,
    required this.isOrgAdmin,
    this.canViewAllFarms = false,
    this.defaultFarmId,
  });

  final AuthUser user;
  final List<FarmSummary> farms;
  final bool isOrgAdmin;
  final bool canViewAllFarms;
  final String? defaultFarmId;

  bool get isFarmOwner => user.isFarmOwner;

  /// CrabSenseBE `/api/auth/me` returns `UserDto` in `data` (no nested farms).
  factory AuthMePayload.fromUserDto(
    Map<String, dynamic> json, {
    List<FarmSummary> farms = const [],
  }) {
    return AuthMePayload(
      user: AuthUser.fromJson(json),
      farms: farms,
      isOrgAdmin: UserRoles.isSystemAdmin(
        _str(json, 'role', 'Role', fallback: 'Staff'),
      ),
      canViewAllFarms: UserRoles.isSystemAdmin(
        _str(json, 'role', 'Role', fallback: 'Staff'),
      ),
    );
  }

  factory AuthMePayload.fromJson(Map<String, dynamic> json) {
    final farmsRaw = json['farms'] ?? json['Farms'];
    final farms = <FarmSummary>[];
    if (farmsRaw is List) {
      for (final item in farmsRaw) {
        if (item is Map<String, dynamic>) {
          farms.add(FarmSummary.fromJson(item));
        } else if (item is Map) {
          farms.add(FarmSummary.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final userRaw = json['user'] ?? json['User'];
    if (userRaw is Map) {
      return AuthMePayload(
        user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
        farms: farms,
        isOrgAdmin: json['isOrgAdmin'] == true ||
            json['IsOrgAdmin'] == true ||
            UserRoles.isSystemAdmin(
              _str(Map<String, dynamic>.from(userRaw), 'role', 'Role'),
            ),
        canViewAllFarms: json['canViewAllFarms'] == true ||
            json['CanViewAllFarms'] == true ||
            json['isOrgAdmin'] == true ||
            json['IsOrgAdmin'] == true,
        defaultFarmId: _optionalStr(json, 'defaultFarmId', 'DefaultFarmId'),
      );
    }

    if (json['id'] != null || json['Id'] != null) {
      return AuthMePayload.fromUserDto(json, farms: farms);
    }

    throw const FormatException('auth/me: thiếu user');
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.farms,
    required this.selectedFarm,
    required this.isOrgAdmin,
    this.refreshToken,
  });

  final String token;
  final String? refreshToken;
  final AuthUser user;
  final List<FarmSummary> farms;
  final FarmSummary selectedFarm;
  final bool isOrgAdmin;

  bool get isFarmOwner => user.isFarmOwner;
  bool get canManageFarms => isFarmOwner || isOrgAdmin;

  AuthSession copyWith({
    FarmSummary? selectedFarm,
    List<FarmSummary>? farms,
  }) =>
      AuthSession(
        token: token,
        refreshToken: refreshToken,
        user: user,
        farms: farms ?? this.farms,
        selectedFarm: selectedFarm ?? this.selectedFarm,
        isOrgAdmin: isOrgAdmin,
      );
}

String _str(
  Map<String, dynamic> json,
  String a,
  String b, {
  String fallback = '',
}) {
  final v = json[a] ?? json[b];
  if (v == null) return fallback;
  return v.toString();
}

String? _optionalStr(Map<String, dynamic> json, String a, String b) {
  final v = json[a] ?? json[b];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
