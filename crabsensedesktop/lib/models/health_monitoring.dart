import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum HealthLevel {
  healthy,
  monitoring,
  atRisk,
  emergency;

  static HealthLevel fromScore(double score) {
    if (score >= 80) return HealthLevel.healthy;
    if (score >= 60) return HealthLevel.monitoring;
    if (score >= 40) return HealthLevel.atRisk;
    return HealthLevel.emergency;
  }

  String get label => switch (this) {
        HealthLevel.healthy => 'Khỏe mạnh',
        HealthLevel.monitoring => 'Cần theo dõi',
        HealthLevel.atRisk => 'Nguy cơ',
        HealthLevel.emergency => 'Cảnh báo khẩn cấp',
      };

  Color get color => switch (this) {
        HealthLevel.healthy => DashboardColors.healthy,
        HealthLevel.monitoring => DashboardColors.monitoring,
        HealthLevel.atRisk => DashboardColors.molting,
        HealthLevel.emergency => DashboardColors.risk,
      };
}

enum DiseaseRiskLevel {
  low,
  medium,
  high,
  critical;

  String get label => switch (this) {
        DiseaseRiskLevel.low => 'Thấp',
        DiseaseRiskLevel.medium => 'Trung bình',
        DiseaseRiskLevel.high => 'Cao',
        DiseaseRiskLevel.critical => 'Khẩn cấp',
      };
}

enum MoltingMonitorStatus {
  normal,
  preMolt,
  molting,
  postMolt;

  String get label => switch (this) {
        MoltingMonitorStatus.normal => 'Bình thường',
        MoltingMonitorStatus.preMolt => 'Tiền lột xác',
        MoltingMonitorStatus.molting => 'Đang lột xác',
        MoltingMonitorStatus.postMolt => 'Hậu lột xác',
      };
}

class HealthScoreComponents {
  const HealthScoreComponents({
    required this.activity,
    required this.feeding,
    required this.growth,
    required this.waterQuality,
    required this.diseaseStatus,
  });

  final double activity;
  final double feeding;
  final double growth;
  final double waterQuality;
  final double diseaseStatus;

  double get total =>
      activity * 0.30 +
      feeding * 0.25 +
      growth * 0.20 +
      waterQuality * 0.15 +
      diseaseStatus * 0.10;

  double get activityContribution => activity * 0.30;
  double get feedingContribution => feeding * 0.25;
  double get growthContribution => growth * 0.20;
  double get waterContribution => waterQuality * 0.15;
  double get diseaseContribution => diseaseStatus * 0.10;
}

class HealthTrendPoint {
  const HealthTrendPoint({required this.date, required this.score});

  final DateTime date;
  final double score;
}

class IndexContribution {
  const IndexContribution({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class DiseaseCheckItem {
  const DiseaseCheckItem({
    required this.name,
    required this.result,
    required this.isClear,
  });

  final String name;
  final String result;
  final bool isClear;
}

class HealthMonitoringProfile {
  const HealthMonitoringProfile({
    required this.crabId,
    required this.boxId,
    required this.batchId,
    required this.components,
    required this.trend,
    required this.contributions,
    required this.diseaseRisk,
    required this.molting,
    required this.activity,
    required this.feeding,
    required this.growth,
    required this.diseaseSurveillance,
    required this.aiInsight,
    required this.aiRecommendation,
    this.activityTrendPercent = 0,
    this.feedingTrendPercent = 0,
    this.growthTrendLabel = 'Stable',
    this.waterQualityLabel = 'Optimum',
  });

  final String crabId;
  final String boxId;
  final String batchId;
  final HealthScoreComponents components;
  final List<HealthTrendPoint> trend;
  final List<IndexContribution> contributions;
  final DiseaseRiskLevel diseaseRisk;
  final MoltingMonitorData molting;
  final ActivityMonitorData activity;
  final FeedingMonitorData feeding;
  final GrowthMonitorData growth;
  final List<DiseaseCheckItem> diseaseSurveillance;
  final String aiInsight;
  final String aiRecommendation;
  final double activityTrendPercent;
  final double feedingTrendPercent;
  final String growthTrendLabel;
  final String waterQualityLabel;

  double get healthScore => components.total;

  HealthLevel get level => HealthLevel.fromScore(healthScore);

  factory HealthMonitoringProfile.empty(String crabId) {
    const components = HealthScoreComponents(
      activity: 0,
      feeding: 0,
      growth: 0,
      waterQuality: 0,
      diseaseStatus: 0,
    );
    return HealthMonitoringProfile(
      crabId: crabId,
      boxId: '—',
      batchId: '—',
      components: components,
      trend: const [],
      contributions: const [],
      diseaseRisk: DiseaseRiskLevel.low,
      molting: MoltingMonitorData(
        moltCount: 0,
        lastMoltDate: DateTime.fromMillisecondsSinceEpoch(0),
        cycleDays: 0,
        recoveryHours: 0,
        status: MoltingMonitorStatus.normal,
      ),
      activity: const ActivityMonitorData(
        movementPercent: 0,
        frequencyPerHour: 0,
        restHoursPerDay: 0,
        feedingMinutesPerDay: 0,
        feedingReaction: '—',
        abnormalBehavior: '—',
        statusLabel: 'Chưa có dữ liệu',
      ),
      feeding: const FeedingMonitorData(
        suppliedGram: 0,
        leftoverGram: 0,
        eatingRatePercent: 0,
        mealsPerDay: 0,
        fcr: 0,
        statusLabel: 'Chưa có dữ liệu',
      ),
      growth: const GrowthMonitorData(
        currentWeightGram: 0,
        weeklyGainGram: 0,
        adgGram: 0,
        growthRatePercent: 0,
        statusLabel: 'Chưa có dữ liệu',
      ),
      diseaseSurveillance: const [],
      aiInsight: 'Chưa có dữ liệu theo dõi sức khỏe cho cua này.',
      aiRecommendation: '',
    );
  }

  List<String> get autoAlerts {
    final alerts = <String>[];
    if (healthScore > 0 && healthScore < 60) {
      alerts.add('Health Score giảm dưới 60');
    }
    if (feeding.leftoverGram > 2) {
      alerts.add('Thức ăn thừa cao — kiểm tra khẩu phần');
    }
    if (activity.movementPercent > 0 && activity.movementPercent < 50) {
      alerts.add('Activity giảm bất thường');
    }
    if (molting.recoveryHours > 48) {
      alerts.add('Sau lột xác hồi phục quá 48h');
    }
    return alerts;
  }
}

class MoltingMonitorData {
  const MoltingMonitorData({
    required this.moltCount,
    required this.lastMoltDate,
    required this.cycleDays,
    required this.recoveryHours,
    required this.status,
  });

  final int moltCount;
  final DateTime lastMoltDate;
  final int cycleDays;
  final int recoveryHours;
  final MoltingMonitorStatus status;
}

class ActivityMonitorData {
  const ActivityMonitorData({
    required this.movementPercent,
    required this.frequencyPerHour,
    required this.restHoursPerDay,
    required this.feedingMinutesPerDay,
    required this.feedingReaction,
    required this.abnormalBehavior,
    required this.statusLabel,
  });

  final double movementPercent;
  final int frequencyPerHour;
  final double restHoursPerDay;
  final int feedingMinutesPerDay;
  final String feedingReaction;
  final String abnormalBehavior;
  final String statusLabel;
}

class FeedingMonitorData {
  const FeedingMonitorData({
    required this.suppliedGram,
    required this.leftoverGram,
    required this.eatingRatePercent,
    required this.mealsPerDay,
    required this.fcr,
    required this.statusLabel,
  });

  final double suppliedGram;
  final double leftoverGram;
  final double eatingRatePercent;
  final int mealsPerDay;
  final double fcr;
  final String statusLabel;
}

class GrowthMonitorData {
  const GrowthMonitorData({
    required this.currentWeightGram,
    required this.weeklyGainGram,
    required this.adgGram,
    required this.growthRatePercent,
    required this.statusLabel,
  });

  final double currentWeightGram;
  final double weeklyGainGram;
  final double adgGram;
  final double growthRatePercent;
  final String statusLabel;
}
