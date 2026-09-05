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
  dead;

  String get label => switch (this) {
        CrabOperationalStatus.alive => 'ĐANG SỐNG',
        CrabOperationalStatus.molting => 'MOLTING',
        CrabOperationalStatus.warning => 'CẢNH BÁO',
        CrabOperationalStatus.readyHarvest => 'SẮP THU HOẠCH',
        CrabOperationalStatus.harvested => 'ĐÃ THU HOẠCH',
        CrabOperationalStatus.dead => 'CHẾT',
      };

  Color get color => switch (this) {
        CrabOperationalStatus.alive => DashboardColors.healthy,
        CrabOperationalStatus.molting => DashboardColors.molting,
        CrabOperationalStatus.warning => DashboardColors.monitoring,
        CrabOperationalStatus.readyHarvest => DashboardColors.oceanBlue,
        CrabOperationalStatus.harvested => DashboardColors.dead,
        CrabOperationalStatus.dead => DashboardColors.risk,
      };
}

enum CrabLifeStatus {
  raising,
  readyForSale,
  sold,
  dead;

  String get label => switch (this) {
        CrabLifeStatus.raising => 'Đang nuôi',
        CrabLifeStatus.readyForSale => 'Sẵn sàng bán',
        CrabLifeStatus.sold => 'Đã thu hoạch',
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
