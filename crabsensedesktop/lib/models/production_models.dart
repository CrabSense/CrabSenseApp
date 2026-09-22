import 'crab_lot_status.dart';
import 'crab_profile.dart';
import 'crab_status.dart';
import 'farm_record.dart';

class AreaSummaryStats {
  const AreaSummaryStats({
    required this.total,
    required this.active,
    required this.maintenance,
    required this.disabled,
    required this.totalBoxes,
  });

  final int total;
  final int active;
  final int maintenance;
  final int disabled;
  final int totalBoxes;

  factory AreaSummaryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AreaSummaryStats(
        total: 0,
        active: 0,
        maintenance: 0,
        disabled: 0,
        totalBoxes: 0,
      );
    }
    return AreaSummaryStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      maintenance: (json['maintenance'] as num?)?.toInt() ?? 0,
      disabled: (json['disabled'] as num?)?.toInt() ?? 0,
      totalBoxes: (json['totalBoxes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AreaRecord {
  const AreaRecord({
    required this.id,
    required this.farmId,
    required this.areaCode,
    required this.areaName,
    this.description,
    this.status = 'active',
    this.createdAt,
    this.rowCount = 0,
    this.boxCount = 0,
    this.esp32Count = 0,
    this.cameraCount = 0,
    this.mapImageUrl,
    this.mapX1,
    this.mapY1,
    this.mapX2,
    this.mapY2,
    this.location,
    this.region,
    this.address,
    this.avatarUrl,
    this.updatedAt,
    this.crabCount = 0,
    this.occupiedBoxCount = 0,
    this.healthyBoxCount = 0,
    this.watchBoxCount = 0,
    this.alertBoxCount = 0,
    this.emptyBoxCount = 0,
  });

  final String id;
  final String farmId;
  final String areaCode;
  final String areaName;
  final String? description;
  final String status;
  final DateTime? createdAt;
  final int rowCount;
  final int boxCount;
  final int esp32Count;
  final int cameraCount;

  /// Vị trí trong cơ sở (BE `location`), vd. "Đối diện tòa nhà Vinhomes S305".
  final String? location;

  /// Tên nơi / vùng (BE `region`), vd. "Lầu Gà lá é"; `address` giữ cột cũ.
  final String? region;
  final String? address;

  /// Tên nơi hiển thị cạnh mã khu: region → description → address.
  String? get placeName {
    for (final v in [region, description, address]) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty && t != areaCode) return t;
    }
    return null;
  }

  /// Ảnh đại diện khu (BE `avatarUrl`) — thumbnail trong card khu.
  final String? avatarUrl;

  /// Cập nhật cuối (BE `updatedAt`, fallback `createdAt`).
  final DateTime? updatedAt;

  /// Thống kê hộp trong khu (BE `FarmingAreaDto`).
  final int crabCount;
  final int occupiedBoxCount;
  final int healthyBoxCount;
  final int watchBoxCount;
  final int alertBoxCount;
  final int emptyBoxCount;

  /// Ảnh bản đồ trại (BE `mapImageUrl`). Null/rỗng → dùng ảnh mặc định.
  final String? mapImageUrl;

  /// Khung khu trên ảnh bản đồ, tỉ lệ 0–1 (BE `mapX1..mapY2`).
  final double? mapX1;
  final double? mapY1;
  final double? mapX2;
  final double? mapY2;

  bool get hasMapBounds =>
      mapX1 != null && mapY1 != null && mapX2 != null && mapY2 != null;

  String get subtitle =>
      description?.trim().isNotEmpty == true ? description!.trim() : areaCode;

  factory AreaRecord.fromJson(Map<String, dynamic> json) {
    final name =
        (json['areaName'] ?? json['AreaName'] ?? json['name'] ?? json['Name'] ?? '')
            .toString();
    final inactive = json['isActive'] == false || json['IsActive'] == false;
    return AreaRecord(
        id: (json['id'] ?? json['Id']).toString(),
        farmId: (json['farmId'] ??
                json['FarmId'] ??
                json['ownerId'] ??
                json['OwnerId'] ??
                json['farmingAreaId'] ??
                json['FarmingAreaId'] ??
                '')
            .toString(),
        areaCode: (json['code'] ??
                json['Code'] ??
                json['areaCode'] ??
                json['AreaCode'] ??
                name)
            .toString(),
        areaName: name,
        description: (json['description'] ?? json['Description'])?.toString(),
        status: inactive
            ? 'disabled'
            : (json['status'] ?? json['Status'] ?? 'active').toString(),
        createdAt: _parseAreaDate(json['createdAt'] ?? json['CreatedAt']),
        rowCount:
            ((json['rowCount'] ?? json['RowCount']) as num?)?.toInt() ?? 0,
        boxCount:
            ((json['boxCount'] ?? json['BoxCount']) as num?)?.toInt() ?? 0,
        esp32Count:
            ((json['esp32Count'] ?? json['Esp32Count']) as num?)?.toInt() ?? 0,
        cameraCount:
            ((json['cameraCount'] ?? json['CameraCount']) as num?)?.toInt() ??
                0,
        mapImageUrl: (json['mapImageUrl'] ?? json['MapImageUrl'])?.toString(),
        mapX1: _parseRatio(json['mapX1'] ?? json['MapX1']),
        mapY1: _parseRatio(json['mapY1'] ?? json['MapY1']),
        mapX2: _parseRatio(json['mapX2'] ?? json['MapX2']),
        mapY2: _parseRatio(json['mapY2'] ?? json['MapY2']),
        location: (json['location'] ?? json['Location'])?.toString(),
        region: (json['region'] ?? json['Region'])?.toString(),
        address: (json['address'] ?? json['Address'])?.toString(),
        avatarUrl: (json['avatarUrl'] ?? json['AvatarUrl'])?.toString(),
        updatedAt: _parseAreaDate(
          json['updatedAt'] ?? json['UpdatedAt'] ?? json['createdAt'] ?? json['CreatedAt'],
        ),
        crabCount: _areaInt(json, 'crabCount', 'CrabCount'),
        occupiedBoxCount: _areaInt(json, 'occupiedBoxCount', 'OccupiedBoxCount'),
        healthyBoxCount: _areaInt(json, 'healthyBoxCount', 'HealthyBoxCount'),
        watchBoxCount: _areaInt(json, 'watchBoxCount', 'WatchBoxCount'),
        alertBoxCount: _areaInt(json, 'alertBoxCount', 'AlertBoxCount'),
        emptyBoxCount: _areaInt(json, 'emptyBoxCount', 'EmptyBoxCount'),
      );
  }

  static int _areaInt(Map<String, dynamic> json, String a, String b) {
    final raw = json[a] ?? json[b];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  static DateTime? _parseAreaDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  AreaRecord copyWith({
    int? rowCount,
    int? boxCount,
    int? esp32Count,
    int? cameraCount,
  }) =>
      AreaRecord(
        id: id,
        farmId: farmId,
        areaCode: areaCode,
        areaName: areaName,
        description: description,
        status: status,
        createdAt: createdAt,
        rowCount: rowCount ?? this.rowCount,
        boxCount: boxCount ?? this.boxCount,
        esp32Count: esp32Count ?? this.esp32Count,
        cameraCount: cameraCount ?? this.cameraCount,
        mapImageUrl: mapImageUrl,
        mapX1: mapX1,
        mapY1: mapY1,
        mapX2: mapX2,
        mapY2: mapY2,
        location: location,
        region: region,
        address: address,
        avatarUrl: avatarUrl,
        updatedAt: updatedAt,
        crabCount: crabCount,
        occupiedBoxCount: occupiedBoxCount,
        healthyBoxCount: healthyBoxCount,
        watchBoxCount: watchBoxCount,
        alertBoxCount: alertBoxCount,
        emptyBoxCount: emptyBoxCount,
      );
}

/// Toạ độ bản đồ BE trả dạng tỉ lệ 0–1 (numeric) — chấp nhận num hoặc chuỗi.
double? _parseRatio(dynamic raw) {
  if (raw == null) return null;
  final v = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
  if (v == null || v.isNaN) return null;
  return v.clamp(0.0, 1.0).toDouble();
}

class RowRecord {
  const RowRecord({
    required this.id,
    required this.areaId,
    required this.rowCode,
    required this.rowName,
    this.areaName,
    this.areaLocation,
    this.location,
    this.description,
    this.capacity = 0,
    this.status = FarmStatus.active,
    this.boxCount = 0,
    this.crabCount = 0,
    this.healthyBoxCount = 0,
    this.alertBoxCount = 0,
    this.occupiedBoxCount = 0,
    this.watchBoxCount = 0,
    this.emptyBoxCount = 0,
    this.updatedAt,
    this.mapX,
    this.mapY,
  });

  final String id;
  final String areaId;
  final String? areaName;
  final String? areaLocation;
  final String rowCode;
  final String rowName;
  final String? location;
  final String? description;
  final int capacity;
  final FarmStatus status;
  final int boxCount;
  final int crabCount;
  final int healthyBoxCount;
  final int alertBoxCount;

  /// Hộp đang có cua / theo dõi / trống (BE `OccupiedBoxCount`…). Nếu BE cũ
  /// chưa trả, xem [occupiedBoxes] / [emptyBoxes] để có giá trị suy ra.
  final int occupiedBoxCount;
  final int watchBoxCount;
  final int emptyBoxCount;
  final DateTime? updatedAt;

  int get occupiedBoxes =>
      occupiedBoxCount > 0 ? occupiedBoxCount : crabCount.clamp(0, boxCount);
  int get emptyBoxes => (boxCount - occupiedBoxes).clamp(0, boxCount);

  /// Tâm dãy trên ảnh bản đồ trại, tỉ lệ 0–1 (BE `mapX`/`mapY`).
  final double? mapX;
  final double? mapY;

  bool get hasMapPoint => mapX != null && mapY != null;

  String get displayLocation {
    final loc = location?.trim() ?? '';
    if (loc.isEmpty) return '—';
    return loc;
  }

  String get displayPlace {
    final area = areaName?.trim() ?? '';
    final loc = location?.trim() ?? '';
    if (area.isEmpty && loc.isEmpty) return '—';
    if (loc.isEmpty) return area;
    if (area.isEmpty) return loc;
    return '$area - $loc';
  }

  String get displayBoxes {
    if (capacity > 0) return '$boxCount / $capacity';
    return '$boxCount';
  }

  factory RowRecord.fromJson(Map<String, dynamic> json) {
    final name =
        (json['rowName'] ?? json['RowName'] ?? json['name'] ?? json['Name'] ?? '')
            .toString();
    final code = (json['code'] ??
            json['Code'] ??
            json['rowCode'] ??
            json['RowCode'] ??
            name)
        .toString();
    return RowRecord(
      id: (json['id'] ?? json['Id']).toString(),
      areaId: (json['areaId'] ??
              json['AreaId'] ??
              json['farmingAreaId'] ??
              json['FarmingAreaId'] ??
              '')
          .toString(),
      areaName: (json['areaName'] ?? json['AreaName'])?.toString(),
      areaLocation: (json['areaLocation'] ?? json['AreaLocation'])?.toString(),
      rowCode: code.isNotEmpty ? code : name,
      rowName: name,
      location: (json['location'] ?? json['Location'])?.toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      capacity: _rowInt(json, 'capacity', 'Capacity'),
      status: FarmStatus.parse(
        json['status'] ?? json['Status'],
        json['isActive'] ?? json['IsActive'],
      ),
      boxCount: _rowInt(json, 'boxCount', 'BoxCount'),
      crabCount: _rowInt(json, 'crabCount', 'CrabCount'),
      healthyBoxCount: _rowInt(json, 'healthyBoxCount', 'HealthyBoxCount'),
      alertBoxCount: _rowInt(json, 'alertBoxCount', 'AlertBoxCount'),
      occupiedBoxCount: _rowInt(json, 'occupiedBoxCount', 'OccupiedBoxCount'),
      watchBoxCount: _rowInt(json, 'watchBoxCount', 'WatchBoxCount'),
      emptyBoxCount: _rowInt(json, 'emptyBoxCount', 'EmptyBoxCount'),
      updatedAt: DateTime.tryParse(
          (json['updatedAt'] ?? json['UpdatedAt'] ?? '').toString()),
      mapX: _parseRatio(json['mapX'] ?? json['MapX']),
      mapY: _parseRatio(json['mapY'] ?? json['MapY']),
    );
  }

  static int _rowInt(Map<String, dynamic> json, String a, String b) {
    final raw = json[a] ?? json[b];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }
}

class BoxRecord {
  const BoxRecord({
    required this.id,
    required this.rowId,
    required this.boxCode,
    this.position,
    this.volume,
    required this.status,
    this.displayName,
    this.areaId,
    this.areaName,
    this.areaCode,
    this.rowName,
    this.rowCode,
    this.isOccupied = false,
    this.crabId,
    this.crabTag,
    this.crabMoltingStage,
    this.crabStatus,
    this.crabCondition,
    this.alertCount = 0,
    this.aiSummary,
    this.crabCount = 0,
    this.crabInBoxSince,
    this.aiUpdatedAt,
    this.emptySince,
    this.mapX,
    this.mapY,
  });

  final String id;
  final String rowId;
  final String boxCode;
  final String? position;
  final double? volume;
  final String status;
  final String? displayName;
  final String? areaId;
  final String? areaName;
  final String? areaCode;
  final String? rowName;
  final String? rowCode;
  final bool isOccupied;
  final String? crabId;
  final String? crabTag;
  final String? crabMoltingStage;
  final String? crabStatus;
  final String? crabCondition;
  final int alertCount;
  final String? aiSummary;
  final int crabCount;
  final DateTime? crabInBoxSince;
  final DateTime? aiUpdatedAt;
  final DateTime? emptySince;

  /// Tâm hộp trên ảnh bản đồ trại, tỉ lệ 0–1 (BE `mapX`/`mapY`).
  final double? mapX;
  final double? mapY;

  bool get hasMapPoint => mapX != null && mapY != null;

  String get title =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!.trim()
          : boxCode;

  bool get hasCrab {
    if (crabCount > 0) return true;
    final life = (crabStatus ?? '').trim().toLowerCase();
    final cond = (crabCondition ?? '').trim().toLowerCase();
    if (life == 'dead' ||
        life == 'harvested' ||
        life == 'missing' ||
        life == 'sold' ||
        cond == 'dead' ||
        cond == 'harvested' ||
        cond == 'sold') {
      return false;
    }
    if (crabId != null && crabId!.isNotEmpty && crabId != 'null') return true;
    if (crabTag != null && crabTag!.trim().isNotEmpty) return true;
    return isOccupied && status.toLowerCase() != 'empty';
  }

  factory BoxRecord.fromJson(Map<String, dynamic> json) {
    final occupied = json['isOccupied'] == true || json['IsOccupied'] == true;
    final code =
        (json['boxCode'] ?? json['BoxCode'] ?? json['code'] ?? json['Code'] ?? '')
            .toString();
    return BoxRecord(
      id: (json['id'] ?? json['Id']).toString(),
      rowId: (json['rowId'] ??
              json['RowId'] ??
              json['farmingRowId'] ??
              json['FarmingRowId'] ??
              '')
          .toString(),
      boxCode: code,
      position: (json['position'] ?? json['Position'])?.toString(),
      volume: (json['volume'] ?? json['Volume']) is num
          ? (json['volume'] ?? json['Volume']).toDouble()
          : null,
      status: (json['status'] ?? json['Status'] ?? (occupied ? 'occupied' : 'empty'))
          .toString(),
      displayName: _boxStr(json, const ['displayName', 'DisplayName']),
      areaId: _boxStr(json, const [
        'areaId',
        'AreaId',
        'farmingAreaId',
        'FarmingAreaId',
      ]),
      areaName: _boxStr(json, const ['areaName', 'AreaName']),
      areaCode: _boxStr(json, const ['areaCode', 'AreaCode']),
      rowName: _boxStr(json, const ['rowName', 'RowName']),
      rowCode: _boxStr(json, const ['rowCode', 'RowCode']),
      isOccupied: occupied,
      crabId: _boxStr(json, const ['crabId', 'CrabId']),
      crabTag: _boxStr(json, const ['crabTag', 'CrabTag']),
      crabMoltingStage:
          _boxStr(json, const ['crabMoltingStage', 'CrabMoltingStage']),
      crabStatus: _boxStr(json, const ['crabStatus', 'CrabStatus']),
      crabCondition: _boxStr(json, const ['crabCondition', 'CrabCondition']),
      alertCount: _boxInt(json, 'alertCount', 'AlertCount'),
      aiSummary: _boxStr(json, const ['aiSummary', 'AiSummary']),
      crabCount: _boxInt(json, 'crabCount', 'CrabCount'),
      crabInBoxSince: _boxDate(
        json,
        const ['crabInBoxSince', 'CrabInBoxSince'],
      ),
      aiUpdatedAt: _boxDate(
        json,
        const ['aiUpdatedAt', 'AiUpdatedAt'],
      ),
      emptySince: _boxDate(
        json,
        const ['emptySince', 'EmptySince'],
      ),
      mapX: _parseRatio(json['mapX'] ?? json['MapX']),
      mapY: _parseRatio(json['mapY'] ?? json['MapY']),
    );
  }

  static int _boxInt(Map<String, dynamic> json, String a, String b) {
    final raw = json[a] ?? json[b];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  static DateTime? _boxDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw == null) continue;
      if (raw is DateTime) return raw;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  static String? _boxStr(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }
}

class FarmingBatchRecord {
  const FarmingBatchRecord({
    required this.id,
    required this.boxId,
    required this.batchCode,
    required this.startDate,
    this.expectedHarvestDate,
    this.actualHarvestDate,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.status,
    this.boxCode,
    this.name,
    this.supplierName,
    this.totalWeightKg,
    this.averageWeightGram,
    this.weightMinGram,
    this.weightMaxGram,
    this.unitPriceVndPerKg,
    this.crabCostVnd,
    this.shippingCostVnd,
    this.otherCostVnd,
    this.totalCostVnd,
    this.condition = 'Good',
    this.deadOnArrival = 0,
    this.notes,
    this.imageUrls = const [],
  });

  final String id;
  final String boxId;
  final String batchCode;
  final String? boxCode;
  final DateTime startDate;
  final DateTime? expectedHarvestDate;
  final DateTime? actualHarvestDate;
  final int initialQuantity;
  final int currentQuantity;
  final String status;
  final String? name;
  final String? supplierName;
  final double? totalWeightKg;
  final double? averageWeightGram;
  final double? weightMinGram;
  final double? weightMaxGram;
  final double? unitPriceVndPerKg;
  final double? crabCostVnd;
  final double? shippingCostVnd;
  final double? otherCostVnd;
  final double? totalCostVnd;
  final String condition;
  final int deadOnArrival;
  final String? notes;
  final List<String> imageUrls;

  int get placedCount => currentQuantity;

  CrabLotWorkflowStatus get workflowStatus => CrabLotWorkflowStatusX.resolve(
        raw: status,
        placed: placedCount,
        quantity: initialQuantity,
      );

  String get lotName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return batchCode;
  }

  int get remainingCount {
    if (workflowStatus == CrabLotWorkflowStatus.cancelled) return 0;
    final left = initialQuantity - placedCount - deadOnArrival;
    return left < 0 ? 0 : left;
  }

  int get rejectedCount {
    if (workflowStatus == CrabLotWorkflowStatus.cancelled) {
      final leftover = initialQuantity - placedCount;
      return deadOnArrival + (leftover < 0 ? 0 : leftover);
    }
    return deadOnArrival;
  }

  int get allocationPercent {
    if (initialQuantity <= 0) return 0;
    final p = ((placedCount / initialQuantity) * 100).round();
    if (p < 0) return 0;
    if (p > 100) return 100;
    return p;
  }

  /// Tên lô · mã lô (phiếu nhập).
  String get displayLabel {
    final n = name?.trim();
    if (n != null && n.isNotEmpty && n != batchCode) {
      return '$n · $batchCode';
    }
    final box = boxCode?.trim();
    if (box != null && box.isNotEmpty) return '$batchCode — $box';
    return batchCode;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.length >= 10) return DateTime.tryParse(s.substring(0, 10));
    return DateTime.tryParse(s);
  }

  static double? _num(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) {
        final parsed = double.tryParse(raw.replaceAll(',', ''));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  factory FarmingBatchRecord.fromJson(Map<String, dynamic> json) {
    final qty = ((json['quantity'] ??
                json['Quantity'] ??
                json['initialQuantity'] ??
                json['InitialQuantity']) as num?)
            ?.toInt() ??
        0;
    final placed = ((json['placedCount'] ??
                json['PlacedCount'] ??
                json['currentQuantity'] ??
                json['CurrentQuantity']) as num?)
            ?.toInt();
    return FarmingBatchRecord(
      id: (json['id'] ?? json['Id']).toString(),
      boxId: (json['boxId'] ?? json['BoxId'] ?? '').toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'])?.toString(),
      batchCode: (json['lotCode'] ??
              json['LotCode'] ??
              json['batchCode'] ??
              json['BatchCode'] ??
              '')
          .toString(),
      name: (json['name'] ?? json['Name'])?.toString(),
      startDate: _parseDate(
            json['importDate'] ??
                json['ImportDate'] ??
                json['startDate'] ??
                json['StartDate'],
          ) ??
          DateTime.now(),
      expectedHarvestDate:
          _parseDate(json['expectedHarvestDate'] ?? json['ExpectedHarvestDate']),
      actualHarvestDate:
          _parseDate(json['actualHarvestDate'] ?? json['ActualHarvestDate']),
      initialQuantity: qty,
      currentQuantity: placed ?? qty,
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      supplierName: (json['supplierName'] ?? json['SupplierName'])?.toString(),
      totalWeightKg: _num(json, ['totalWeightKg', 'TotalWeightKg']),
      averageWeightGram: _num(json, ['averageWeightGram', 'AverageWeightGram']),
      weightMinGram: _num(json, ['weightMinGram', 'WeightMinGram']),
      weightMaxGram: _num(json, ['weightMaxGram', 'WeightMaxGram']),
      unitPriceVndPerKg: _num(json, ['unitPriceVndPerKg', 'UnitPriceVndPerKg']),
      crabCostVnd: _num(json, ['crabCostVnd', 'CrabCostVnd']),
      shippingCostVnd: _num(json, ['shippingCostVnd', 'ShippingCostVnd']),
      otherCostVnd: _num(json, ['otherCostVnd', 'OtherCostVnd']),
      totalCostVnd: _num(json, ['totalCostVnd', 'TotalCostVnd']),
      condition: (json['condition'] ?? json['Condition'] ?? 'Good').toString(),
      deadOnArrival:
          ((json['deadOnArrival'] ?? json['DeadOnArrival']) as num?)?.toInt() ??
              0,
      notes: (json['notes'] ?? json['Notes'])?.toString(),
      imageUrls: parseCrabImageUrls(
        json['imageUrls'] ?? json['ImageUrls'] ?? json['imageUrlsJson'] ?? json['ImageUrlsJson'],
      ),
    );
  }
}

class BatchCrabRecord {
  const BatchCrabRecord({
    required this.id,
    required this.batchId,
    required this.crabCode,
    required this.gender,
    this.weight,
    this.shellWidth,
    required this.status,
  });

  final String id;
  final String batchId;
  final String crabCode;
  final String gender;
  final double? weight;
  final double? shellWidth;
  final String status;

  factory BatchCrabRecord.fromJson(Map<String, dynamic> json) {
    final status = resolveCrabLifecycleStatus(json);
    final weightRaw = json['weightGram'] ?? json['WeightGram'] ?? json['weight'] ?? json['Weight'];
    return BatchCrabRecord(
      id: (json['id'] ?? json['Id']).toString(),
      batchId: (json['crabLotId'] ??
              json['CrabLotId'] ??
              json['batchId'] ??
              json['BatchId'] ??
              '')
          .toString(),
      crabCode: (json['tag'] ?? json['Tag'] ?? json['crabCode'] ?? json['CrabCode'] ?? '')
          .toString(),
      gender: (json['gender'] ?? json['Gender'] ?? 'unknown').toString(),
      weight: weightRaw is num ? weightRaw.toDouble() : null,
      shellWidth: _crabWidthMm(json),
      status: status,
    );
  }
}

class CrabManagementSummaryDto {
  const CrabManagementSummaryDto({
    required this.total,
    required this.alive,
    required this.dead,
    required this.molting,
    required this.readyHarvest,
  });

  final int total;
  final int alive;
  final int dead;
  final int molting;
  final int readyHarvest;

  factory CrabManagementSummaryDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CrabManagementSummaryDto(
        total: 0,
        alive: 0,
        dead: 0,
        molting: 0,
        readyHarvest: 0,
      );
    }
    return CrabManagementSummaryDto(
      total: (json['total'] as num? ?? json['Total'] as num?)?.toInt() ?? 0,
      alive: (json['alive'] as num? ?? json['Alive'] as num?)?.toInt() ?? 0,
      dead: (json['dead'] as num? ?? json['Dead'] as num?)?.toInt() ?? 0,
      molting: (json['molting'] as num? ?? json['Molting'] as num?)?.toInt() ?? 0,
      readyHarvest:
          (json['readyHarvest'] as num? ?? json['ReadyHarvest'] as num?)?.toInt() ?? 0,
    );
  }
}

class CrabManagementListItem {
  const CrabManagementListItem({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.boxId,
    required this.boxCode,
    required this.rowId,
    required this.rowCode,
    required this.rowName,
    required this.areaId,
    required this.areaCode,
    required this.areaName,
    required this.crabCode,
    required this.gender,
    this.weight,
    this.shellWidth,
    this.shellLength,
    required this.status,
    required this.moltCount,
    this.lastMoltDate,
    this.healthStatus,
    this.growthStage,
    this.profileNote,
    required this.batchStartDate,
  });

  final String id;
  final String batchId;
  final String batchCode;
  final String boxId;
  final String boxCode;
  final String rowId;
  final String rowCode;
  final String rowName;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String crabCode;
  final String gender;
  final double? weight;
  final double? shellWidth;
  final double? shellLength;
  final String status;
  final int moltCount;
  final String? lastMoltDate;
  final String? healthStatus;
  final String? growthStage;
  final String? profileNote;
  final String batchStartDate;

  factory CrabManagementListItem.fromJson(Map<String, dynamic> json) {
    final molting = (json['moltingStage'] ?? json['MoltingStage'] ?? '').toString();
    final status = resolveCrabLifecycleStatus(json);
    final weightRaw =
        json['weightGram'] ?? json['WeightGram'] ?? json['weight'] ?? json['Weight'];
    final lotId = (json['crabLotId'] ??
            json['CrabLotId'] ??
            json['batchId'] ??
            json['BatchId'] ??
            '')
        .toString();
    return CrabManagementListItem(
      id: (json['id'] ?? json['Id']).toString(),
      batchId: lotId,
      batchCode: (json['lotCode'] ??
              json['LotCode'] ??
              json['batchCode'] ??
              json['BatchCode'] ??
              lotId)
          .toString(),
      boxId: (json['boxId'] ?? json['BoxId'] ?? '').toString(),
      boxCode: (json['boxCode'] ?? json['BoxCode'] ?? '').toString(),
      rowId: (json['farmingRowId'] ??
              json['FarmingRowId'] ??
              json['rowId'] ??
              json['RowId'] ??
              '')
          .toString(),
      rowCode: (json['rowCode'] ?? json['RowCode'] ?? '').toString(),
      rowName: (json['rowName'] ?? json['RowName'] ?? '').toString(),
      areaId: (json['farmingAreaId'] ??
              json['FarmingAreaId'] ??
              json['areaId'] ??
              json['AreaId'] ??
              '')
          .toString(),
      areaCode: (json['areaCode'] ?? json['AreaCode'] ?? '').toString(),
      areaName: (json['areaName'] ?? json['AreaName'] ?? '').toString(),
      crabCode: (json['tag'] ??
              json['Tag'] ??
              json['crabCode'] ??
              json['CrabCode'] ??
              '')
          .toString(),
      gender: (json['gender'] ?? json['Gender'] ?? 'unknown').toString(),
      weight: weightRaw is num ? weightRaw.toDouble() : null,
      shellWidth: _crabWidthMm(json),
      shellLength: _crabLengthMm(json),
      status: status,
      moltCount: (json['moltCount'] ?? json['MoltCount'] as num?)?.toInt() ?? 0,
      lastMoltDate: (json['moltedAt'] ??
              json['MoltedAt'] ??
              json['lastMoltDate'] ??
              json['LastMoltDate'])
          ?.toString(),
      healthStatus: (json['healthStatus'] ??
              json['HealthStatus'] ??
              json['condition'] ??
              json['Condition'] ??
              molting)
          ?.toString(),
      growthStage: (json['growthStage'] ?? json['GrowthStage'])?.toString(),
      profileNote: (json['profileNote'] ?? json['ProfileNote'])?.toString(),
      batchStartDate: (json['stockedAt'] ??
              json['StockedAt'] ??
              json['batchStartDate'] ??
              json['BatchStartDate'] ??
              '')
          .toString(),
    );
  }
}

double? _crabWidthMm(Map<String, dynamic> json) {
  final raw = json['carapaceWidthMm'] ??
      json['CarapaceWidthMm'] ??
      json['shellWidth'] ??
      json['ShellWidth'];
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw');
}

double? _crabLengthMm(Map<String, dynamic> json) {
  final raw = json['carapaceLengthMm'] ?? json['CarapaceLengthMm'];
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw');
}
