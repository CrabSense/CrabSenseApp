// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/database.dart' as db;
import '../../domain/entities/harvest.dart';
import '../../domain/entities/harvest_summary.dart';

/// Data Transfer Object (DTO) for the [Harvest] entity.
///
/// Handles JSON serialization/deserialization for API responses and
/// Drift row mapping for local database operations. Extends [Harvest]
/// so it can be used directly wherever a domain entity is expected.
///
/// Includes data-layer fields [isDirty] and [syncedAt] for offline-first
/// sync tracking (Requirements 11.7-11.8).
///
/// Requirements: 11.1-11.10
class HarvestModel extends Harvest {
  const HarvestModel({
    required super.id,
    required super.boxId,
    required super.farmId,
    required super.totalWeight,
    required super.crabCount,
    required super.qualityGrade,
    required super.harvestDate,
    required super.operatorId,
    required super.operatorName,
    super.photoUrls = const [],
    super.notes,
    super.createdAt,
    super.isSynced = false,
    this.isDirty = false,
    this.syncedAt,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Factory constructors
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a [HarvestModel] from a raw API JSON map.
  ///
  /// Supports both camelCase and snake_case field names for API compatibility.
  factory HarvestModel.fromJson(Map<String, dynamic> json) => HarvestModel(
        id: json['id'] as String? ?? '',
        boxId: json['boxId'] as String? ?? json['box_id'] as String? ?? '',
        farmId: json['farmId'] as String? ?? json['farm_id'] as String? ?? '',
        totalWeight: (json['totalWeight'] ?? json['total_weight'] as num?)?.toDouble() ?? 0.0,
        crabCount: (json['crabCount'] ?? json['crab_count'] as num?)?.toInt() ?? 0,
        qualityGrade: QualityGrade.fromString(
          json['qualityGrade'] as String? ?? json['quality_grade'] as String? ?? 'GRADE_A',
        ),
        harvestDate: _parseDateTime(
          json['harvestDate'] as String? ?? json['harvest_date'] as String? ?? json['createdAt'] as String? ?? json['created_at'] as String?,
        ),
        operatorId: json['operatorId'] as String? ?? json['operator_id'] as String? ?? json['harvestedBy'] as String? ?? json['harvested_by'] as String? ?? '',
        operatorName: json['operatorName'] as String? ?? json['operator_name'] as String? ?? '',
        photoUrls: _parseStringList(json['photoUrls'] ?? json['photo_urls']),
        notes: json['notes'] as String?,
        createdAt: _parseDateTimeNullable(json['createdAt'] as String? ?? json['created_at'] as String?),
        isSynced: json['isSynced'] as bool? ?? json['is_synced'] as bool? ?? true,
        isDirty: json['isDirty'] as bool? ?? json['is_dirty'] as bool? ?? false,
        syncedAt: _parseDateTimeNullable(json['syncedAt'] as String? ?? json['synced_at'] as String?),
      );

  /// Creates a [HarvestModel] from a Drift-generated [db.Harvest] row.
  factory HarvestModel.fromDrift(db.Harvest row, {String? farmId, String? operatorName}) => HarvestModel(
        id: row.id,
        boxId: row.boxId,
        farmId: farmId ?? '',
        totalWeight: row.totalWeight,
        crabCount: row.crabCount,
        qualityGrade: QualityGrade.fromString(row.qualityGrade),
        harvestDate: row.harvestDate,
        operatorId: row.harvestedBy,
        operatorName: operatorName ?? '',
        photoUrls: _parseStringListFromJson(row.photoUrls),
        notes: row.notes.isEmpty ? null : row.notes,
        createdAt: row.cachedAt,
        isSynced: !row.isDirty,
        isDirty: row.isDirty,
        syncedAt: row.syncedAt,
      );

  /// Creates a [HarvestModel] from a domain [Harvest] entity.
  factory HarvestModel.fromEntity(
    Harvest entity, {
    bool isDirty = false,
    DateTime? syncedAt,
  }) =>
      HarvestModel(
        id: entity.id,
        boxId: entity.boxId,
        farmId: entity.farmId,
        totalWeight: entity.totalWeight,
        crabCount: entity.crabCount,
        qualityGrade: entity.qualityGrade,
        harvestDate: entity.harvestDate,
        operatorId: entity.operatorId,
        operatorName: entity.operatorName,
        photoUrls: entity.photoUrls,
        notes: entity.notes,
        createdAt: entity.createdAt,
        isSynced: entity.isSynced,
        isDirty: isDirty,
        syncedAt: syncedAt,
      );

  /// True when local changes have not yet been synced to remote API.
  final bool isDirty;

  /// Server synchronization timestamp.
  final DateTime? syncedAt;

  // ──────────────────────────────────────────────────────────────────────────
  // Serialization & Conversion
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'id': id,
        'boxId': boxId,
        'farmId': farmId,
        'totalWeight': totalWeight,
        'crabCount': crabCount,
        'qualityGrade': qualityGrade.toCode(),
        'harvestDate': harvestDate.toIso8601String(),
        'operatorId': operatorId,
        'operatorName': operatorName,
        'photoUrls': photoUrls,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        'isSynced': isSynced,
      };

  /// Converts this model to a [db.HarvestsCompanion] for Drift inserts/updates.
  db.HarvestsCompanion toDriftCompanion() => db.HarvestsCompanion(
        id: Value(id),
        boxId: Value(boxId),
        totalWeight: Value(totalWeight),
        crabCount: Value(crabCount),
        qualityGrade: Value(qualityGrade.toCode()),
        harvestDate: Value(harvestDate),
        harvestedBy: Value(operatorId),
        photoUrls: Value(jsonEncode(photoUrls)),
        notes: Value(notes ?? ''),
        isDirty: Value(isDirty),
        syncedAt: Value(syncedAt),
        cachedAt: Value(DateTime.now()),
      );

  /// Converts this model to the pure domain [Harvest] entity.
  Harvest toEntity() => Harvest(
        id: id,
        boxId: boxId,
        farmId: farmId,
        totalWeight: totalWeight,
        crabCount: crabCount,
        qualityGrade: qualityGrade,
        harvestDate: harvestDate,
        operatorId: operatorId,
        operatorName: operatorName,
        photoUrls: photoUrls,
        notes: notes,
        createdAt: createdAt,
        isSynced: !isDirty && isSynced,
      );

  @override
  HarvestModel copyWith({
    String? id,
    String? boxId,
    String? farmId,
    double? totalWeight,
    int? crabCount,
    QualityGrade? qualityGrade,
    DateTime? harvestDate,
    String? operatorId,
    String? operatorName,
    List<String>? photoUrls,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
    bool? isDirty,
    DateTime? syncedAt,
  }) =>
      HarvestModel(
        id: id ?? this.id,
        boxId: boxId ?? this.boxId,
        farmId: farmId ?? this.farmId,
        totalWeight: totalWeight ?? this.totalWeight,
        crabCount: crabCount ?? this.crabCount,
        qualityGrade: qualityGrade ?? this.qualityGrade,
        harvestDate: harvestDate ?? this.harvestDate,
        operatorId: operatorId ?? this.operatorId,
        operatorName: operatorName ?? this.operatorName,
        photoUrls: photoUrls ?? this.photoUrls,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        isDirty: isDirty ?? this.isDirty,
        syncedAt: syncedAt ?? this.syncedAt,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  static List<String> _parseStringList(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return _parseStringListFromJson(raw);
    }
    return [];
  }

  static List<String> _parseStringListFromJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } on FormatException {
      return [];
    }
  }

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }

  static DateTime? _parseDateTimeNullable(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}

/// JSON-serializable DTO for [HarvestSummary].
///
/// Requirement 11.10
class HarvestSummaryModel extends HarvestSummary {
  const HarvestSummaryModel({
    required super.farmId,
    required super.startDate,
    required super.endDate,
    required super.totalWeight,
    required super.totalCrabCount,
    required super.totalHarvestsCount,
    super.farmName,
    super.gradeBreakdown = const {},
  });

  /// Factory constructor to parse [HarvestSummaryModel] from JSON.
  factory HarvestSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['gradeBreakdown'] as Map<String, dynamic>? ?? json['grade_breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = <QualityGrade, double>{};
    rawBreakdown.forEach((key, val) {
      final grade = QualityGrade.fromString(key);
      final weight = (val as num?)?.toDouble() ?? 0.0;
      breakdown[grade] = weight;
    });

    return HarvestSummaryModel(
      farmId: json['farmId'] as String? ?? json['farm_id'] as String? ?? '',
      farmName: json['farmName'] as String? ?? json['farm_name'] as String?,
      startDate: _parseDateTime(json['startDate'] as String? ?? json['start_date'] as String?),
      endDate: _parseDateTime(json['endDate'] as String? ?? json['end_date'] as String?),
      totalWeight: (json['totalWeight'] ?? json['total_weight'] as num?)?.toDouble() ?? 0.0,
      totalCrabCount: (json['totalCrabCount'] ?? json['total_crab_count'] as num?)?.toInt() ?? 0,
      totalHarvestsCount: (json['totalHarvestsCount'] ?? json['total_harvests_count'] as num?)?.toInt() ?? 0,
      gradeBreakdown: breakdown,
    );
  }

  /// Factory constructor to convert domain [HarvestSummary] entity to model.
  factory HarvestSummaryModel.fromEntity(HarvestSummary entity) => HarvestSummaryModel(
        farmId: entity.farmId,
        farmName: entity.farmName,
        startDate: entity.startDate,
        endDate: entity.endDate,
        totalWeight: entity.totalWeight,
        totalCrabCount: entity.totalCrabCount,
        totalHarvestsCount: entity.totalHarvestsCount,
        gradeBreakdown: entity.gradeBreakdown,
      );

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    final breakdownMap = <String, double>{};
    gradeBreakdown.forEach((grade, weight) {
      breakdownMap[grade.toCode()] = weight;
    });

    return {
      'farmId': farmId,
      if (farmName != null) 'farmName': farmName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalWeight': totalWeight,
      'totalCrabCount': totalCrabCount,
      'totalHarvestsCount': totalHarvestsCount,
      'gradeBreakdown': breakdownMap,
    };
  }

  /// Converts this model to domain [HarvestSummary] entity.
  HarvestSummary toEntity() => HarvestSummary(
        farmId: farmId,
        farmName: farmName,
        startDate: startDate,
        endDate: endDate,
        totalWeight: totalWeight,
        totalCrabCount: totalCrabCount,
        totalHarvestsCount: totalHarvestsCount,
        gradeBreakdown: gradeBreakdown,
      );

  static DateTime _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now().toUtc();
    }
    return DateTime.parse(value);
  }
}
