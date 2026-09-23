// ignore_for_file: lines_longer_than_80_chars

/// Data models for Quản lý Cua (Crab Management) feature.
/// Follows the desktop spec with full lifecycle + health tracking.
library;

// ── Enums ─────────────────────────────────────────────────────────────────────

enum CrabHealthStatus {
  healthy, // HEALTHY — Khỏe mạnh
  monitoring, // MONITORING — Theo dõi
  weak, // WEAK — Bệnh / Yếu
  alert, // ALERT — Cảnh báo
  unknown,
}

enum CrabLifecycleStatus {
  growing, // GROWING — Đang nuôi
  molting, // MOLTING — Đang lột xác
  readyToHarvest, // READY_TO_HARVEST — Sắp thu hoạch
  harvested, // HARVESTED — Đã thu hoạch
  dead, // DEAD — Chết
  unknown,
}

enum CrabGender {
  female, // Cái
  male, // Đực
  unknown, // Chưa xác định
}

// ── Extensions ────────────────────────────────────────────────────────────────

extension CrabHealthStatusX on CrabHealthStatus {
  String get label {
    switch (this) {
      case CrabHealthStatus.healthy:
        return 'Khỏe mạnh';
      case CrabHealthStatus.monitoring:
        return 'Theo dõi';
      case CrabHealthStatus.weak:
        return 'Bệnh / Yếu';
      case CrabHealthStatus.alert:
        return 'Cảnh báo';
      case CrabHealthStatus.unknown:
        return 'Không rõ';
    }
  }

  static CrabHealthStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'HEALTHY':
        return CrabHealthStatus.healthy;
      case 'MONITORING':
        return CrabHealthStatus.monitoring;
      case 'WEAK':
        return CrabHealthStatus.weak;
      case 'ALERT':
        return CrabHealthStatus.alert;
      default:
        return CrabHealthStatus.unknown;
    }
  }
}

extension CrabLifecycleStatusX on CrabLifecycleStatus {
  String get label {
    switch (this) {
      case CrabLifecycleStatus.growing:
        return 'Đang nuôi';
      case CrabLifecycleStatus.molting:
        return 'Đang lột xác';
      case CrabLifecycleStatus.readyToHarvest:
        return 'Sắp thu hoạch';
      case CrabLifecycleStatus.harvested:
        return 'Đã thu hoạch';
      case CrabLifecycleStatus.dead:
        return 'Chết';
      case CrabLifecycleStatus.unknown:
        return 'Không rõ';
    }
  }

  static CrabLifecycleStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'GROWING':
        return CrabLifecycleStatus.growing;
      case 'MOLTING':
        return CrabLifecycleStatus.molting;
      case 'READY_TO_HARVEST':
        return CrabLifecycleStatus.readyToHarvest;
      case 'HARVESTED':
        return CrabLifecycleStatus.harvested;
      case 'DEAD':
        return CrabLifecycleStatus.dead;
      default:
        return CrabLifecycleStatus.unknown;
    }
  }
}

extension CrabGenderX on CrabGender {
  String get label {
    switch (this) {
      case CrabGender.female:
        return 'Cái';
      case CrabGender.male:
        return 'Đực';
      case CrabGender.unknown:
        return 'Chưa xác định';
    }
  }

  static CrabGender fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'FEMALE':
        return CrabGender.female;
      case 'MALE':
        return CrabGender.male;
      default:
        return CrabGender.unknown;
    }
  }
}

// ── Batch ref ─────────────────────────────────────────────────────────────────

class CrabBatchRef {
  const CrabBatchRef({required this.id, this.name});
  final String id;
  final String? name;
}

// ── Location ref ──────────────────────────────────────────────────────────────

class CrabLocationRef {
  const CrabLocationRef({
    required this.farmAreaId,
    required this.farmAreaName,
    required this.rowId,
    required this.rowName,
    required this.boxId,
    required this.boxCode,
  });
  final String farmAreaId;
  final String farmAreaName;
  final String rowId;
  final String rowName;
  final String boxId;
  final String boxCode;
}

// ── Main crab record ──────────────────────────────────────────────────────────

class CrabRecord {
  const CrabRecord({
    required this.id,
    required this.location,
    required this.batch,
    required this.gender,
    required this.weightGram,
    required this.shellWidthMm,
    required this.shellLengthMm,
    required this.moltCount,
    required this.healthStatus,
    required this.lifecycleStatus,
    required this.enteredAt,
    required this.updatedAt,
    this.lastMoltAt,
    this.note,
    this.aiStatus,
  });

  final String id;
  final CrabLocationRef location;
  final CrabBatchRef batch;
  final CrabGender gender;
  final double weightGram;
  final double shellWidthMm;
  final double shellLengthMm;
  final int moltCount;
  final CrabHealthStatus healthStatus;
  final CrabLifecycleStatus lifecycleStatus;
  final DateTime enteredAt;
  final DateTime updatedAt;
  final DateTime? lastMoltAt;
  final String? note;
  final String? aiStatus; // e.g. "Không phát hiện bất thường"

  /// Format: "92 × 74 mm"
  String get sizeLabel {
    final w = shellWidthMm % 1 == 0
        ? shellWidthMm.toInt().toString()
        : shellWidthMm.toStringAsFixed(1);
    final l = shellLengthMm % 1 == 0
        ? shellLengthMm.toInt().toString()
        : shellLengthMm.toStringAsFixed(1);
    return '$w × $l mm';
  }

  /// Format: "120 g"
  String get weightLabel {
    if (weightGram % 1 == 0) return '${weightGram.toInt()} g';
    return '${weightGram.toStringAsFixed(1)} g';
  }

  factory CrabRecord.fromJson(Map<String, dynamic> json) {
    String asStr(Object? v) => v?.toString() ?? '';
    double asDouble(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int asInt(Object? v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final batchJson = json['batch'] as Map<String, dynamic>? ?? {};
    final farmAreaJson = json['farmArea'] as Map<String, dynamic>? ?? {};
    final rowJson = json['row'] as Map<String, dynamic>? ?? {};
    final boxJson = json['box'] as Map<String, dynamic>? ?? {};

    return CrabRecord(
      id: asStr(json['id']),
      batch: CrabBatchRef(
        id: asStr(batchJson['id'] ?? json['batchId'] ?? json['crabLotId']),
        name: asStr(batchJson['code'] ?? batchJson['name'] ?? batchJson['id']),
      ),
      location: CrabLocationRef(
        farmAreaId: asStr(farmAreaJson['id'] ?? json['farmAreaId']),
        farmAreaName: asStr(farmAreaJson['name'] ?? json['farmAreaName']),
        rowId: asStr(rowJson['id'] ?? json['rowId']),
        rowName: asStr(rowJson['name'] ?? json['rowName']),
        boxId: asStr(boxJson['id'] ?? json['boxId']),
        boxCode: asStr(
          boxJson['code'] ??
              boxJson['name'] ??
              boxJson['id'] ??
              json['boxCode'],
        ),
      ),
      gender: CrabGenderX.fromString(asStr(json['gender'])),
      weightGram: asDouble(json['weightGram'] ?? json['weight']),
      shellWidthMm: asDouble(json['shellWidthMm'] ?? json['shellWidth']),
      shellLengthMm: asDouble(json['shellLengthMm'] ?? json['shellLength']),
      moltCount: asInt(json['moltCount'] ?? json['moltingCount']),
      healthStatus: CrabHealthStatusX.fromString(
        asStr(json['healthStatus'] ?? json['health_status']),
      ),
      lifecycleStatus: CrabLifecycleStatusX.fromString(
        asStr(
          json['lifecycleStatus'] ?? json['lifecycle_status'] ?? json['status'],
        ),
      ),
      enteredAt:
          parseDate(json['enteredAt'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
      lastMoltAt: parseDate(json['lastMoltAt']),
      note: json['note']?.toString(),
      aiStatus: json['aiStatus']?.toString(),
    );
  }
}

// ── KPI Summary ───────────────────────────────────────────────────────────────

class CrabKpiSummary {
  const CrabKpiSummary({
    required this.total,
    required this.growing,
    required this.monitoring,
    required this.molting,
    required this.readyToHarvest,
    required this.dead,
  });

  final int total;
  final int growing;
  final int monitoring;
  final int molting;
  final int readyToHarvest;
  final int dead;

  double get growingPct => total == 0 ? 0 : growing / total * 100;
  double get monitoringPct => total == 0 ? 0 : monitoring / total * 100;
  double get moltingPct => total == 0 ? 0 : molting / total * 100;
  double get harvestPct => total == 0 ? 0 : readyToHarvest / total * 100;
  double get deadPct => total == 0 ? 0 : dead / total * 100;

  factory CrabKpiSummary.fromList(List<CrabRecord> crabs) {
    return CrabKpiSummary(
      total: crabs.length,
      growing: crabs
          .where((c) => c.lifecycleStatus == CrabLifecycleStatus.growing)
          .length,
      monitoring: crabs
          .where(
            (c) =>
                c.healthStatus == CrabHealthStatus.monitoring ||
                c.healthStatus == CrabHealthStatus.alert,
          )
          .length,
      molting: crabs
          .where((c) => c.lifecycleStatus == CrabLifecycleStatus.molting)
          .length,
      readyToHarvest: crabs
          .where((c) => c.lifecycleStatus == CrabLifecycleStatus.readyToHarvest)
          .length,
      dead: crabs
          .where((c) => c.lifecycleStatus == CrabLifecycleStatus.dead)
          .length,
    );
  }

  factory CrabKpiSummary.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return CrabKpiSummary(
      total: asInt(json['total']),
      growing: asInt(json['growing'] ?? json['active']),
      monitoring: asInt(json['monitoring'] ?? json['watch']),
      molting: asInt(json['molting']),
      readyToHarvest: asInt(json['readyToHarvest'] ?? json['ready_to_harvest']),
      dead: asInt(json['dead']),
    );
  }

  static CrabKpiSummary get empty => const CrabKpiSummary(
    total: 0,
    growing: 0,
    monitoring: 0,
    molting: 0,
    readyToHarvest: 0,
    dead: 0,
  );
}

// ── Filter state ──────────────────────────────────────────────────────────────

class CrabFilterState {
  const CrabFilterState({
    this.searchQuery = '',
    this.farmAreaId,
    this.rowId,
    this.boxId,
    this.batchId,
    this.gender,
    this.lifecycleStatus,
    this.healthStatus,
    this.quickStatus,
  });

  final String searchQuery;
  final String? farmAreaId;
  final String? rowId;
  final String? boxId;
  final String? batchId;
  final CrabGender? gender;
  final CrabLifecycleStatus? lifecycleStatus;
  final CrabHealthStatus? healthStatus;
  final CrabLifecycleStatus? quickStatus; // null = all

  bool get isEmpty =>
      searchQuery.isEmpty &&
      farmAreaId == null &&
      rowId == null &&
      boxId == null &&
      batchId == null &&
      gender == null &&
      lifecycleStatus == null &&
      healthStatus == null &&
      quickStatus == null;

  CrabFilterState copyWith({
    String? searchQuery,
    Object? farmAreaId = _sentinel,
    Object? rowId = _sentinel,
    Object? boxId = _sentinel,
    Object? batchId = _sentinel,
    Object? gender = _sentinel,
    Object? lifecycleStatus = _sentinel,
    Object? healthStatus = _sentinel,
    Object? quickStatus = _sentinel,
  }) {
    return CrabFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      farmAreaId: farmAreaId == _sentinel
          ? this.farmAreaId
          : farmAreaId as String?,
      rowId: rowId == _sentinel ? this.rowId : rowId as String?,
      boxId: boxId == _sentinel ? this.boxId : boxId as String?,
      batchId: batchId == _sentinel ? this.batchId : batchId as String?,
      gender: gender == _sentinel ? this.gender : gender as CrabGender?,
      lifecycleStatus: lifecycleStatus == _sentinel
          ? this.lifecycleStatus
          : lifecycleStatus as CrabLifecycleStatus?,
      healthStatus: healthStatus == _sentinel
          ? this.healthStatus
          : healthStatus as CrabHealthStatus?,
      quickStatus: quickStatus == _sentinel
          ? this.quickStatus
          : quickStatus as CrabLifecycleStatus?,
    );
  }

  CrabFilterState clear() => const CrabFilterState();
}

const _sentinel = Object();

// ── Pagination ────────────────────────────────────────────────────────────────

class CrabPage {
  const CrabPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<CrabRecord> items;
  final int total;
  final int page;
  final int pageSize;

  int get totalPages => pageSize == 0 ? 1 : (total / pageSize).ceil();
  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory CrabPage.fromJson(Map<String, dynamic> json, int page, int pageSize) {
    final itemsJson = json['items'] as List? ?? json['data'] as List? ?? [];
    return CrabPage(
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(CrabRecord.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? itemsJson.length,
      page: page,
      pageSize: pageSize,
    );
  }

  static CrabPage empty(int pageSize) =>
      CrabPage(items: const [], total: 0, page: 1, pageSize: pageSize);
}

// ── Simple farm / row / box dropdowns ─────────────────────────────────────────

class FarmAreaOption {
  const FarmAreaOption({required this.id, required this.name});
  final String id;
  final String name;
  factory FarmAreaOption.fromJson(Map<String, dynamic> j) =>
      FarmAreaOption(id: j['id'].toString(), name: j['name'].toString());
}

class RowOption {
  const RowOption({
    required this.id,
    required this.name,
    required this.farmAreaId,
  });
  final String id;
  final String name;
  final String farmAreaId;
  factory RowOption.fromJson(Map<String, dynamic> j) => RowOption(
    id: j['id'].toString(),
    name: j['name'].toString(),
    farmAreaId: (j['farmingAreaId'] ?? j['farmAreaId'] ?? '').toString(),
  );
}

class BoxOption {
  const BoxOption({required this.id, required this.code, required this.rowId});
  final String id;
  final String code;
  final String rowId;
  factory BoxOption.fromJson(Map<String, dynamic> j) => BoxOption(
    id: j['id'].toString(),
    code: (j['code'] ?? j['name'] ?? j['id']).toString(),
    rowId: (j['farmingRowId'] ?? j['rowId'] ?? '').toString(),
  );
}

class BatchOption {
  const BatchOption({required this.id, required this.code});
  final String id;
  final String code;
  factory BatchOption.fromJson(Map<String, dynamic> j) => BatchOption(
    id: j['id'].toString(),
    code: (j['code'] ?? j['name'] ?? j['id']).toString(),
  );
}

// ── Death reasons ─────────────────────────────────────────────────────────────

enum DeathReason {
  unknown,
  disease,
  environmentalShock,
  moltFailure,
  injury,
  other,
}

extension DeathReasonX on DeathReason {
  String get label {
    switch (this) {
      case DeathReason.unknown:
        return 'Chưa xác định';
      case DeathReason.disease:
        return 'Bệnh';
      case DeathReason.environmentalShock:
        return 'Sốc môi trường';
      case DeathReason.moltFailure:
        return 'Lột xác thất bại';
      case DeathReason.injury:
        return 'Tổn thương';
      case DeathReason.other:
        return 'Khác';
    }
  }
}
