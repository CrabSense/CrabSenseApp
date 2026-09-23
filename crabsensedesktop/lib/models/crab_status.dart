import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum CrabGender {
  unknown,
  male,
  female;

  String get label => switch (this) {
        CrabGender.unknown => 'Chưa xác định',
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

/// Bộ lọc chip nhanh trên màn Quản lý Cua.
/// “Theo dõi” là SỨC KHỎE; các chip còn lại là TRẠNG THÁI.
enum CrabManagementStatusFilter {
  all,
  growing,
  monitoring,
  molting,
  readyHarvest,
  dead;

  String get label => switch (this) {
        CrabManagementStatusFilter.all => 'Tất cả',
        CrabManagementStatusFilter.growing => 'Đang nuôi',
        CrabManagementStatusFilter.monitoring => 'Theo dõi',
        CrabManagementStatusFilter.molting => 'Đang lột xác',
        CrabManagementStatusFilter.readyHarvest => 'Sắp thu hoạch',
        CrabManagementStatusFilter.dead => 'Chết',
      };
}

/// Trạng thái nuôi — tách biệt với sức khỏe.
enum CrabLifecycleStatus {
  growing,
  molting,
  readyHarvest,
  harvested,
  dead;

  String get label => switch (this) {
        CrabLifecycleStatus.growing => 'Đang nuôi',
        CrabLifecycleStatus.molting => 'Đang lột xác',
        CrabLifecycleStatus.readyHarvest => 'Sắp thu hoạch',
        CrabLifecycleStatus.harvested => 'Đã thu hoạch',
        CrabLifecycleStatus.dead => 'Chết',
      };

  Color get color => switch (this) {
        CrabLifecycleStatus.growing => DashboardColors.brand,
        CrabLifecycleStatus.molting => const Color(0xFF7C3AED),
        CrabLifecycleStatus.readyHarvest => DashboardColors.seaGreen,
        CrabLifecycleStatus.harvested => const Color(0xFF2495E8),
        CrabLifecycleStatus.dead => DashboardColors.risk,
      };
}

/// Sức khỏe hiển thị — không gồm “Đang lột xác”.
enum CrabDisplayHealth {
  healthy,
  monitoring,
  weak,
  alert;

  String get label => switch (this) {
        CrabDisplayHealth.healthy => 'Khỏe mạnh',
        CrabDisplayHealth.monitoring => 'Theo dõi',
        CrabDisplayHealth.weak => 'Bệnh / Yếu',
        CrabDisplayHealth.alert => 'Cảnh báo',
      };

  Color get color => switch (this) {
        CrabDisplayHealth.healthy => DashboardColors.brand,
        CrabDisplayHealth.monitoring => const Color(0xFFF5B700),
        CrabDisplayHealth.weak => DashboardColors.risk,
        CrabDisplayHealth.alert => const Color(0xFFF97316),
      };
}

enum CrabDevelopmentStage {
  juvenile,
  growing,
  preMolt,
  molting,
  postMolt,
  preHarvest,
  harvestReady;

  String get label => switch (this) {
        CrabDevelopmentStage.juvenile => 'Ấu trùng',
        CrabDevelopmentStage.growing => 'Sinh trưởng',
        CrabDevelopmentStage.preMolt => 'Chuẩn bị lột',
        CrabDevelopmentStage.molting => 'Đang lột',
        CrabDevelopmentStage.postMolt => 'Sau lột',
        CrabDevelopmentStage.preHarvest => 'Gần thu hoạch',
        CrabDevelopmentStage.harvestReady => 'Sắp thu hoạch',
      };

  static const editOptions = [
    CrabDevelopmentStage.growing,
    CrabDevelopmentStage.preMolt,
    CrabDevelopmentStage.molting,
    CrabDevelopmentStage.postMolt,
    CrabDevelopmentStage.harvestReady,
  ];
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
