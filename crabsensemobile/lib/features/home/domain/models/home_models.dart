import 'package:flutter/material.dart';
import '../../../water_quality/domain/entities/water_quality.dart';

/// Trạng thái tổng quan trang trại (Farm Overview Hero)
class FarmSummary {
  final int? totalBoxes;
  final int? totalCrabs;
  final int? activeBoxes;
  final int? openAlerts;
  final double? iotOnlinePercentage;
  final DateTime? lastUpdated;

  const FarmSummary({
    required this.totalBoxes,
    required this.totalCrabs,
    required this.activeBoxes,
    required this.openAlerts,
    required this.iotOnlinePercentage,
    required this.lastUpdated,
  });
}

/// Mức độ sức khỏe trang trại (Farm Health Score - Điểm nhấn #1)
enum HealthStatusLevel {
  excellent, // 85-100 (Success)
  good, // 70-84 (Info)
  warning, // 50-69 (Warning)
  danger, // <50 (Danger)
}

class FarmHealthScore {
  final int? score;
  final HealthStatusLevel? statusLevel;
  final String statusLabel; // Excellent / Good / Warning / Critical
  final double? deltaVsYesterday;
  final DateTime? lastAiUpdated;
  final int? waterQualityScore;
  final int? crabHealthScore;
  final int? deviceStatusScore;
  final String explanation; // Explanation why score increased/decreased

  const FarmHealthScore({
    required this.score,
    required this.statusLevel,
    required this.statusLabel,
    required this.deltaVsYesterday,
    required this.lastAiUpdated,
    required this.waterQualityScore,
    required this.crabHealthScore,
    required this.deviceStatusScore,
    required this.explanation,
  });

  static const unavailable = FarmHealthScore(
    score: null, statusLevel: null, statusLabel: 'Chưa có đánh giá xác minh',
    deltaVsYesterday: null, lastAiUpdated: null, waterQualityScore: null,
    crabHealthScore: null, deviceStatusScore: null,
    explanation: 'Xem riêng từng phép đo RAS và cảnh báo đã ghi nhận.',
  );

  static HealthStatusLevel calculateLevel(int score) {
    if (score >= 85) return HealthStatusLevel.excellent;
    if (score >= 70) return HealthStatusLevel.good;
    if (score >= 50) return HealthStatusLevel.warning;
    return HealthStatusLevel.danger;
  }
}

/// Đề xuất hành động từ AI (AI Recommendation - Điểm nhấn #2)
enum AiActionType { harvest, inspect, waterTreatment, observe }

enum ActionPriority { high, medium, low }

class AiRecommendation {
  final String id;
  final AiActionType type;
  final String title;
  final String description;
  final String targetBoxOrArea; // e.g. "Box B01-12"
  final int? confidencePercentage;
  final ActionPriority priority;
  final String reason; // AI detected molting completion
  final String optimalTimeframe; // e.g. "Trong 6 giờ"
  final String expectedImpact; // e.g. "Tăng tỷ lệ cua lột loại A 15%"
  final bool hasActiveRecommendation;

  const AiRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetBoxOrArea,
    required this.confidencePercentage,
    required this.priority,
    required this.reason,
    required this.optimalTimeframe,
    required this.expectedImpact,
    this.hasActiveRecommendation = true,
  });

  static const AiRecommendation empty = AiRecommendation(
    id: 'empty', type: AiActionType.observe,
    title: 'Chưa có đánh giá AI xác minh',
    description: 'Chưa có đề xuất có nguồn gốc xác minh.',
    targetBoxOrArea: '', confidencePercentage: null,
    priority: ActionPriority.low, reason: '',
    optimalTimeframe: '', expectedImpact: '',
    hasActiveRecommendation: false,
  );
}

/// Thao tác nhanh (Quick Action - Điểm nhấn #3)
class QuickActionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool isPrimary;

  const QuickActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.isPrimary = false,
  });
}

/// Tóm tắt cảnh báo (Alert Summary Section A)
enum AlertSeverityLevel { critical, warning, info }

class AlertSummaryItem {
  final String id;
  final String title;
  final String location;
  final AlertSeverityLevel severity;
  final DateTime? timestamp;
  final String status;

  const AlertSummaryItem({
    required this.id,
    required this.title,
    required this.location,
    required this.severity,
    required this.timestamp,
    required this.status,
  });
}

/// Tổng quan chất lượng nước (Water Quality Section B)
enum MetricStatus { optimal, warning, danger }

enum MetricTrend { up, down, stable }

class WaterMetricItem {
  final String code;
  final String name;
  final double currentValue;
  final String unit;
  final MetricStatus status;
  final MetricTrend trend;
  final DateTime lastUpdated;
  final double? minThreshold;
  final double? maxThreshold;
  final WaterQuality? qualifiedReading;
  final int? sessionRevision;

  const WaterMetricItem({
    required this.code,
    required this.name,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.trend,
    required this.lastUpdated,
    this.minThreshold,
    this.maxThreshold,
    this.qualifiedReading,
    this.sessionRevision,
  });
}

/// Công việc trong ngày (Today's Tasks Section C)
class TodayTaskItem {
  final String id;
  final String title;
  final String target;
  final DateTime? deadline;
  final ActionPriority priority;
  final bool isCompleted;

  const TodayTaskItem({
    required this.id,
    required this.title,
    required this.target,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
  });
}

class FeedingHistoryDay {
  final DateTime date;
  final int many;
  final int little;
  final int none;

  const FeedingHistoryDay({
    required this.date,
    required this.many,
    required this.little,
    required this.none,
  });
}

class BoxStatusHistoryDay {
  final DateTime date;
  final int normal;
  final int watch;
  final int molting;
  final int alert;
  final int empty;

  const BoxStatusHistoryDay({
    required this.date,
    required this.normal,
    required this.watch,
    required this.molting,
    required this.alert,
    required this.empty,
  });
}

/// Trạng thái thiết bị (Device Status Section D)
class DeviceSummary {
  final int? onlineCount;
  final int? totalCount;
  const DeviceSummary({required this.onlineCount, required this.totalCount});
  static const unavailable = DeviceSummary(onlineCount: null, totalCount: null);
  factory DeviceSummary.fromAreaInventory(Map<String, dynamic>? json) {
    final total = homeCount(json?['totalCount']);
    final online = homeCount(json?['onlineCount']);
    if (total == null || online == null || online > total ||
        json?['isOnline'] is! bool || json?['isOnline'] != (online > 0)) {
      return unavailable;
    }
    return DeviceSummary(onlineCount: online, totalCount: total);
  }
  double? get percentage {
    final total = totalCount, online = onlineCount;
    if (total == null || total == 0 || online == null || online > total) return null;
    return online * 100 / total;
  }
}

int? homeCount(Object? value) => value is int && value >= 0 ? value : null;

DateTime? homeSourceTime(Object? raw, {bool allowFuture = false, DateTime? now}) {
  if (raw is! String) return null;
  final p = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](\d{2}):(\d{2}))$').firstMatch(raw);
  if (p == null) return null;
  final year = int.parse(p[1]!), month = int.parse(p[2]!), day = int.parse(p[3]!);
  if (year < 2000 || month < 1 || month > 12 || day < 1 ||
      day > DateTime.utc(year, month + 1, 0).day ||
      int.parse(p[4]!) > 23 || int.parse(p[5]!) > 59 || int.parse(p[6]!) > 59 ||
      int.parse(p[7] ?? '0') > 23 || int.parse(p[8] ?? '0') > 59) return null;
  final dt = DateTime.tryParse(raw);
  return dt == null || (!allowFuture && dt.isAfter(now ?? DateTime.now())) ? null : dt;
}

String homeCountLabel(int? count) => count?.toString() ?? '—';
String homeTimeLabel(DateTime? dt, {DateTime? now}) {
  if (dt == null) return 'Chưa có thời gian';
  final diff = (now ?? DateTime.now()).difference(dt);
  if (diff.isNegative) return 'Chưa có thời gian';
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

/// Nhật ký hoạt động gần đây (Recent Activity Section E)
enum ActivityType {
  qrScan,
  sensorUpdate,
  aiDetection,
  harvest,
  sync,
  alertHandled,
}

class RecentActivityItem {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final DateTime? timestamp;

  const RecentActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });
}

/// Tuỳ chọn khu nuôi trên Home (id + tên)
class FarmOption {
  final String id;
  final String name;
  final int boxCount;

  const FarmOption({required this.id, required this.name, this.boxCount = 0});
}

/// Tổng hợp dữ liệu hiển thị toàn màn hình Home (Command Center State Data)
class HomeStateData {
  final String operatorName;
  final String? selectedFarmId;
  final String selectedFarmName;
  final List<FarmOption> availableFarms;
  final bool isOnline;
  final int? unreadNotificationsCount;
  final FarmSummary farmSummary;
  final FarmHealthScore healthScore;
  final AiRecommendation aiRecommendation;
  final List<AlertSummaryItem> topAlerts;
  final List<WaterMetricItem> waterMetrics;
  final List<TodayTaskItem> todayTasks;
  final List<FeedingHistoryDay> feedingHistory;
  final List<BoxStatusHistoryDay> boxStatusHistory;
  final DeviceSummary deviceSummary;
  final List<RecentActivityItem> recentActivities;
  final Map<String, int> boxStatusCounts;
  final bool isOfflineCached;
  final DateTime? lastSyncedAt;

  const HomeStateData({
    required this.operatorName,
    this.selectedFarmId,
    required this.selectedFarmName,
    required this.availableFarms,
    required this.isOnline,
    required this.unreadNotificationsCount,
    required this.farmSummary,
    required this.healthScore,
    required this.aiRecommendation,
    required this.topAlerts,
    required this.waterMetrics,
    required this.todayTasks,
    this.feedingHistory = const [],
    this.boxStatusHistory = const [],
    required this.deviceSummary,
    required this.recentActivities,
    this.boxStatusCounts = const {},
    this.isOfflineCached = false,
    this.lastSyncedAt,
  });
}
