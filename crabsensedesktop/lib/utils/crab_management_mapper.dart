import 'package:flutter/material.dart';

import '../models/crab_individual.dart';
import '../models/crab_status.dart';
import '../models/production_models.dart';
import '../theme/dashboard_theme.dart';
import 'app_formatters.dart';

String areaDisplayLabel(CrabManagementListItem item) {
  if (item.areaCode.trim().isNotEmpty && item.areaName.trim().isNotEmpty) {
    return '${item.areaCode} — ${item.areaName}';
  }
  if (item.areaCode.trim().isNotEmpty) return item.areaCode;
  return item.areaName;
}

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
      'sold' => CrabLifeStatus.sold,
      'harvested' || 'ready' => CrabLifeStatus.readyForSale,
      _ => CrabLifeStatus.raising,
    };

CrabLifecycleStatus mapLifecycleStatus({
  required String status,
  String? growthStage,
  String? healthStatus,
}) {
  final s = status.toLowerCase();
  if (s == 'dead') return CrabLifecycleStatus.dead;
  if (s == 'harvested' || s == 'sold') return CrabLifecycleStatus.harvested;
  if (s == 'molting' || s.contains('molt')) return CrabLifecycleStatus.molting;
  final g = (growthStage ?? '').toLowerCase();
  if (g.contains('harvest') || g.contains('thu')) {
    return CrabLifecycleStatus.readyHarvest;
  }
  final h = (healthStatus ?? '').toLowerCase();
  if (h.contains('molt')) return CrabLifecycleStatus.molting;
  return CrabLifecycleStatus.growing;
}

CrabDisplayHealth mapDisplayHealth(String? api) {
  final s = (api ?? '').toLowerCase();
  if (s.contains('alert') || s.contains('cảnh')) return CrabDisplayHealth.alert;
  if (s.contains('risk') ||
      s.contains('weak') ||
      s.contains('yếu') ||
      s.contains('bệnh') ||
      s.contains('sick')) {
    return CrabDisplayHealth.weak;
  }
  if (s.contains('monitor') || s.contains('theo')) {
    return CrabDisplayHealth.monitoring;
  }
  return CrabDisplayHealth.healthy;
}

String lifeStatusToApi(CrabLifeStatus life) => switch (life) {
      CrabLifeStatus.dead => 'dead',
      CrabLifeStatus.sold => 'sold',
      CrabLifeStatus.readyForSale => 'harvested',
      _ => 'alive',
    };

CrabHealthStatus mapHealthStatus(String? api) {
  final s = (api ?? 'healthy').toLowerCase();
  if (s.contains('molt')) return CrabHealthStatus.molting;
  if (s.contains('risk') ||
      s.contains('nguy') ||
      s.contains('weak') ||
      s.contains('yếu') ||
      s.contains('bệnh') ||
      s.contains('sick') ||
      s.contains('alert')) {
    return CrabHealthStatus.atRisk;
  }
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
  if (s.contains('premolt') || s.contains('pre_molt') || s.contains('chuẩn bị lột') || s.contains('saplot')) {
    return CrabDevelopmentStage.preMolt;
  }
  if (s.contains('post') || s.contains('soft') || s.contains('sau lột')) {
    return CrabDevelopmentStage.postMolt;
  }
  if (s.contains('molt') || s.contains('đang lột')) {
    return CrabDevelopmentStage.molting;
  }
  if (s.contains('harvest') || s.contains('thu')) {
    return CrabDevelopmentStage.harvestReady;
  }
  if (s.contains('pre')) return CrabDevelopmentStage.preHarvest;
  return CrabDevelopmentStage.growing;
}

String growthStageToApi(CrabDevelopmentStage s) => switch (s) {
      CrabDevelopmentStage.juvenile => 'juvenile',
      CrabDevelopmentStage.growing => 'growing',
      CrabDevelopmentStage.preMolt => 'premolt',
      CrabDevelopmentStage.molting => 'molting',
      CrabDevelopmentStage.postMolt => 'softshell',
      CrabDevelopmentStage.preHarvest => 'pre_harvest',
      CrabDevelopmentStage.harvestReady => 'harvest_ready',
    };

String healthDisplayToCondition(CrabDisplayHealth h) => switch (h) {
      CrabDisplayHealth.healthy => 'normal',
      CrabDisplayHealth.monitoring => 'weak',
      CrabDisplayHealth.weak => 'problem',
      CrabDisplayHealth.alert => 'problem',
    };

String lifecycleToMoltingStage(CrabLifecycleStatus s, CrabDevelopmentStage stage) {
  if (s == CrabLifecycleStatus.molting) return 'molting';
  if (s == CrabLifecycleStatus.readyHarvest) return 'harvest_ready';
  return growthStageToApi(stage);
}

MoltCondition mapMoltCondition(String api) {
  final s = api.toLowerCase();
  if (s.contains('watch') || s.contains('incomplete')) {
    return MoltCondition.needsWatch;
  }
  if (s.contains('weak') || s.contains('yếu') || s.contains('fail')) {
    return MoltCondition.weak;
  }
  return MoltCondition.normal;
}

/// BE chỉ nhận success | failed | incomplete.
String moltConditionToApi(MoltCondition c) => switch (c) {
      MoltCondition.normal => 'success',
      MoltCondition.weak => 'failed',
      MoltCondition.needsWatch => 'incomplete',
    };

DateTime? parseApiDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

CrabIndividual crabFromListItem(CrabManagementListItem item) {
  final release = parseApiDate(item.batchStartDate) ?? DateTime.now();
  final lifecycle = mapLifecycleStatus(
    status: item.status,
    growthStage: item.growthStage,
    healthStatus: item.healthStatus,
  );
  return CrabIndividual(
    id: item.id,
    displayCode: item.crabCode,
    boxId: item.boxId,
    batchId: item.batchCode,
    areaId: item.areaId,
    areaCode: item.areaCode,
    areaName: item.areaName,
    rowId: item.rowId,
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
    lifecycleStatus: lifecycle,
    healthScore: _healthScore(item),
    developmentStage: mapGrowthStage(item.growthStage),
    updatedAt: parseApiDate(item.updatedAt) ?? DateTime.now(),
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
  final parsedMolts = <CrabMoltRecord>[];
  final rawMolts = body['moltLogs'];
  if (rawMolts is List) {
    for (final m in rawMolts.whereType<Map>()) {
      final map = Map<String, dynamic>.from(m);
      final date = parseApiDate(map['moltDate']?.toString());
      if (date == null) continue;
      parsedMolts.add(
        CrabMoltRecord(
          id: (map['id'] ?? map['Id'])?.toString(),
          number: 0,
          date: date,
          condition: mapMoltCondition((map['condition'] ?? 'normal').toString()),
          note: map['note']?.toString(),
          photoUrls: photoUrlsFromJson(map['photoUrls'] ?? map['PhotoUrls']),
        ),
      );
    }
  }
  parsedMolts.sort((a, b) => a.date.compareTo(b.date));
  final molts = [
    for (var i = 0; i < parsedMolts.length; i++)
      CrabMoltRecord(
        id: parsedMolts[i].id,
        number: i + 1,
        date: parsedMolts[i].date,
        condition: parsedMolts[i].condition,
        note: parsedMolts[i].note,
        photoUrls: parsedMolts[i].photoUrls,
      ),
  ];

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
    moltCount: molts.isNotEmpty ? molts.length : base.moltCount,
    lastMoltDate: molts.isNotEmpty ? molts.last.date : base.lastMoltDate,
    estimatedValueVnd: estimatedVnd,
    meatQualityScore: meatScore,
    alertCount: diseases.length,
    quickNote: note ?? base.quickNote,
  );
}

const crabLifeStatusOptions = [
  'Tất cả trạng thái',
  'Đang nuôi',
  'Sẵn sàng bán',
  'Đã bán',
  'Đã chết',
];

const crabHealthStatusOptions = [
  'Tất cả sức khỏe',
  'Khỏe mạnh',
  'Tốt',
  'Theo dõi',
  'Đang lột xác',
  'Nguy cơ',
];

List<CrabSummaryKpi> crabManagementSummaryKpis(CrabManagementSummary s) => [
      CrabSummaryKpi(
        label: 'TỔNG SỐ CUA',
        value: formatInt(s.total),
        subtext: 'Tất cả cá thể trong hệ thống',
        icon: Icons.set_meal_outlined,
        accentColor: const Color(0xFF2495E8),
      ),
      CrabSummaryKpi(
        label: 'ĐANG NUÔI',
        value: formatInt(s.alive),
        subtext: '${s.pct(s.alive).toStringAsFixed(1)}%',
        icon: Icons.eco_outlined,
        accentColor: DashboardColors.brandGreen,
      ),
      CrabSummaryKpi(
        label: 'THEO DÕI',
        value: formatInt(s.monitoring),
        subtext: '${s.pct(s.monitoring).toStringAsFixed(1)}%',
        icon: Icons.warning_amber_rounded,
        accentColor: const Color(0xFFF5B700),
      ),
      CrabSummaryKpi(
        label: 'ĐANG LỘT XÁC',
        value: formatInt(s.molting),
        subtext: '${s.pct(s.molting).toStringAsFixed(1)}%',
        icon: Icons.sync_outlined,
        accentColor: const Color(0xFF7C3AED),
      ),
      CrabSummaryKpi(
        label: 'SẮP THU HOẠCH',
        value: formatInt(s.readyHarvest),
        subtext: '${s.pct(s.readyHarvest).toStringAsFixed(1)}%',
        icon: Icons.shopping_basket_outlined,
        accentColor: DashboardColors.seaGreen,
      ),
      CrabSummaryKpi(
        label: 'CUA CHẾT',
        value: formatInt(s.dead),
        subtext: '${s.pct(s.dead).toStringAsFixed(1)}%',
        icon: Icons.heart_broken_outlined,
        accentColor: DashboardColors.risk,
      ),
    ];

List<CrabSummaryKpi> crabSummaryKpis(List<CrabIndividual> crabs) {
  return crabManagementSummaryKpis(summarizeCrabs(crabs));
}

CrabManagementSummary summarizeCrabs(List<CrabIndividual> crabs) {
  final total = crabs.length;
  final growing =
      crabs.where((c) => c.lifecycleStatus == CrabLifecycleStatus.growing).length;
  final monitoring =
      crabs.where((c) => c.displayHealth == CrabDisplayHealth.monitoring).length;
  final molting =
      crabs.where((c) => c.lifecycleStatus == CrabLifecycleStatus.molting).length;
  final ready = crabs
      .where((c) => c.lifecycleStatus == CrabLifecycleStatus.readyHarvest)
      .length;
  final dead =
      crabs.where((c) => c.lifecycleStatus == CrabLifecycleStatus.dead).length;
  return CrabManagementSummary(
    total: total,
    alive: growing,
    dead: dead,
    molting: molting,
    readyHarvest: ready,
    aliveRate: total == 0 ? 0 : growing / total * 100,
    monitoring: monitoring,
  );
}

CrabIndividual? findCrabById(List<CrabIndividual> crabs, String id) {
  final key = id.trim();
  if (key.isEmpty) return null;
  for (final c in crabs) {
    if (c.id == key) return c;
  }
  for (final c in crabs) {
    if (c.code == key || c.displayCode == key) return c;
  }
  return null;
}

List<String> photoUrlsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item != null && item.toString().trim().isNotEmpty) item.toString().trim(),
  ];
}
