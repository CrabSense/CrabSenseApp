import 'package:flutter/material.dart';

import 'crab_status.dart';

class CrabMoltRecord {
  const CrabMoltRecord({
    required this.number,
    required this.date,
    required this.condition,
    this.note,
  });

  final int number;
  final DateTime date;
  final MoltCondition condition;
  final String? note;
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
    required this.releaseDate,
    required this.moltCount,
    required this.healthStatus,
    required this.lifeStatus,
    required this.healthScore,
    this.displayCode,
    this.areaName = 'Khu A',
    this.rowName = 'Dãy 01',
    this.boxName,
    this.developmentStage = CrabDevelopmentStage.growing,
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
  final String areaName;
  final String rowName;
  final String? boxName;
  final CrabDevelopmentStage developmentStage;
  final DateTime? updatedAt;
  final CrabGender gender;
  final double weightGram;
  final double shellSizeCm;
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

  String get boxLabel => boxName ?? 'Hộp $boxId';

  String get locationLine => '$areaName · $rowName · $boxLabel';

  DateTime get lastUpdated => updatedAt ?? releaseDate;

  CrabOperationalStatus get operationalStatus {
    if (lifeStatus == CrabLifeStatus.dead) return CrabOperationalStatus.dead;
    if (lifeStatus == CrabLifeStatus.sold) {
      return CrabOperationalStatus.harvested;
    }
    if (healthStatus == CrabHealthStatus.molting) {
      return CrabOperationalStatus.molting;
    }
    if (lifeStatus == CrabLifeStatus.readyForSale ||
        developmentStage == CrabDevelopmentStage.harvestReady) {
      return CrabOperationalStatus.readyHarvest;
    }
    if (healthStatus == CrabHealthStatus.atRisk ||
        healthStatus == CrabHealthStatus.monitoring ||
        healthScore < 70) {
      return CrabOperationalStatus.warning;
    }
    return CrabOperationalStatus.alive;
  }

  bool matchesStatusFilter(CrabManagementStatusFilter filter) {
    switch (filter) {
      case CrabManagementStatusFilter.all:
        return true;
      case CrabManagementStatusFilter.alive:
        return lifeStatus == CrabLifeStatus.raising ||
            lifeStatus == CrabLifeStatus.readyForSale;
      case CrabManagementStatusFilter.molting:
        return healthStatus == CrabHealthStatus.molting ||
            operationalStatus == CrabOperationalStatus.molting;
      case CrabManagementStatusFilter.sickWeak:
        return healthStatus == CrabHealthStatus.atRisk ||
            healthStatus == CrabHealthStatus.monitoring ||
            healthScore < 75;
      case CrabManagementStatusFilter.dead:
        return lifeStatus == CrabLifeStatus.dead;
      case CrabManagementStatusFilter.harvested:
        return lifeStatus == CrabLifeStatus.sold;
    }
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
    String? areaName,
    String? rowName,
    String? boxName,
    CrabDevelopmentStage? developmentStage,
    DateTime? updatedAt,
    CrabGender? gender,
    double? weightGram,
    double? shellSizeCm,
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
      areaName: areaName ?? this.areaName,
      rowName: rowName ?? this.rowName,
      boxName: boxName ?? this.boxName,
      developmentStage: developmentStage ?? this.developmentStage,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      weightGram: weightGram ?? this.weightGram,
      shellSizeCm: shellSizeCm ?? this.shellSizeCm,
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
  });

  final int total;
  final int alive;
  final int dead;
  final int molting;
  final int readyHarvest;
  final double aliveRate;
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
