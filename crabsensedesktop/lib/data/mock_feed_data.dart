import '../models/feed_management.dart';

abstract final class MockFeedData {
  static const kpi = FeedKpi(
    totalStockKg: 520,
    stockTrendPercent: 12,
    consumedTodayKg: 38,
    weeklyAvgKg: 35.5,
    avgFcr: 1.85,
    fcrTarget: 2.0,
    feedingsPerDay: 3,
    feedingsCompleted: 1,
    lowStockCount: 2,
    monthlyConsumedKg: 780,
  );

  static const aiInsight =
      'FCR lứa CFM-2026-002 đang cao hơn trung bình (1.98). '
      'Lượng thức ăn thừa tăng trong 3 ngày gần đây tại Khu B.';

  static const aiRecommendation =
      'Giảm khẩu phần 10% buổi trưa. Kiểm tra Health Score và DO khu B.';

  static List<FeedInventoryItem> inventory() => const [
        FeedInventoryItem(
          id: 'f1',
          code: 'FEED-001',
          name: 'Thức ăn viên 40% đạm',
          typeLabel: 'Viên nổi',
          stockKg: 240,
          unit: 'kg',
          expiryDate: '12/08/2026',
          status: FeedStockStatus.sufficient,
        ),
        FeedInventoryItem(
          id: 'f2',
          code: 'FEED-002',
          name: 'Cá tạp (cá rác/ốc)',
          typeLabel: 'Tươi',
          stockKg: 45,
          unit: 'kg',
          expiryDate: '20/05/2026',
          status: FeedStockStatus.expiringSoon,
        ),
        FeedInventoryItem(
          id: 'f3',
          code: 'FEED-003',
          name: 'Thức ăn viên Bio-Growth',
          typeLabel: 'Viên nổi',
          stockKg: 235,
          unit: 'kg',
          expiryDate: '15/09/2026',
          status: FeedStockStatus.normal,
        ),
      ];

  static List<BatchFeedConsumption> batchConsumption() => const [
        BatchFeedConsumption(
          batchId: 'CFM-2026-001',
          crabCount: 1000,
          totalFeedKg: 320,
          weightGainKg: 175,
          fcr: 1.83,
        ),
        BatchFeedConsumption(
          batchId: 'CFM-2026-002',
          crabCount: 1200,
          totalFeedKg: 410,
          weightGainKg: 210,
          fcr: 1.98,
        ),
      ];

  static List<DailyFeedConsumption> dailyConsumption() => const [
        DailyFeedConsumption(
          date: '01/03',
          morningKg: 12,
          noonKg: 10,
          eveningKg: 14,
          leftoverKg: 2,
          eatRatePercent: 94.4,
        ),
        DailyFeedConsumption(
          date: '02/03',
          morningKg: 13,
          noonKg: 10,
          eveningKg: 15,
          leftoverKg: 1.5,
          eatRatePercent: 96.1,
        ),
      ];

  static DateTime _d(int day) => DateTime(2026, 5, day);

  static List<FeedingScheduleItem> allSchedules() {
    FeedingScheduleItem slot({
      required String id,
      required int day,
      required String time,
      required String area,
      required String batchId,
      required String feedName,
      required double portionKg,
      required bool completed,
      String? completedAt,
    }) {
      return FeedingScheduleItem(
        id: id,
        scheduledDate: _d(day),
        time: time,
        area: area,
        batchId: batchId,
        feedName: feedName,
        portionKg: portionKg,
        completed: completed,
        completedAt: completedAt,
      );
    }

    return [
      // Streak 1–3/05 (hoàn thành đủ)
      slot(
        id: 'sch-101',
        day: 1,
        time: '08:00',
        area: 'Khu A',
        batchId: 'CFM-2026-001',
        feedName: 'Thức ăn viên',
        portionKg: 12,
        completed: true,
        completedAt: '08:04',
      ),
      slot(
        id: 'sch-102',
        day: 2,
        time: '08:00',
        area: 'Khu A',
        batchId: 'CFM-2026-001',
        feedName: 'Thức ăn viên',
        portionKg: 12,
        completed: true,
        completedAt: '08:06',
      ),
      slot(
        id: 'sch-103',
        day: 3,
        time: '08:00',
        area: 'Khu A',
        batchId: 'CFM-2026-001',
        feedName: 'Thức ăn viên',
        portionKg: 12,
        completed: true,
        completedAt: '08:02',
      ),
      slot(
        id: 'sch-105',
        day: 5,
        time: '13:00',
        area: 'Khu B',
        batchId: 'CFM-2026-002',
        feedName: 'Cá tạp',
        portionKg: 10,
        completed: true,
        completedAt: '13:10',
      ),
      // Streak 6–9/05
      for (final day in [6, 7, 8, 9])
        slot(
          id: 'sch-$day',
          day: day,
          time: '08:00',
          area: 'Khu A',
          batchId: 'CFM-2026-001',
          feedName: 'Thức ăn viên',
          portionKg: 11,
          completed: true,
          completedAt: '08:00',
        ),
      // Mốc 7 ngày liên tiếp
      slot(
        id: 'sch-111',
        day: 11,
        time: '08:00',
        area: 'Khu C',
        batchId: 'CFM-2026-003',
        feedName: 'Thức ăn viên',
        portionKg: 14,
        completed: true,
        completedAt: '08:01',
      ),
      // Hôm nay 24/05 — 3 buổi
      FeedingScheduleItem(
        id: 'sch-1',
        scheduledDate: _d(24),
        time: '08:00',
        area: 'Khu A',
        batchId: 'CFM-2026-001',
        feedName: 'Thức ăn viên 40% đạm',
        portionKg: 12,
        completed: true,
        completedAt: '08:05',
      ),
      FeedingScheduleItem(
        id: 'sch-2',
        scheduledDate: _d(24),
        time: '13:00',
        area: 'Khu B',
        batchId: 'CFM-2026-002',
        feedName: 'Cá tạp',
        portionKg: 15,
        completed: false,
      ),
      FeedingScheduleItem(
        id: 'sch-3',
        scheduledDate: _d(24),
        time: '18:00',
        area: 'Khu C',
        batchId: 'CFM-2026-003',
        feedName: 'Thức ăn viên Bio-Growth',
        portionKg: 14,
        completed: false,
      ),
      // Ngày mai — đã lên lịch
      FeedingScheduleItem(
        id: 'sch-f25',
        scheduledDate: _d(25),
        time: '08:00',
        area: 'Khu A',
        batchId: 'CFM-2026-001',
        feedName: 'Thức ăn viên',
        portionKg: 12,
        completed: false,
        repeatRule: 'Hàng ngày',
      ),
    ];
  }

  static List<FeedingScheduleItem> todaySchedule() => allSchedules()
      .where((s) => s.scheduledDate.day == 24)
      .toList();

  static FeedPortionSuggestion portionSuggestion() => const FeedPortionSuggestion(
        batchId: 'CFM-2026-001',
        aliveCount: 960,
        avgWeightG: 125,
        totalBiomassKg: 120,
        dailyPercent: 3,
        dailyFeedKg: 3.6,
      );
}
