import 'package:flutter/material.dart';

import '../models/farm_report.dart';

abstract final class MockFarmReportData {
  static const kpi = FarmReportKpi(
    survivalRatePercent: 96.8,
    survivalTrendPercent: 2.1,
    avgGrowthPerWeekG: 18,
    avgHealthScore: 88,
    opsEfficiencyPercent: 94,
    totalRevenueVnd: 185000000,
    revenueForecastPercent: 12.5,
    totalCostVnd: 118000000,
    feedCostSharePercent: 42,
    netProfitVnd: 67000000,
    roiPercent: 36.2,
    electricityKwh: 1250,
    electricityTrendPercent: 15,
    waterM3: 85,
    carbonReductionPercent: 8,
  );

  static const aiSummary =
      'Trong 30 ngày gần nhất, dữ liệu vận hành ổn định. '
      'Tỷ lệ sống đạt 96.8%, Health Score trung bình duy trì ở mức tốt.';

  static const aiAnalysis = [
    'Chi phí thức ăn lứa CFM-2026-001 chiếm 42% tổng chi phí — cao hơn mức trung bình 5%.',
    'Điện tiêu thụ tăng 15% do máy sủi oxy dự phòng chạy nhiều hơn (22h–04h).',
    'DO khu B dao động nhẹ trong 3 ngày qua, chưa vượt ngưỡng cảnh báo.',
  ];

  static const aiActions = [
    ReportAiAction(
      text: 'Kiểm tra cảm biến DO khu B',
      icon: Icons.sensors_outlined,
    ),
    ReportAiAction(
      text: 'Tối ưu lịch sủi oxy (22h–04h)',
      icon: Icons.schedule_outlined,
    ),
    ReportAiAction(
      text: 'Giảm khẩu phần CFM-2026-002 khoảng 5%',
      icon: Icons.restaurant_outlined,
    ),
  ];

  static List<SurvivalGrowthPeriod> survivalGrowthBars() => const [
        SurvivalGrowthPeriod(label: 'T1', survivalPercent: 94, growthG: 14),
        SurvivalGrowthPeriod(label: 'T2', survivalPercent: 95, growthG: 16),
        SurvivalGrowthPeriod(label: 'T3', survivalPercent: 96, growthG: 17),
        SurvivalGrowthPeriod(label: 'T4', survivalPercent: 97, growthG: 18),
      ];

  static List<CostAllocationSegment> costAllocation() => const [
        CostAllocationSegment(
          label: 'Thức ăn',
          percent: 42,
          color: Color(0xFF7C5CFF),
        ),
        CostAllocationSegment(
          label: 'Điện',
          percent: 15,
          color: Color(0xFF57E6FF),
        ),
        CostAllocationSegment(
          label: 'Khác',
          percent: 43,
          color: Color(0xFF4DA6FF),
        ),
      ];

  static List<ResourceUsageItem> resources() => const [
        ResourceUsageItem(
          label: 'Điện',
          value: '1.250',
          unit: 'kWh',
          trendLabel: '+15%',
          alert: true,
        ),
        ResourceUsageItem(
          label: 'Nguồn nước',
          value: '85',
          unit: 'm³',
        ),
        ResourceUsageItem(
          label: 'Carbon Footprint',
          value: '-8%',
          unit: 'giảm',
        ),
      ];

  static List<DailyReportRow> dailyRows() => const [
        DailyReportRow(
          date: '01/03/2026',
          batchId: 'CFM-2026-001',
          survivalPercent: 97,
          growthG: 16,
          healthScore: 89,
          costVnd: 2500000,
          revenueVnd: 0,
          profitVnd: -2500000,
        ),
        DailyReportRow(
          date: '02/03/2026',
          batchId: 'CFM-2026-001',
          survivalPercent: 97,
          growthG: 18,
          healthScore: 90,
          costVnd: 2200000,
          revenueVnd: 0,
          profitVnd: -2200000,
        ),
        DailyReportRow(
          date: '10/03/2026',
          batchId: 'CFM-2026-002',
          survivalPercent: 96.2,
          growthG: 17,
          healthScore: 87,
          costVnd: 2800000,
          revenueVnd: 0,
          profitVnd: -2800000,
        ),
        DailyReportRow(
          date: '20/03/2026',
          batchId: 'CFM-2026-001',
          survivalPercent: 96.8,
          growthG: 20,
          healthScore: 88,
          costVnd: 3200000,
          revenueVnd: 53760000,
          profitVnd: 50560000,
        ),
        DailyReportRow(
          date: '22/03/2026',
          batchId: 'CFM-2026-002',
          survivalPercent: 95.5,
          growthG: 19,
          healthScore: 86,
          costVnd: 3100000,
          revenueVnd: 29450000,
          profitVnd: 26350000,
        ),
      ];

  static String formatVndShort(int vnd) {
    if (vnd >= 1000000) {
      return '${(vnd / 1000000).toStringAsFixed(vnd % 1000000 == 0 ? 0 : 1)}M';
    }
    if (vnd >= 1000) {
      return '${(vnd / 1000).round()}K';
    }
    return '$vnd';
  }

  static String formatVndFull(int vnd) {
    final s = vnd.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final prefix = vnd < 0 ? '-' : '';
    return '$prefix${buf.toString()}đ';
  }
}
