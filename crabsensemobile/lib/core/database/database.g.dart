// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedFarmIdsMeta = const VerificationMeta(
    'assignedFarmIds',
  );
  @override
  late final GeneratedColumn<String> assignedFarmIds = GeneratedColumn<String>(
    'assigned_farm_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
    'last_login_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    name,
    role,
    assignedFarmIds,
    photoUrl,
    createdAt,
    lastLoginAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('assigned_farm_ids')) {
      context.handle(
        _assignedFarmIdsMeta,
        assignedFarmIds.isAcceptableOrUnknown(
          data['assigned_farm_ids']!,
          _assignedFarmIdsMeta,
        ),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      assignedFarmIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_farm_ids'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  /// UUID primary key.
  final String id;
  final String email;
  final String name;

  /// Role string: admin | farmManager | fieldOperator | sales | viewer
  final String role;

  /// JSON-encoded list of assigned farm IDs.
  final String assignedFarmIds;

  /// URL to the user's profile photo (nullable).
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  /// Cached at timestamp for 30-day retention policy (req 23.6).
  final DateTime cachedAt;
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.assignedFarmIds,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['assigned_farm_ids'] = Variable<String>(assignedFarmIds);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      name: Value(name),
      role: Value(role),
      assignedFarmIds: Value(assignedFarmIds),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      createdAt: Value(createdAt),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      assignedFarmIds: serializer.fromJson<String>(json['assignedFarmIds']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'assignedFarmIds': serializer.toJson<String>(assignedFarmIds),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? assignedFarmIds,
    Value<String?> photoUrl = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastLoginAt = const Value.absent(),
    DateTime? cachedAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
    role: role ?? this.role,
    assignedFarmIds: assignedFarmIds ?? this.assignedFarmIds,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      assignedFarmIds: data.assignedFarmIds.present
          ? data.assignedFarmIds.value
          : this.assignedFarmIds,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('assignedFarmIds: $assignedFarmIds, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    name,
    role,
    assignedFarmIds,
    photoUrl,
    createdAt,
    lastLoginAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.name == this.name &&
          other.role == this.role &&
          other.assignedFarmIds == this.assignedFarmIds &&
          other.photoUrl == this.photoUrl &&
          other.createdAt == this.createdAt &&
          other.lastLoginAt == this.lastLoginAt &&
          other.cachedAt == this.cachedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> name;
  final Value<String> role;
  final Value<String> assignedFarmIds;
  final Value<String?> photoUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastLoginAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.assignedFarmIds = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String email,
    required String name,
    required String role,
    this.assignedFarmIds = const Value.absent(),
    this.photoUrl = const Value.absent(),
    required DateTime createdAt,
    this.lastLoginAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       name = Value(name),
       role = Value(role),
       createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? assignedFarmIds,
    Expression<String>? photoUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastLoginAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (assignedFarmIds != null) 'assigned_farm_ids': assignedFarmIds,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? name,
    Value<String>? role,
    Value<String>? assignedFarmIds,
    Value<String?>? photoUrl,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastLoginAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      assignedFarmIds: assignedFarmIds ?? this.assignedFarmIds,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (assignedFarmIds.present) {
      map['assigned_farm_ids'] = Variable<String>(assignedFarmIds.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('assignedFarmIds: $assignedFarmIds, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoxesTable extends Boxes with TableInfo<$BoxesTable, Boxe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qrCodeMeta = const VerificationMeta('qrCode');
  @override
  late final GeneratedColumn<String> qrCode = GeneratedColumn<String>(
    'qr_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _farmIdMeta = const VerificationMeta('farmId');
  @override
  late final GeneratedColumn<String> farmId = GeneratedColumn<String>(
    'farm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pondIdMeta = const VerificationMeta('pondId');
  @override
  late final GeneratedColumn<String> pondId = GeneratedColumn<String>(
    'pond_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentCrabCountMeta = const VerificationMeta(
    'currentCrabCount',
  );
  @override
  late final GeneratedColumn<int> currentCrabCount = GeneratedColumn<int>(
    'current_crab_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
    'capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _speciesMeta = const VerificationMeta(
    'species',
  );
  @override
  late final GeneratedColumn<String> species = GeneratedColumn<String>(
    'species',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageWeightMeta = const VerificationMeta(
    'averageWeight',
  );
  @override
  late final GeneratedColumn<double> averageWeight = GeneratedColumn<double>(
    'average_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastVideoAtMeta = const VerificationMeta(
    'lastVideoAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVideoAt = GeneratedColumn<DateTime>(
    'last_video_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    qrCode,
    farmId,
    pondId,
    location,
    currentCrabCount,
    capacity,
    species,
    averageWeight,
    status,
    createdAt,
    lastVideoAt,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Boxe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('qr_code')) {
      context.handle(
        _qrCodeMeta,
        qrCode.isAcceptableOrUnknown(data['qr_code']!, _qrCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_qrCodeMeta);
    }
    if (data.containsKey('farm_id')) {
      context.handle(
        _farmIdMeta,
        farmId.isAcceptableOrUnknown(data['farm_id']!, _farmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_farmIdMeta);
    }
    if (data.containsKey('pond_id')) {
      context.handle(
        _pondIdMeta,
        pondId.isAcceptableOrUnknown(data['pond_id']!, _pondIdMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('current_crab_count')) {
      context.handle(
        _currentCrabCountMeta,
        currentCrabCount.isAcceptableOrUnknown(
          data['current_crab_count']!,
          _currentCrabCountMeta,
        ),
      );
    }
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
      );
    }
    if (data.containsKey('species')) {
      context.handle(
        _speciesMeta,
        species.isAcceptableOrUnknown(data['species']!, _speciesMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesMeta);
    }
    if (data.containsKey('average_weight')) {
      context.handle(
        _averageWeightMeta,
        averageWeight.isAcceptableOrUnknown(
          data['average_weight']!,
          _averageWeightMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_video_at')) {
      context.handle(
        _lastVideoAtMeta,
        lastVideoAt.isAcceptableOrUnknown(
          data['last_video_at']!,
          _lastVideoAtMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Boxe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Boxe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      qrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_code'],
      )!,
      farmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farm_id'],
      )!,
      pondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_id'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      currentCrabCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_crab_count'],
      )!,
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capacity'],
      )!,
      species: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species'],
      )!,
      averageWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_weight'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastVideoAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_video_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $BoxesTable createAlias(String alias) {
    return $BoxesTable(attachedDatabase, alias);
  }
}

class Boxe extends DataClass implements Insertable<Boxe> {
  final String id;
  final String qrCode;
  final String farmId;
  final String? pondId;

  /// JSON-encoded location object (latitude, longitude, label).
  final String? location;
  final int currentCrabCount;
  final int capacity;

  /// Species string: blueCrab | mudCrab | softShell
  final String species;
  final double averageWeight;

  /// Status string: active | inactive | maintenance | harvested
  final String status;
  final DateTime createdAt;
  final DateTime? lastVideoAt;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Boxe({
    required this.id,
    required this.qrCode,
    required this.farmId,
    this.pondId,
    this.location,
    required this.currentCrabCount,
    required this.capacity,
    required this.species,
    required this.averageWeight,
    required this.status,
    required this.createdAt,
    this.lastVideoAt,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['qr_code'] = Variable<String>(qrCode);
    map['farm_id'] = Variable<String>(farmId);
    if (!nullToAbsent || pondId != null) {
      map['pond_id'] = Variable<String>(pondId);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['current_crab_count'] = Variable<int>(currentCrabCount);
    map['capacity'] = Variable<int>(capacity);
    map['species'] = Variable<String>(species);
    map['average_weight'] = Variable<double>(averageWeight);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastVideoAt != null) {
      map['last_video_at'] = Variable<DateTime>(lastVideoAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  BoxesCompanion toCompanion(bool nullToAbsent) {
    return BoxesCompanion(
      id: Value(id),
      qrCode: Value(qrCode),
      farmId: Value(farmId),
      pondId: pondId == null && nullToAbsent
          ? const Value.absent()
          : Value(pondId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      currentCrabCount: Value(currentCrabCount),
      capacity: Value(capacity),
      species: Value(species),
      averageWeight: Value(averageWeight),
      status: Value(status),
      createdAt: Value(createdAt),
      lastVideoAt: lastVideoAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVideoAt),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Boxe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Boxe(
      id: serializer.fromJson<String>(json['id']),
      qrCode: serializer.fromJson<String>(json['qrCode']),
      farmId: serializer.fromJson<String>(json['farmId']),
      pondId: serializer.fromJson<String?>(json['pondId']),
      location: serializer.fromJson<String?>(json['location']),
      currentCrabCount: serializer.fromJson<int>(json['currentCrabCount']),
      capacity: serializer.fromJson<int>(json['capacity']),
      species: serializer.fromJson<String>(json['species']),
      averageWeight: serializer.fromJson<double>(json['averageWeight']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastVideoAt: serializer.fromJson<DateTime?>(json['lastVideoAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'qrCode': serializer.toJson<String>(qrCode),
      'farmId': serializer.toJson<String>(farmId),
      'pondId': serializer.toJson<String?>(pondId),
      'location': serializer.toJson<String?>(location),
      'currentCrabCount': serializer.toJson<int>(currentCrabCount),
      'capacity': serializer.toJson<int>(capacity),
      'species': serializer.toJson<String>(species),
      'averageWeight': serializer.toJson<double>(averageWeight),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastVideoAt': serializer.toJson<DateTime?>(lastVideoAt),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Boxe copyWith({
    String? id,
    String? qrCode,
    String? farmId,
    Value<String?> pondId = const Value.absent(),
    Value<String?> location = const Value.absent(),
    int? currentCrabCount,
    int? capacity,
    String? species,
    double? averageWeight,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> lastVideoAt = const Value.absent(),
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Boxe(
    id: id ?? this.id,
    qrCode: qrCode ?? this.qrCode,
    farmId: farmId ?? this.farmId,
    pondId: pondId.present ? pondId.value : this.pondId,
    location: location.present ? location.value : this.location,
    currentCrabCount: currentCrabCount ?? this.currentCrabCount,
    capacity: capacity ?? this.capacity,
    species: species ?? this.species,
    averageWeight: averageWeight ?? this.averageWeight,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    lastVideoAt: lastVideoAt.present ? lastVideoAt.value : this.lastVideoAt,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Boxe copyWithCompanion(BoxesCompanion data) {
    return Boxe(
      id: data.id.present ? data.id.value : this.id,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
      farmId: data.farmId.present ? data.farmId.value : this.farmId,
      pondId: data.pondId.present ? data.pondId.value : this.pondId,
      location: data.location.present ? data.location.value : this.location,
      currentCrabCount: data.currentCrabCount.present
          ? data.currentCrabCount.value
          : this.currentCrabCount,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      species: data.species.present ? data.species.value : this.species,
      averageWeight: data.averageWeight.present
          ? data.averageWeight.value
          : this.averageWeight,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastVideoAt: data.lastVideoAt.present
          ? data.lastVideoAt.value
          : this.lastVideoAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Boxe(')
          ..write('id: $id, ')
          ..write('qrCode: $qrCode, ')
          ..write('farmId: $farmId, ')
          ..write('pondId: $pondId, ')
          ..write('location: $location, ')
          ..write('currentCrabCount: $currentCrabCount, ')
          ..write('capacity: $capacity, ')
          ..write('species: $species, ')
          ..write('averageWeight: $averageWeight, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVideoAt: $lastVideoAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    qrCode,
    farmId,
    pondId,
    location,
    currentCrabCount,
    capacity,
    species,
    averageWeight,
    status,
    createdAt,
    lastVideoAt,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Boxe &&
          other.id == this.id &&
          other.qrCode == this.qrCode &&
          other.farmId == this.farmId &&
          other.pondId == this.pondId &&
          other.location == this.location &&
          other.currentCrabCount == this.currentCrabCount &&
          other.capacity == this.capacity &&
          other.species == this.species &&
          other.averageWeight == this.averageWeight &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.lastVideoAt == this.lastVideoAt &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class BoxesCompanion extends UpdateCompanion<Boxe> {
  final Value<String> id;
  final Value<String> qrCode;
  final Value<String> farmId;
  final Value<String?> pondId;
  final Value<String?> location;
  final Value<int> currentCrabCount;
  final Value<int> capacity;
  final Value<String> species;
  final Value<double> averageWeight;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastVideoAt;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const BoxesCompanion({
    this.id = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.farmId = const Value.absent(),
    this.pondId = const Value.absent(),
    this.location = const Value.absent(),
    this.currentCrabCount = const Value.absent(),
    this.capacity = const Value.absent(),
    this.species = const Value.absent(),
    this.averageWeight = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastVideoAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoxesCompanion.insert({
    required String id,
    required String qrCode,
    required String farmId,
    this.pondId = const Value.absent(),
    this.location = const Value.absent(),
    this.currentCrabCount = const Value.absent(),
    this.capacity = const Value.absent(),
    required String species,
    this.averageWeight = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.lastVideoAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       qrCode = Value(qrCode),
       farmId = Value(farmId),
       species = Value(species),
       createdAt = Value(createdAt);
  static Insertable<Boxe> custom({
    Expression<String>? id,
    Expression<String>? qrCode,
    Expression<String>? farmId,
    Expression<String>? pondId,
    Expression<String>? location,
    Expression<int>? currentCrabCount,
    Expression<int>? capacity,
    Expression<String>? species,
    Expression<double>? averageWeight,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastVideoAt,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (qrCode != null) 'qr_code': qrCode,
      if (farmId != null) 'farm_id': farmId,
      if (pondId != null) 'pond_id': pondId,
      if (location != null) 'location': location,
      if (currentCrabCount != null) 'current_crab_count': currentCrabCount,
      if (capacity != null) 'capacity': capacity,
      if (species != null) 'species': species,
      if (averageWeight != null) 'average_weight': averageWeight,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (lastVideoAt != null) 'last_video_at': lastVideoAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoxesCompanion copyWith({
    Value<String>? id,
    Value<String>? qrCode,
    Value<String>? farmId,
    Value<String?>? pondId,
    Value<String?>? location,
    Value<int>? currentCrabCount,
    Value<int>? capacity,
    Value<String>? species,
    Value<double>? averageWeight,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastVideoAt,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return BoxesCompanion(
      id: id ?? this.id,
      qrCode: qrCode ?? this.qrCode,
      farmId: farmId ?? this.farmId,
      pondId: pondId ?? this.pondId,
      location: location ?? this.location,
      currentCrabCount: currentCrabCount ?? this.currentCrabCount,
      capacity: capacity ?? this.capacity,
      species: species ?? this.species,
      averageWeight: averageWeight ?? this.averageWeight,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastVideoAt: lastVideoAt ?? this.lastVideoAt,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (qrCode.present) {
      map['qr_code'] = Variable<String>(qrCode.value);
    }
    if (farmId.present) {
      map['farm_id'] = Variable<String>(farmId.value);
    }
    if (pondId.present) {
      map['pond_id'] = Variable<String>(pondId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (currentCrabCount.present) {
      map['current_crab_count'] = Variable<int>(currentCrabCount.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (species.present) {
      map['species'] = Variable<String>(species.value);
    }
    if (averageWeight.present) {
      map['average_weight'] = Variable<double>(averageWeight.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastVideoAt.present) {
      map['last_video_at'] = Variable<DateTime>(lastVideoAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoxesCompanion(')
          ..write('id: $id, ')
          ..write('qrCode: $qrCode, ')
          ..write('farmId: $farmId, ')
          ..write('pondId: $pondId, ')
          ..write('location: $location, ')
          ..write('currentCrabCount: $currentCrabCount, ')
          ..write('capacity: $capacity, ')
          ..write('species: $species, ')
          ..write('averageWeight: $averageWeight, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVideoAt: $lastVideoAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CrabsTable extends Crabs with TableInfo<$CrabsTable, Crab> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CrabsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<String> boxId = GeneratedColumn<String>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boxes (id)',
    ),
  );
  static const VerificationMeta _speciesMeta = const VerificationMeta(
    'species',
  );
  @override
  late final GeneratedColumn<String> species = GeneratedColumn<String>(
    'species',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _moltingStatusMeta = const VerificationMeta(
    'moltingStatus',
  );
  @override
  late final GeneratedColumn<String> moltingStatus = GeneratedColumn<String>(
    'molting_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthStatusMeta = const VerificationMeta(
    'healthStatus',
  );
  @override
  late final GeneratedColumn<String> healthStatus = GeneratedColumn<String>(
    'health_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedByMeta = const VerificationMeta(
    'addedBy',
  );
  @override
  late final GeneratedColumn<String> addedBy = GeneratedColumn<String>(
    'added_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boxId,
    species,
    weight,
    moltingStatus,
    healthStatus,
    source,
    addedAt,
    addedBy,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crabs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Crab> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('species')) {
      context.handle(
        _speciesMeta,
        species.isAcceptableOrUnknown(data['species']!, _speciesMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('molting_status')) {
      context.handle(
        _moltingStatusMeta,
        moltingStatus.isAcceptableOrUnknown(
          data['molting_status']!,
          _moltingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_moltingStatusMeta);
    }
    if (data.containsKey('health_status')) {
      context.handle(
        _healthStatusMeta,
        healthStatus.isAcceptableOrUnknown(
          data['health_status']!,
          _healthStatusMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('added_by')) {
      context.handle(
        _addedByMeta,
        addedBy.isAcceptableOrUnknown(data['added_by']!, _addedByMeta),
      );
    } else if (isInserting) {
      context.missing(_addedByMeta);
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Crab map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Crab(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_id'],
      )!,
      species: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      moltingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}molting_status'],
      )!,
      healthStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      addedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_by'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CrabsTable createAlias(String alias) {
    return $CrabsTable(attachedDatabase, alias);
  }
}

class Crab extends DataClass implements Insertable<Crab> {
  final String id;

  /// Foreign key → boxes.id
  final String boxId;

  /// Species: blueCrab | mudCrab | softShell
  final String species;
  final double weight;

  /// Molting status: preMolt | molting | postMolt | hardShell
  final String moltingStatus;

  /// Health status: normal | disease | stress | unknown
  final String healthStatus;

  /// Source of the crab: farm | purchase | transfer
  final String source;
  final DateTime addedAt;

  /// Operator user ID who added this crab record.
  final String addedBy;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Crab({
    required this.id,
    required this.boxId,
    required this.species,
    required this.weight,
    required this.moltingStatus,
    required this.healthStatus,
    required this.source,
    required this.addedAt,
    required this.addedBy,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['box_id'] = Variable<String>(boxId);
    map['species'] = Variable<String>(species);
    map['weight'] = Variable<double>(weight);
    map['molting_status'] = Variable<String>(moltingStatus);
    map['health_status'] = Variable<String>(healthStatus);
    map['source'] = Variable<String>(source);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['added_by'] = Variable<String>(addedBy);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CrabsCompanion toCompanion(bool nullToAbsent) {
    return CrabsCompanion(
      id: Value(id),
      boxId: Value(boxId),
      species: Value(species),
      weight: Value(weight),
      moltingStatus: Value(moltingStatus),
      healthStatus: Value(healthStatus),
      source: Value(source),
      addedAt: Value(addedAt),
      addedBy: Value(addedBy),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Crab.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Crab(
      id: serializer.fromJson<String>(json['id']),
      boxId: serializer.fromJson<String>(json['boxId']),
      species: serializer.fromJson<String>(json['species']),
      weight: serializer.fromJson<double>(json['weight']),
      moltingStatus: serializer.fromJson<String>(json['moltingStatus']),
      healthStatus: serializer.fromJson<String>(json['healthStatus']),
      source: serializer.fromJson<String>(json['source']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      addedBy: serializer.fromJson<String>(json['addedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boxId': serializer.toJson<String>(boxId),
      'species': serializer.toJson<String>(species),
      'weight': serializer.toJson<double>(weight),
      'moltingStatus': serializer.toJson<String>(moltingStatus),
      'healthStatus': serializer.toJson<String>(healthStatus),
      'source': serializer.toJson<String>(source),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'addedBy': serializer.toJson<String>(addedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Crab copyWith({
    String? id,
    String? boxId,
    String? species,
    double? weight,
    String? moltingStatus,
    String? healthStatus,
    String? source,
    DateTime? addedAt,
    String? addedBy,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Crab(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    species: species ?? this.species,
    weight: weight ?? this.weight,
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    source: source ?? this.source,
    addedAt: addedAt ?? this.addedAt,
    addedBy: addedBy ?? this.addedBy,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Crab copyWithCompanion(CrabsCompanion data) {
    return Crab(
      id: data.id.present ? data.id.value : this.id,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      species: data.species.present ? data.species.value : this.species,
      weight: data.weight.present ? data.weight.value : this.weight,
      moltingStatus: data.moltingStatus.present
          ? data.moltingStatus.value
          : this.moltingStatus,
      healthStatus: data.healthStatus.present
          ? data.healthStatus.value
          : this.healthStatus,
      source: data.source.present ? data.source.value : this.source,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      addedBy: data.addedBy.present ? data.addedBy.value : this.addedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Crab(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('species: $species, ')
          ..write('weight: $weight, ')
          ..write('moltingStatus: $moltingStatus, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('source: $source, ')
          ..write('addedAt: $addedAt, ')
          ..write('addedBy: $addedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    species,
    weight,
    moltingStatus,
    healthStatus,
    source,
    addedAt,
    addedBy,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Crab &&
          other.id == this.id &&
          other.boxId == this.boxId &&
          other.species == this.species &&
          other.weight == this.weight &&
          other.moltingStatus == this.moltingStatus &&
          other.healthStatus == this.healthStatus &&
          other.source == this.source &&
          other.addedAt == this.addedAt &&
          other.addedBy == this.addedBy &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class CrabsCompanion extends UpdateCompanion<Crab> {
  final Value<String> id;
  final Value<String> boxId;
  final Value<String> species;
  final Value<double> weight;
  final Value<String> moltingStatus;
  final Value<String> healthStatus;
  final Value<String> source;
  final Value<DateTime> addedAt;
  final Value<String> addedBy;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CrabsCompanion({
    this.id = const Value.absent(),
    this.boxId = const Value.absent(),
    this.species = const Value.absent(),
    this.weight = const Value.absent(),
    this.moltingStatus = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.source = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.addedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CrabsCompanion.insert({
    required String id,
    required String boxId,
    required String species,
    this.weight = const Value.absent(),
    required String moltingStatus,
    this.healthStatus = const Value.absent(),
    required String source,
    required DateTime addedAt,
    required String addedBy,
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boxId = Value(boxId),
       species = Value(species),
       moltingStatus = Value(moltingStatus),
       source = Value(source),
       addedAt = Value(addedAt),
       addedBy = Value(addedBy);
  static Insertable<Crab> custom({
    Expression<String>? id,
    Expression<String>? boxId,
    Expression<String>? species,
    Expression<double>? weight,
    Expression<String>? moltingStatus,
    Expression<String>? healthStatus,
    Expression<String>? source,
    Expression<DateTime>? addedAt,
    Expression<String>? addedBy,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boxId != null) 'box_id': boxId,
      if (species != null) 'species': species,
      if (weight != null) 'weight': weight,
      if (moltingStatus != null) 'molting_status': moltingStatus,
      if (healthStatus != null) 'health_status': healthStatus,
      if (source != null) 'source': source,
      if (addedAt != null) 'added_at': addedAt,
      if (addedBy != null) 'added_by': addedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CrabsCompanion copyWith({
    Value<String>? id,
    Value<String>? boxId,
    Value<String>? species,
    Value<double>? weight,
    Value<String>? moltingStatus,
    Value<String>? healthStatus,
    Value<String>? source,
    Value<DateTime>? addedAt,
    Value<String>? addedBy,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CrabsCompanion(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      species: species ?? this.species,
      weight: weight ?? this.weight,
      moltingStatus: moltingStatus ?? this.moltingStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<String>(boxId.value);
    }
    if (species.present) {
      map['species'] = Variable<String>(species.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (moltingStatus.present) {
      map['molting_status'] = Variable<String>(moltingStatus.value);
    }
    if (healthStatus.present) {
      map['health_status'] = Variable<String>(healthStatus.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (addedBy.present) {
      map['added_by'] = Variable<String>(addedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CrabsCompanion(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('species: $species, ')
          ..write('weight: $weight, ')
          ..write('moltingStatus: $moltingStatus, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('source: $source, ')
          ..write('addedAt: $addedAt, ')
          ..write('addedBy: $addedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaterQualityReadingsTable extends WaterQualityReadings
    with TableInfo<$WaterQualityReadingsTable, WaterQualityReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterQualityReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sensorIdMeta = const VerificationMeta(
    'sensorId',
  );
  @override
  late final GeneratedColumn<String> sensorId = GeneratedColumn<String>(
    'sensor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _farmIdMeta = const VerificationMeta('farmId');
  @override
  late final GeneratedColumn<String> farmId = GeneratedColumn<String>(
    'farm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pondIdMeta = const VerificationMeta('pondId');
  @override
  late final GeneratedColumn<String> pondId = GeneratedColumn<String>(
    'pond_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
    'ph',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dissolvedOxygenMeta = const VerificationMeta(
    'dissolvedOxygen',
  );
  @override
  late final GeneratedColumn<double> dissolvedOxygen = GeneratedColumn<double>(
    'dissolved_oxygen',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _salinityMeta = const VerificationMeta(
    'salinity',
  );
  @override
  late final GeneratedColumn<double> salinity = GeneratedColumn<double>(
    'salinity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAlertTriggeredMeta = const VerificationMeta(
    'isAlertTriggered',
  );
  @override
  late final GeneratedColumn<bool> isAlertTriggered = GeneratedColumn<bool>(
    'is_alert_triggered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alert_triggered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sensorId,
    farmId,
    pondId,
    temperature,
    ph,
    dissolvedOxygen,
    salinity,
    timestamp,
    isAlertTriggered,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_quality_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterQualityReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sensor_id')) {
      context.handle(
        _sensorIdMeta,
        sensorId.isAcceptableOrUnknown(data['sensor_id']!, _sensorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sensorIdMeta);
    }
    if (data.containsKey('farm_id')) {
      context.handle(
        _farmIdMeta,
        farmId.isAcceptableOrUnknown(data['farm_id']!, _farmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_farmIdMeta);
    }
    if (data.containsKey('pond_id')) {
      context.handle(
        _pondIdMeta,
        pondId.isAcceptableOrUnknown(data['pond_id']!, _pondIdMeta),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    }
    if (data.containsKey('dissolved_oxygen')) {
      context.handle(
        _dissolvedOxygenMeta,
        dissolvedOxygen.isAcceptableOrUnknown(
          data['dissolved_oxygen']!,
          _dissolvedOxygenMeta,
        ),
      );
    }
    if (data.containsKey('salinity')) {
      context.handle(
        _salinityMeta,
        salinity.isAcceptableOrUnknown(data['salinity']!, _salinityMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_alert_triggered')) {
      context.handle(
        _isAlertTriggeredMeta,
        isAlertTriggered.isAcceptableOrUnknown(
          data['is_alert_triggered']!,
          _isAlertTriggeredMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterQualityReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterQualityReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sensorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sensor_id'],
      )!,
      farmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farm_id'],
      )!,
      pondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_id'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      ph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph'],
      )!,
      dissolvedOxygen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dissolved_oxygen'],
      )!,
      salinity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salinity'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      isAlertTriggered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alert_triggered'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $WaterQualityReadingsTable createAlias(String alias) {
    return $WaterQualityReadingsTable(attachedDatabase, alias);
  }
}

class WaterQualityReading extends DataClass
    implements Insertable<WaterQualityReading> {
  final String id;
  final String sensorId;
  final String farmId;
  final String? pondId;

  /// Temperature in Celsius (26–30 optimal range).
  final double temperature;

  /// pH level (7.5–8.5 optimal range).
  final double ph;

  /// Dissolved oxygen in mg/L (minimum 5.0).
  final double dissolvedOxygen;

  /// Salinity in ppt (15–25 optimal range).
  final double salinity;
  final DateTime timestamp;
  final bool isAlertTriggered;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const WaterQualityReading({
    required this.id,
    required this.sensorId,
    required this.farmId,
    this.pondId,
    required this.temperature,
    required this.ph,
    required this.dissolvedOxygen,
    required this.salinity,
    required this.timestamp,
    required this.isAlertTriggered,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sensor_id'] = Variable<String>(sensorId);
    map['farm_id'] = Variable<String>(farmId);
    if (!nullToAbsent || pondId != null) {
      map['pond_id'] = Variable<String>(pondId);
    }
    map['temperature'] = Variable<double>(temperature);
    map['ph'] = Variable<double>(ph);
    map['dissolved_oxygen'] = Variable<double>(dissolvedOxygen);
    map['salinity'] = Variable<double>(salinity);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_alert_triggered'] = Variable<bool>(isAlertTriggered);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  WaterQualityReadingsCompanion toCompanion(bool nullToAbsent) {
    return WaterQualityReadingsCompanion(
      id: Value(id),
      sensorId: Value(sensorId),
      farmId: Value(farmId),
      pondId: pondId == null && nullToAbsent
          ? const Value.absent()
          : Value(pondId),
      temperature: Value(temperature),
      ph: Value(ph),
      dissolvedOxygen: Value(dissolvedOxygen),
      salinity: Value(salinity),
      timestamp: Value(timestamp),
      isAlertTriggered: Value(isAlertTriggered),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory WaterQualityReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterQualityReading(
      id: serializer.fromJson<String>(json['id']),
      sensorId: serializer.fromJson<String>(json['sensorId']),
      farmId: serializer.fromJson<String>(json['farmId']),
      pondId: serializer.fromJson<String?>(json['pondId']),
      temperature: serializer.fromJson<double>(json['temperature']),
      ph: serializer.fromJson<double>(json['ph']),
      dissolvedOxygen: serializer.fromJson<double>(json['dissolvedOxygen']),
      salinity: serializer.fromJson<double>(json['salinity']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isAlertTriggered: serializer.fromJson<bool>(json['isAlertTriggered']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sensorId': serializer.toJson<String>(sensorId),
      'farmId': serializer.toJson<String>(farmId),
      'pondId': serializer.toJson<String?>(pondId),
      'temperature': serializer.toJson<double>(temperature),
      'ph': serializer.toJson<double>(ph),
      'dissolvedOxygen': serializer.toJson<double>(dissolvedOxygen),
      'salinity': serializer.toJson<double>(salinity),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isAlertTriggered': serializer.toJson<bool>(isAlertTriggered),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  WaterQualityReading copyWith({
    String? id,
    String? sensorId,
    String? farmId,
    Value<String?> pondId = const Value.absent(),
    double? temperature,
    double? ph,
    double? dissolvedOxygen,
    double? salinity,
    DateTime? timestamp,
    bool? isAlertTriggered,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => WaterQualityReading(
    id: id ?? this.id,
    sensorId: sensorId ?? this.sensorId,
    farmId: farmId ?? this.farmId,
    pondId: pondId.present ? pondId.value : this.pondId,
    temperature: temperature ?? this.temperature,
    ph: ph ?? this.ph,
    dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
    salinity: salinity ?? this.salinity,
    timestamp: timestamp ?? this.timestamp,
    isAlertTriggered: isAlertTriggered ?? this.isAlertTriggered,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  WaterQualityReading copyWithCompanion(WaterQualityReadingsCompanion data) {
    return WaterQualityReading(
      id: data.id.present ? data.id.value : this.id,
      sensorId: data.sensorId.present ? data.sensorId.value : this.sensorId,
      farmId: data.farmId.present ? data.farmId.value : this.farmId,
      pondId: data.pondId.present ? data.pondId.value : this.pondId,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      ph: data.ph.present ? data.ph.value : this.ph,
      dissolvedOxygen: data.dissolvedOxygen.present
          ? data.dissolvedOxygen.value
          : this.dissolvedOxygen,
      salinity: data.salinity.present ? data.salinity.value : this.salinity,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isAlertTriggered: data.isAlertTriggered.present
          ? data.isAlertTriggered.value
          : this.isAlertTriggered,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterQualityReading(')
          ..write('id: $id, ')
          ..write('sensorId: $sensorId, ')
          ..write('farmId: $farmId, ')
          ..write('pondId: $pondId, ')
          ..write('temperature: $temperature, ')
          ..write('ph: $ph, ')
          ..write('dissolvedOxygen: $dissolvedOxygen, ')
          ..write('salinity: $salinity, ')
          ..write('timestamp: $timestamp, ')
          ..write('isAlertTriggered: $isAlertTriggered, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sensorId,
    farmId,
    pondId,
    temperature,
    ph,
    dissolvedOxygen,
    salinity,
    timestamp,
    isAlertTriggered,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterQualityReading &&
          other.id == this.id &&
          other.sensorId == this.sensorId &&
          other.farmId == this.farmId &&
          other.pondId == this.pondId &&
          other.temperature == this.temperature &&
          other.ph == this.ph &&
          other.dissolvedOxygen == this.dissolvedOxygen &&
          other.salinity == this.salinity &&
          other.timestamp == this.timestamp &&
          other.isAlertTriggered == this.isAlertTriggered &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class WaterQualityReadingsCompanion
    extends UpdateCompanion<WaterQualityReading> {
  final Value<String> id;
  final Value<String> sensorId;
  final Value<String> farmId;
  final Value<String?> pondId;
  final Value<double> temperature;
  final Value<double> ph;
  final Value<double> dissolvedOxygen;
  final Value<double> salinity;
  final Value<DateTime> timestamp;
  final Value<bool> isAlertTriggered;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const WaterQualityReadingsCompanion({
    this.id = const Value.absent(),
    this.sensorId = const Value.absent(),
    this.farmId = const Value.absent(),
    this.pondId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.ph = const Value.absent(),
    this.dissolvedOxygen = const Value.absent(),
    this.salinity = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isAlertTriggered = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterQualityReadingsCompanion.insert({
    required String id,
    required String sensorId,
    required String farmId,
    this.pondId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.ph = const Value.absent(),
    this.dissolvedOxygen = const Value.absent(),
    this.salinity = const Value.absent(),
    required DateTime timestamp,
    this.isAlertTriggered = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sensorId = Value(sensorId),
       farmId = Value(farmId),
       timestamp = Value(timestamp);
  static Insertable<WaterQualityReading> custom({
    Expression<String>? id,
    Expression<String>? sensorId,
    Expression<String>? farmId,
    Expression<String>? pondId,
    Expression<double>? temperature,
    Expression<double>? ph,
    Expression<double>? dissolvedOxygen,
    Expression<double>? salinity,
    Expression<DateTime>? timestamp,
    Expression<bool>? isAlertTriggered,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sensorId != null) 'sensor_id': sensorId,
      if (farmId != null) 'farm_id': farmId,
      if (pondId != null) 'pond_id': pondId,
      if (temperature != null) 'temperature': temperature,
      if (ph != null) 'ph': ph,
      if (dissolvedOxygen != null) 'dissolved_oxygen': dissolvedOxygen,
      if (salinity != null) 'salinity': salinity,
      if (timestamp != null) 'timestamp': timestamp,
      if (isAlertTriggered != null) 'is_alert_triggered': isAlertTriggered,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterQualityReadingsCompanion copyWith({
    Value<String>? id,
    Value<String>? sensorId,
    Value<String>? farmId,
    Value<String?>? pondId,
    Value<double>? temperature,
    Value<double>? ph,
    Value<double>? dissolvedOxygen,
    Value<double>? salinity,
    Value<DateTime>? timestamp,
    Value<bool>? isAlertTriggered,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return WaterQualityReadingsCompanion(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      farmId: farmId ?? this.farmId,
      pondId: pondId ?? this.pondId,
      temperature: temperature ?? this.temperature,
      ph: ph ?? this.ph,
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      salinity: salinity ?? this.salinity,
      timestamp: timestamp ?? this.timestamp,
      isAlertTriggered: isAlertTriggered ?? this.isAlertTriggered,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sensorId.present) {
      map['sensor_id'] = Variable<String>(sensorId.value);
    }
    if (farmId.present) {
      map['farm_id'] = Variable<String>(farmId.value);
    }
    if (pondId.present) {
      map['pond_id'] = Variable<String>(pondId.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (dissolvedOxygen.present) {
      map['dissolved_oxygen'] = Variable<double>(dissolvedOxygen.value);
    }
    if (salinity.present) {
      map['salinity'] = Variable<double>(salinity.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isAlertTriggered.present) {
      map['is_alert_triggered'] = Variable<bool>(isAlertTriggered.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterQualityReadingsCompanion(')
          ..write('id: $id, ')
          ..write('sensorId: $sensorId, ')
          ..write('farmId: $farmId, ')
          ..write('pondId: $pondId, ')
          ..write('temperature: $temperature, ')
          ..write('ph: $ph, ')
          ..write('dissolvedOxygen: $dissolvedOxygen, ')
          ..write('salinity: $salinity, ')
          ..write('timestamp: $timestamp, ')
          ..write('isAlertTriggered: $isAlertTriggered, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedActionsMeta =
      const VerificationMeta('recommendedActions');
  @override
  late final GeneratedColumn<String> recommendedActions =
      GeneratedColumn<String>(
        'recommended_actions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgedAtMeta = const VerificationMeta(
    'acknowledgedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acknowledgedAt =
      GeneratedColumn<DateTime>(
        'acknowledged_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _acknowledgedByMeta = const VerificationMeta(
    'acknowledgedBy',
  );
  @override
  late final GeneratedColumn<String> acknowledgedBy = GeneratedColumn<String>(
    'acknowledged_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unread'),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    severity,
    title,
    message,
    sourceId,
    sourceType,
    recommendedActions,
    createdAt,
    acknowledgedAt,
    acknowledgedBy,
    status,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('recommended_actions')) {
      context.handle(
        _recommendedActionsMeta,
        recommendedActions.isAcceptableOrUnknown(
          data['recommended_actions']!,
          _recommendedActionsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
        _acknowledgedAtMeta,
        acknowledgedAt.isAcceptableOrUnknown(
          data['acknowledged_at']!,
          _acknowledgedAtMeta,
        ),
      );
    }
    if (data.containsKey('acknowledged_by')) {
      context.handle(
        _acknowledgedByMeta,
        acknowledgedBy.isAcceptableOrUnknown(
          data['acknowledged_by']!,
          _acknowledgedByMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      ),
      recommendedActions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_actions'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      acknowledgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acknowledged_at'],
      ),
      acknowledgedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acknowledged_by'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }
}

class Alert extends DataClass implements Insertable<Alert> {
  final String id;

  /// Alert type: waterQuality | equipment | crabHealth | maintenance | task | system
  final String type;

  /// Severity: critical | warning | info
  final String severity;
  final String title;
  final String message;

  /// Optional ID of the source entity (box_id, sensor_id, etc.).
  final String? sourceId;

  /// Type of the source entity: box | sensor | system
  final String? sourceType;

  /// JSON-encoded list of recommended action strings.
  final String recommendedActions;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  /// Status: unread | read | acknowledged | dismissed
  final String status;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.sourceId,
    this.sourceType,
    required this.recommendedActions,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    required this.status,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    map['recommended_actions'] = Variable<String>(recommendedActions);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt);
    }
    if (!nullToAbsent || acknowledgedBy != null) {
      map['acknowledged_by'] = Variable<String>(acknowledgedBy);
    }
    map['status'] = Variable<String>(status);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      type: Value(type),
      severity: Value(severity),
      title: Value(title),
      message: Value(message),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      recommendedActions: Value(recommendedActions),
      createdAt: Value(createdAt),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
      acknowledgedBy: acknowledgedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedBy),
      status: Value(status),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Alert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      recommendedActions: serializer.fromJson<String>(
        json['recommendedActions'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      acknowledgedAt: serializer.fromJson<DateTime?>(json['acknowledgedAt']),
      acknowledgedBy: serializer.fromJson<String?>(json['acknowledgedBy']),
      status: serializer.fromJson<String>(json['status']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'sourceId': serializer.toJson<String?>(sourceId),
      'sourceType': serializer.toJson<String?>(sourceType),
      'recommendedActions': serializer.toJson<String>(recommendedActions),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'acknowledgedAt': serializer.toJson<DateTime?>(acknowledgedAt),
      'acknowledgedBy': serializer.toJson<String?>(acknowledgedBy),
      'status': serializer.toJson<String>(status),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Alert copyWith({
    String? id,
    String? type,
    String? severity,
    String? title,
    String? message,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> sourceType = const Value.absent(),
    String? recommendedActions,
    DateTime? createdAt,
    Value<DateTime?> acknowledgedAt = const Value.absent(),
    Value<String?> acknowledgedBy = const Value.absent(),
    String? status,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Alert(
    id: id ?? this.id,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    message: message ?? this.message,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    sourceType: sourceType.present ? sourceType.value : this.sourceType,
    recommendedActions: recommendedActions ?? this.recommendedActions,
    createdAt: createdAt ?? this.createdAt,
    acknowledgedAt: acknowledgedAt.present
        ? acknowledgedAt.value
        : this.acknowledgedAt,
    acknowledgedBy: acknowledgedBy.present
        ? acknowledgedBy.value
        : this.acknowledgedBy,
    status: status ?? this.status,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Alert copyWithCompanion(AlertsCompanion data) {
    return Alert(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      recommendedActions: data.recommendedActions.present
          ? data.recommendedActions.value
          : this.recommendedActions,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
      acknowledgedBy: data.acknowledgedBy.present
          ? data.acknowledgedBy.value
          : this.acknowledgedBy,
      status: data.status.present ? data.status.value : this.status,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceType: $sourceType, ')
          ..write('recommendedActions: $recommendedActions, ')
          ..write('createdAt: $createdAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('acknowledgedBy: $acknowledgedBy, ')
          ..write('status: $status, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    severity,
    title,
    message,
    sourceId,
    sourceType,
    recommendedActions,
    createdAt,
    acknowledgedAt,
    acknowledgedBy,
    status,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.id == this.id &&
          other.type == this.type &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.message == this.message &&
          other.sourceId == this.sourceId &&
          other.sourceType == this.sourceType &&
          other.recommendedActions == this.recommendedActions &&
          other.createdAt == this.createdAt &&
          other.acknowledgedAt == this.acknowledgedAt &&
          other.acknowledgedBy == this.acknowledgedBy &&
          other.status == this.status &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class AlertsCompanion extends UpdateCompanion<Alert> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> severity;
  final Value<String> title;
  final Value<String> message;
  final Value<String?> sourceId;
  final Value<String?> sourceType;
  final Value<String> recommendedActions;
  final Value<DateTime> createdAt;
  final Value<DateTime?> acknowledgedAt;
  final Value<String?> acknowledgedBy;
  final Value<String> status;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.recommendedActions = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.acknowledgedBy = const Value.absent(),
    this.status = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsCompanion.insert({
    required String id,
    required String type,
    required String severity,
    required String title,
    required String message,
    this.sourceId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.recommendedActions = const Value.absent(),
    required DateTime createdAt,
    this.acknowledgedAt = const Value.absent(),
    this.acknowledgedBy = const Value.absent(),
    this.status = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       severity = Value(severity),
       title = Value(title),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<Alert> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? sourceId,
    Expression<String>? sourceType,
    Expression<String>? recommendedActions,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? acknowledgedAt,
    Expression<String>? acknowledgedBy,
    Expression<String>? status,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceType != null) 'source_type': sourceType,
      if (recommendedActions != null) 'recommended_actions': recommendedActions,
      if (createdAt != null) 'created_at': createdAt,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
      if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
      if (status != null) 'status': status,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? severity,
    Value<String>? title,
    Value<String>? message,
    Value<String?>? sourceId,
    Value<String?>? sourceType,
    Value<String>? recommendedActions,
    Value<DateTime>? createdAt,
    Value<DateTime?>? acknowledgedAt,
    Value<String?>? acknowledgedBy,
    Value<String>? status,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      status: status ?? this.status,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (recommendedActions.present) {
      map['recommended_actions'] = Variable<String>(recommendedActions.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt.value);
    }
    if (acknowledgedBy.present) {
      map['acknowledged_by'] = Variable<String>(acknowledgedBy.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceType: $sourceType, ')
          ..write('recommendedActions: $recommendedActions, ')
          ..write('createdAt: $createdAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('acknowledgedBy: $acknowledgedBy, ')
          ..write('status: $status, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperationLogsTable extends OperationLogs
    with TableInfo<$OperationLogsTable, OperationLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIdsMeta = const VerificationMeta('boxIds');
  @override
  late final GeneratedColumn<String> boxIds = GeneratedColumn<String>(
    'box_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoUrlsMeta = const VerificationMeta(
    'photoUrls',
  );
  @override
  late final GeneratedColumn<String> photoUrls = GeneratedColumn<String>(
    'photo_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorIdMeta = const VerificationMeta(
    'operatorId',
  );
  @override
  late final GeneratedColumn<String> operatorId = GeneratedColumn<String>(
    'operator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorNameMeta = const VerificationMeta(
    'operatorName',
  );
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
    'operator_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    boxIds,
    quantity,
    unit,
    notes,
    photoUrls,
    timestamp,
    operatorId,
    operatorName,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operation_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperationLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('box_ids')) {
      context.handle(
        _boxIdsMeta,
        boxIds.isAcceptableOrUnknown(data['box_ids']!, _boxIdsMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photo_urls')) {
      context.handle(
        _photoUrlsMeta,
        photoUrls.isAcceptableOrUnknown(data['photo_urls']!, _photoUrlsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('operator_id')) {
      context.handle(
        _operatorIdMeta,
        operatorId.isAcceptableOrUnknown(data['operator_id']!, _operatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_operatorIdMeta);
    }
    if (data.containsKey('operator_name')) {
      context.handle(
        _operatorNameMeta,
        operatorName.isAcceptableOrUnknown(
          data['operator_name']!,
          _operatorNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operatorNameMeta);
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OperationLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperationLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      boxIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_ids'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      photoUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_urls'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      operatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_id'],
      )!,
      operatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_name'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $OperationLogsTable createAlias(String alias) {
    return $OperationLogsTable(attachedDatabase, alias);
  }
}

class OperationLog extends DataClass implements Insertable<OperationLog> {
  final String id;

  /// Operation type: feeding | waterChange | mineralAddition |
  ///                  cleaning | medication | inspection
  final String type;

  /// JSON-encoded list of box IDs this operation applies to.
  final String boxIds;
  final double? quantity;
  final String? unit;
  final String notes;

  /// JSON-encoded list of photo URL strings.
  final String photoUrls;
  final DateTime timestamp;
  final String operatorId;
  final String operatorName;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const OperationLog({
    required this.id,
    required this.type,
    required this.boxIds,
    this.quantity,
    this.unit,
    required this.notes,
    required this.photoUrls,
    required this.timestamp,
    required this.operatorId,
    required this.operatorName,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['box_ids'] = Variable<String>(boxIds);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['notes'] = Variable<String>(notes);
    map['photo_urls'] = Variable<String>(photoUrls);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['operator_id'] = Variable<String>(operatorId);
    map['operator_name'] = Variable<String>(operatorName);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  OperationLogsCompanion toCompanion(bool nullToAbsent) {
    return OperationLogsCompanion(
      id: Value(id),
      type: Value(type),
      boxIds: Value(boxIds),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      notes: Value(notes),
      photoUrls: Value(photoUrls),
      timestamp: Value(timestamp),
      operatorId: Value(operatorId),
      operatorName: Value(operatorName),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory OperationLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperationLog(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      boxIds: serializer.fromJson<String>(json['boxIds']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      notes: serializer.fromJson<String>(json['notes']),
      photoUrls: serializer.fromJson<String>(json['photoUrls']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      operatorId: serializer.fromJson<String>(json['operatorId']),
      operatorName: serializer.fromJson<String>(json['operatorName']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'boxIds': serializer.toJson<String>(boxIds),
      'quantity': serializer.toJson<double?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'notes': serializer.toJson<String>(notes),
      'photoUrls': serializer.toJson<String>(photoUrls),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'operatorId': serializer.toJson<String>(operatorId),
      'operatorName': serializer.toJson<String>(operatorName),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  OperationLog copyWith({
    String? id,
    String? type,
    String? boxIds,
    Value<double?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    String? notes,
    String? photoUrls,
    DateTime? timestamp,
    String? operatorId,
    String? operatorName,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => OperationLog(
    id: id ?? this.id,
    type: type ?? this.type,
    boxIds: boxIds ?? this.boxIds,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    notes: notes ?? this.notes,
    photoUrls: photoUrls ?? this.photoUrls,
    timestamp: timestamp ?? this.timestamp,
    operatorId: operatorId ?? this.operatorId,
    operatorName: operatorName ?? this.operatorName,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  OperationLog copyWithCompanion(OperationLogsCompanion data) {
    return OperationLog(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      boxIds: data.boxIds.present ? data.boxIds.value : this.boxIds,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoUrls: data.photoUrls.present ? data.photoUrls.value : this.photoUrls,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      operatorId: data.operatorId.present
          ? data.operatorId.value
          : this.operatorId,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperationLog(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('boxIds: $boxIds, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('notes: $notes, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('timestamp: $timestamp, ')
          ..write('operatorId: $operatorId, ')
          ..write('operatorName: $operatorName, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    boxIds,
    quantity,
    unit,
    notes,
    photoUrls,
    timestamp,
    operatorId,
    operatorName,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperationLog &&
          other.id == this.id &&
          other.type == this.type &&
          other.boxIds == this.boxIds &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.notes == this.notes &&
          other.photoUrls == this.photoUrls &&
          other.timestamp == this.timestamp &&
          other.operatorId == this.operatorId &&
          other.operatorName == this.operatorName &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class OperationLogsCompanion extends UpdateCompanion<OperationLog> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> boxIds;
  final Value<double?> quantity;
  final Value<String?> unit;
  final Value<String> notes;
  final Value<String> photoUrls;
  final Value<DateTime> timestamp;
  final Value<String> operatorId;
  final Value<String> operatorName;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const OperationLogsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.boxIds = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrls = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.operatorId = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperationLogsCompanion.insert({
    required String id,
    required String type,
    this.boxIds = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrls = const Value.absent(),
    required DateTime timestamp,
    required String operatorId,
    required String operatorName,
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       timestamp = Value(timestamp),
       operatorId = Value(operatorId),
       operatorName = Value(operatorName);
  static Insertable<OperationLog> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? boxIds,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? notes,
    Expression<String>? photoUrls,
    Expression<DateTime>? timestamp,
    Expression<String>? operatorId,
    Expression<String>? operatorName,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (boxIds != null) 'box_ids': boxIds,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (notes != null) 'notes': notes,
      if (photoUrls != null) 'photo_urls': photoUrls,
      if (timestamp != null) 'timestamp': timestamp,
      if (operatorId != null) 'operator_id': operatorId,
      if (operatorName != null) 'operator_name': operatorName,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperationLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? boxIds,
    Value<double?>? quantity,
    Value<String?>? unit,
    Value<String>? notes,
    Value<String>? photoUrls,
    Value<DateTime>? timestamp,
    Value<String>? operatorId,
    Value<String>? operatorName,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return OperationLogsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      boxIds: boxIds ?? this.boxIds,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      timestamp: timestamp ?? this.timestamp,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (boxIds.present) {
      map['box_ids'] = Variable<String>(boxIds.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoUrls.present) {
      map['photo_urls'] = Variable<String>(photoUrls.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (operatorId.present) {
      map['operator_id'] = Variable<String>(operatorId.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationLogsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('boxIds: $boxIds, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('notes: $notes, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('timestamp: $timestamp, ')
          ..write('operatorId: $operatorId, ')
          ..write('operatorName: $operatorName, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HarvestsTable extends Harvests with TableInfo<$HarvestsTable, Harvest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HarvestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<String> boxId = GeneratedColumn<String>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boxes (id)',
    ),
  );
  static const VerificationMeta _totalWeightMeta = const VerificationMeta(
    'totalWeight',
  );
  @override
  late final GeneratedColumn<double> totalWeight = GeneratedColumn<double>(
    'total_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _crabCountMeta = const VerificationMeta(
    'crabCount',
  );
  @override
  late final GeneratedColumn<int> crabCount = GeneratedColumn<int>(
    'crab_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qualityGradeMeta = const VerificationMeta(
    'qualityGrade',
  );
  @override
  late final GeneratedColumn<String> qualityGrade = GeneratedColumn<String>(
    'quality_grade',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _harvestDateMeta = const VerificationMeta(
    'harvestDate',
  );
  @override
  late final GeneratedColumn<DateTime> harvestDate = GeneratedColumn<DateTime>(
    'harvest_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _harvestedByMeta = const VerificationMeta(
    'harvestedBy',
  );
  @override
  late final GeneratedColumn<String> harvestedBy = GeneratedColumn<String>(
    'harvested_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlsMeta = const VerificationMeta(
    'photoUrls',
  );
  @override
  late final GeneratedColumn<String> photoUrls = GeneratedColumn<String>(
    'photo_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boxId,
    totalWeight,
    crabCount,
    qualityGrade,
    harvestDate,
    harvestedBy,
    destination,
    photoUrls,
    notes,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'harvests';
  @override
  VerificationContext validateIntegrity(
    Insertable<Harvest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('total_weight')) {
      context.handle(
        _totalWeightMeta,
        totalWeight.isAcceptableOrUnknown(
          data['total_weight']!,
          _totalWeightMeta,
        ),
      );
    }
    if (data.containsKey('crab_count')) {
      context.handle(
        _crabCountMeta,
        crabCount.isAcceptableOrUnknown(data['crab_count']!, _crabCountMeta),
      );
    }
    if (data.containsKey('quality_grade')) {
      context.handle(
        _qualityGradeMeta,
        qualityGrade.isAcceptableOrUnknown(
          data['quality_grade']!,
          _qualityGradeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualityGradeMeta);
    }
    if (data.containsKey('harvest_date')) {
      context.handle(
        _harvestDateMeta,
        harvestDate.isAcceptableOrUnknown(
          data['harvest_date']!,
          _harvestDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_harvestDateMeta);
    }
    if (data.containsKey('harvested_by')) {
      context.handle(
        _harvestedByMeta,
        harvestedBy.isAcceptableOrUnknown(
          data['harvested_by']!,
          _harvestedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_harvestedByMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('photo_urls')) {
      context.handle(
        _photoUrlsMeta,
        photoUrls.isAcceptableOrUnknown(data['photo_urls']!, _photoUrlsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Harvest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Harvest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_id'],
      )!,
      totalWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_weight'],
      )!,
      crabCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}crab_count'],
      )!,
      qualityGrade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_grade'],
      )!,
      harvestDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}harvest_date'],
      )!,
      harvestedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}harvested_by'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      photoUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_urls'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $HarvestsTable createAlias(String alias) {
    return $HarvestsTable(attachedDatabase, alias);
  }
}

class Harvest extends DataClass implements Insertable<Harvest> {
  final String id;

  /// Foreign key → boxes.id
  final String boxId;

  /// Total weight in kg.
  final double totalWeight;
  final int crabCount;

  /// Quality grade: gradeA | gradeB | gradeC
  final String qualityGrade;
  final DateTime harvestDate;
  final String harvestedBy;
  final String? destination;

  /// JSON-encoded list of photo URL strings.
  final String photoUrls;
  final String notes;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Harvest({
    required this.id,
    required this.boxId,
    required this.totalWeight,
    required this.crabCount,
    required this.qualityGrade,
    required this.harvestDate,
    required this.harvestedBy,
    this.destination,
    required this.photoUrls,
    required this.notes,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['box_id'] = Variable<String>(boxId);
    map['total_weight'] = Variable<double>(totalWeight);
    map['crab_count'] = Variable<int>(crabCount);
    map['quality_grade'] = Variable<String>(qualityGrade);
    map['harvest_date'] = Variable<DateTime>(harvestDate);
    map['harvested_by'] = Variable<String>(harvestedBy);
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    map['photo_urls'] = Variable<String>(photoUrls);
    map['notes'] = Variable<String>(notes);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  HarvestsCompanion toCompanion(bool nullToAbsent) {
    return HarvestsCompanion(
      id: Value(id),
      boxId: Value(boxId),
      totalWeight: Value(totalWeight),
      crabCount: Value(crabCount),
      qualityGrade: Value(qualityGrade),
      harvestDate: Value(harvestDate),
      harvestedBy: Value(harvestedBy),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      photoUrls: Value(photoUrls),
      notes: Value(notes),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Harvest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Harvest(
      id: serializer.fromJson<String>(json['id']),
      boxId: serializer.fromJson<String>(json['boxId']),
      totalWeight: serializer.fromJson<double>(json['totalWeight']),
      crabCount: serializer.fromJson<int>(json['crabCount']),
      qualityGrade: serializer.fromJson<String>(json['qualityGrade']),
      harvestDate: serializer.fromJson<DateTime>(json['harvestDate']),
      harvestedBy: serializer.fromJson<String>(json['harvestedBy']),
      destination: serializer.fromJson<String?>(json['destination']),
      photoUrls: serializer.fromJson<String>(json['photoUrls']),
      notes: serializer.fromJson<String>(json['notes']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boxId': serializer.toJson<String>(boxId),
      'totalWeight': serializer.toJson<double>(totalWeight),
      'crabCount': serializer.toJson<int>(crabCount),
      'qualityGrade': serializer.toJson<String>(qualityGrade),
      'harvestDate': serializer.toJson<DateTime>(harvestDate),
      'harvestedBy': serializer.toJson<String>(harvestedBy),
      'destination': serializer.toJson<String?>(destination),
      'photoUrls': serializer.toJson<String>(photoUrls),
      'notes': serializer.toJson<String>(notes),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Harvest copyWith({
    String? id,
    String? boxId,
    double? totalWeight,
    int? crabCount,
    String? qualityGrade,
    DateTime? harvestDate,
    String? harvestedBy,
    Value<String?> destination = const Value.absent(),
    String? photoUrls,
    String? notes,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Harvest(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    totalWeight: totalWeight ?? this.totalWeight,
    crabCount: crabCount ?? this.crabCount,
    qualityGrade: qualityGrade ?? this.qualityGrade,
    harvestDate: harvestDate ?? this.harvestDate,
    harvestedBy: harvestedBy ?? this.harvestedBy,
    destination: destination.present ? destination.value : this.destination,
    photoUrls: photoUrls ?? this.photoUrls,
    notes: notes ?? this.notes,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Harvest copyWithCompanion(HarvestsCompanion data) {
    return Harvest(
      id: data.id.present ? data.id.value : this.id,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      totalWeight: data.totalWeight.present
          ? data.totalWeight.value
          : this.totalWeight,
      crabCount: data.crabCount.present ? data.crabCount.value : this.crabCount,
      qualityGrade: data.qualityGrade.present
          ? data.qualityGrade.value
          : this.qualityGrade,
      harvestDate: data.harvestDate.present
          ? data.harvestDate.value
          : this.harvestDate,
      harvestedBy: data.harvestedBy.present
          ? data.harvestedBy.value
          : this.harvestedBy,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      photoUrls: data.photoUrls.present ? data.photoUrls.value : this.photoUrls,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Harvest(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('crabCount: $crabCount, ')
          ..write('qualityGrade: $qualityGrade, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('harvestedBy: $harvestedBy, ')
          ..write('destination: $destination, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('notes: $notes, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    totalWeight,
    crabCount,
    qualityGrade,
    harvestDate,
    harvestedBy,
    destination,
    photoUrls,
    notes,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Harvest &&
          other.id == this.id &&
          other.boxId == this.boxId &&
          other.totalWeight == this.totalWeight &&
          other.crabCount == this.crabCount &&
          other.qualityGrade == this.qualityGrade &&
          other.harvestDate == this.harvestDate &&
          other.harvestedBy == this.harvestedBy &&
          other.destination == this.destination &&
          other.photoUrls == this.photoUrls &&
          other.notes == this.notes &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class HarvestsCompanion extends UpdateCompanion<Harvest> {
  final Value<String> id;
  final Value<String> boxId;
  final Value<double> totalWeight;
  final Value<int> crabCount;
  final Value<String> qualityGrade;
  final Value<DateTime> harvestDate;
  final Value<String> harvestedBy;
  final Value<String?> destination;
  final Value<String> photoUrls;
  final Value<String> notes;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const HarvestsCompanion({
    this.id = const Value.absent(),
    this.boxId = const Value.absent(),
    this.totalWeight = const Value.absent(),
    this.crabCount = const Value.absent(),
    this.qualityGrade = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.harvestedBy = const Value.absent(),
    this.destination = const Value.absent(),
    this.photoUrls = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HarvestsCompanion.insert({
    required String id,
    required String boxId,
    this.totalWeight = const Value.absent(),
    this.crabCount = const Value.absent(),
    required String qualityGrade,
    required DateTime harvestDate,
    required String harvestedBy,
    this.destination = const Value.absent(),
    this.photoUrls = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boxId = Value(boxId),
       qualityGrade = Value(qualityGrade),
       harvestDate = Value(harvestDate),
       harvestedBy = Value(harvestedBy);
  static Insertable<Harvest> custom({
    Expression<String>? id,
    Expression<String>? boxId,
    Expression<double>? totalWeight,
    Expression<int>? crabCount,
    Expression<String>? qualityGrade,
    Expression<DateTime>? harvestDate,
    Expression<String>? harvestedBy,
    Expression<String>? destination,
    Expression<String>? photoUrls,
    Expression<String>? notes,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boxId != null) 'box_id': boxId,
      if (totalWeight != null) 'total_weight': totalWeight,
      if (crabCount != null) 'crab_count': crabCount,
      if (qualityGrade != null) 'quality_grade': qualityGrade,
      if (harvestDate != null) 'harvest_date': harvestDate,
      if (harvestedBy != null) 'harvested_by': harvestedBy,
      if (destination != null) 'destination': destination,
      if (photoUrls != null) 'photo_urls': photoUrls,
      if (notes != null) 'notes': notes,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HarvestsCompanion copyWith({
    Value<String>? id,
    Value<String>? boxId,
    Value<double>? totalWeight,
    Value<int>? crabCount,
    Value<String>? qualityGrade,
    Value<DateTime>? harvestDate,
    Value<String>? harvestedBy,
    Value<String?>? destination,
    Value<String>? photoUrls,
    Value<String>? notes,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return HarvestsCompanion(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      totalWeight: totalWeight ?? this.totalWeight,
      crabCount: crabCount ?? this.crabCount,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      harvestDate: harvestDate ?? this.harvestDate,
      harvestedBy: harvestedBy ?? this.harvestedBy,
      destination: destination ?? this.destination,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<String>(boxId.value);
    }
    if (totalWeight.present) {
      map['total_weight'] = Variable<double>(totalWeight.value);
    }
    if (crabCount.present) {
      map['crab_count'] = Variable<int>(crabCount.value);
    }
    if (qualityGrade.present) {
      map['quality_grade'] = Variable<String>(qualityGrade.value);
    }
    if (harvestDate.present) {
      map['harvest_date'] = Variable<DateTime>(harvestDate.value);
    }
    if (harvestedBy.present) {
      map['harvested_by'] = Variable<String>(harvestedBy.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (photoUrls.present) {
      map['photo_urls'] = Variable<String>(photoUrls.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HarvestsCompanion(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('crabCount: $crabCount, ')
          ..write('qualityGrade: $qualityGrade, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('harvestedBy: $harvestedBy, ')
          ..write('destination: $destination, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('notes: $notes, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyerNameMeta = const VerificationMeta(
    'buyerName',
  );
  @override
  late final GeneratedColumn<String> buyerName = GeneratedColumn<String>(
    'buyer_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyerContactMeta = const VerificationMeta(
    'buyerContact',
  );
  @override
  late final GeneratedColumn<String> buyerContact = GeneratedColumn<String>(
    'buyer_contact',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _saleDateMeta = const VerificationMeta(
    'saleDate',
  );
  @override
  late final GeneratedColumn<DateTime> saleDate = GeneratedColumn<DateTime>(
    'sale_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    buyerName,
    buyerContact,
    quantity,
    unitPrice,
    totalAmount,
    paymentMethod,
    paymentStatus,
    saleDate,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('buyer_name')) {
      context.handle(
        _buyerNameMeta,
        buyerName.isAcceptableOrUnknown(data['buyer_name']!, _buyerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_buyerNameMeta);
    }
    if (data.containsKey('buyer_contact')) {
      context.handle(
        _buyerContactMeta,
        buyerContact.isAcceptableOrUnknown(
          data['buyer_contact']!,
          _buyerContactMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('sale_date')) {
      context.handle(
        _saleDateMeta,
        saleDate.isAcceptableOrUnknown(data['sale_date']!, _saleDateMeta),
      );
    } else if (isInserting) {
      context.missing(_saleDateMeta);
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      buyerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buyer_name'],
      )!,
      buyerContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buyer_contact'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      saleDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sale_date'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;

  /// Unique transaction identifier generated at creation.
  final String transactionId;
  final String buyerName;
  final String? buyerContact;

  /// Quantity in kg.
  final double quantity;
  final double unitPrice;
  final double totalAmount;

  /// Payment method: cash | bankTransfer | credit
  final String paymentMethod;

  /// Payment status: pending | completed | cancelled
  final String paymentStatus;
  final DateTime saleDate;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Sale({
    required this.id,
    required this.transactionId,
    required this.buyerName,
    this.buyerContact,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.saleDate,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['buyer_name'] = Variable<String>(buyerName);
    if (!nullToAbsent || buyerContact != null) {
      map['buyer_contact'] = Variable<String>(buyerContact);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['total_amount'] = Variable<double>(totalAmount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['sale_date'] = Variable<DateTime>(saleDate);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      buyerName: Value(buyerName),
      buyerContact: buyerContact == null && nullToAbsent
          ? const Value.absent()
          : Value(buyerContact),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      totalAmount: Value(totalAmount),
      paymentMethod: Value(paymentMethod),
      paymentStatus: Value(paymentStatus),
      saleDate: Value(saleDate),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      buyerName: serializer.fromJson<String>(json['buyerName']),
      buyerContact: serializer.fromJson<String?>(json['buyerContact']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      saleDate: serializer.fromJson<DateTime>(json['saleDate']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'buyerName': serializer.toJson<String>(buyerName),
      'buyerContact': serializer.toJson<String?>(buyerContact),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'saleDate': serializer.toJson<DateTime>(saleDate),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Sale copyWith({
    String? id,
    String? transactionId,
    String? buyerName,
    Value<String?> buyerContact = const Value.absent(),
    double? quantity,
    double? unitPrice,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? saleDate,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Sale(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    buyerName: buyerName ?? this.buyerName,
    buyerContact: buyerContact.present ? buyerContact.value : this.buyerContact,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    totalAmount: totalAmount ?? this.totalAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    saleDate: saleDate ?? this.saleDate,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      buyerName: data.buyerName.present ? data.buyerName.value : this.buyerName,
      buyerContact: data.buyerContact.present
          ? data.buyerContact.value
          : this.buyerContact,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      saleDate: data.saleDate.present ? data.saleDate.value : this.saleDate,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('buyerName: $buyerName, ')
          ..write('buyerContact: $buyerContact, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('saleDate: $saleDate, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    buyerName,
    buyerContact,
    quantity,
    unitPrice,
    totalAmount,
    paymentMethod,
    paymentStatus,
    saleDate,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.buyerName == this.buyerName &&
          other.buyerContact == this.buyerContact &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.totalAmount == this.totalAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentStatus == this.paymentStatus &&
          other.saleDate == this.saleDate &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> buyerName;
  final Value<String?> buyerContact;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<double> totalAmount;
  final Value<String> paymentMethod;
  final Value<String> paymentStatus;
  final Value<DateTime> saleDate;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.buyerName = const Value.absent(),
    this.buyerContact = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.saleDate = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    required String transactionId,
    required String buyerName,
    this.buyerContact = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.totalAmount = const Value.absent(),
    required String paymentMethod,
    this.paymentStatus = const Value.absent(),
    required DateTime saleDate,
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       buyerName = Value(buyerName),
       paymentMethod = Value(paymentMethod),
       saleDate = Value(saleDate);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? buyerName,
    Expression<String>? buyerContact,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? totalAmount,
    Expression<String>? paymentMethod,
    Expression<String>? paymentStatus,
    Expression<DateTime>? saleDate,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (buyerName != null) 'buyer_name': buyerName,
      if (buyerContact != null) 'buyer_contact': buyerContact,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (saleDate != null) 'sale_date': saleDate,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? buyerName,
    Value<String?>? buyerContact,
    Value<double>? quantity,
    Value<double>? unitPrice,
    Value<double>? totalAmount,
    Value<String>? paymentMethod,
    Value<String>? paymentStatus,
    Value<DateTime>? saleDate,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return SalesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact ?? this.buyerContact,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      saleDate: saleDate ?? this.saleDate,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (buyerName.present) {
      map['buyer_name'] = Variable<String>(buyerName.value);
    }
    if (buyerContact.present) {
      map['buyer_contact'] = Variable<String>(buyerContact.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (saleDate.present) {
      map['sale_date'] = Variable<DateTime>(saleDate.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('buyerName: $buyerName, ')
          ..write('buyerContact: $buyerContact, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('saleDate: $saleDate, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    entityId,
    entityType,
    payload,
    createdAt,
    retryCount,
    status,
    priority,
    lastAttemptAt,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;

  /// Operation type string, e.g. "create_harvest", "acknowledge_alert".
  final String operationType;

  /// ID of the entity this operation targets.
  final String entityId;

  /// Entity type: box | crab | alert | operationLog | harvest | sale | inspection
  final String entityType;

  /// JSON-encoded payload of the operation.
  final String payload;
  final DateTime createdAt;

  /// Number of failed sync attempts so far.
  final int retryCount;

  /// Queue item status: pending | processing | failed | completed
  final String status;

  /// Priority level — higher numbers are processed first within
  /// the same batch. Maps to data priorities in design section 4.1:
  ///   3 = critical (alerts, water quality thresholds)
  ///   2 = high     (harvests, sales, AI results)
  ///   1 = medium   (operation logs, inspections)
  ///   0 = low      (analytics, historical data)
  final int priority;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  const SyncQueueData({
    required this.id,
    required this.operationType,
    required this.entityId,
    required this.entityType,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    required this.priority,
    this.lastAttemptAt,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operationType: Value(operationType),
      entityId: Value(entityId),
      entityType: Value(entityType),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      priority: Value(priority),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationType': serializer.toJson<String>(operationType),
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? operationType,
    String? entityId,
    String? entityType,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    String? status,
    int? priority,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    entityId,
    entityType,
    payload,
    createdAt,
    retryCount,
    status,
    priority,
    lastAttemptAt,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.errorMessage == this.errorMessage);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> operationType;
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<int> priority;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String operationType,
    required String entityId,
    required String entityType,
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationType = Value(operationType),
       entityId = Value(entityId),
       entityType = Value(entityType),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? operationType,
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? operationType,
    Value<String>? entityId,
    Value<String>? entityType,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String>? status,
    Value<int>? priority,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VideosTable extends Videos with TableInfo<$VideosTable, Video> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<String> boxId = GeneratedColumn<String>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boxes (id)',
    ),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedByMeta = const VerificationMeta(
    'capturedBy',
  );
  @override
  late final GeneratedColumn<String> capturedBy = GeneratedColumn<String>(
    'captured_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadedAtMeta = const VerificationMeta(
    'uploadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
    'uploaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiDetectionIdMeta = const VerificationMeta(
    'aiDetectionId',
  );
  @override
  late final GeneratedColumn<String> aiDetectionId = GeneratedColumn<String>(
    'ai_detection_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boxId,
    localPath,
    durationSeconds,
    fileSizeBytes,
    status,
    capturedAt,
    capturedBy,
    uploadedAt,
    aiDetectionId,
    retryCount,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Video> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('captured_by')) {
      context.handle(
        _capturedByMeta,
        capturedBy.isAcceptableOrUnknown(data['captured_by']!, _capturedByMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedByMeta);
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
        _uploadedAtMeta,
        uploadedAt.isAcceptableOrUnknown(data['uploaded_at']!, _uploadedAtMeta),
      );
    }
    if (data.containsKey('ai_detection_id')) {
      context.handle(
        _aiDetectionIdMeta,
        aiDetectionId.isAcceptableOrUnknown(
          data['ai_detection_id']!,
          _aiDetectionIdMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Video map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Video(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      capturedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}captured_by'],
      )!,
      uploadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}uploaded_at'],
      ),
      aiDetectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_detection_id'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }
}

class Video extends DataClass implements Insertable<Video> {
  final String id;

  /// Foreign key → boxes.id
  final String boxId;

  /// Absolute path to the video file on device storage.
  final String localPath;

  /// Duration of the recording in seconds (5–10 valid range).
  final int durationSeconds;

  /// Compressed file size in bytes; null until compression completes.
  final int? fileSizeBytes;

  /// Upload status: pending | uploading | uploaded | failed
  final String status;
  final DateTime capturedAt;

  /// Identifier of the field operator who recorded this video.
  final String capturedBy;

  /// Timestamp when the upload completed; null until uploaded.
  final DateTime? uploadedAt;

  /// ID of the [AIDetection] result; null until analysis is complete.
  final String? aiDetectionId;

  /// Number of failed upload attempts for exponential back-off (Req 6.10).
  final int retryCount;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Video({
    required this.id,
    required this.boxId,
    required this.localPath,
    required this.durationSeconds,
    this.fileSizeBytes,
    required this.status,
    required this.capturedAt,
    required this.capturedBy,
    this.uploadedAt,
    this.aiDetectionId,
    required this.retryCount,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['box_id'] = Variable<String>(boxId);
    map['local_path'] = Variable<String>(localPath);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    map['status'] = Variable<String>(status);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['captured_by'] = Variable<String>(capturedBy);
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    }
    if (!nullToAbsent || aiDetectionId != null) {
      map['ai_detection_id'] = Variable<String>(aiDetectionId);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      id: Value(id),
      boxId: Value(boxId),
      localPath: Value(localPath),
      durationSeconds: Value(durationSeconds),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      status: Value(status),
      capturedAt: Value(capturedAt),
      capturedBy: Value(capturedBy),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
      aiDetectionId: aiDetectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(aiDetectionId),
      retryCount: Value(retryCount),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Video.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Video(
      id: serializer.fromJson<String>(json['id']),
      boxId: serializer.fromJson<String>(json['boxId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      status: serializer.fromJson<String>(json['status']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      capturedBy: serializer.fromJson<String>(json['capturedBy']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
      aiDetectionId: serializer.fromJson<String?>(json['aiDetectionId']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boxId': serializer.toJson<String>(boxId),
      'localPath': serializer.toJson<String>(localPath),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'status': serializer.toJson<String>(status),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'capturedBy': serializer.toJson<String>(capturedBy),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
      'aiDetectionId': serializer.toJson<String?>(aiDetectionId),
      'retryCount': serializer.toJson<int>(retryCount),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Video copyWith({
    String? id,
    String? boxId,
    String? localPath,
    int? durationSeconds,
    Value<int?> fileSizeBytes = const Value.absent(),
    String? status,
    DateTime? capturedAt,
    String? capturedBy,
    Value<DateTime?> uploadedAt = const Value.absent(),
    Value<String?> aiDetectionId = const Value.absent(),
    int? retryCount,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Video(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    localPath: localPath ?? this.localPath,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    fileSizeBytes: fileSizeBytes.present
        ? fileSizeBytes.value
        : this.fileSizeBytes,
    status: status ?? this.status,
    capturedAt: capturedAt ?? this.capturedAt,
    capturedBy: capturedBy ?? this.capturedBy,
    uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
    aiDetectionId: aiDetectionId.present
        ? aiDetectionId.value
        : this.aiDetectionId,
    retryCount: retryCount ?? this.retryCount,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Video copyWithCompanion(VideosCompanion data) {
    return Video(
      id: data.id.present ? data.id.value : this.id,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      status: data.status.present ? data.status.value : this.status,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      capturedBy: data.capturedBy.present
          ? data.capturedBy.value
          : this.capturedBy,
      uploadedAt: data.uploadedAt.present
          ? data.uploadedAt.value
          : this.uploadedAt,
      aiDetectionId: data.aiDetectionId.present
          ? data.aiDetectionId.value
          : this.aiDetectionId,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Video(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('localPath: $localPath, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('status: $status, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('capturedBy: $capturedBy, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('aiDetectionId: $aiDetectionId, ')
          ..write('retryCount: $retryCount, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    localPath,
    durationSeconds,
    fileSizeBytes,
    status,
    capturedAt,
    capturedBy,
    uploadedAt,
    aiDetectionId,
    retryCount,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Video &&
          other.id == this.id &&
          other.boxId == this.boxId &&
          other.localPath == this.localPath &&
          other.durationSeconds == this.durationSeconds &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.status == this.status &&
          other.capturedAt == this.capturedAt &&
          other.capturedBy == this.capturedBy &&
          other.uploadedAt == this.uploadedAt &&
          other.aiDetectionId == this.aiDetectionId &&
          other.retryCount == this.retryCount &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class VideosCompanion extends UpdateCompanion<Video> {
  final Value<String> id;
  final Value<String> boxId;
  final Value<String> localPath;
  final Value<int> durationSeconds;
  final Value<int?> fileSizeBytes;
  final Value<String> status;
  final Value<DateTime> capturedAt;
  final Value<String> capturedBy;
  final Value<DateTime?> uploadedAt;
  final Value<String?> aiDetectionId;
  final Value<int> retryCount;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const VideosCompanion({
    this.id = const Value.absent(),
    this.boxId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.capturedBy = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.aiDetectionId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideosCompanion.insert({
    required String id,
    required String boxId,
    required String localPath,
    this.durationSeconds = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime capturedAt,
    required String capturedBy,
    this.uploadedAt = const Value.absent(),
    this.aiDetectionId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boxId = Value(boxId),
       localPath = Value(localPath),
       capturedAt = Value(capturedAt),
       capturedBy = Value(capturedBy);
  static Insertable<Video> custom({
    Expression<String>? id,
    Expression<String>? boxId,
    Expression<String>? localPath,
    Expression<int>? durationSeconds,
    Expression<int>? fileSizeBytes,
    Expression<String>? status,
    Expression<DateTime>? capturedAt,
    Expression<String>? capturedBy,
    Expression<DateTime>? uploadedAt,
    Expression<String>? aiDetectionId,
    Expression<int>? retryCount,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boxId != null) 'box_id': boxId,
      if (localPath != null) 'local_path': localPath,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (status != null) 'status': status,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (capturedBy != null) 'captured_by': capturedBy,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (aiDetectionId != null) 'ai_detection_id': aiDetectionId,
      if (retryCount != null) 'retry_count': retryCount,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideosCompanion copyWith({
    Value<String>? id,
    Value<String>? boxId,
    Value<String>? localPath,
    Value<int>? durationSeconds,
    Value<int?>? fileSizeBytes,
    Value<String>? status,
    Value<DateTime>? capturedAt,
    Value<String>? capturedBy,
    Value<DateTime?>? uploadedAt,
    Value<String?>? aiDetectionId,
    Value<int>? retryCount,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return VideosCompanion(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      localPath: localPath ?? this.localPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBy: capturedBy ?? this.capturedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      aiDetectionId: aiDetectionId ?? this.aiDetectionId,
      retryCount: retryCount ?? this.retryCount,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<String>(boxId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (capturedBy.present) {
      map['captured_by'] = Variable<String>(capturedBy.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (aiDetectionId.present) {
      map['ai_detection_id'] = Variable<String>(aiDetectionId.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideosCompanion(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('localPath: $localPath, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('status: $status, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('capturedBy: $capturedBy, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('aiDetectionId: $aiDetectionId, ')
          ..write('retryCount: $retryCount, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiDetectionsTable extends AiDetections
    with TableInfo<$AiDetectionsTable, AiDetection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiDetectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES videos (id)',
    ),
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<String> boxId = GeneratedColumn<String>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moltingStatusMeta = const VerificationMeta(
    'moltingStatus',
  );
  @override
  late final GeneratedColumn<String> moltingStatus = GeneratedColumn<String>(
    'molting_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthStatusMeta = const VerificationMeta(
    'healthStatus',
  );
  @override
  late final GeneratedColumn<String> healthStatus = GeneratedColumn<String>(
    'health_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _confidenceScoreMeta = const VerificationMeta(
    'confidenceScore',
  );
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
    'confidence_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _detectedCrabsMeta = const VerificationMeta(
    'detectedCrabs',
  );
  @override
  late final GeneratedColumn<String> detectedCrabs = GeneratedColumn<String>(
    'detected_crabs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _recommendationsMeta = const VerificationMeta(
    'recommendations',
  );
  @override
  late final GeneratedColumn<String> recommendations = GeneratedColumn<String>(
    'recommendations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _analyzedAtMeta = const VerificationMeta(
    'analyzedAt',
  );
  @override
  late final GeneratedColumn<DateTime> analyzedAt = GeneratedColumn<DateTime>(
    'analyzed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedbackStatusMeta = const VerificationMeta(
    'feedbackStatus',
  );
  @override
  late final GeneratedColumn<String> feedbackStatus = GeneratedColumn<String>(
    'feedback_status',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    boxId,
    moltingStatus,
    healthStatus,
    confidenceScore,
    detectedCrabs,
    recommendations,
    analyzedAt,
    feedbackStatus,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_detections';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiDetection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('molting_status')) {
      context.handle(
        _moltingStatusMeta,
        moltingStatus.isAcceptableOrUnknown(
          data['molting_status']!,
          _moltingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_moltingStatusMeta);
    }
    if (data.containsKey('health_status')) {
      context.handle(
        _healthStatusMeta,
        healthStatus.isAcceptableOrUnknown(
          data['health_status']!,
          _healthStatusMeta,
        ),
      );
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
        _confidenceScoreMeta,
        confidenceScore.isAcceptableOrUnknown(
          data['confidence_score']!,
          _confidenceScoreMeta,
        ),
      );
    }
    if (data.containsKey('detected_crabs')) {
      context.handle(
        _detectedCrabsMeta,
        detectedCrabs.isAcceptableOrUnknown(
          data['detected_crabs']!,
          _detectedCrabsMeta,
        ),
      );
    }
    if (data.containsKey('recommendations')) {
      context.handle(
        _recommendationsMeta,
        recommendations.isAcceptableOrUnknown(
          data['recommendations']!,
          _recommendationsMeta,
        ),
      );
    }
    if (data.containsKey('analyzed_at')) {
      context.handle(
        _analyzedAtMeta,
        analyzedAt.isAcceptableOrUnknown(data['analyzed_at']!, _analyzedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_analyzedAtMeta);
    }
    if (data.containsKey('feedback_status')) {
      context.handle(
        _feedbackStatusMeta,
        feedbackStatus.isAcceptableOrUnknown(
          data['feedback_status']!,
          _feedbackStatusMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiDetection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiDetection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_id'],
      )!,
      moltingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}molting_status'],
      )!,
      healthStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_status'],
      )!,
      confidenceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence_score'],
      )!,
      detectedCrabs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detected_crabs'],
      )!,
      recommendations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommendations'],
      )!,
      analyzedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}analyzed_at'],
      )!,
      feedbackStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback_status'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AiDetectionsTable createAlias(String alias) {
    return $AiDetectionsTable(attachedDatabase, alias);
  }
}

class AiDetection extends DataClass implements Insertable<AiDetection> {
  final String id;

  /// Foreign key → videos.id
  final String videoId;

  /// The box this detection is associated with.
  final String boxId;

  /// Molting stage: preMolt | molting | postMolt | hardShell
  final String moltingStatus;

  /// Health status: normal | disease | stress | unknown
  final String healthStatus;

  /// Overall confidence score in [0.0, 1.0].
  final double confidenceScore;

  /// JSON-encoded list of DetectionBox objects.
  final String detectedCrabs;

  /// JSON-encoded list of recommendation strings.
  final String recommendations;
  final DateTime analyzedAt;

  /// Operator feedback: correct | incorrect | null (no feedback yet).
  final String? feedbackStatus;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const AiDetection({
    required this.id,
    required this.videoId,
    required this.boxId,
    required this.moltingStatus,
    required this.healthStatus,
    required this.confidenceScore,
    required this.detectedCrabs,
    required this.recommendations,
    required this.analyzedAt,
    this.feedbackStatus,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['video_id'] = Variable<String>(videoId);
    map['box_id'] = Variable<String>(boxId);
    map['molting_status'] = Variable<String>(moltingStatus);
    map['health_status'] = Variable<String>(healthStatus);
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['detected_crabs'] = Variable<String>(detectedCrabs);
    map['recommendations'] = Variable<String>(recommendations);
    map['analyzed_at'] = Variable<DateTime>(analyzedAt);
    if (!nullToAbsent || feedbackStatus != null) {
      map['feedback_status'] = Variable<String>(feedbackStatus);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AiDetectionsCompanion toCompanion(bool nullToAbsent) {
    return AiDetectionsCompanion(
      id: Value(id),
      videoId: Value(videoId),
      boxId: Value(boxId),
      moltingStatus: Value(moltingStatus),
      healthStatus: Value(healthStatus),
      confidenceScore: Value(confidenceScore),
      detectedCrabs: Value(detectedCrabs),
      recommendations: Value(recommendations),
      analyzedAt: Value(analyzedAt),
      feedbackStatus: feedbackStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackStatus),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory AiDetection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiDetection(
      id: serializer.fromJson<String>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      boxId: serializer.fromJson<String>(json['boxId']),
      moltingStatus: serializer.fromJson<String>(json['moltingStatus']),
      healthStatus: serializer.fromJson<String>(json['healthStatus']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      detectedCrabs: serializer.fromJson<String>(json['detectedCrabs']),
      recommendations: serializer.fromJson<String>(json['recommendations']),
      analyzedAt: serializer.fromJson<DateTime>(json['analyzedAt']),
      feedbackStatus: serializer.fromJson<String?>(json['feedbackStatus']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'videoId': serializer.toJson<String>(videoId),
      'boxId': serializer.toJson<String>(boxId),
      'moltingStatus': serializer.toJson<String>(moltingStatus),
      'healthStatus': serializer.toJson<String>(healthStatus),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'detectedCrabs': serializer.toJson<String>(detectedCrabs),
      'recommendations': serializer.toJson<String>(recommendations),
      'analyzedAt': serializer.toJson<DateTime>(analyzedAt),
      'feedbackStatus': serializer.toJson<String?>(feedbackStatus),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  AiDetection copyWith({
    String? id,
    String? videoId,
    String? boxId,
    String? moltingStatus,
    String? healthStatus,
    double? confidenceScore,
    String? detectedCrabs,
    String? recommendations,
    DateTime? analyzedAt,
    Value<String?> feedbackStatus = const Value.absent(),
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => AiDetection(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    boxId: boxId ?? this.boxId,
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    confidenceScore: confidenceScore ?? this.confidenceScore,
    detectedCrabs: detectedCrabs ?? this.detectedCrabs,
    recommendations: recommendations ?? this.recommendations,
    analyzedAt: analyzedAt ?? this.analyzedAt,
    feedbackStatus: feedbackStatus.present
        ? feedbackStatus.value
        : this.feedbackStatus,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  AiDetection copyWithCompanion(AiDetectionsCompanion data) {
    return AiDetection(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      moltingStatus: data.moltingStatus.present
          ? data.moltingStatus.value
          : this.moltingStatus,
      healthStatus: data.healthStatus.present
          ? data.healthStatus.value
          : this.healthStatus,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      detectedCrabs: data.detectedCrabs.present
          ? data.detectedCrabs.value
          : this.detectedCrabs,
      recommendations: data.recommendations.present
          ? data.recommendations.value
          : this.recommendations,
      analyzedAt: data.analyzedAt.present
          ? data.analyzedAt.value
          : this.analyzedAt,
      feedbackStatus: data.feedbackStatus.present
          ? data.feedbackStatus.value
          : this.feedbackStatus,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiDetection(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('boxId: $boxId, ')
          ..write('moltingStatus: $moltingStatus, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('detectedCrabs: $detectedCrabs, ')
          ..write('recommendations: $recommendations, ')
          ..write('analyzedAt: $analyzedAt, ')
          ..write('feedbackStatus: $feedbackStatus, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoId,
    boxId,
    moltingStatus,
    healthStatus,
    confidenceScore,
    detectedCrabs,
    recommendations,
    analyzedAt,
    feedbackStatus,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiDetection &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.boxId == this.boxId &&
          other.moltingStatus == this.moltingStatus &&
          other.healthStatus == this.healthStatus &&
          other.confidenceScore == this.confidenceScore &&
          other.detectedCrabs == this.detectedCrabs &&
          other.recommendations == this.recommendations &&
          other.analyzedAt == this.analyzedAt &&
          other.feedbackStatus == this.feedbackStatus &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class AiDetectionsCompanion extends UpdateCompanion<AiDetection> {
  final Value<String> id;
  final Value<String> videoId;
  final Value<String> boxId;
  final Value<String> moltingStatus;
  final Value<String> healthStatus;
  final Value<double> confidenceScore;
  final Value<String> detectedCrabs;
  final Value<String> recommendations;
  final Value<DateTime> analyzedAt;
  final Value<String?> feedbackStatus;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AiDetectionsCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.boxId = const Value.absent(),
    this.moltingStatus = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.detectedCrabs = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.analyzedAt = const Value.absent(),
    this.feedbackStatus = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiDetectionsCompanion.insert({
    required String id,
    required String videoId,
    required String boxId,
    required String moltingStatus,
    this.healthStatus = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.detectedCrabs = const Value.absent(),
    this.recommendations = const Value.absent(),
    required DateTime analyzedAt,
    this.feedbackStatus = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       videoId = Value(videoId),
       boxId = Value(boxId),
       moltingStatus = Value(moltingStatus),
       analyzedAt = Value(analyzedAt);
  static Insertable<AiDetection> custom({
    Expression<String>? id,
    Expression<String>? videoId,
    Expression<String>? boxId,
    Expression<String>? moltingStatus,
    Expression<String>? healthStatus,
    Expression<double>? confidenceScore,
    Expression<String>? detectedCrabs,
    Expression<String>? recommendations,
    Expression<DateTime>? analyzedAt,
    Expression<String>? feedbackStatus,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (boxId != null) 'box_id': boxId,
      if (moltingStatus != null) 'molting_status': moltingStatus,
      if (healthStatus != null) 'health_status': healthStatus,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (detectedCrabs != null) 'detected_crabs': detectedCrabs,
      if (recommendations != null) 'recommendations': recommendations,
      if (analyzedAt != null) 'analyzed_at': analyzedAt,
      if (feedbackStatus != null) 'feedback_status': feedbackStatus,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiDetectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? videoId,
    Value<String>? boxId,
    Value<String>? moltingStatus,
    Value<String>? healthStatus,
    Value<double>? confidenceScore,
    Value<String>? detectedCrabs,
    Value<String>? recommendations,
    Value<DateTime>? analyzedAt,
    Value<String?>? feedbackStatus,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return AiDetectionsCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      boxId: boxId ?? this.boxId,
      moltingStatus: moltingStatus ?? this.moltingStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectedCrabs: detectedCrabs ?? this.detectedCrabs,
      recommendations: recommendations ?? this.recommendations,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<String>(boxId.value);
    }
    if (moltingStatus.present) {
      map['molting_status'] = Variable<String>(moltingStatus.value);
    }
    if (healthStatus.present) {
      map['health_status'] = Variable<String>(healthStatus.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (detectedCrabs.present) {
      map['detected_crabs'] = Variable<String>(detectedCrabs.value);
    }
    if (recommendations.present) {
      map['recommendations'] = Variable<String>(recommendations.value);
    }
    if (analyzedAt.present) {
      map['analyzed_at'] = Variable<DateTime>(analyzedAt.value);
    }
    if (feedbackStatus.present) {
      map['feedback_status'] = Variable<String>(feedbackStatus.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiDetectionsCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('boxId: $boxId, ')
          ..write('moltingStatus: $moltingStatus, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('detectedCrabs: $detectedCrabs, ')
          ..write('recommendations: $recommendations, ')
          ..write('analyzedAt: $analyzedAt, ')
          ..write('feedbackStatus: $feedbackStatus, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectionsTable extends Inspections
    with TableInfo<$InspectionsTable, Inspection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIdMeta = const VerificationMeta('boxId');
  @override
  late final GeneratedColumn<String> boxId = GeneratedColumn<String>(
    'box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boxes (id)',
    ),
  );
  static const VerificationMeta _relatedVideoIdMeta = const VerificationMeta(
    'relatedVideoId',
  );
  @override
  late final GeneratedColumn<String> relatedVideoId = GeneratedColumn<String>(
    'related_video_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moltingStatusMeta = const VerificationMeta(
    'moltingStatus',
  );
  @override
  late final GeneratedColumn<String> moltingStatus = GeneratedColumn<String>(
    'molting_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthStatusMeta = const VerificationMeta(
    'healthStatus',
  );
  @override
  late final GeneratedColumn<String> healthStatus = GeneratedColumn<String>(
    'health_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoUrlsMeta = const VerificationMeta(
    'photoUrls',
  );
  @override
  late final GeneratedColumn<String> photoUrls = GeneratedColumn<String>(
    'photo_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorIdMeta = const VerificationMeta(
    'operatorId',
  );
  @override
  late final GeneratedColumn<String> operatorId = GeneratedColumn<String>(
    'operator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorNameMeta = const VerificationMeta(
    'operatorName',
  );
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
    'operator_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aiAgreementMeta = const VerificationMeta(
    'aiAgreement',
  );
  @override
  late final GeneratedColumn<bool> aiAgreement = GeneratedColumn<bool>(
    'ai_agreement',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ai_agreement" IN (0, 1))',
    ),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boxId,
    relatedVideoId,
    moltingStatus,
    healthStatus,
    weight,
    notes,
    photoUrls,
    timestamp,
    operatorId,
    operatorName,
    aiAgreement,
    syncStatus,
    isDirty,
    syncedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Inspection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('box_id')) {
      context.handle(
        _boxIdMeta,
        boxId.isAcceptableOrUnknown(data['box_id']!, _boxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIdMeta);
    }
    if (data.containsKey('related_video_id')) {
      context.handle(
        _relatedVideoIdMeta,
        relatedVideoId.isAcceptableOrUnknown(
          data['related_video_id']!,
          _relatedVideoIdMeta,
        ),
      );
    }
    if (data.containsKey('molting_status')) {
      context.handle(
        _moltingStatusMeta,
        moltingStatus.isAcceptableOrUnknown(
          data['molting_status']!,
          _moltingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_moltingStatusMeta);
    }
    if (data.containsKey('health_status')) {
      context.handle(
        _healthStatusMeta,
        healthStatus.isAcceptableOrUnknown(
          data['health_status']!,
          _healthStatusMeta,
        ),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photo_urls')) {
      context.handle(
        _photoUrlsMeta,
        photoUrls.isAcceptableOrUnknown(data['photo_urls']!, _photoUrlsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('operator_id')) {
      context.handle(
        _operatorIdMeta,
        operatorId.isAcceptableOrUnknown(data['operator_id']!, _operatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_operatorIdMeta);
    }
    if (data.containsKey('operator_name')) {
      context.handle(
        _operatorNameMeta,
        operatorName.isAcceptableOrUnknown(
          data['operator_name']!,
          _operatorNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operatorNameMeta);
    }
    if (data.containsKey('ai_agreement')) {
      context.handle(
        _aiAgreementMeta,
        aiAgreement.isAcceptableOrUnknown(
          data['ai_agreement']!,
          _aiAgreementMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Inspection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Inspection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_id'],
      )!,
      relatedVideoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_video_id'],
      ),
      moltingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}molting_status'],
      )!,
      healthStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_status'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      photoUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_urls'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      operatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_id'],
      )!,
      operatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_name'],
      )!,
      aiAgreement: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai_agreement'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $InspectionsTable createAlias(String alias) {
    return $InspectionsTable(attachedDatabase, alias);
  }
}

class Inspection extends DataClass implements Insertable<Inspection> {
  final String id;

  /// Foreign key → boxes.id
  final String boxId;

  /// Optional video / AI detection ID this inspection is linked to.
  final String? relatedVideoId;

  /// Molting status: preMolt | molting | postMolt | hardShell
  final String moltingStatus;

  /// Health status: normal | disease | stress | unknown
  final String healthStatus;

  /// Weight recorded in grams (must be > 0).
  final double weight;
  final String notes;

  /// JSON-encoded list of photo URL strings.
  final String photoUrls;
  final DateTime timestamp;
  final String operatorId;
  final String operatorName;

  /// Whether the operator agreed with the AI result: true / false / null.
  final bool? aiAgreement;

  /// Sync status: pending | synced | failed
  final String syncStatus;
  final bool isDirty;
  final DateTime? syncedAt;
  final DateTime cachedAt;
  const Inspection({
    required this.id,
    required this.boxId,
    this.relatedVideoId,
    required this.moltingStatus,
    required this.healthStatus,
    required this.weight,
    required this.notes,
    required this.photoUrls,
    required this.timestamp,
    required this.operatorId,
    required this.operatorName,
    this.aiAgreement,
    required this.syncStatus,
    required this.isDirty,
    this.syncedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['box_id'] = Variable<String>(boxId);
    if (!nullToAbsent || relatedVideoId != null) {
      map['related_video_id'] = Variable<String>(relatedVideoId);
    }
    map['molting_status'] = Variable<String>(moltingStatus);
    map['health_status'] = Variable<String>(healthStatus);
    map['weight'] = Variable<double>(weight);
    map['notes'] = Variable<String>(notes);
    map['photo_urls'] = Variable<String>(photoUrls);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['operator_id'] = Variable<String>(operatorId);
    map['operator_name'] = Variable<String>(operatorName);
    if (!nullToAbsent || aiAgreement != null) {
      map['ai_agreement'] = Variable<bool>(aiAgreement);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  InspectionsCompanion toCompanion(bool nullToAbsent) {
    return InspectionsCompanion(
      id: Value(id),
      boxId: Value(boxId),
      relatedVideoId: relatedVideoId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedVideoId),
      moltingStatus: Value(moltingStatus),
      healthStatus: Value(healthStatus),
      weight: Value(weight),
      notes: Value(notes),
      photoUrls: Value(photoUrls),
      timestamp: Value(timestamp),
      operatorId: Value(operatorId),
      operatorName: Value(operatorName),
      aiAgreement: aiAgreement == null && nullToAbsent
          ? const Value.absent()
          : Value(aiAgreement),
      syncStatus: Value(syncStatus),
      isDirty: Value(isDirty),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Inspection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Inspection(
      id: serializer.fromJson<String>(json['id']),
      boxId: serializer.fromJson<String>(json['boxId']),
      relatedVideoId: serializer.fromJson<String?>(json['relatedVideoId']),
      moltingStatus: serializer.fromJson<String>(json['moltingStatus']),
      healthStatus: serializer.fromJson<String>(json['healthStatus']),
      weight: serializer.fromJson<double>(json['weight']),
      notes: serializer.fromJson<String>(json['notes']),
      photoUrls: serializer.fromJson<String>(json['photoUrls']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      operatorId: serializer.fromJson<String>(json['operatorId']),
      operatorName: serializer.fromJson<String>(json['operatorName']),
      aiAgreement: serializer.fromJson<bool?>(json['aiAgreement']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boxId': serializer.toJson<String>(boxId),
      'relatedVideoId': serializer.toJson<String?>(relatedVideoId),
      'moltingStatus': serializer.toJson<String>(moltingStatus),
      'healthStatus': serializer.toJson<String>(healthStatus),
      'weight': serializer.toJson<double>(weight),
      'notes': serializer.toJson<String>(notes),
      'photoUrls': serializer.toJson<String>(photoUrls),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'operatorId': serializer.toJson<String>(operatorId),
      'operatorName': serializer.toJson<String>(operatorName),
      'aiAgreement': serializer.toJson<bool?>(aiAgreement),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'isDirty': serializer.toJson<bool>(isDirty),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Inspection copyWith({
    String? id,
    String? boxId,
    Value<String?> relatedVideoId = const Value.absent(),
    String? moltingStatus,
    String? healthStatus,
    double? weight,
    String? notes,
    String? photoUrls,
    DateTime? timestamp,
    String? operatorId,
    String? operatorName,
    Value<bool?> aiAgreement = const Value.absent(),
    String? syncStatus,
    bool? isDirty,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Inspection(
    id: id ?? this.id,
    boxId: boxId ?? this.boxId,
    relatedVideoId: relatedVideoId.present
        ? relatedVideoId.value
        : this.relatedVideoId,
    moltingStatus: moltingStatus ?? this.moltingStatus,
    healthStatus: healthStatus ?? this.healthStatus,
    weight: weight ?? this.weight,
    notes: notes ?? this.notes,
    photoUrls: photoUrls ?? this.photoUrls,
    timestamp: timestamp ?? this.timestamp,
    operatorId: operatorId ?? this.operatorId,
    operatorName: operatorName ?? this.operatorName,
    aiAgreement: aiAgreement.present ? aiAgreement.value : this.aiAgreement,
    syncStatus: syncStatus ?? this.syncStatus,
    isDirty: isDirty ?? this.isDirty,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Inspection copyWithCompanion(InspectionsCompanion data) {
    return Inspection(
      id: data.id.present ? data.id.value : this.id,
      boxId: data.boxId.present ? data.boxId.value : this.boxId,
      relatedVideoId: data.relatedVideoId.present
          ? data.relatedVideoId.value
          : this.relatedVideoId,
      moltingStatus: data.moltingStatus.present
          ? data.moltingStatus.value
          : this.moltingStatus,
      healthStatus: data.healthStatus.present
          ? data.healthStatus.value
          : this.healthStatus,
      weight: data.weight.present ? data.weight.value : this.weight,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoUrls: data.photoUrls.present ? data.photoUrls.value : this.photoUrls,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      operatorId: data.operatorId.present
          ? data.operatorId.value
          : this.operatorId,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      aiAgreement: data.aiAgreement.present
          ? data.aiAgreement.value
          : this.aiAgreement,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Inspection(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('relatedVideoId: $relatedVideoId, ')
          ..write('moltingStatus: $moltingStatus, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('weight: $weight, ')
          ..write('notes: $notes, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('timestamp: $timestamp, ')
          ..write('operatorId: $operatorId, ')
          ..write('operatorName: $operatorName, ')
          ..write('aiAgreement: $aiAgreement, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boxId,
    relatedVideoId,
    moltingStatus,
    healthStatus,
    weight,
    notes,
    photoUrls,
    timestamp,
    operatorId,
    operatorName,
    aiAgreement,
    syncStatus,
    isDirty,
    syncedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Inspection &&
          other.id == this.id &&
          other.boxId == this.boxId &&
          other.relatedVideoId == this.relatedVideoId &&
          other.moltingStatus == this.moltingStatus &&
          other.healthStatus == this.healthStatus &&
          other.weight == this.weight &&
          other.notes == this.notes &&
          other.photoUrls == this.photoUrls &&
          other.timestamp == this.timestamp &&
          other.operatorId == this.operatorId &&
          other.operatorName == this.operatorName &&
          other.aiAgreement == this.aiAgreement &&
          other.syncStatus == this.syncStatus &&
          other.isDirty == this.isDirty &&
          other.syncedAt == this.syncedAt &&
          other.cachedAt == this.cachedAt);
}

class InspectionsCompanion extends UpdateCompanion<Inspection> {
  final Value<String> id;
  final Value<String> boxId;
  final Value<String?> relatedVideoId;
  final Value<String> moltingStatus;
  final Value<String> healthStatus;
  final Value<double> weight;
  final Value<String> notes;
  final Value<String> photoUrls;
  final Value<DateTime> timestamp;
  final Value<String> operatorId;
  final Value<String> operatorName;
  final Value<bool?> aiAgreement;
  final Value<String> syncStatus;
  final Value<bool> isDirty;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const InspectionsCompanion({
    this.id = const Value.absent(),
    this.boxId = const Value.absent(),
    this.relatedVideoId = const Value.absent(),
    this.moltingStatus = const Value.absent(),
    this.healthStatus = const Value.absent(),
    this.weight = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrls = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.operatorId = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.aiAgreement = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionsCompanion.insert({
    required String id,
    required String boxId,
    this.relatedVideoId = const Value.absent(),
    required String moltingStatus,
    this.healthStatus = const Value.absent(),
    this.weight = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrls = const Value.absent(),
    required DateTime timestamp,
    required String operatorId,
    required String operatorName,
    this.aiAgreement = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boxId = Value(boxId),
       moltingStatus = Value(moltingStatus),
       timestamp = Value(timestamp),
       operatorId = Value(operatorId),
       operatorName = Value(operatorName);
  static Insertable<Inspection> custom({
    Expression<String>? id,
    Expression<String>? boxId,
    Expression<String>? relatedVideoId,
    Expression<String>? moltingStatus,
    Expression<String>? healthStatus,
    Expression<double>? weight,
    Expression<String>? notes,
    Expression<String>? photoUrls,
    Expression<DateTime>? timestamp,
    Expression<String>? operatorId,
    Expression<String>? operatorName,
    Expression<bool>? aiAgreement,
    Expression<String>? syncStatus,
    Expression<bool>? isDirty,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boxId != null) 'box_id': boxId,
      if (relatedVideoId != null) 'related_video_id': relatedVideoId,
      if (moltingStatus != null) 'molting_status': moltingStatus,
      if (healthStatus != null) 'health_status': healthStatus,
      if (weight != null) 'weight': weight,
      if (notes != null) 'notes': notes,
      if (photoUrls != null) 'photo_urls': photoUrls,
      if (timestamp != null) 'timestamp': timestamp,
      if (operatorId != null) 'operator_id': operatorId,
      if (operatorName != null) 'operator_name': operatorName,
      if (aiAgreement != null) 'ai_agreement': aiAgreement,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (isDirty != null) 'is_dirty': isDirty,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? boxId,
    Value<String?>? relatedVideoId,
    Value<String>? moltingStatus,
    Value<String>? healthStatus,
    Value<double>? weight,
    Value<String>? notes,
    Value<String>? photoUrls,
    Value<DateTime>? timestamp,
    Value<String>? operatorId,
    Value<String>? operatorName,
    Value<bool?>? aiAgreement,
    Value<String>? syncStatus,
    Value<bool>? isDirty,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return InspectionsCompanion(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      relatedVideoId: relatedVideoId ?? this.relatedVideoId,
      moltingStatus: moltingStatus ?? this.moltingStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      timestamp: timestamp ?? this.timestamp,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      aiAgreement: aiAgreement ?? this.aiAgreement,
      syncStatus: syncStatus ?? this.syncStatus,
      isDirty: isDirty ?? this.isDirty,
      syncedAt: syncedAt ?? this.syncedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boxId.present) {
      map['box_id'] = Variable<String>(boxId.value);
    }
    if (relatedVideoId.present) {
      map['related_video_id'] = Variable<String>(relatedVideoId.value);
    }
    if (moltingStatus.present) {
      map['molting_status'] = Variable<String>(moltingStatus.value);
    }
    if (healthStatus.present) {
      map['health_status'] = Variable<String>(healthStatus.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoUrls.present) {
      map['photo_urls'] = Variable<String>(photoUrls.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (operatorId.present) {
      map['operator_id'] = Variable<String>(operatorId.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (aiAgreement.present) {
      map['ai_agreement'] = Variable<bool>(aiAgreement.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionsCompanion(')
          ..write('id: $id, ')
          ..write('boxId: $boxId, ')
          ..write('relatedVideoId: $relatedVideoId, ')
          ..write('moltingStatus: $moltingStatus, ')
          ..write('healthStatus: $healthStatus, ')
          ..write('weight: $weight, ')
          ..write('notes: $notes, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('timestamp: $timestamp, ')
          ..write('operatorId: $operatorId, ')
          ..write('operatorName: $operatorName, ')
          ..write('aiAgreement: $aiAgreement, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('isDirty: $isDirty, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $BoxesTable boxes = $BoxesTable(this);
  late final $CrabsTable crabs = $CrabsTable(this);
  late final $WaterQualityReadingsTable waterQualityReadings =
      $WaterQualityReadingsTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $OperationLogsTable operationLogs = $OperationLogsTable(this);
  late final $HarvestsTable harvests = $HarvestsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $VideosTable videos = $VideosTable(this);
  late final $AiDetectionsTable aiDetections = $AiDetectionsTable(this);
  late final $InspectionsTable inspections = $InspectionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    boxes,
    crabs,
    waterQualityReadings,
    alerts,
    operationLogs,
    harvests,
    sales,
    syncQueue,
    videos,
    aiDetections,
    inspections,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String email,
      required String name,
      required String role,
      Value<String> assignedFarmIds,
      Value<String?> photoUrl,
      required DateTime createdAt,
      Value<DateTime?> lastLoginAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> name,
      Value<String> role,
      Value<String> assignedFarmIds,
      Value<String?> photoUrl,
      Value<DateTime> createdAt,
      Value<DateTime?> lastLoginAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedFarmIds => $composableBuilder(
    column: $table.assignedFarmIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedFarmIds => $composableBuilder(
    column: $table.assignedFarmIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get assignedFarmIds => $composableBuilder(
    column: $table.assignedFarmIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> assignedFarmIds = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                email: email,
                name: name,
                role: role,
                assignedFarmIds: assignedFarmIds,
                photoUrl: photoUrl,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String name,
                required String role,
                Value<String> assignedFarmIds = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastLoginAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                email: email,
                name: name,
                role: role,
                assignedFarmIds: assignedFarmIds,
                photoUrl: photoUrl,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$BoxesTableCreateCompanionBuilder =
    BoxesCompanion Function({
      required String id,
      required String qrCode,
      required String farmId,
      Value<String?> pondId,
      Value<String?> location,
      Value<int> currentCrabCount,
      Value<int> capacity,
      required String species,
      Value<double> averageWeight,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> lastVideoAt,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$BoxesTableUpdateCompanionBuilder =
    BoxesCompanion Function({
      Value<String> id,
      Value<String> qrCode,
      Value<String> farmId,
      Value<String?> pondId,
      Value<String?> location,
      Value<int> currentCrabCount,
      Value<int> capacity,
      Value<String> species,
      Value<double> averageWeight,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> lastVideoAt,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$BoxesTableReferences
    extends BaseReferences<_$AppDatabase, $BoxesTable, Boxe> {
  $$BoxesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CrabsTable, List<Crab>> _crabsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.crabs,
    aliasName: 'boxes__id__crabs__box_id',
  );

  $$CrabsTableProcessedTableManager get crabsRefs {
    final manager = $$CrabsTableTableManager(
      $_db,
      $_db.crabs,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_crabsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HarvestsTable, List<Harvest>> _harvestsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.harvests,
    aliasName: 'boxes__id__harvests__box_id',
  );

  $$HarvestsTableProcessedTableManager get harvestsRefs {
    final manager = $$HarvestsTableTableManager(
      $_db,
      $_db.harvests,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_harvestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VideosTable, List<Video>> _videosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.videos,
    aliasName: 'boxes__id__videos__box_id',
  );

  $$VideosTableProcessedTableManager get videosRefs {
    final manager = $$VideosTableTableManager(
      $_db,
      $_db.videos,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_videosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InspectionsTable, List<Inspection>>
  _inspectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inspections,
    aliasName: 'boxes__id__inspections__box_id',
  );

  $$InspectionsTableProcessedTableManager get inspectionsRefs {
    final manager = $$InspectionsTableTableManager(
      $_db,
      $_db.inspections,
    ).filter((f) => f.boxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inspectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoxesTableFilterComposer extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farmId => $composableBuilder(
    column: $table.farmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentCrabCount => $composableBuilder(
    column: $table.currentCrabCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageWeight => $composableBuilder(
    column: $table.averageWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVideoAt => $composableBuilder(
    column: $table.lastVideoAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> crabsRefs(
    Expression<bool> Function($$CrabsTableFilterComposer f) f,
  ) {
    final $$CrabsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.crabs,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CrabsTableFilterComposer(
            $db: $db,
            $table: $db.crabs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> harvestsRefs(
    Expression<bool> Function($$HarvestsTableFilterComposer f) f,
  ) {
    final $$HarvestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.harvests,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestsTableFilterComposer(
            $db: $db,
            $table: $db.harvests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> videosRefs(
    Expression<bool> Function($$VideosTableFilterComposer f) f,
  ) {
    final $$VideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideosTableFilterComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inspectionsRefs(
    Expression<bool> Function($$InspectionsTableFilterComposer f) f,
  ) {
    final $$InspectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableFilterComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoxesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farmId => $composableBuilder(
    column: $table.farmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentCrabCount => $composableBuilder(
    column: $table.currentCrabCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageWeight => $composableBuilder(
    column: $table.averageWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVideoAt => $composableBuilder(
    column: $table.lastVideoAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get qrCode =>
      $composableBuilder(column: $table.qrCode, builder: (column) => column);

  GeneratedColumn<String> get farmId =>
      $composableBuilder(column: $table.farmId, builder: (column) => column);

  GeneratedColumn<String> get pondId =>
      $composableBuilder(column: $table.pondId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get currentCrabCount => $composableBuilder(
    column: $table.currentCrabCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<double> get averageWeight => $composableBuilder(
    column: $table.averageWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVideoAt => $composableBuilder(
    column: $table.lastVideoAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> crabsRefs<T extends Object>(
    Expression<T> Function($$CrabsTableAnnotationComposer a) f,
  ) {
    final $$CrabsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.crabs,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CrabsTableAnnotationComposer(
            $db: $db,
            $table: $db.crabs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> harvestsRefs<T extends Object>(
    Expression<T> Function($$HarvestsTableAnnotationComposer a) f,
  ) {
    final $$HarvestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.harvests,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestsTableAnnotationComposer(
            $db: $db,
            $table: $db.harvests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> videosRefs<T extends Object>(
    Expression<T> Function($$VideosTableAnnotationComposer a) f,
  ) {
    final $$VideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideosTableAnnotationComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inspectionsRefs<T extends Object>(
    Expression<T> Function($$InspectionsTableAnnotationComposer a) f,
  ) {
    final $$InspectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.boxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoxesTable,
          Boxe,
          $$BoxesTableFilterComposer,
          $$BoxesTableOrderingComposer,
          $$BoxesTableAnnotationComposer,
          $$BoxesTableCreateCompanionBuilder,
          $$BoxesTableUpdateCompanionBuilder,
          (Boxe, $$BoxesTableReferences),
          Boxe,
          PrefetchHooks Function({
            bool crabsRefs,
            bool harvestsRefs,
            bool videosRefs,
            bool inspectionsRefs,
          })
        > {
  $$BoxesTableTableManager(_$AppDatabase db, $BoxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> qrCode = const Value.absent(),
                Value<String> farmId = const Value.absent(),
                Value<String?> pondId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> currentCrabCount = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                Value<String> species = const Value.absent(),
                Value<double> averageWeight = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastVideoAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxesCompanion(
                id: id,
                qrCode: qrCode,
                farmId: farmId,
                pondId: pondId,
                location: location,
                currentCrabCount: currentCrabCount,
                capacity: capacity,
                species: species,
                averageWeight: averageWeight,
                status: status,
                createdAt: createdAt,
                lastVideoAt: lastVideoAt,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String qrCode,
                required String farmId,
                Value<String?> pondId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> currentCrabCount = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                required String species,
                Value<double> averageWeight = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastVideoAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxesCompanion.insert(
                id: id,
                qrCode: qrCode,
                farmId: farmId,
                pondId: pondId,
                location: location,
                currentCrabCount: currentCrabCount,
                capacity: capacity,
                species: species,
                averageWeight: averageWeight,
                status: status,
                createdAt: createdAt,
                lastVideoAt: lastVideoAt,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BoxesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                crabsRefs = false,
                harvestsRefs = false,
                videosRefs = false,
                inspectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (crabsRefs) db.crabs,
                    if (harvestsRefs) db.harvests,
                    if (videosRefs) db.videos,
                    if (inspectionsRefs) db.inspections,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (crabsRefs)
                        await $_getPrefetchedData<Boxe, $BoxesTable, Crab>(
                          currentTable: table,
                          referencedTable: $$BoxesTableReferences
                              ._crabsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoxesTableReferences(db, table, p0).crabsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boxId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (harvestsRefs)
                        await $_getPrefetchedData<Boxe, $BoxesTable, Harvest>(
                          currentTable: table,
                          referencedTable: $$BoxesTableReferences
                              ._harvestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoxesTableReferences(
                                db,
                                table,
                                p0,
                              ).harvestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boxId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (videosRefs)
                        await $_getPrefetchedData<Boxe, $BoxesTable, Video>(
                          currentTable: table,
                          referencedTable: $$BoxesTableReferences
                              ._videosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoxesTableReferences(db, table, p0).videosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boxId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inspectionsRefs)
                        await $_getPrefetchedData<
                          Boxe,
                          $BoxesTable,
                          Inspection
                        >(
                          currentTable: table,
                          referencedTable: $$BoxesTableReferences
                              ._inspectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoxesTableReferences(
                                db,
                                table,
                                p0,
                              ).inspectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boxId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BoxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoxesTable,
      Boxe,
      $$BoxesTableFilterComposer,
      $$BoxesTableOrderingComposer,
      $$BoxesTableAnnotationComposer,
      $$BoxesTableCreateCompanionBuilder,
      $$BoxesTableUpdateCompanionBuilder,
      (Boxe, $$BoxesTableReferences),
      Boxe,
      PrefetchHooks Function({
        bool crabsRefs,
        bool harvestsRefs,
        bool videosRefs,
        bool inspectionsRefs,
      })
    >;
typedef $$CrabsTableCreateCompanionBuilder =
    CrabsCompanion Function({
      required String id,
      required String boxId,
      required String species,
      Value<double> weight,
      required String moltingStatus,
      Value<String> healthStatus,
      required String source,
      required DateTime addedAt,
      required String addedBy,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CrabsTableUpdateCompanionBuilder =
    CrabsCompanion Function({
      Value<String> id,
      Value<String> boxId,
      Value<String> species,
      Value<double> weight,
      Value<String> moltingStatus,
      Value<String> healthStatus,
      Value<String> source,
      Value<DateTime> addedAt,
      Value<String> addedBy,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CrabsTableReferences
    extends BaseReferences<_$AppDatabase, $CrabsTable, Crab> {
  $$CrabsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoxesTable _boxIdTable(_$AppDatabase db) =>
      db.boxes.createAlias('crabs__box_id__boxes__id');

  $$BoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<String>('box_id')!;

    final manager = $$BoxesTableTableManager(
      $_db,
      $_db.boxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CrabsTableFilterComposer extends Composer<_$AppDatabase, $CrabsTable> {
  $$CrabsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedBy => $composableBuilder(
    column: $table.addedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoxesTableFilterComposer get boxId {
    final $$BoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableFilterComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CrabsTableOrderingComposer
    extends Composer<_$AppDatabase, $CrabsTable> {
  $$CrabsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedBy => $composableBuilder(
    column: $table.addedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoxesTableOrderingComposer get boxId {
    final $$BoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableOrderingComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CrabsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CrabsTable> {
  $$CrabsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get addedBy =>
      $composableBuilder(column: $table.addedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$BoxesTableAnnotationComposer get boxId {
    final $$BoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CrabsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CrabsTable,
          Crab,
          $$CrabsTableFilterComposer,
          $$CrabsTableOrderingComposer,
          $$CrabsTableAnnotationComposer,
          $$CrabsTableCreateCompanionBuilder,
          $$CrabsTableUpdateCompanionBuilder,
          (Crab, $$CrabsTableReferences),
          Crab,
          PrefetchHooks Function({bool boxId})
        > {
  $$CrabsTableTableManager(_$AppDatabase db, $CrabsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CrabsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CrabsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CrabsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boxId = const Value.absent(),
                Value<String> species = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<String> moltingStatus = const Value.absent(),
                Value<String> healthStatus = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<String> addedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrabsCompanion(
                id: id,
                boxId: boxId,
                species: species,
                weight: weight,
                moltingStatus: moltingStatus,
                healthStatus: healthStatus,
                source: source,
                addedAt: addedAt,
                addedBy: addedBy,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boxId,
                required String species,
                Value<double> weight = const Value.absent(),
                required String moltingStatus,
                Value<String> healthStatus = const Value.absent(),
                required String source,
                required DateTime addedAt,
                required String addedBy,
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CrabsCompanion.insert(
                id: id,
                boxId: boxId,
                species: species,
                weight: weight,
                moltingStatus: moltingStatus,
                healthStatus: healthStatus,
                source: source,
                addedAt: addedAt,
                addedBy: addedBy,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CrabsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({boxId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boxId,
                                referencedTable: $$CrabsTableReferences
                                    ._boxIdTable(db),
                                referencedColumn: $$CrabsTableReferences
                                    ._boxIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CrabsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CrabsTable,
      Crab,
      $$CrabsTableFilterComposer,
      $$CrabsTableOrderingComposer,
      $$CrabsTableAnnotationComposer,
      $$CrabsTableCreateCompanionBuilder,
      $$CrabsTableUpdateCompanionBuilder,
      (Crab, $$CrabsTableReferences),
      Crab,
      PrefetchHooks Function({bool boxId})
    >;
typedef $$WaterQualityReadingsTableCreateCompanionBuilder =
    WaterQualityReadingsCompanion Function({
      required String id,
      required String sensorId,
      required String farmId,
      Value<String?> pondId,
      Value<double> temperature,
      Value<double> ph,
      Value<double> dissolvedOxygen,
      Value<double> salinity,
      required DateTime timestamp,
      Value<bool> isAlertTriggered,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$WaterQualityReadingsTableUpdateCompanionBuilder =
    WaterQualityReadingsCompanion Function({
      Value<String> id,
      Value<String> sensorId,
      Value<String> farmId,
      Value<String?> pondId,
      Value<double> temperature,
      Value<double> ph,
      Value<double> dissolvedOxygen,
      Value<double> salinity,
      Value<DateTime> timestamp,
      Value<bool> isAlertTriggered,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$WaterQualityReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterQualityReadingsTable> {
  $$WaterQualityReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensorId => $composableBuilder(
    column: $table.sensorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farmId => $composableBuilder(
    column: $table.farmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salinity => $composableBuilder(
    column: $table.salinity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlertTriggered => $composableBuilder(
    column: $table.isAlertTriggered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterQualityReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterQualityReadingsTable> {
  $$WaterQualityReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensorId => $composableBuilder(
    column: $table.sensorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farmId => $composableBuilder(
    column: $table.farmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salinity => $composableBuilder(
    column: $table.salinity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlertTriggered => $composableBuilder(
    column: $table.isAlertTriggered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterQualityReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterQualityReadingsTable> {
  $$WaterQualityReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sensorId =>
      $composableBuilder(column: $table.sensorId, builder: (column) => column);

  GeneratedColumn<String> get farmId =>
      $composableBuilder(column: $table.farmId, builder: (column) => column);

  GeneratedColumn<String> get pondId =>
      $composableBuilder(column: $table.pondId, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salinity =>
      $composableBuilder(column: $table.salinity, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isAlertTriggered => $composableBuilder(
    column: $table.isAlertTriggered,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$WaterQualityReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterQualityReadingsTable,
          WaterQualityReading,
          $$WaterQualityReadingsTableFilterComposer,
          $$WaterQualityReadingsTableOrderingComposer,
          $$WaterQualityReadingsTableAnnotationComposer,
          $$WaterQualityReadingsTableCreateCompanionBuilder,
          $$WaterQualityReadingsTableUpdateCompanionBuilder,
          (
            WaterQualityReading,
            BaseReferences<
              _$AppDatabase,
              $WaterQualityReadingsTable,
              WaterQualityReading
            >,
          ),
          WaterQualityReading,
          PrefetchHooks Function()
        > {
  $$WaterQualityReadingsTableTableManager(
    _$AppDatabase db,
    $WaterQualityReadingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterQualityReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterQualityReadingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WaterQualityReadingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sensorId = const Value.absent(),
                Value<String> farmId = const Value.absent(),
                Value<String?> pondId = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> ph = const Value.absent(),
                Value<double> dissolvedOxygen = const Value.absent(),
                Value<double> salinity = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isAlertTriggered = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterQualityReadingsCompanion(
                id: id,
                sensorId: sensorId,
                farmId: farmId,
                pondId: pondId,
                temperature: temperature,
                ph: ph,
                dissolvedOxygen: dissolvedOxygen,
                salinity: salinity,
                timestamp: timestamp,
                isAlertTriggered: isAlertTriggered,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sensorId,
                required String farmId,
                Value<String?> pondId = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> ph = const Value.absent(),
                Value<double> dissolvedOxygen = const Value.absent(),
                Value<double> salinity = const Value.absent(),
                required DateTime timestamp,
                Value<bool> isAlertTriggered = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterQualityReadingsCompanion.insert(
                id: id,
                sensorId: sensorId,
                farmId: farmId,
                pondId: pondId,
                temperature: temperature,
                ph: ph,
                dissolvedOxygen: dissolvedOxygen,
                salinity: salinity,
                timestamp: timestamp,
                isAlertTriggered: isAlertTriggered,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterQualityReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterQualityReadingsTable,
      WaterQualityReading,
      $$WaterQualityReadingsTableFilterComposer,
      $$WaterQualityReadingsTableOrderingComposer,
      $$WaterQualityReadingsTableAnnotationComposer,
      $$WaterQualityReadingsTableCreateCompanionBuilder,
      $$WaterQualityReadingsTableUpdateCompanionBuilder,
      (
        WaterQualityReading,
        BaseReferences<
          _$AppDatabase,
          $WaterQualityReadingsTable,
          WaterQualityReading
        >,
      ),
      WaterQualityReading,
      PrefetchHooks Function()
    >;
typedef $$AlertsTableCreateCompanionBuilder =
    AlertsCompanion Function({
      required String id,
      required String type,
      required String severity,
      required String title,
      required String message,
      Value<String?> sourceId,
      Value<String?> sourceType,
      Value<String> recommendedActions,
      required DateTime createdAt,
      Value<DateTime?> acknowledgedAt,
      Value<String?> acknowledgedBy,
      Value<String> status,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$AlertsTableUpdateCompanionBuilder =
    AlertsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> severity,
      Value<String> title,
      Value<String> message,
      Value<String?> sourceId,
      Value<String?> sourceType,
      Value<String> recommendedActions,
      Value<DateTime> createdAt,
      Value<DateTime?> acknowledgedAt,
      Value<String?> acknowledgedBy,
      Value<String> status,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$AlertsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedActions => $composableBuilder(
    column: $table.recommendedActions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acknowledgedBy => $composableBuilder(
    column: $table.acknowledgedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedActions => $composableBuilder(
    column: $table.recommendedActions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acknowledgedBy => $composableBuilder(
    column: $table.acknowledgedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedActions => $composableBuilder(
    column: $table.recommendedActions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get acknowledgedAt => $composableBuilder(
    column: $table.acknowledgedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acknowledgedBy => $composableBuilder(
    column: $table.acknowledgedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          Alert,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
          Alert,
          PrefetchHooks Function()
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String> recommendedActions = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> acknowledgedAt = const Value.absent(),
                Value<String?> acknowledgedBy = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                type: type,
                severity: severity,
                title: title,
                message: message,
                sourceId: sourceId,
                sourceType: sourceType,
                recommendedActions: recommendedActions,
                createdAt: createdAt,
                acknowledgedAt: acknowledgedAt,
                acknowledgedBy: acknowledgedBy,
                status: status,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String severity,
                required String title,
                required String message,
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String> recommendedActions = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> acknowledgedAt = const Value.absent(),
                Value<String?> acknowledgedBy = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                type: type,
                severity: severity,
                title: title,
                message: message,
                sourceId: sourceId,
                sourceType: sourceType,
                recommendedActions: recommendedActions,
                createdAt: createdAt,
                acknowledgedAt: acknowledgedAt,
                acknowledgedBy: acknowledgedBy,
                status: status,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      Alert,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (Alert, BaseReferences<_$AppDatabase, $AlertsTable, Alert>),
      Alert,
      PrefetchHooks Function()
    >;
typedef $$OperationLogsTableCreateCompanionBuilder =
    OperationLogsCompanion Function({
      required String id,
      required String type,
      Value<String> boxIds,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String> notes,
      Value<String> photoUrls,
      required DateTime timestamp,
      required String operatorId,
      required String operatorName,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$OperationLogsTableUpdateCompanionBuilder =
    OperationLogsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> boxIds,
      Value<double?> quantity,
      Value<String?> unit,
      Value<String> notes,
      Value<String> photoUrls,
      Value<DateTime> timestamp,
      Value<String> operatorId,
      Value<String> operatorName,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$OperationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationLogsTable> {
  $$OperationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boxIds => $composableBuilder(
    column: $table.boxIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrls => $composableBuilder(
    column: $table.photoUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operatorId => $composableBuilder(
    column: $table.operatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationLogsTable> {
  $$OperationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boxIds => $composableBuilder(
    column: $table.boxIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrls => $composableBuilder(
    column: $table.photoUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operatorId => $composableBuilder(
    column: $table.operatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationLogsTable> {
  $$OperationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get boxIds =>
      $composableBuilder(column: $table.boxIds, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoUrls =>
      $composableBuilder(column: $table.photoUrls, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get operatorId => $composableBuilder(
    column: $table.operatorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$OperationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationLogsTable,
          OperationLog,
          $$OperationLogsTableFilterComposer,
          $$OperationLogsTableOrderingComposer,
          $$OperationLogsTableAnnotationComposer,
          $$OperationLogsTableCreateCompanionBuilder,
          $$OperationLogsTableUpdateCompanionBuilder,
          (
            OperationLog,
            BaseReferences<_$AppDatabase, $OperationLogsTable, OperationLog>,
          ),
          OperationLog,
          PrefetchHooks Function()
        > {
  $$OperationLogsTableTableManager(_$AppDatabase db, $OperationLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> boxIds = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> photoUrls = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> operatorId = const Value.absent(),
                Value<String> operatorName = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationLogsCompanion(
                id: id,
                type: type,
                boxIds: boxIds,
                quantity: quantity,
                unit: unit,
                notes: notes,
                photoUrls: photoUrls,
                timestamp: timestamp,
                operatorId: operatorId,
                operatorName: operatorName,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<String> boxIds = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> photoUrls = const Value.absent(),
                required DateTime timestamp,
                required String operatorId,
                required String operatorName,
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationLogsCompanion.insert(
                id: id,
                type: type,
                boxIds: boxIds,
                quantity: quantity,
                unit: unit,
                notes: notes,
                photoUrls: photoUrls,
                timestamp: timestamp,
                operatorId: operatorId,
                operatorName: operatorName,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OperationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationLogsTable,
      OperationLog,
      $$OperationLogsTableFilterComposer,
      $$OperationLogsTableOrderingComposer,
      $$OperationLogsTableAnnotationComposer,
      $$OperationLogsTableCreateCompanionBuilder,
      $$OperationLogsTableUpdateCompanionBuilder,
      (
        OperationLog,
        BaseReferences<_$AppDatabase, $OperationLogsTable, OperationLog>,
      ),
      OperationLog,
      PrefetchHooks Function()
    >;
typedef $$HarvestsTableCreateCompanionBuilder =
    HarvestsCompanion Function({
      required String id,
      required String boxId,
      Value<double> totalWeight,
      Value<int> crabCount,
      required String qualityGrade,
      required DateTime harvestDate,
      required String harvestedBy,
      Value<String?> destination,
      Value<String> photoUrls,
      Value<String> notes,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$HarvestsTableUpdateCompanionBuilder =
    HarvestsCompanion Function({
      Value<String> id,
      Value<String> boxId,
      Value<double> totalWeight,
      Value<int> crabCount,
      Value<String> qualityGrade,
      Value<DateTime> harvestDate,
      Value<String> harvestedBy,
      Value<String?> destination,
      Value<String> photoUrls,
      Value<String> notes,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$HarvestsTableReferences
    extends BaseReferences<_$AppDatabase, $HarvestsTable, Harvest> {
  $$HarvestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoxesTable _boxIdTable(_$AppDatabase db) =>
      db.boxes.createAlias('harvests__box_id__boxes__id');

  $$BoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<String>('box_id')!;

    final manager = $$BoxesTableTableManager(
      $_db,
      $_db.boxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HarvestsTableFilterComposer
    extends Composer<_$AppDatabase, $HarvestsTable> {
  $$HarvestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get crabCount => $composableBuilder(
    column: $table.crabCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityGrade => $composableBuilder(
    column: $table.qualityGrade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get harvestDate => $composableBuilder(
    column: $table.harvestDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get harvestedBy => $composableBuilder(
    column: $table.harvestedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrls => $composableBuilder(
    column: $table.photoUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoxesTableFilterComposer get boxId {
    final $$BoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableFilterComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HarvestsTableOrderingComposer
    extends Composer<_$AppDatabase, $HarvestsTable> {
  $$HarvestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get crabCount => $composableBuilder(
    column: $table.crabCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityGrade => $composableBuilder(
    column: $table.qualityGrade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get harvestDate => $composableBuilder(
    column: $table.harvestDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get harvestedBy => $composableBuilder(
    column: $table.harvestedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrls => $composableBuilder(
    column: $table.photoUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoxesTableOrderingComposer get boxId {
    final $$BoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableOrderingComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HarvestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HarvestsTable> {
  $$HarvestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get crabCount =>
      $composableBuilder(column: $table.crabCount, builder: (column) => column);

  GeneratedColumn<String> get qualityGrade => $composableBuilder(
    column: $table.qualityGrade,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get harvestDate => $composableBuilder(
    column: $table.harvestDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get harvestedBy => $composableBuilder(
    column: $table.harvestedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrls =>
      $composableBuilder(column: $table.photoUrls, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$BoxesTableAnnotationComposer get boxId {
    final $$BoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HarvestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HarvestsTable,
          Harvest,
          $$HarvestsTableFilterComposer,
          $$HarvestsTableOrderingComposer,
          $$HarvestsTableAnnotationComposer,
          $$HarvestsTableCreateCompanionBuilder,
          $$HarvestsTableUpdateCompanionBuilder,
          (Harvest, $$HarvestsTableReferences),
          Harvest,
          PrefetchHooks Function({bool boxId})
        > {
  $$HarvestsTableTableManager(_$AppDatabase db, $HarvestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HarvestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HarvestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HarvestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boxId = const Value.absent(),
                Value<double> totalWeight = const Value.absent(),
                Value<int> crabCount = const Value.absent(),
                Value<String> qualityGrade = const Value.absent(),
                Value<DateTime> harvestDate = const Value.absent(),
                Value<String> harvestedBy = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String> photoUrls = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HarvestsCompanion(
                id: id,
                boxId: boxId,
                totalWeight: totalWeight,
                crabCount: crabCount,
                qualityGrade: qualityGrade,
                harvestDate: harvestDate,
                harvestedBy: harvestedBy,
                destination: destination,
                photoUrls: photoUrls,
                notes: notes,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boxId,
                Value<double> totalWeight = const Value.absent(),
                Value<int> crabCount = const Value.absent(),
                required String qualityGrade,
                required DateTime harvestDate,
                required String harvestedBy,
                Value<String?> destination = const Value.absent(),
                Value<String> photoUrls = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HarvestsCompanion.insert(
                id: id,
                boxId: boxId,
                totalWeight: totalWeight,
                crabCount: crabCount,
                qualityGrade: qualityGrade,
                harvestDate: harvestDate,
                harvestedBy: harvestedBy,
                destination: destination,
                photoUrls: photoUrls,
                notes: notes,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HarvestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boxId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boxId,
                                referencedTable: $$HarvestsTableReferences
                                    ._boxIdTable(db),
                                referencedColumn: $$HarvestsTableReferences
                                    ._boxIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HarvestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HarvestsTable,
      Harvest,
      $$HarvestsTableFilterComposer,
      $$HarvestsTableOrderingComposer,
      $$HarvestsTableAnnotationComposer,
      $$HarvestsTableCreateCompanionBuilder,
      $$HarvestsTableUpdateCompanionBuilder,
      (Harvest, $$HarvestsTableReferences),
      Harvest,
      PrefetchHooks Function({bool boxId})
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      required String id,
      required String transactionId,
      required String buyerName,
      Value<String?> buyerContact,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<double> totalAmount,
      required String paymentMethod,
      Value<String> paymentStatus,
      required DateTime saleDate,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> buyerName,
      Value<String?> buyerContact,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<double> totalAmount,
      Value<String> paymentMethod,
      Value<String> paymentStatus,
      Value<DateTime> saleDate,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyerContact => $composableBuilder(
    column: $table.buyerContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get saleDate => $composableBuilder(
    column: $table.saleDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyerContact => $composableBuilder(
    column: $table.buyerContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get saleDate => $composableBuilder(
    column: $table.saleDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get buyerName =>
      $composableBuilder(column: $table.buyerName, builder: (column) => column);

  GeneratedColumn<String> get buyerContact => $composableBuilder(
    column: $table.buyerContact,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get saleDate =>
      $composableBuilder(column: $table.saleDate, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, BaseReferences<_$AppDatabase, $SalesTable, Sale>),
          Sale,
          PrefetchHooks Function()
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> buyerName = const Value.absent(),
                Value<String?> buyerContact = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<DateTime> saleDate = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion(
                id: id,
                transactionId: transactionId,
                buyerName: buyerName,
                buyerContact: buyerContact,
                quantity: quantity,
                unitPrice: unitPrice,
                totalAmount: totalAmount,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                saleDate: saleDate,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String buyerName,
                Value<String?> buyerContact = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                required String paymentMethod,
                Value<String> paymentStatus = const Value.absent(),
                required DateTime saleDate,
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion.insert(
                id: id,
                transactionId: transactionId,
                buyerName: buyerName,
                buyerContact: buyerContact,
                quantity: quantity,
                unitPrice: unitPrice,
                totalAmount: totalAmount,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                saleDate: saleDate,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, BaseReferences<_$AppDatabase, $SalesTable, Sale>),
      Sale,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String operationType,
      required String entityId,
      required String entityType,
      required String payload,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<int> priority,
      Value<DateTime?> lastAttemptAt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> operationType,
      Value<String> entityId,
      Value<String> entityType,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String> status,
      Value<int> priority,
      Value<DateTime?> lastAttemptAt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                operationType: operationType,
                entityId: entityId,
                entityType: entityType,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                priority: priority,
                lastAttemptAt: lastAttemptAt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationType,
                required String entityId,
                required String entityType,
                required String payload,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                operationType: operationType,
                entityId: entityId,
                entityType: entityType,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                status: status,
                priority: priority,
                lastAttemptAt: lastAttemptAt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$VideosTableCreateCompanionBuilder =
    VideosCompanion Function({
      required String id,
      required String boxId,
      required String localPath,
      Value<int> durationSeconds,
      Value<int?> fileSizeBytes,
      Value<String> status,
      required DateTime capturedAt,
      required String capturedBy,
      Value<DateTime?> uploadedAt,
      Value<String?> aiDetectionId,
      Value<int> retryCount,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$VideosTableUpdateCompanionBuilder =
    VideosCompanion Function({
      Value<String> id,
      Value<String> boxId,
      Value<String> localPath,
      Value<int> durationSeconds,
      Value<int?> fileSizeBytes,
      Value<String> status,
      Value<DateTime> capturedAt,
      Value<String> capturedBy,
      Value<DateTime?> uploadedAt,
      Value<String?> aiDetectionId,
      Value<int> retryCount,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$VideosTableReferences
    extends BaseReferences<_$AppDatabase, $VideosTable, Video> {
  $$VideosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoxesTable _boxIdTable(_$AppDatabase db) =>
      db.boxes.createAlias('videos__box_id__boxes__id');

  $$BoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<String>('box_id')!;

    final manager = $$BoxesTableTableManager(
      $_db,
      $_db.boxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AiDetectionsTable, List<AiDetection>>
  _aiDetectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.aiDetections,
    aliasName: 'videos__id__ai_detections__video_id',
  );

  $$AiDetectionsTableProcessedTableManager get aiDetectionsRefs {
    final manager = $$AiDetectionsTableTableManager(
      $_db,
      $_db.aiDetections,
    ).filter((f) => f.videoId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_aiDetectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VideosTableFilterComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capturedBy => $composableBuilder(
    column: $table.capturedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiDetectionId => $composableBuilder(
    column: $table.aiDetectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoxesTableFilterComposer get boxId {
    final $$BoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableFilterComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> aiDetectionsRefs(
    Expression<bool> Function($$AiDetectionsTableFilterComposer f) f,
  ) {
    final $$AiDetectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiDetections,
      getReferencedColumn: (t) => t.videoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiDetectionsTableFilterComposer(
            $db: $db,
            $table: $db.aiDetections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VideosTableOrderingComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capturedBy => $composableBuilder(
    column: $table.capturedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiDetectionId => $composableBuilder(
    column: $table.aiDetectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoxesTableOrderingComposer get boxId {
    final $$BoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableOrderingComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get capturedBy => $composableBuilder(
    column: $table.capturedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiDetectionId => $composableBuilder(
    column: $table.aiDetectionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$BoxesTableAnnotationComposer get boxId {
    final $$BoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> aiDetectionsRefs<T extends Object>(
    Expression<T> Function($$AiDetectionsTableAnnotationComposer a) f,
  ) {
    final $$AiDetectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiDetections,
      getReferencedColumn: (t) => t.videoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiDetectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.aiDetections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideosTable,
          Video,
          $$VideosTableFilterComposer,
          $$VideosTableOrderingComposer,
          $$VideosTableAnnotationComposer,
          $$VideosTableCreateCompanionBuilder,
          $$VideosTableUpdateCompanionBuilder,
          (Video, $$VideosTableReferences),
          Video,
          PrefetchHooks Function({bool boxId, bool aiDetectionsRefs})
        > {
  $$VideosTableTableManager(_$AppDatabase db, $VideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boxId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> capturedBy = const Value.absent(),
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<String?> aiDetectionId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideosCompanion(
                id: id,
                boxId: boxId,
                localPath: localPath,
                durationSeconds: durationSeconds,
                fileSizeBytes: fileSizeBytes,
                status: status,
                capturedAt: capturedAt,
                capturedBy: capturedBy,
                uploadedAt: uploadedAt,
                aiDetectionId: aiDetectionId,
                retryCount: retryCount,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boxId,
                required String localPath,
                Value<int> durationSeconds = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime capturedAt,
                required String capturedBy,
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<String?> aiDetectionId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideosCompanion.insert(
                id: id,
                boxId: boxId,
                localPath: localPath,
                durationSeconds: durationSeconds,
                fileSizeBytes: fileSizeBytes,
                status: status,
                capturedAt: capturedAt,
                capturedBy: capturedBy,
                uploadedAt: uploadedAt,
                aiDetectionId: aiDetectionId,
                retryCount: retryCount,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$VideosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({boxId = false, aiDetectionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (aiDetectionsRefs) db.aiDetections],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boxId,
                                referencedTable: $$VideosTableReferences
                                    ._boxIdTable(db),
                                referencedColumn: $$VideosTableReferences
                                    ._boxIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aiDetectionsRefs)
                    await $_getPrefetchedData<Video, $VideosTable, AiDetection>(
                      currentTable: table,
                      referencedTable: $$VideosTableReferences
                          ._aiDetectionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$VideosTableReferences(
                        db,
                        table,
                        p0,
                      ).aiDetectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.videoId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideosTable,
      Video,
      $$VideosTableFilterComposer,
      $$VideosTableOrderingComposer,
      $$VideosTableAnnotationComposer,
      $$VideosTableCreateCompanionBuilder,
      $$VideosTableUpdateCompanionBuilder,
      (Video, $$VideosTableReferences),
      Video,
      PrefetchHooks Function({bool boxId, bool aiDetectionsRefs})
    >;
typedef $$AiDetectionsTableCreateCompanionBuilder =
    AiDetectionsCompanion Function({
      required String id,
      required String videoId,
      required String boxId,
      required String moltingStatus,
      Value<String> healthStatus,
      Value<double> confidenceScore,
      Value<String> detectedCrabs,
      Value<String> recommendations,
      required DateTime analyzedAt,
      Value<String?> feedbackStatus,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$AiDetectionsTableUpdateCompanionBuilder =
    AiDetectionsCompanion Function({
      Value<String> id,
      Value<String> videoId,
      Value<String> boxId,
      Value<String> moltingStatus,
      Value<String> healthStatus,
      Value<double> confidenceScore,
      Value<String> detectedCrabs,
      Value<String> recommendations,
      Value<DateTime> analyzedAt,
      Value<String?> feedbackStatus,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$AiDetectionsTableReferences
    extends BaseReferences<_$AppDatabase, $AiDetectionsTable, AiDetection> {
  $$AiDetectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VideosTable _videoIdTable(_$AppDatabase db) =>
      db.videos.createAlias('ai_detections__video_id__videos__id');

  $$VideosTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$VideosTableTableManager(
      $_db,
      $_db.videos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AiDetectionsTableFilterComposer
    extends Composer<_$AppDatabase, $AiDetectionsTable> {
  $$AiDetectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boxId => $composableBuilder(
    column: $table.boxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detectedCrabs => $composableBuilder(
    column: $table.detectedCrabs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendations => $composableBuilder(
    column: $table.recommendations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedbackStatus => $composableBuilder(
    column: $table.feedbackStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VideosTableFilterComposer get videoId {
    final $$VideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideosTableFilterComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiDetectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiDetectionsTable> {
  $$AiDetectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boxId => $composableBuilder(
    column: $table.boxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detectedCrabs => $composableBuilder(
    column: $table.detectedCrabs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendations => $composableBuilder(
    column: $table.recommendations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedbackStatus => $composableBuilder(
    column: $table.feedbackStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VideosTableOrderingComposer get videoId {
    final $$VideosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideosTableOrderingComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiDetectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiDetectionsTable> {
  $$AiDetectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get boxId =>
      $composableBuilder(column: $table.boxId, builder: (column) => column);

  GeneratedColumn<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
    column: $table.confidenceScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detectedCrabs => $composableBuilder(
    column: $table.detectedCrabs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendations => $composableBuilder(
    column: $table.recommendations,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedbackStatus => $composableBuilder(
    column: $table.feedbackStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$VideosTableAnnotationComposer get videoId {
    final $$VideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideosTableAnnotationComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiDetectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiDetectionsTable,
          AiDetection,
          $$AiDetectionsTableFilterComposer,
          $$AiDetectionsTableOrderingComposer,
          $$AiDetectionsTableAnnotationComposer,
          $$AiDetectionsTableCreateCompanionBuilder,
          $$AiDetectionsTableUpdateCompanionBuilder,
          (AiDetection, $$AiDetectionsTableReferences),
          AiDetection,
          PrefetchHooks Function({bool videoId})
        > {
  $$AiDetectionsTableTableManager(_$AppDatabase db, $AiDetectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiDetectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiDetectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiDetectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> boxId = const Value.absent(),
                Value<String> moltingStatus = const Value.absent(),
                Value<String> healthStatus = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> detectedCrabs = const Value.absent(),
                Value<String> recommendations = const Value.absent(),
                Value<DateTime> analyzedAt = const Value.absent(),
                Value<String?> feedbackStatus = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiDetectionsCompanion(
                id: id,
                videoId: videoId,
                boxId: boxId,
                moltingStatus: moltingStatus,
                healthStatus: healthStatus,
                confidenceScore: confidenceScore,
                detectedCrabs: detectedCrabs,
                recommendations: recommendations,
                analyzedAt: analyzedAt,
                feedbackStatus: feedbackStatus,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String videoId,
                required String boxId,
                required String moltingStatus,
                Value<String> healthStatus = const Value.absent(),
                Value<double> confidenceScore = const Value.absent(),
                Value<String> detectedCrabs = const Value.absent(),
                Value<String> recommendations = const Value.absent(),
                required DateTime analyzedAt,
                Value<String?> feedbackStatus = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiDetectionsCompanion.insert(
                id: id,
                videoId: videoId,
                boxId: boxId,
                moltingStatus: moltingStatus,
                healthStatus: healthStatus,
                confidenceScore: confidenceScore,
                detectedCrabs: detectedCrabs,
                recommendations: recommendations,
                analyzedAt: analyzedAt,
                feedbackStatus: feedbackStatus,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AiDetectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.videoId,
                                referencedTable: $$AiDetectionsTableReferences
                                    ._videoIdTable(db),
                                referencedColumn: $$AiDetectionsTableReferences
                                    ._videoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AiDetectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiDetectionsTable,
      AiDetection,
      $$AiDetectionsTableFilterComposer,
      $$AiDetectionsTableOrderingComposer,
      $$AiDetectionsTableAnnotationComposer,
      $$AiDetectionsTableCreateCompanionBuilder,
      $$AiDetectionsTableUpdateCompanionBuilder,
      (AiDetection, $$AiDetectionsTableReferences),
      AiDetection,
      PrefetchHooks Function({bool videoId})
    >;
typedef $$InspectionsTableCreateCompanionBuilder =
    InspectionsCompanion Function({
      required String id,
      required String boxId,
      Value<String?> relatedVideoId,
      required String moltingStatus,
      Value<String> healthStatus,
      Value<double> weight,
      Value<String> notes,
      Value<String> photoUrls,
      required DateTime timestamp,
      required String operatorId,
      required String operatorName,
      Value<bool?> aiAgreement,
      Value<String> syncStatus,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$InspectionsTableUpdateCompanionBuilder =
    InspectionsCompanion Function({
      Value<String> id,
      Value<String> boxId,
      Value<String?> relatedVideoId,
      Value<String> moltingStatus,
      Value<String> healthStatus,
      Value<double> weight,
      Value<String> notes,
      Value<String> photoUrls,
      Value<DateTime> timestamp,
      Value<String> operatorId,
      Value<String> operatorName,
      Value<bool?> aiAgreement,
      Value<String> syncStatus,
      Value<bool> isDirty,
      Value<DateTime?> syncedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$InspectionsTableReferences
    extends BaseReferences<_$AppDatabase, $InspectionsTable, Inspection> {
  $$InspectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoxesTable _boxIdTable(_$AppDatabase db) =>
      db.boxes.createAlias('inspections__box_id__boxes__id');

  $$BoxesTableProcessedTableManager get boxId {
    final $_column = $_itemColumn<String>('box_id')!;

    final manager = $$BoxesTableTableManager(
      $_db,
      $_db.boxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InspectionsTableFilterComposer
    extends Composer<_$AppDatabase, $InspectionsTable> {
  $$InspectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedVideoId => $composableBuilder(
    column: $table.relatedVideoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrls => $composableBuilder(
    column: $table.photoUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operatorId => $composableBuilder(
    column: $table.operatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get aiAgreement => $composableBuilder(
    column: $table.aiAgreement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoxesTableFilterComposer get boxId {
    final $$BoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableFilterComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectionsTable> {
  $$InspectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedVideoId => $composableBuilder(
    column: $table.relatedVideoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrls => $composableBuilder(
    column: $table.photoUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operatorId => $composableBuilder(
    column: $table.operatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aiAgreement => $composableBuilder(
    column: $table.aiAgreement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoxesTableOrderingComposer get boxId {
    final $$BoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableOrderingComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectionsTable> {
  $$InspectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relatedVideoId => $composableBuilder(
    column: $table.relatedVideoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get moltingStatus => $composableBuilder(
    column: $table.moltingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthStatus => $composableBuilder(
    column: $table.healthStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoUrls =>
      $composableBuilder(column: $table.photoUrls, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get operatorId => $composableBuilder(
    column: $table.operatorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operatorName => $composableBuilder(
    column: $table.operatorName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get aiAgreement => $composableBuilder(
    column: $table.aiAgreement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$BoxesTableAnnotationComposer get boxId {
    final $$BoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boxId,
      referencedTable: $db.boxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.boxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InspectionsTable,
          Inspection,
          $$InspectionsTableFilterComposer,
          $$InspectionsTableOrderingComposer,
          $$InspectionsTableAnnotationComposer,
          $$InspectionsTableCreateCompanionBuilder,
          $$InspectionsTableUpdateCompanionBuilder,
          (Inspection, $$InspectionsTableReferences),
          Inspection,
          PrefetchHooks Function({bool boxId})
        > {
  $$InspectionsTableTableManager(_$AppDatabase db, $InspectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InspectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InspectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boxId = const Value.absent(),
                Value<String?> relatedVideoId = const Value.absent(),
                Value<String> moltingStatus = const Value.absent(),
                Value<String> healthStatus = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> photoUrls = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> operatorId = const Value.absent(),
                Value<String> operatorName = const Value.absent(),
                Value<bool?> aiAgreement = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectionsCompanion(
                id: id,
                boxId: boxId,
                relatedVideoId: relatedVideoId,
                moltingStatus: moltingStatus,
                healthStatus: healthStatus,
                weight: weight,
                notes: notes,
                photoUrls: photoUrls,
                timestamp: timestamp,
                operatorId: operatorId,
                operatorName: operatorName,
                aiAgreement: aiAgreement,
                syncStatus: syncStatus,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boxId,
                Value<String?> relatedVideoId = const Value.absent(),
                required String moltingStatus,
                Value<String> healthStatus = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> photoUrls = const Value.absent(),
                required DateTime timestamp,
                required String operatorId,
                required String operatorName,
                Value<bool?> aiAgreement = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectionsCompanion.insert(
                id: id,
                boxId: boxId,
                relatedVideoId: relatedVideoId,
                moltingStatus: moltingStatus,
                healthStatus: healthStatus,
                weight: weight,
                notes: notes,
                photoUrls: photoUrls,
                timestamp: timestamp,
                operatorId: operatorId,
                operatorName: operatorName,
                aiAgreement: aiAgreement,
                syncStatus: syncStatus,
                isDirty: isDirty,
                syncedAt: syncedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InspectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boxId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boxId,
                                referencedTable: $$InspectionsTableReferences
                                    ._boxIdTable(db),
                                referencedColumn: $$InspectionsTableReferences
                                    ._boxIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InspectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InspectionsTable,
      Inspection,
      $$InspectionsTableFilterComposer,
      $$InspectionsTableOrderingComposer,
      $$InspectionsTableAnnotationComposer,
      $$InspectionsTableCreateCompanionBuilder,
      $$InspectionsTableUpdateCompanionBuilder,
      (Inspection, $$InspectionsTableReferences),
      Inspection,
      PrefetchHooks Function({bool boxId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$BoxesTableTableManager get boxes =>
      $$BoxesTableTableManager(_db, _db.boxes);
  $$CrabsTableTableManager get crabs =>
      $$CrabsTableTableManager(_db, _db.crabs);
  $$WaterQualityReadingsTableTableManager get waterQualityReadings =>
      $$WaterQualityReadingsTableTableManager(_db, _db.waterQualityReadings);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db, _db.alerts);
  $$OperationLogsTableTableManager get operationLogs =>
      $$OperationLogsTableTableManager(_db, _db.operationLogs);
  $$HarvestsTableTableManager get harvests =>
      $$HarvestsTableTableManager(_db, _db.harvests);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db, _db.videos);
  $$AiDetectionsTableTableManager get aiDetections =>
      $$AiDetectionsTableTableManager(_db, _db.aiDetections);
  $$InspectionsTableTableManager get inspections =>
      $$InspectionsTableTableManager(_db, _db.inspections);
}
