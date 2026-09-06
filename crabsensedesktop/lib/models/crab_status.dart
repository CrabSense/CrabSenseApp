import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum CrabGender {
  unknown,
  male,
  female;

  String get label => switch (this) {
        CrabGender.unknown => 'Chưa rõ',
        CrabGender.male => 'Đực',
        CrabGender.female => 'Cái',
      };
}

enum CrabHealthStatus {
  healthy,
  good,
  monitoring,
  molting,
  atRisk;

  String get label => switch (this) {
        CrabHealthStatus.healthy => 'Khỏe mạnh',
        CrabHealthStatus.good => 'Tốt',
        CrabHealthStatus.monitoring => 'Theo dõi',
        CrabHealthStatus.molting => 'Đang lột xác',
        CrabHealthStatus.atRisk => 'Nguy cơ',
      };

  Color get color => switch (this) {
        CrabHealthStatus.healthy => DashboardColors.healthy,
        CrabHealthStatus.good => DashboardColors.cyan,
        CrabHealthStatus.monitoring => DashboardColors.monitoring,
        CrabHealthStatus.molting => DashboardColors.molting,
        CrabHealthStatus.atRisk => DashboardColors.risk,
      };
}

/// Bộ lọc trạng thái trên màn Quản lý Cua.
enum CrabManagementStatusFilter {
  all,
  alive,
  molting,
  sickWeak,
  dead,
  harvested;

  String get label => switch (this) {
        CrabManagementStatusFilter.all => 'Tất cả',
        CrabManagementStatusFilter.alive => 'Đang sống',
        CrabManagementStatusFilter.molting => 'Đang lột xác',
        CrabManagementStatusFilter.sickWeak => 'Bệnh/yếu',
        CrabManagementStatusFilter.dead => 'Chết',
        CrabManagementStatusFilter.harvested => 'Đã thu hoạch',
      };
}

enum CrabDevelopmentStage {
  juvenile,
  growing,
  preHarvest,
  harvestReady;

  String get label => switch (this) {
        CrabDevelopmentStage.juvenile => 'Ấu trùng',
        CrabDevelopmentStage.growing => 'Đang lớn',
        CrabDevelopmentStage.preHarvest => 'Gần thu hoạch',
        CrabDevelopmentStage.harvestReady => 'Sẵn thu hoạch',
      };
}

/// Badge trạng thái vận hành (bảng danh sách).
enum CrabOperationalStatus {
  alive,
  molting,
  warning,
  readyHarvest,
  harvested,
  sold,
  dead;

  String get label => switch (this) {
        CrabOperationalStatus.alive => 'ĐANG SỐNG',
        CrabOperationalStatus.molting => 'MOLTING',
        CrabOperationalStatus.warning => 'CẢNH BÁO',
        CrabOperationalStatus.readyHarvest => 'SẮP THU HOẠCH',
        CrabOperationalStatus.harvested => 'ĐÃ THU HOẠCH',
        CrabOperationalStatus.sold => 'ĐÃ BÁN',
        CrabOperationalStatus.dead => 'CHẾT',
      };

  Color get color => switch (this) {
        CrabOperationalStatus.alive => DashboardColors.healthy,
        CrabOperationalStatus.molting => DashboardColors.molting,
        CrabOperationalStatus.warning => DashboardColors.monitoring,
        CrabOperationalStatus.readyHarvest => DashboardColors.oceanBlue,
        CrabOperationalStatus.harvested => DashboardColors.cyan,
        CrabOperationalStatus.sold => DashboardColors.purple,
        CrabOperationalStatus.dead => DashboardColors.risk,
      };
}

/// BE gửi `status` (Harvested/Sold/Dead/Alive) và `isAlive`.
/// Thu hoạch cũng `isAlive == false` — không được suy ra chết từ cờ đó.
String resolveCrabLifecycleStatus(Map<String, dynamic> json) {
  final fromStatus = _normalizeLifecycle(
    (json['status'] ?? json['Status'] ?? '').toString(),
  );
  if (fromStatus != null) return fromStatus;
  final fromCondition = _normalizeLifecycle(
    (json['condition'] ?? json['Condition'] ?? '').toString(),
  );
  if (fromCondition != null) return fromCondition;

  final alive = json['isAlive'] ?? json['IsAlive'];
  final molting =
      (json['moltingStage'] ?? json['MoltingStage'] ?? '').toString();
  if (alive is bool) {
    if (!alive) return 'dead';
    return molting.toLowerCase().contains('molt') ? 'molting' : 'alive';
  }
  return 'alive';
}

String? _normalizeLifecycle(String raw) {
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return null;
  if (key.contains('sold') || key.contains('daban') || key.contains('đã bán')) {
    return 'sold';
  }
  if (key.contains('harvest') ||
      key.contains('thu hoạch') ||
      key.contains('thuhoach')) {
    return 'harvested';
  }
  if (key.contains('dead') ||
      key.contains('chet') ||
      key.contains('chết') ||
      key == 'missing') {
    return 'dead';
  }
  if (key.contains('molt') || key.contains('lột')) return 'molting';
  if (key.contains('alive') ||
      key.contains('quarant') ||
      key.contains('normal') ||
      key.contains('raising')) {
    return 'alive';
  }
  return null;
}

enum CrabLifeStatus {
  raising,
  readyForSale,
  sold,
  dead;

  String get label => switch (this) {
        CrabLifeStatus.raising => 'Đang nuôi',
        CrabLifeStatus.readyForSale => 'Đã thu hoạch',
        CrabLifeStatus.sold => 'Đã bán',
        CrabLifeStatus.dead => 'Đã chết',
      };

  Color get color => switch (this) {
        CrabLifeStatus.raising => DashboardColors.cyan,
        CrabLifeStatus.readyForSale => DashboardColors.blue,
        CrabLifeStatus.sold => DashboardColors.purple,
        CrabLifeStatus.dead => DashboardColors.dead,
      };
}

enum MoltCondition {
  normal,
  weak,
  needsWatch;

  String get label => switch (this) {
        MoltCondition.normal => 'Bình thường',
        MoltCondition.weak => 'Yếu',
        MoltCondition.needsWatch => 'Cần theo dõi',
      };
}

enum DiseaseSeverity {
  mild,
  moderate,
  severe;

  String get label => switch (this) {
        DiseaseSeverity.mild => 'Nhẹ',
        DiseaseSeverity.moderate => 'Trung bình',
        DiseaseSeverity.severe => 'Nặng',
      };
}

enum DiseaseRecordStatus {
  resolved,
  monitoring,
  active;

  String get label => switch (this) {
        DiseaseRecordStatus.resolved => 'Đã xử lý',
        DiseaseRecordStatus.monitoring => 'Theo dõi',
        DiseaseRecordStatus.active => 'Đang xử lý',
      };
}
