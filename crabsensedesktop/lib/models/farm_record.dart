import 'auth_models.dart';

class FarmRecord {
  const FarmRecord({
    required this.id,
    required this.code,
    required this.name,
    this.location,
    this.address = '',
    this.region,
    this.areaSquareMeters,
    this.establishedAt,
    this.description,
    this.avatarUrl,
    this.status = FarmStatus.active,
    this.ownerId,
    this.createdAt,
    this.rowCount = 0,
    this.boxCount = 0,
    this.crabCount = 0,
    this.healthyBoxCount = 0,
    this.alertBoxCount = 0,
  });

  final String id;
  final String code;
  final String name;
  final String? location;
  final String address;
  final String? region;
  final double? areaSquareMeters;
  final DateTime? establishedAt;
  final String? description;
  final String? avatarUrl;
  final FarmStatus status;
  final String? ownerId;
  final DateTime? createdAt;
  final int rowCount;
  final int boxCount;
  final int crabCount;
  final int healthyBoxCount;
  final int alertBoxCount;

  bool get isActive => status == FarmStatus.active;

  static bool _isBlankAddress(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return true;
    return t.toLowerCase() == 'chưa cập nhật';
  }

  String get displayLocation {
    final loc = location?.trim() ?? '';
    if (loc.isEmpty) return '—';
    return loc;
  }

  String get displayAddress {
    final addr = _isBlankAddress(address) ? '' : address.trim();
    final reg = region?.trim() ?? '';
    if (addr.isEmpty && reg.isEmpty) return '—';
    if (addr.isEmpty) return reg;
    if (reg.isEmpty) return addr;
    if (addr.toLowerCase().contains(reg.toLowerCase())) return addr;
    return '$addr, $reg';
  }

  String get displayArea {
    final n = areaSquareMeters;
    if (n == null) return '—';
    if ((n - n.round()).abs() < 0.001) return '${n.round()} m²';
    return '${n.toStringAsFixed(1)} m²';
  }

  /// Bỏ địa chỉ cũ bị nhét vào mô tả (`địa chỉ — mô tả`).
  String? get displayDescription {
    var desc = description?.trim() ?? '';
    if (desc.isEmpty) return null;

    if (desc.contains(' — ')) {
      final parts = desc.split(' — ');
      final head = parts.first.trim();
      final tail = parts.sublist(1).join(' — ').trim();
      if (_isBlankAddress(head) ||
          (!_isBlankAddress(address) &&
              (address.contains(head) || head.contains(address.trim())))) {
        desc = tail;
      }
    }

    if (desc.isEmpty) return null;
    if (desc == address.trim() || desc == displayAddress) return null;
    return desc;
  }

  factory FarmRecord.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreated != null) created = DateTime.tryParse(rawCreated.toString());

    DateTime? established;
    final rawEst = json['establishedAt'] ?? json['EstablishedAt'];
    if (rawEst != null) established = DateTime.tryParse(rawEst.toString());

    final name = (json['name'] ?? json['Name'] ?? 'Khu nuôi').toString();
    final code = (json['code'] ?? json['Code'] ?? '').toString();
    final areaRaw = json['areaSquareMeters'] ?? json['AreaSquareMeters'];
    return FarmRecord(
      id: (json['id'] ?? json['Id']).toString(),
      code: code.isNotEmpty ? code : name,
      name: name,
      location: (json['location'] ?? json['Location'])?.toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
      region: (json['region'] ?? json['Region'])?.toString(),
      areaSquareMeters: areaRaw is num ? areaRaw.toDouble() : double.tryParse('$areaRaw'),
      establishedAt: established,
      description: (json['description'] ?? json['Description'])?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['AvatarUrl'])?.toString(),
      status: FarmStatus.parse(json['status'] ?? json['Status'], json['isActive'] ?? json['IsActive']),
      ownerId: (json['ownerId'] ?? json['OwnerId'])?.toString(),
      createdAt: created,
      rowCount: _intOf(json, 'rowCount', 'RowCount'),
      boxCount: _intOf(json, 'boxCount', 'BoxCount'),
      crabCount: _intOf(json, 'crabCount', 'CrabCount'),
      healthyBoxCount: _intOf(json, 'healthyBoxCount', 'HealthyBoxCount'),
      alertBoxCount: _intOf(json, 'alertBoxCount', 'AlertBoxCount'),
    );
  }

  FarmSummary toSummary() => FarmSummary(id: id, code: code, name: name);

  static int _intOf(Map<String, dynamic> json, String a, String b) {
    final raw = json[a] ?? json[b];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }
}

enum FarmStatus {
  active,
  suspended,
  closed;

  String get apiValue => switch (this) {
        FarmStatus.active => 'Active',
        FarmStatus.suspended => 'Suspended',
        FarmStatus.closed => 'Closed',
      };

  String get label => switch (this) {
        FarmStatus.active => 'Đang hoạt động',
        FarmStatus.suspended => 'Tạm ngưng',
        FarmStatus.closed => 'Ngừng hoạt động',
      };

  String get emoji => switch (this) {
        FarmStatus.active => '🟢',
        FarmStatus.suspended => '🟡',
        FarmStatus.closed => '🔴',
      };

  static FarmStatus parse(dynamic status, [dynamic isActive]) {
    final raw = status?.toString().trim().toLowerCase() ?? '';
    if (raw == 'suspended') return FarmStatus.suspended;
    if (raw == 'closed' || raw == 'inactive' || raw == 'disabled') {
      return FarmStatus.closed;
    }
    if (raw == 'active') return FarmStatus.active;
    if (isActive == false) return FarmStatus.closed;
    return FarmStatus.active;
  }
}
