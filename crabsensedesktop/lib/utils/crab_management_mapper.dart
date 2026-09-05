import '../models/crab_individual.dart';
import '../models/crab_status.dart';
import '../models/production_models.dart';

String areaDisplayLabel(CrabManagementListItem item) =>
    '${item.areaCode} — ${item.areaName}';

CrabGender mapGender(String api) => switch (api.toLowerCase()) {
      'male' || 'đực' || 'm' => CrabGender.male,
      'female' || 'cái' || 'f' => CrabGender.female,
      _ => CrabGender.unknown,
    };

String genderToApi(CrabGender g) => switch (g) {
      CrabGender.unknown => 'unknown',
      CrabGender.male => 'male',
      CrabGender.female => 'female',
    };

CrabLifeStatus mapLifeStatus(String api) => switch (api.toLowerCase()) {
      'dead' => CrabLifeStatus.dead,
      'harvested' || 'sold' => CrabLifeStatus.sold,
      'ready' => CrabLifeStatus.readyForSale,
      _ => CrabLifeStatus.raising,
    };

String lifeStatusToApi(CrabLifeStatus life) => switch (life) {
      CrabLifeStatus.dead => 'dead',
      CrabLifeStatus.sold => 'harvested',
      CrabLifeStatus.readyForSale => 'ready',
      _ => 'alive',
    };

CrabHealthStatus mapHealthStatus(String? api) {
  final s = (api ?? 'healthy').toLowerCase();
  if (s.contains('molt')) return CrabHealthStatus.molting;
  if (s.contains('risk') || s.contains('nguy')) return CrabHealthStatus.atRisk;
  if (s.contains('monitor') || s.contains('theo')) {
    return CrabHealthStatus.monitoring;
  }
  if (s.contains('good') || s.contains('tốt')) return CrabHealthStatus.good;
  return CrabHealthStatus.healthy;
}

String healthStatusToApi(CrabHealthStatus h) => switch (h) {
      CrabHealthStatus.healthy => 'healthy',
      CrabHealthStatus.good => 'good',
      CrabHealthStatus.monitoring => 'monitoring',
      CrabHealthStatus.molting => 'molting',
      CrabHealthStatus.atRisk => 'at_risk',
    };

CrabDevelopmentStage mapGrowthStage(String? api) {
  final s = (api ?? 'growing').toLowerCase();
  if (s.contains('juvenile') || s.contains('ấu')) {
    return CrabDevelopmentStage.juvenile;
  }
  if (s.contains('pre')) return CrabDevelopmentStage.preHarvest;
  if (s.contains('harvest') || s.contains('thu')) {
    return CrabDevelopmentStage.harvestReady;
  }
  return CrabDevelopmentStage.growing;
}

String growthStageToApi(CrabDevelopmentStage s) => switch (s) {
      CrabDevelopmentStage.juvenile => 'juvenile',
      CrabDevelopmentStage.growing => 'growing',
      CrabDevelopmentStage.preHarvest => 'pre_harvest',
      CrabDevelopmentStage.harvestReady => 'harvest_ready',
    };

MoltCondition mapMoltCondition(String api) {
  final s = api.toLowerCase();
  if (s.contains('watch')) return MoltCondition.needsWatch;
  if (s.contains('weak') || s.contains('yếu')) return MoltCondition.weak;
  return MoltCondition.normal;
}

String moltConditionToApi(MoltCondition c) => switch (c) {
      MoltCondition.normal => 'normal',
      MoltCondition.weak => 'weak',
      MoltCondition.needsWatch => 'needs_watch',
    };

DateTime? parseApiDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

CrabIndividual crabFromListItem(CrabManagementListItem item) {
  final release = parseApiDate(item.batchStartDate) ?? DateTime.now();
  return CrabIndividual(
    id: item.id,
    displayCode: item.crabCode,
    boxId: item.boxId,
    batchId: item.batchCode,
    areaName: areaDisplayLabel(item),
    rowName: item.rowName.isNotEmpty ? item.rowName : item.rowCode,
    boxName: item.boxCode,
    gender: mapGender(item.gender),
    weightGram: item.weight ?? 0,
    shellSizeCm: item.shellWidth ?? 0,
    carapaceLengthMm: item.shellLength ?? 0,
    releaseDate: release,
    moltCount: item.moltCount,
    lastMoltDate: parseApiDate(item.lastMoltDate),
    healthStatus: mapHealthStatus(item.healthStatus),
    lifeStatus: mapLifeStatus(item.status),
    healthScore: _healthScore(item),
    developmentStage: mapGrowthStage(item.growthStage),
    updatedAt: DateTime.now(),
    quickNote: item.profileNote ?? '',
  );
}

int _healthScore(CrabManagementListItem item) {
  if (item.status == 'dead') return 0;
  return switch (mapHealthStatus(item.healthStatus)) {
    CrabHealthStatus.healthy => 92,
    CrabHealthStatus.good => 85,
    CrabHealthStatus.monitoring => 72,
    CrabHealthStatus.molting => 78,
    CrabHealthStatus.atRisk => 55,
  };
}

bool _isHealthyDiseaseNote(String? note) {
  if (note == null || note.trim().isEmpty) return true;
  final d = note.trim().toLowerCase();
  return d == 'không' ||
      d == 'khong' ||
      d == 'none' ||
      d == 'ok' ||
      d.contains('khỏe') ||
      d.contains('khoẻ');
}

CrabIndividual mergeCrabDetail(
  CrabIndividual base,
  Map<String, dynamic> body,
) {
  final molts = <CrabMoltRecord>[];
  final rawMolts = body['moltLogs'];
  if (rawMolts is List) {
    for (final m in rawMolts.whereType<Map>()) {
      final map = Map<String, dynamic>.from(m);
      final date = parseApiDate(map['moltDate']?.toString());
      if (date == null) continue;
      molts.add(
        CrabMoltRecord(
          number: (map['moltNumber'] as num?)?.toInt() ?? molts.length + 1,
          date: date,
          condition: mapMoltCondition((map['condition'] ?? 'normal').toString()),
          note: map['note']?.toString(),
        ),
      );
    }
  }

  final healthLogs = <CrabHealthLogEntry>[];
  final rawHealth = body['healthRecords'];
  if (rawHealth is List) {
    for (final h in rawHealth.whereType<Map>()) {
      final map = Map<String, dynamic>.from(h);
      final at = DateTime.tryParse((map['recordedAt'] ?? '').toString());
      if (at == null) continue;
      healthLogs.add(
        CrabHealthLogEntry(
          recordedAt: at.toLocal(),
          weightGram: (map['weight'] as num?)?.toDouble() ?? base.weightGram,
          shellSizeCm:
              (map['shellWidth'] as num?)?.toDouble() ?? base.shellSizeCm,
          shellCondition: (map['shellStatus'] ?? '').toString(),
          diseaseNote: (map['diseaseStatus'] ?? '').toString(),
        ),
      );
    }
  }

  final weightHistory = healthLogs
      .map(
        (h) => CrabWeightPoint(
          date: h.recordedAt,
          weightGram: h.weightGram,
          shellSizeCm: h.shellSizeCm,
        ),
      )
      .toList();

  final feedings = <CrabFeedingRecord>[];
  final rawFeed = body['feedingLogs'];
  if (rawFeed is List) {
    for (final f in rawFeed.whereType<Map>()) {
      final map = Map<String, dynamic>.from(f);
      final at = DateTime.tryParse((map['fedAt'] ?? map['FedAt'] ?? '').toString());
      if (at == null) continue;
      feedings.add(
        CrabFeedingRecord(
          date: at.toLocal(),
          foodType: (map['foodType'] ?? map['FoodType'] ?? 'Thức ăn').toString(),
          amountGram: (map['quantity'] ?? map['Quantity'] as num?)?.toDouble() ?? 0,
          note: map['note']?.toString(),
        ),
      );
    }
  }

  final diseases = <CrabDiseaseRecord>[];
  for (final h in healthLogs) {
    if (_isHealthyDiseaseNote(h.diseaseNote)) continue;
    diseases.add(
      CrabDiseaseRecord(
        date: h.recordedAt,
        name: h.diseaseNote,
        severity: DiseaseSeverity.moderate,
        symptoms: h.shellCondition,
        treatment: 'Theo dõi',
        status: DiseaseRecordStatus.monitoring,
      ),
    );
  }

  double estimatedVnd = base.estimatedValueVnd;
  double meatScore = base.meatQualityScore;
  final rawValue = body['value'];
  if (rawValue is Map) {
    final v = Map<String, dynamic>.from(rawValue);
    final price = v['estimatedPrice'] ?? v['EstimatedPrice'];
    if (price is num) estimatedVnd = price.toDouble();
    final meat = v['meatQuality'] ?? v['MeatQuality'];
    if (meat is num) meatScore = meat.toDouble();
  }

  final rawProfile = body['profile'];
  String? note = base.quickNote;
  if (rawProfile is Map) {
    final p = Map<String, dynamic>.from(rawProfile);
    note = (p['note'] ?? p['Note'])?.toString() ?? note;
  }

  return base.copyWith(
    molts: molts.isNotEmpty ? molts : base.molts,
    healthLogs: healthLogs.isNotEmpty ? healthLogs : base.healthLogs,
    weightHistory: weightHistory.isNotEmpty ? weightHistory : base.weightHistory,
    feedings: feedings.isNotEmpty ? feedings : base.feedings,
    diseases: diseases.isNotEmpty ? diseases : base.diseases,
    moltCount: molts.isNotEmpty ? molts.last.number : base.moltCount,
    lastMoltDate: molts.isNotEmpty ? molts.last.date : base.lastMoltDate,
    estimatedValueVnd: estimatedVnd,
    meatQualityScore: meatScore,
    alertCount: diseases.length,
    quickNote: note ?? base.quickNote,
  );
}
