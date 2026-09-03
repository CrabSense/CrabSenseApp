import '../models/batch_feed_history.dart';
import '../models/farming_batch_group.dart';

abstract final class MockBatchFeedData {
  static BatchFeedHistorySummary summaryFor(FarmingBatchGroup group) {
    final kg = group.totalInitial * 0.169;
    return BatchFeedHistorySummary(
      totalFeedKg: kg,
      totalTrendPercent: 12,
      todayKg: (kg / 22).clamp(2.5, 6.0),
      avgFcr: 1.85,
      nextFeedingTime: '14:00',
      nextFeedingSubtitle: 'Scheduled - Auto',
    );
  }

  static BatchFeedAiInsight aiInsightFor(FarmingBatchGroup group) => BatchFeedAiInsight(
        message:
            'Dựa trên Oxy và nhiệt độ hiện tại, AI khuyến nghị giảm 5% khẩu phần cho đợt ${group.batchCode} '
            'để tránh thừa thức ăn gây ô nhiễm nước.',
        doMgL: 5.2,
        temperatureC: 29.5,
      );

  static List<double> fcrLast7Days() => [1.92, 1.88, 1.86, 1.85, 1.84, 1.85, 1.85];

  static List<BatchFeedingLogEntry> logsFor(FarmingBatchGroup group) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      BatchFeedingLogEntry(
        at: today.add(const Duration(hours: 10, minutes: 30)),
        feedType: 'Viên nén nổi Premium',
        weightKg: 1.2,
        method: BatchFeedingMethod.automatic,
        status: BatchFeedingLogStatus.completed,
        dayLabel: 'Hôm nay',
      ),
      BatchFeedingLogEntry(
        at: today.add(const Duration(hours: 6)),
        feedType: 'Viên nén nổi Premium',
        weightKg: 0.9,
        method: BatchFeedingMethod.manual,
        status: BatchFeedingLogStatus.completed,
        dayLabel: 'Hôm nay',
      ),
      BatchFeedingLogEntry(
        at: today.subtract(const Duration(days: 1)).add(const Duration(hours: 17)),
        feedType: 'Viên nén nổi Premium',
        weightKg: 1.1,
        method: BatchFeedingMethod.automatic,
        status: BatchFeedingLogStatus.completed,
      ),
      BatchFeedingLogEntry(
        at: today.subtract(const Duration(days: 1)).add(const Duration(hours: 10, minutes: 30)),
        feedType: 'Viên nén nổi Premium',
        weightKg: 1.2,
        method: BatchFeedingMethod.automatic,
        status: BatchFeedingLogStatus.completed,
      ),
      BatchFeedingLogEntry(
        at: today.add(const Duration(hours: 14)),
        feedType: 'Viên nén nổi Premium',
        weightKg: 1.0,
        method: BatchFeedingMethod.automatic,
        status: BatchFeedingLogStatus.pending,
        dayLabel: 'Hôm nay',
      ),
      BatchFeedingLogEntry(
        at: today.subtract(const Duration(days: 2)).add(const Duration(hours: 17)),
        feedType: 'Viên nén nổi Premium',
        weightKg: 1.0,
        method: BatchFeedingMethod.manual,
        status: BatchFeedingLogStatus.completed,
      ),
    ];
  }
}
