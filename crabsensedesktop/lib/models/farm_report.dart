import 'package:flutter/material.dart';

enum ReportTimeRange { today, week7, days30, custom }

enum ReportType { overview, health, environment, finance, devices }

class FarmReportKpi {
  const FarmReportKpi({
    required this.survivalRatePercent,
    required this.survivalTrendPercent,
    required this.avgGrowthPerWeekG,
    required this.avgHealthScore,
    required this.opsEfficiencyPercent,
    required this.totalRevenueVnd,
    required this.revenueForecastPercent,
    required this.totalCostVnd,
    required this.feedCostSharePercent,
    required this.netProfitVnd,
    required this.roiPercent,
    required this.electricityKwh,
    required this.electricityTrendPercent,
    required this.waterM3,
    required this.carbonReductionPercent,
  });

  final double survivalRatePercent;
  final double survivalTrendPercent;
  final double avgGrowthPerWeekG;
  final double avgHealthScore;
  final double opsEfficiencyPercent;
  final int totalRevenueVnd;
  final double revenueForecastPercent;
  final int totalCostVnd;
  final double feedCostSharePercent;
  final int netProfitVnd;
  final double roiPercent;
  final double electricityKwh;
  final double electricityTrendPercent;
  final double waterM3;
  final double carbonReductionPercent;
}

class SurvivalGrowthPeriod {
  const SurvivalGrowthPeriod({
    required this.label,
    required this.survivalPercent,
    required this.growthG,
  });

  final String label;
  final double survivalPercent;
  final double growthG;
}

class CostAllocationSegment {
  const CostAllocationSegment({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;
}

class ResourceUsageItem {
  const ResourceUsageItem({
    required this.label,
    required this.value,
    required this.unit,
    this.trendLabel,
    this.alert = false,
  });

  final String label;
  final String value;
  final String unit;
  final String? trendLabel;
  final bool alert;
}

class DailyReportRow {
  const DailyReportRow({
    required this.date,
    required this.batchId,
    required this.survivalPercent,
    required this.growthG,
    required this.healthScore,
    required this.costVnd,
    required this.revenueVnd,
    required this.profitVnd,
  });

  final String date;
  final String batchId;
  final double survivalPercent;
  final double growthG;
  final int healthScore;
  final int costVnd;
  final int revenueVnd;
  final int profitVnd;
}

class ReportAiAction {
  const ReportAiAction({required this.text, required this.icon});

  final String text;
  final IconData icon;
}
