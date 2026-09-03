import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum FarmLogType {
  feeding,
  waterChange,
  weightUpdate,
  molting,
  disease,
  medication,
  maintenance,
  harvest,
  deathRecord,
  observation,
  other;

  String get label => switch (this) {
        FarmLogType.feeding => 'Cho ăn',
        FarmLogType.waterChange => 'Thay nước',
        FarmLogType.weightUpdate => 'Cân cua',
        FarmLogType.molting => 'Lột xác',
        FarmLogType.disease => 'Điều trị',
        FarmLogType.medication => 'Thuốc',
        FarmLogType.maintenance => 'Bảo trì',
        FarmLogType.harvest => 'Thu hoạch',
        FarmLogType.deathRecord => 'Ghi nhận chết',
        FarmLogType.observation => 'Quan sát',
        FarmLogType.other => 'Khác',
      };

  String get pillLabel => switch (this) {
        FarmLogType.feeding => 'CHO ĂN',
        FarmLogType.waterChange => 'THAY NƯỚC',
        FarmLogType.weightUpdate => 'CÂN CUA',
        FarmLogType.molting => 'LỘT XÁC',
        FarmLogType.disease => 'ĐIỀU TRỊ',
        FarmLogType.medication => 'THUỐC',
        FarmLogType.maintenance => 'BẢO TRÌ',
        FarmLogType.harvest => 'THU HOẠCH',
        FarmLogType.deathRecord => 'CHẾT',
        FarmLogType.observation => 'QUAN SÁT',
        FarmLogType.other => 'KHÁC',
      };

  Color get color => switch (this) {
        FarmLogType.feeding => DashboardColors.blue,
        FarmLogType.waterChange => DashboardColors.cyan,
        FarmLogType.weightUpdate => const Color(0xFF67E8F9),
        FarmLogType.molting => const Color(0xFFC4B5FD),
        FarmLogType.disease => DashboardColors.risk,
        FarmLogType.medication => DashboardColors.molting,
        FarmLogType.maintenance => const Color(0xFF94A3B8),
        FarmLogType.harvest => DashboardColors.healthy,
        FarmLogType.deathRecord => DashboardColors.risk,
        FarmLogType.observation => DashboardColors.blue,
        FarmLogType.other => DashboardColors.textMuted,
      };

  IconData get icon => switch (this) {
        FarmLogType.feeding => Icons.restaurant_outlined,
        FarmLogType.waterChange => Icons.water_drop_outlined,
        FarmLogType.weightUpdate => Icons.monitor_weight_outlined,
        FarmLogType.molting => Icons.pets_outlined,
        FarmLogType.disease => Icons.medical_services_outlined,
        FarmLogType.medication => Icons.medication_outlined,
        FarmLogType.maintenance => Icons.build_outlined,
        FarmLogType.harvest => Icons.agriculture_outlined,
        FarmLogType.deathRecord => Icons.warning_amber_outlined,
        FarmLogType.observation => Icons.visibility_outlined,
        FarmLogType.other => Icons.more_horiz,
      };
}

enum EvidenceType { photo, video, none }

class FarmLogKpi {
  const FarmLogKpi({
    required this.totalToday,
    required this.feeding,
    required this.molting,
    required this.weighing,
    required this.treatment,
    required this.maintenance,
    required this.harvest,
  });

  final int totalToday;
  final int feeding;
  final int molting;
  final int weighing;
  final int treatment;
  final int maintenance;
  final int harvest;
}

class FarmActivityLogEntry {
  const FarmActivityLogEntry({
    required this.id,
    required this.logCode,
    required this.time,
    required this.type,
    required this.content,
    required this.performer,
    required this.area,
    this.batchId = '',
    this.boxId = '',
    this.crabId = '',
    this.note = '',
    this.subjectDetail = '',
    this.evidenceType = EvidenceType.none,
    this.evidenceLabel = '',
    this.imageUrls = const [],
    this.logDate = '',
  });

  final String id;
  final String logCode;
  final String time;
  final FarmLogType type;
  final String content;
  final String performer;
  final String area;
  final String batchId;
  final String boxId;
  final String crabId;
  final String note;
  final String subjectDetail;
  final EvidenceType evidenceType;
  final String evidenceLabel;
  final List<String> imageUrls;
  final String logDate;
}

class FarmLogAiSummary {
  const FarmLogAiSummary({
    required this.feeding7d,
    required this.molting7d,
    required this.disease7d,
    required this.maintenance7d,
    required this.recommendation,
  });

  final int feeding7d;
  final int molting7d;
  final int disease7d;
  final int maintenance7d;
  final String recommendation;
}
