import 'package:flutter/material.dart';

class CrabStatusHistoryDay {
  final DateTime date;
  final int normal;
  final int watch;
  final int molting;
  final int alert;
  final int empty;

  const CrabStatusHistoryDay({
    required this.date,
    required this.normal,
    required this.watch,
    required this.molting,
    required this.alert,
    required this.empty,
  });
}

/// Trạng thái tổng quan trang trại (Farm Overview Hero)
class FarmSummary {
  final int totalBoxes;
  final int totalCrabs;
  final int activeBoxes;
  final int openAlerts;
  final double iotOnlinePercentage;
  final DateTime lastUpdated;

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
  final int score; // 0 - 100
  final HealthStatusLevel statusLevel;
  final String statusLabel; // Excellent / Good / Warning / Critical
  final double deltaVsYesterday; // e.g. +3.0 %
  final DateTime lastAiUpdated;
  final int waterQualityScore; // e.g. 94
  final int crabHealthScore; // e.g. 90
  final int deviceStatusScore; // e.g. 88
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
  final int confidencePercentage; // e.g. 94
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
    id: 'empty',
    type: AiActionType.observe,
    title: 'Không có hành động khẩn cấp',
    description: 'Hệ thống đang hoạt động ổn định',
    targetBoxOrArea: 'Toàn trang trại',
    confidencePercentage: 99,
    priority: ActionPriority.low,
    reason:
        'Tất cả các thông số nước và tình trạng cua đều nằm trong ngưỡng an toàn.',
    optimalTimeframe: 'Duy trì giám sát',
    expectedImpact: 'Ổn định vận hành',
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
  final DateTime timestamp;
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

  const WaterMetricItem({
    required this.code,
    required this.name,
    required this.currentValue,
    required this.unit,
    required this.status,
    required this.trend,
    required this.lastUpdated,
  });
}

/// Công việc trong ngày (Today's Tasks Section C)
class TodayTaskItem {
  final String id;
  final String title;
  final String target;
  final DateTime deadline;
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

/// Trạng thái thiết bị (Device Status Section D)
class DeviceSummary {
  final int esp32Online;
  final int esp32Total;
  final int cameraOnline;
  final int cameraTotal;
  final int pumpRunning;
  final int pumpTotal;
  final int valveReady;
  final int valveTotal;

  const DeviceSummary({
    required this.esp32Online,
    required this.esp32Total,
    required this.cameraOnline,
    required this.cameraTotal,
    required this.pumpRunning,
    required this.pumpTotal,
    required this.valveReady,
    required this.valveTotal,
  });
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
  final DateTime timestamp;

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

  const FarmOption({required this.id, required this.name});
}

/// Tổng hợp dữ liệu hiển thị toàn màn hình Home (Command Center State Data)
class HomeStateData {
  final String operatorName;
  final String? selectedFarmId;
  final String selectedFarmName;
  final List<FarmOption> availableFarms;
  final bool isOnline;
  final int unreadNotificationsCount;
  final FarmSummary farmSummary;
  final FarmHealthScore healthScore;
  final AiRecommendation aiRecommendation;
  final List<AlertSummaryItem> topAlerts;
  final List<WaterMetricItem> waterMetrics;
  final List<TodayTaskItem> todayTasks;
  final DeviceSummary deviceSummary;
  final List<RecentActivityItem> recentActivities;
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
    required this.deviceSummary,
    required this.recentActivities,
    this.isOfflineCached = false,
    this.lastSyncedAt,
  });
}
