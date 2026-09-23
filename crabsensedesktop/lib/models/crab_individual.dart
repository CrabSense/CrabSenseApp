import 'package:flutter/material.dart';

import 'crab_status.dart';

class CrabMoltRecord {
  const CrabMoltRecord({
    this.id,
    required this.number,
    required this.date,
    required this.condition,
    this.note,
    this.photoUrls = const [],
  });

  final String? id;
  final int number;
  final DateTime date;
  final MoltCondition condition;
  final String? note;
  final List<String> photoUrls;
}

class CrabDiseaseRecord {
  const CrabDiseaseRecord({
    required this.date,
    required this.name,
    required this.severity,
    required this.symptoms,
    required this.treatment,
    required this.status,
  });

  final DateTime date;
  final String name;
  final DiseaseSeverity severity;
  final String symptoms;
  final String treatment;
  final DiseaseRecordStatus status;
}

class CrabFeedingRecord {
  const CrabFeedingRecord({
    required this.date,
    required this.foodType,
    required this.amountGram,
    this.note,
  });

  final DateTime date;
  final String foodType;
  final double amountGram;
  final String? note;
}

class CrabWeightPoint {
  const CrabWeightPoint({
    required this.date,
    required this.weightGram,
    this.shellSizeCm,
  });

  final DateTime date;
  final double weightGram;
  final double? shellSizeCm;
}

class CrabHealthLogEntry {
  const CrabHealthLogEntry({
    required this.recordedAt,
    required this.weightGram,
    required this.shellSizeCm,
    required this.shellCondition,
    required this.diseaseNote,
    this.note,
  });

  final DateTime recordedAt;
  final double weightGram;
  final double shellSizeCm;
  final String shellCondition;
  final String diseaseNote;
  final String? note;
}

class CrabIndividual {
  const CrabIndividual({
    required this.id,
    required this.boxId,
    required this.batchId,
    required this.gender,
    required this.weightGram,
    required this.shellSizeCm,
    this.carapaceLengthMm = 0,
    required this.releaseDate,
    required this.moltCount,
    required this.healthStatus,
    required this.lifeStatus,
    required this.healthScore,
    this.displayCode,
    this.areaId = '',
    this.areaCode = '',
    this.areaName = 'Khu A',
    this.rowId = '',
    this.rowName = 'Dãy 01',
    this.boxName,
    this.developmentStage = CrabDevelopmentStage.growing,
    this.lifecycleStatus = CrabLifecycleStatus.growing,
    this.crabType = 'Cua biển',
    this.updatedAt,
    this.lastMoltDate,
    this.quickNote = '',
    this.molts = const [],
    this.diseases = const [],
    this.feedings = const [],
    this.weightHistory = const [],
    this.healthLogs = const [],
    this.envTempC = 28.5,
    this.envSalinityPpt = 25,
    this.alertCount = 0,
    this.estimatedValueVnd = 0,
    this.meatQualityScore = 80,
  });

  final String id;
  final String? displayCode;
  final String boxId;
  final String batchId;
  final String areaId;
  final String areaCode;
  final String areaName;
  final String rowId;
  final String rowName;
  final String? boxName;
  final CrabDevelopmentStage developmentStage;
  final CrabLifecycleStatus lifecycleStatus;
  final String crabType;
  final DateTime? updatedAt;
  final CrabGender gender;
  final double weightGram;
  /// Bề rộng mai (mm). Tên cũ shellSizeCm — đơn vị thực tế là mm.
  final double shellSizeCm;
  /// Bề ngang mai (mm).
  final double carapaceLengthMm;
  final DateTime releaseDate;
  final int moltCount;
  final DateTime? lastMoltDate;
  final CrabHealthStatus healthStatus;
  final CrabLifeStatus lifeStatus;
  final int healthScore;
  final String quickNote;
  final List<CrabMoltRecord> molts;
  final List<CrabDiseaseRecord> diseases;
  final List<CrabFeedingRecord> feedings;
  final List<CrabWeightPoint> weightHistory;
  final List<CrabHealthLogEntry> healthLogs;
  final double envTempC;
  final double envSalinityPpt;
  final int alertCount;
  final double estimatedValueVnd;
  final double meatQualityScore;

  String get code => displayCode ?? id;

  String get boxLabel {
    final code = (boxName ?? '').trim();
    if (code.isNotEmpty) return code;
    return boxId.trim().isEmpty ? '—' : 'Hộp $boxId';
  }

  String get areaLabel {
    if (areaCode.trim().isNotEmpty && areaName.trim().isNotEmpty) {
      return '$areaCode — $areaName';
    }
    if (areaCode.trim().isNotEmpty) return areaCode;
    if (areaName.trim().isNotEmpty) return areaName;
    return '—';
  }

  String get rowLabel {
    final name = rowName.trim();
    if (name.isNotEmpty) return name;
    return '—';
  }

  String get locationLine => '$areaLabel · $rowLabel · $boxLabel';

  DateTime get lastUpdated => updatedAt ?? releaseDate;

  /// Sức khỏe hiển thị — không dùng “Đang lột xác” (đó là trạng thái).
  CrabDisplayHealth get displayHealth {
    switch (healthStatus) {
      case CrabHealthStatus.monitoring:
        return CrabDisplayHealth.monitoring;
      case CrabHealthStatus.atRisk:
        return alertCount > 0 ? CrabDisplayHealth.alert : CrabDisplayHealth.weak;
      case CrabHealthStatus.molting:
        if (healthScore > 0 && healthScore < 70) {
          return CrabDisplayHealth.monitoring;
        }
        return CrabDisplayHealth.healthy;
      case CrabHealthStatus.healthy:
      case CrabHealthStatus.good:
        return CrabDisplayHealth.healthy;
    }
  }

  String get sizeLabel {
    final w = normalizeCarapaceMm(shellSizeCm);
    final l = normalizeCarapaceMm(carapaceLengthMm);
    if (w <= 0 && l <= 0) return '—';
    if (l <= 0) return '${formatMm(w)} mm';
    if (w <= 0) return '${formatMm(l)} mm';
    return '${formatMm(w)} × ${formatMm(l)} mm';
  }

  String get weightLabel =>
      weightGram > 0 ? '${weightGram.round()} g' : '—';

  CrabOperationalStatus get operationalStatus {
    return switch (lifecycleStatus) {
      CrabLifecycleStatus.dead => CrabOperationalStatus.dead,
      CrabLifecycleStatus.harvested => CrabOperationalStatus.harvested,
      CrabLifecycleStatus.molting => CrabOperationalStatus.molting,
      CrabLifecycleStatus.readyHarvest => CrabOperationalStatus.readyHarvest,
      CrabLifecycleStatus.growing => CrabOperationalStatus.alive,
    };
  }

  bool matchesStatusFilter(CrabManagementStatusFilter filter) {
    switch (filter) {
      case CrabManagementStatusFilter.all:
        return true;
      case CrabManagementStatusFilter.growing:
        return lifecycleStatus == CrabLifecycleStatus.growing;
      case CrabManagementStatusFilter.monitoring:
        return displayHealth == CrabDisplayHealth.monitoring;
      case CrabManagementStatusFilter.molting:
        return lifecycleStatus == CrabLifecycleStatus.molting;
      case CrabManagementStatusFilter.readyHarvest:
        return lifecycleStatus == CrabLifecycleStatus.readyHarvest;
      case CrabManagementStatusFilter.dead:
        return lifecycleStatus == CrabLifecycleStatus.dead;
    }
  }

  static double normalizeCarapaceMm(double value) {
    if (value <= 0) return 0;
    var v = value;
    while (v >= 200) {
      v /= 10;
    }
    return v;
  }

  static String formatMm(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  int get ageDays => DateTime.now().difference(releaseDate).inDays;

  int? get daysSinceLastMolt => lastMoltDate == null
      ? null
      : DateTime.now().difference(lastMoltDate!).inDays;

  double get growthLast7Days {
    if (weightHistory.length < 2) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    CrabWeightPoint? past;
    for (final p in weightHistory) {
      if (!p.date.isAfter(weekAgo)) past = p;
    }
    past ??= weightHistory.first;
    return weightGram - past.weightGram;
  }

  double get avgFeedingGram {
    if (feedings.isEmpty) return 0;
    final total = feedings.fold<double>(0, (s, f) => s + f.amountGram);
    return total / feedings.length;
  }

  bool get canMarkReadyForSale =>
      lifeStatus != CrabLifeStatus.dead &&
      lifeStatus != CrabLifeStatus.sold &&
      weightGram >= 150 &&
      healthScore >= 85 &&
      !diseases.any(
        (d) =>
            d.status != DiseaseRecordStatus.resolved &&
            DateTime.now().difference(d.date).inDays <= 7,
      ) &&
      (daysSinceLastMolt == null || daysSinceLastMolt! >= 3);

  CrabIndividual copyWith({
    String? id,
    String? displayCode,
    String? boxId,
    String? batchId,
    String? areaId,
    String? areaCode,
    String? areaName,
    String? rowId,
    String? rowName,
    String? boxName,
    CrabDevelopmentStage? developmentStage,
    CrabLifecycleStatus? lifecycleStatus,
    String? crabType,
    DateTime? updatedAt,
    CrabGender? gender,
    double? weightGram,
    double? shellSizeCm,
    double? carapaceLengthMm,
    DateTime? releaseDate,
    int? moltCount,
    DateTime? lastMoltDate,
    CrabHealthStatus? healthStatus,
    CrabLifeStatus? lifeStatus,
    int? healthScore,
    String? quickNote,
    List<CrabMoltRecord>? molts,
    List<CrabDiseaseRecord>? diseases,
    List<CrabFeedingRecord>? feedings,
    List<CrabWeightPoint>? weightHistory,
    List<CrabHealthLogEntry>? healthLogs,
    double? envTempC,
    double? envSalinityPpt,
    int? alertCount,
    double? estimatedValueVnd,
    double? meatQualityScore,
  }) {
    return CrabIndividual(
      id: id ?? this.id,
      displayCode: displayCode ?? this.displayCode,
      boxId: boxId ?? this.boxId,
      batchId: batchId ?? this.batchId,
      areaId: areaId ?? this.areaId,
      areaCode: areaCode ?? this.areaCode,
      areaName: areaName ?? this.areaName,
      rowId: rowId ?? this.rowId,
      rowName: rowName ?? this.rowName,
      boxName: boxName ?? this.boxName,
      developmentStage: developmentStage ?? this.developmentStage,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      crabType: crabType ?? this.crabType,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      weightGram: weightGram ?? this.weightGram,
      shellSizeCm: shellSizeCm ?? this.shellSizeCm,
      carapaceLengthMm: carapaceLengthMm ?? this.carapaceLengthMm,
      releaseDate: releaseDate ?? this.releaseDate,
      moltCount: moltCount ?? this.moltCount,
      lastMoltDate: lastMoltDate ?? this.lastMoltDate,
      healthStatus: healthStatus ?? this.healthStatus,
      lifeStatus: lifeStatus ?? this.lifeStatus,
      healthScore: healthScore ?? this.healthScore,
      quickNote: quickNote ?? this.quickNote,
      molts: molts ?? this.molts,
      diseases: diseases ?? this.diseases,
      feedings: feedings ?? this.feedings,
      weightHistory: weightHistory ?? this.weightHistory,
      healthLogs: healthLogs ?? this.healthLogs,
      envTempC: envTempC ?? this.envTempC,
      envSalinityPpt: envSalinityPpt ?? this.envSalinityPpt,
      alertCount: alertCount ?? this.alertCount,
      estimatedValueVnd: estimatedValueVnd ?? this.estimatedValueVnd,
      meatQualityScore: meatQualityScore ?? this.meatQualityScore,
    );
  }
}

class CrabManagementSummary {
  const CrabManagementSummary({
    required this.total,
    required this.alive,
    required this.dead,
    required this.molting,
    required this.readyHarvest,
    required this.aliveRate,
    this.monitoring = 0,
  });

  final int total;
  final int alive;
  final int dead;
  final int molting;
  final int readyHarvest;
  final double aliveRate;
  final int monitoring;

  double pct(int n) => total <= 0 ? 0 : n / total * 100;
}

class CrabSummaryKpi {
  const CrabSummaryKpi({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
    this.showProgress = false,
    this.progress,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;
  final bool showProgress;
  final double? progress;
}
