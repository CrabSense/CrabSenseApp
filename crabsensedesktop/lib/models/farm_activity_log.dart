import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum FarmLogSource {
  manual,
  auto;

  String get label => this == FarmLogSource.auto ? 'Tự động' : 'Thủ công';
}

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
  other,
  crabInbound,
  placeInBox,
  moveBox,
  inspectCrab,
  cleanBox,
  anomaly,
  watch,
  preMolt,
  cleanSystem,
  waterCheck,
  waterAnalysis,
  rasControl,
  aiEvent;

  static const manualChoices = [
    FarmLogType.crabInbound,
    FarmLogType.placeInBox,
    FarmLogType.moveBox,
    FarmLogType.inspectCrab,
    FarmLogType.feeding,
    FarmLogType.cleanBox,
    FarmLogType.anomaly,
    FarmLogType.watch,
    FarmLogType.preMolt,
    FarmLogType.molting,
    FarmLogType.deathRecord,
    FarmLogType.harvest,
    FarmLogType.waterChange,
    FarmLogType.cleanSystem,
    FarmLogType.waterCheck,
  ];

  String get label => switch (this) {
        FarmLogType.feeding => 'Cho ăn',
        FarmLogType.waterChange => 'Thay nước',
        FarmLogType.weightUpdate => 'Cân cua',
        FarmLogType.molting => 'Đã lột',
        FarmLogType.disease => 'Điều trị',
        FarmLogType.medication => 'Thuốc',
        FarmLogType.maintenance => 'Bảo trì',
        FarmLogType.harvest => 'Thu hoạch',
        FarmLogType.deathRecord => 'Cua chết',
        FarmLogType.observation => 'Quan sát',
        FarmLogType.other => 'Khác',
        FarmLogType.crabInbound => 'Nhập cua',
        FarmLogType.placeInBox => 'Thả cua vào hộp',
        FarmLogType.moveBox => 'Chuyển hộp',
        FarmLogType.inspectCrab => 'Kiểm tra cua',
        FarmLogType.cleanBox => 'Vệ sinh hộp',
        FarmLogType.anomaly => 'Phát hiện bất thường',
        FarmLogType.watch => 'Theo dõi',
        FarmLogType.preMolt => 'Sắp lột',
        FarmLogType.cleanSystem => 'Vệ sinh hệ thống',
        FarmLogType.waterCheck => 'Kiểm tra nước',
        FarmLogType.waterAnalysis => 'Phân tích nước',
        FarmLogType.rasControl => 'Điều khiển RAS',
        FarmLogType.aiEvent => 'AI phát hiện',
      };

  String get pillLabel => label.toUpperCase();

  Color get color => switch (this) {
        FarmLogType.feeding => DashboardColors.blue,
        FarmLogType.waterChange ||
        FarmLogType.waterCheck ||
        FarmLogType.waterAnalysis =>
          DashboardColors.cyan,
        FarmLogType.weightUpdate => const Color(0xFF67E8F9),
        FarmLogType.molting || FarmLogType.preMolt => const Color(0xFFA78BFA),
        FarmLogType.disease || FarmLogType.medication || FarmLogType.anomaly =>
          DashboardColors.risk,
        FarmLogType.maintenance ||
        FarmLogType.cleanBox ||
        FarmLogType.cleanSystem =>
          const Color(0xFF94A3B8),
        FarmLogType.harvest => DashboardColors.healthy,
        FarmLogType.deathRecord => DashboardColors.risk,
        FarmLogType.rasControl => DashboardColors.cyan,
        FarmLogType.aiEvent => DashboardColors.purple,
        FarmLogType.watch => DashboardColors.monitoring,
        _ => DashboardColors.blue,
      };

  IconData get icon => switch (this) {
        FarmLogType.feeding => Icons.restaurant_outlined,
        FarmLogType.waterChange ||
        FarmLogType.waterCheck =>
          Icons.water_drop_outlined,
        FarmLogType.waterAnalysis => Icons.science_outlined,
        FarmLogType.weightUpdate => Icons.monitor_weight_outlined,
        FarmLogType.molting ||
        FarmLogType.preMolt ||
        FarmLogType.inspectCrab =>
          Icons.pets_outlined,
        FarmLogType.disease => Icons.medical_services_outlined,
        FarmLogType.medication => Icons.medication_outlined,
        FarmLogType.maintenance ||
        FarmLogType.cleanBox ||
        FarmLogType.cleanSystem =>
          Icons.cleaning_services_outlined,
        FarmLogType.harvest => Icons.agriculture_outlined,
        FarmLogType.deathRecord => Icons.warning_amber_outlined,
        FarmLogType.observation => Icons.visibility_outlined,
        FarmLogType.crabInbound => Icons.local_shipping_outlined,
        FarmLogType.placeInBox || FarmLogType.moveBox => Icons.inventory_2_outlined,
        FarmLogType.anomaly => Icons.report_gmailerrorred_outlined,
        FarmLogType.watch => Icons.visibility_outlined,
        FarmLogType.rasControl => Icons.settings_input_component_outlined,
        FarmLogType.aiEvent => Icons.auto_awesome_outlined,
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
    this.rowName = '',
    this.locationPath = '',
    this.source = FarmLogSource.manual,
    this.occurredAt,
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
  final String rowName;
  final String locationPath;
  final FarmLogSource source;
  final DateTime? occurredAt;

  bool get isAuto => source == FarmLogSource.auto;

  String get placeLabel {
    if (locationPath.trim().isNotEmpty) return locationPath.trim();
    final parts = <String>[
      if (area.trim().isNotEmpty) area.trim(),
      if (rowName.trim().isNotEmpty) rowName.trim(),
      if (boxId.trim().isNotEmpty) boxId.trim(),
      if (crabId.trim().isNotEmpty) crabId.trim(),
    ];
    return parts.join(' → ');
  }

  DateTime get at {
    if (occurredAt != null) return occurredAt!;
    final p = logDate.split('/');
    if (p.length == 3) {
      final d = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      final y = int.tryParse(p[2]);
      final hm = time.split(':');
      if (d != null && m != null && y != null && hm.length >= 2) {
        return DateTime(
          y,
          m,
          d,
          int.tryParse(hm[0]) ?? 0,
          int.tryParse(hm[1]) ?? 0,
        );
      }
    }
    return DateTime.now();
  }
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
