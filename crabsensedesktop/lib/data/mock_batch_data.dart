import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';
import '../models/batch_status.dart';
import '../models/crab_batch.dart';

class BatchSummaryKpi {
  const BatchSummaryKpi({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;
}

class BatchStatusDistribution {
  const BatchStatusDistribution({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;
}

abstract final class MockBatchData {
  static const aiTip =
      'Gợi ý AI: Tăng nồng độ oxy hòa tan ở Khu A (6–7 mg/L) có thể cải thiện tốc độ lột xác trong 48 giờ tới.';
  static const marketForecast =
      'Dự báo thị trường: Giá cua thịt dự kiến tăng ~15% trong 2 tuần tới — cân nhắc lịch thu hoạch các đợt sắp đạt chuẩn.';

  static const farmAreas = ['Khu A', 'Khu B', 'Khu C', 'Khu D'];
  static const ponds = ['Bể 01', 'Bể 02', 'Bể 03', 'Bể 04', 'Bể 05'];

  static List<CrabBatch> initialBatches() => [
        CrabBatch(
          id: 'CFM-2026-001',
          name: 'Lứa Vũng Tàu 01',
          releaseDate: DateTime(2026, 1, 1),
          initialQuantity: 1000,
          aliveCount: 960,
          initialWeightGram: 15,
          avgWeightGram: 125,
          source: 'Vũng Tàu Premium',
          farmArea: 'Khu A',
          pond: 'Bể 01',
          status: BatchStatus.raising,
          healthScore: 93,
          daysToHarvest: 18,
          revenueMillion: 48,
          cycleProgress: 0.75,
        ),
        CrabBatch(
          id: 'CFM001',
          releaseDate: DateTime(2023, 10, 12),
          initialQuantity: 2500,
          aliveCount: 2450,
          initialWeightGram: 12,
          avgWeightGram: 110,
          source: 'Trại giống Minh Hải',
          farmArea: 'Khu B',
          pond: 'Bể 02',
          status: BatchStatus.raising,
          healthScore: 91,
          daysToHarvest: 25,
          revenueMillion: 42,
          cycleProgress: 0.68,
        ),
        CrabBatch(
          id: 'CFM002',
          releaseDate: DateTime(2024, 1, 15),
          initialQuantity: 1250,
          aliveCount: 1200,
          initialWeightGram: 14,
          avgWeightGram: 98,
          source: 'Trại giống Đồng Nai',
          farmArea: 'Khu A',
          pond: 'Bể 03',
          status: BatchStatus.raising,
          healthScore: 88,
          daysToHarvest: 32,
          cycleProgress: 0.55,
        ),
        CrabBatch(
          id: 'CFM003',
          releaseDate: DateTime(2024, 2, 1),
          initialQuantity: 1000,
          aliveCount: 870,
          initialWeightGram: 13,
          avgWeightGram: 135,
          source: 'Trại giống Cà Mau',
          farmArea: 'Khu C',
          pond: 'Bể 01',
          status: BatchStatus.readyHarvest,
          healthScore: 85,
          daysToHarvest: 5,
          revenueMillion: 38,
          cycleProgress: 0.92,
        ),
        CrabBatch(
          id: 'CFM004',
          releaseDate: DateTime(2023, 8, 5),
          initialQuantity: 1800,
          aliveCount: 1720,
          initialWeightGram: 11,
          avgWeightGram: 142,
          source: 'Vũng Tàu Premium',
          farmArea: 'Khu B',
          status: BatchStatus.readyHarvest,
          healthScore: 90,
          daysToHarvest: 8,
          cycleProgress: 0.88,
        ),
        CrabBatch(
          id: 'CFM005',
          releaseDate: DateTime(2023, 5, 20),
          initialQuantity: 900,
          aliveCount: 0,
          initialWeightGram: 10,
          avgWeightGram: 150,
          source: 'Trại giống Minh Hải',
          status: BatchStatus.harvested,
          revenueMillion: 35,
          cycleProgress: 1,
        ),
        CrabBatch(
          id: 'CFM006',
          releaseDate: DateTime(2023, 3, 10),
          initialQuantity: 1100,
          aliveCount: 0,
          initialWeightGram: 12,
          avgWeightGram: 148,
          source: 'Trại giống Đồng Nai',
          status: BatchStatus.harvested,
          revenueMillion: 40,
          cycleProgress: 1,
        ),
        CrabBatch(
          id: 'CFM007',
          releaseDate: DateTime(2024, 3, 1),
          initialQuantity: 800,
          aliveCount: 720,
          initialWeightGram: 14,
          avgWeightGram: 72,
          source: 'Trại giống Cà Mau',
          farmArea: 'Khu D',
          status: BatchStatus.incident,
          healthScore: 62,
          daysToHarvest: 45,
          cycleProgress: 0.4,
        ),
        CrabBatch(
          id: 'CFM008',
          releaseDate: DateTime(2022, 11, 1),
          initialQuantity: 1500,
          aliveCount: 0,
          initialWeightGram: 10,
          avgWeightGram: 155,
          source: 'Vũng Tàu Premium',
          status: BatchStatus.ended,
          revenueMillion: 52,
          cycleProgress: 1,
        ),
        CrabBatch(
          id: 'CFM009',
          releaseDate: DateTime(2024, 1, 20),
          initialQuantity: 2000,
          aliveCount: 1880,
          initialWeightGram: 13,
          avgWeightGram: 95,
          source: 'Trại giống Minh Hải',
          farmArea: 'Khu A',
          status: BatchStatus.raising,
          healthScore: 89,
          cycleProgress: 0.5,
        ),
        CrabBatch(
          id: 'CFM010',
          releaseDate: DateTime(2023, 12, 1),
          initialQuantity: 1300,
          aliveCount: 0,
          initialWeightGram: 12,
          avgWeightGram: 140,
          source: 'Trại giống Đồng Nai',
          status: BatchStatus.harvested,
          revenueMillion: 44,
          cycleProgress: 1,
        ),
        CrabBatch(
          id: 'CFM011',
          releaseDate: DateTime(2024, 2, 15),
          initialQuantity: 950,
          aliveCount: 910,
          initialWeightGram: 15,
          avgWeightGram: 88,
          source: 'Trại giống Cà Mau',
          status: BatchStatus.raising,
          healthScore: 87,
          cycleProgress: 0.35,
        ),
        CrabBatch(
          id: 'CFM012',
          releaseDate: DateTime(2023, 9, 8),
          initialQuantity: 1600,
          aliveCount: 0,
          initialWeightGram: 11,
          avgWeightGram: 152,
          source: 'Vũng Tàu Premium',
          status: BatchStatus.ended,
          revenueMillion: 50,
          cycleProgress: 1,
        ),
      ];

  static List<BatchSummaryKpi> summaryKpis(List<CrabBatch> batches) {
    final total = batches.length;
    final raising =
        batches.where((b) => b.status == BatchStatus.raising).length;
    final harvested = batches
        .where((b) =>
            b.status == BatchStatus.harvested ||
            b.status == BatchStatus.ended)
        .length;
    final active = batches.where((b) => b.aliveCount > 0).toList();
    final avgSurvival = active.isEmpty
        ? 0.0
        : active.map((b) => b.survivalRate).reduce((a, b) => a + b) /
            active.length;

    return [
      BatchSummaryKpi(
        label: 'Tổng lứa',
        value: '$total',
        subtext: '+12% vs t.trước',
        icon: Icons.description_outlined,
        accentColor: Color(0xFF7C5CFF),
      ),
      BatchSummaryKpi(
        label: 'Đang nuôi',
        value: '$raising',
        subtext: 'Live Metrics',
        icon: Icons.waves_outlined,
        accentColor: const Color(0xFF57E6FF),
      ),
      BatchSummaryKpi(
        label: 'Đã thu hoạch',
        value: '$harvested',
        subtext: 'Đã hoàn tất',
        icon: Icons.check_circle_outline,
        accentColor: const Color(0xFF94A3B8),
      ),
      BatchSummaryKpi(
        label: 'Tỷ lệ sống',
        value: '${avgSurvival.toStringAsFixed(1)}%',
        subtext: 'Chỉ số sức khỏe',
        icon: Icons.favorite_outline,
        accentColor: const Color(0xFF57E6FF),
      ),
    ];
  }

  static List<double> weightGrowthGrams(CrabBatch batch) {
    if (batch.id == 'CFM-2026-001') {
      return [15, 25, 40, 58, 82, 125];
    }
    final steps = 6;
    final delta = (batch.avgWeightGram - batch.initialWeightGram) / (steps - 1);
    return List.generate(
      steps,
      (i) => batch.initialWeightGram + delta * i,
    );
  }

  static List<double> expectedWeightGrowth(CrabBatch batch) {
    final actual = weightGrowthGrams(batch);
    return actual.map((v) => v * 0.92 + 5).toList();
  }

  static List<double> survivalHistory(CrabBatch batch) {
    if (batch.id == 'CFM-2026-001') {
      return [100, 99, 98, 97, 96.5, 96];
    }
    final rate = batch.survivalRate;
    return [100, 99.5, 99, 98.5, 98, rate];
  }

  static List<String> survivalLabels(CrabBatch batch) => [
        _fmt(batch.releaseDate),
        _fmt(batch.releaseDate.add(const Duration(days: 14))),
        _fmt(batch.releaseDate.add(const Duration(days: 30))),
        _fmt(batch.releaseDate.add(const Duration(days: 45))),
        _fmt(batch.releaseDate.add(const Duration(days: 60))),
        'Hiện tại',
      ];

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static List<BatchStatusDistribution> crabDistribution(CrabBatch batch) => [
        BatchStatusDistribution(
          label: 'Khỏe mạnh',
          percent: 85,
          color: DashboardColors.cyan,
        ),
        BatchStatusDistribution(
          label: 'Theo dõi',
          percent: 10,
          color: DashboardColors.purple,
        ),
        BatchStatusDistribution(
          label: 'Lột xác',
          percent: 4,
          color: DashboardColors.blue,
        ),
        BatchStatusDistribution(
          label: 'Nguy cơ',
          percent: 1,
          color: DashboardColors.molting,
        ),
      ];

  static List<BatchTimelineEvent> timeline(CrabBatch batch) => [
        BatchTimelineEvent(
          date: batch.releaseDate,
          title: 'Thả giống',
          subtitle: 'Hoàn tất thả ${batch.initialQuantity} con',
          icon: Icons.water_drop_outlined,
        ),
        BatchTimelineEvent(
          date: batch.releaseDate.add(const Duration(days: 4)),
          title: 'Bắt đầu cho ăn',
          subtitle: 'Lịch 08:00 & 17:00 hàng ngày',
          icon: Icons.restaurant_outlined,
        ),
        BatchTimelineEvent(
          date: batch.releaseDate.add(const Duration(days: 19)),
          title: 'Lột xác lần 1',
          subtitle: 'Ghi nhận đợt lột xác #1',
          icon: Icons.pest_control_outlined,
        ),
        BatchTimelineEvent(
          date: batch.releaseDate.add(const Duration(days: 45)),
          title: 'Kiểm tra trọng lượng',
          subtitle: 'TB ${batch.avgWeightGram.toStringAsFixed(0)}g/con',
          icon: Icons.monitor_weight_outlined,
        ),
        BatchTimelineEvent(
          date: batch.releaseDate.add(Duration(days: batch.daysToHarvest + 30)),
          title: 'Dự kiến thu hoạch',
          subtitle: 'Kế hoạch thu hoạch',
          icon: Icons.flag_outlined,
          isFuture: true,
        ),
      ];

  static CrabBatch? findById(List<CrabBatch> batches, String id) {
    try {
      return batches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
