import '../models/health_monitoring.dart';
import '../theme/dashboard_theme.dart';

abstract final class MockHealthMonitoringData {
  static HealthMonitoringProfile profileFor(String crabId) {
    if (crabId == 'CRAB-A01-001') return _a01;
    return _profileFromCrabId(crabId);
  }

  static final _components = HealthScoreComponents(
    activity: 85,
    feeding: 90,
    growth: 80,
    waterQuality: 88,
    diseaseStatus: 100,
  );

  static final _a01 = HealthMonitoringProfile(
    crabId: 'CRAB-A01-001',
    boxId: 'A01',
    batchId: 'CFM-2026-001',
    components: _components,
    activityTrendPercent: 2,
    feedingTrendPercent: 5,
    growthTrendLabel: 'Stable',
    waterQualityLabel: 'Optimum',
    trend: [
      HealthTrendPoint(date: DateTime(2026, 3, 1), score: 82),
      HealthTrendPoint(date: DateTime(2026, 3, 2), score: 84),
      HealthTrendPoint(date: DateTime(2026, 3, 3), score: 87),
      HealthTrendPoint(date: DateTime(2026, 3, 4), score: 86),
      HealthTrendPoint(date: DateTime(2026, 3, 5), score: 87),
    ],
    contributions: [
      IndexContribution(
        label: 'Activity (Hoạt động)',
        value: _components.activityContribution,
        color: DashboardColors.cyan,
      ),
      IndexContribution(
        label: 'Feeding (Dinh dưỡng)',
        value: _components.feedingContribution,
        color: DashboardColors.purple,
      ),
      IndexContribution(
        label: 'Growth (Tăng trưởng)',
        value: _components.growthContribution,
        color: DashboardColors.blue,
      ),
      IndexContribution(
        label: 'Water (Môi trường)',
        value: _components.waterContribution,
        color: DashboardColors.healthy,
      ),
      IndexContribution(
        label: 'Immunity (Miễn dịch)',
        value: _components.diseaseContribution,
        color: DashboardColors.monitoring,
      ),
    ],
    diseaseRisk: DiseaseRiskLevel.low,
    molting: MoltingMonitorData(
      moltCount: 3,
      lastMoltDate: DateTime(2026, 2, 20),
      cycleDays: 18,
      recoveryHours: 36,
      status: MoltingMonitorStatus.normal,
    ),
    activity: ActivityMonitorData(
      movementPercent: 78,
      frequencyPerHour: 12,
      restHoursPerDay: 6.5,
      feedingMinutesPerDay: 35,
      feedingReaction: 'Tốt',
      abnormalBehavior: 'Không phát hiện',
      statusLabel: 'Tốt',
    ),
    feeding: FeedingMonitorData(
      suppliedGram: 10,
      leftoverGram: 1,
      eatingRatePercent: 90,
      mealsPerDay: 2,
      fcr: 1.8,
      statusLabel: 'Ổn định',
    ),
    growth: GrowthMonitorData(
      currentWeightGram: 125,
      weeklyGainGram: 18,
      adgGram: 2.57,
      growthRatePercent: 16.8,
      statusLabel: 'Đều',
    ),
    diseaseSurveillance: const [
      DiseaseCheckItem(name: 'Bệnh đốm đen', result: 'Negative', isClear: true),
      DiseaseCheckItem(name: 'Nhiễm nấm', result: 'Clear', isClear: true),
      DiseaseCheckItem(name: 'Ký sinh trùng', result: 'Clear', isClear: true),
      DiseaseCheckItem(name: 'WSSV PCR', result: 'Negative', isClear: true),
    ],
    aiInsight:
        'CRAB-A01-001 đang có Health Score tốt. Tỷ lệ ăn ổn định, tăng trưởng đều. Không phát hiện dấu hiệu bệnh.',
    aiRecommendation:
        'Duy trì khẩu phần hiện tại. Kiểm tra lại trọng lượng sau 7 ngày.',
  );

  static HealthMonitoringProfile _profileFromCrabId(String crabId) {
    final hash = crabId.hashCode.abs() % 20;
    final activity = (75 + hash).toDouble().clamp(50.0, 98.0);
    final feeding = (80 + hash % 15).toDouble();
    final growth = (70 + hash % 18).toDouble();
    final water = (82 + hash % 10).toDouble();
    final disease = hash > 15 ? 70.0 : 100.0;
    final comp = HealthScoreComponents(
      activity: activity,
      feeding: feeding,
      growth: growth,
      waterQuality: water,
      diseaseStatus: disease,
    );
    return HealthMonitoringProfile(
      crabId: crabId,
      boxId: 'A01',
      batchId: 'CFM-2026-001',
      components: comp,
      trend: List.generate(
        5,
        (i) => HealthTrendPoint(
          date: DateTime(2026, 3, 1 + i),
          score: comp.total - 5 + i,
        ),
      ),
      contributions: _a01.contributions
          .map(
            (c) => IndexContribution(
              label: c.label,
              value: switch (c.label) {
                var l when l.startsWith('Activity') => comp.activityContribution,
                var l when l.startsWith('Feeding') => comp.feedingContribution,
                var l when l.startsWith('Growth') => comp.growthContribution,
                var l when l.startsWith('Water') => comp.waterContribution,
                _ => comp.diseaseContribution,
              },
              color: c.color,
            ),
          )
          .toList(),
      diseaseRisk: disease < 80
          ? DiseaseRiskLevel.medium
          : DiseaseRiskLevel.low,
      molting: _a01.molting,
      activity: _a01.activity,
      feeding: _a01.feeding,
      growth: _a01.growth,
      diseaseSurveillance: _a01.diseaseSurveillance,
      aiInsight: '$crabId — Health Score ${comp.total.toStringAsFixed(0)}/100.',
      aiRecommendation: 'Theo dõi thêm 48h và kiểm tra môi trường nước.',
    );
  }

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static List<String> autoAlerts(HealthMonitoringProfile p) {
    final alerts = <String>[];
    if (p.healthScore < 60) {
      alerts.add('Health Score giảm dưới 60');
    }
    if (p.feeding.leftoverGram > 2) {
      alerts.add('Thức ăn thừa cao — kiểm tra khẩu phần');
    }
    if (p.activity.movementPercent < 50) {
      alerts.add('Activity giảm bất thường');
    }
    if (p.molting.recoveryHours > 48) {
      alerts.add('Sau lột xác hồi phục quá 48h');
    }
    return alerts;
  }
}
