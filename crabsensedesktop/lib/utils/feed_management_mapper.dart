import '../models/feed_management.dart';
import '../models/feed_management_overview.dart';

FeedKpi mapFeedKpi(FeedKpiDto dto) => FeedKpi(
      totalStockKg: dto.totalStockKg,
      stockTrendPercent: dto.stockTrendPercent,
      consumedTodayKg: dto.consumedTodayKg,
      weeklyAvgKg: dto.weeklyAvgKg,
      avgFcr: dto.avgFcr,
      fcrTarget: dto.fcrTarget,
      feedingsPerDay: dto.feedingsPerDay,
      feedingsCompleted: dto.feedingsCompleted,
      lowStockCount: dto.lowStockCount,
      monthlyConsumedKg: dto.monthlyConsumedKg,
    );

FeedStockStatus mapFeedStockStatus(String raw) => switch (raw) {
      'sufficient' => FeedStockStatus.sufficient,
      'expiringSoon' => FeedStockStatus.expiringSoon,
      'useSoon' => FeedStockStatus.useSoon,
      'low' => FeedStockStatus.low,
      _ => FeedStockStatus.normal,
    };

FeedInventoryItem mapFeedInventory(FeedInventoryDto dto) => FeedInventoryItem(
      id: dto.id,
      code: dto.code,
      name: dto.name,
      typeLabel: dto.typeLabel,
      stockKg: dto.stockKg,
      unit: dto.unit,
      expiryDate: dto.expiryDate,
      status: mapFeedStockStatus(dto.status),
    );

BatchFeedConsumption mapBatchConsumption(BatchFeedConsumptionDto dto) =>
    BatchFeedConsumption(
      batchId: dto.batchId,
      crabCount: dto.crabCount,
      totalFeedKg: dto.totalFeedKg,
      weightGainKg: dto.weightGainKg,
      fcr: dto.fcr,
    );

DailyFeedConsumption mapDailyConsumption(DailyFeedConsumptionDto dto) =>
    DailyFeedConsumption(
      date: dto.date,
      morningKg: dto.morningKg,
      noonKg: dto.noonKg,
      eveningKg: dto.eveningKg,
      leftoverKg: dto.leftoverKg,
      eatRatePercent: dto.eatRatePercent,
    );

DateTime? parseScheduleDate(String raw) {
  if (raw.isEmpty) return null;
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

FeedingScheduleItem mapFeedSchedule(FeedScheduleDto dto) => FeedingScheduleItem(
      id: dto.id,
      scheduledDate: parseScheduleDate(dto.scheduledDate) ?? DateTime.now(),
      time: dto.time,
      area: dto.area,
      batchId: dto.batchId,
      feedName: dto.feedName,
      portionKg: dto.portionKg,
      completed: dto.completed,
      completedAt: dto.completedAt,
      repeatRule: dto.repeatRule,
    );

FeedPortionSuggestion mapFeedPortion(FeedPortionDto dto) => FeedPortionSuggestion(
      batchId: dto.batchId,
      aliveCount: dto.aliveCount,
      avgWeightG: dto.avgWeightG,
      totalBiomassKg: dto.totalBiomassKg,
      dailyPercent: dto.dailyPercent,
      dailyFeedKg: dto.dailyFeedKg,
    );
