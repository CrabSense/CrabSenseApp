// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  assignedFarmIds: (json['assignedFarmIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  photoUrl: json['photoUrl'] as String?,
  lastLoginAt: json['lastLoginAt'] == null
      ? null
      : DateTime.parse(json['lastLoginAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'role': _$UserRoleEnumMap[instance.role]!,
  'assignedFarmIds': instance.assignedFarmIds,
  'photoUrl': instance.photoUrl,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.farmManager: 'farmManager',
  UserRole.fieldOperator: 'fieldOperator',
  UserRole.sales: 'sales',
  UserRole.viewer: 'viewer',
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  accessTokenExpiresAt: AuthResponse._parseDateTimeOrDefault(
    json['access_token_expires_at'],
  ),
  refreshTokenExpiresAt: AuthResponse._parseDateTimeOrDefault(
    json['refresh_token_expires_at'],
  ),
);

Map<String, dynamic> _$AuthResponseToJson(
  AuthResponse instance,
) => <String, dynamic>{
  'user': instance.user.toJson(),
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'access_token_expires_at': instance.accessTokenExpiresAt.toIso8601String(),
  'refresh_token_expires_at': instance.refreshTokenExpiresAt.toIso8601String(),
};
