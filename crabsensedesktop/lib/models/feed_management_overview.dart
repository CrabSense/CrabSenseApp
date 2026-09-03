class FeedManagementOverview {
  const FeedManagementOverview({
    required this.kpi,
    required this.aiInsight,
    required this.aiRecommendation,
    required this.portion,
    required this.inventory,
    required this.batchConsumption,
    required this.dailyConsumption,
    required this.schedules,
    required this.areas,
    required this.batches,
    required this.feedTypes,
  });

  final FeedKpiDto kpi;
  final String aiInsight;
  final String aiRecommendation;
  final FeedPortionDto portion;
  final List<FeedInventoryDto> inventory;
  final List<BatchFeedConsumptionDto> batchConsumption;
  final List<DailyFeedConsumptionDto> dailyConsumption;
  final List<FeedScheduleDto> schedules;
  final List<String> areas;
  final List<FeedBatchOptionDto> batches;
  final List<String> feedTypes;

  factory FeedManagementOverview.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) from) {
      final raw = json[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => from(Map<String, dynamic>.from(e)))
          .toList();
    }

    return FeedManagementOverview(
      kpi: FeedKpiDto.fromJson(
        json['kpi'] is Map
            ? Map<String, dynamic>.from(json['kpi'] as Map)
            : {},
      ),
      aiInsight: (json['aiInsight'] ?? '').toString(),
      aiRecommendation: (json['aiRecommendation'] ?? '').toString(),
      portion: FeedPortionDto.fromJson(
        json['portion'] is Map
            ? Map<String, dynamic>.from(json['portion'] as Map)
            : {},
      ),
      inventory: list('inventory', FeedInventoryDto.fromJson),
      batchConsumption: list('batchConsumption', BatchFeedConsumptionDto.fromJson),
      dailyConsumption: list('dailyConsumption', DailyFeedConsumptionDto.fromJson),
      schedules: list('schedules', FeedScheduleDto.fromJson),
      areas: (json['areas'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      batches: list('batches', FeedBatchOptionDto.fromJson),
      feedTypes: (json['feedTypes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class FeedKpiDto {
  const FeedKpiDto({
    required this.totalStockKg,
    required this.stockTrendPercent,
    required this.consumedTodayKg,
    required this.weeklyAvgKg,
    required this.avgFcr,
    required this.fcrTarget,
    required this.feedingsPerDay,
    required this.feedingsCompleted,
    required this.lowStockCount,
    required this.monthlyConsumedKg,
  });

  final double totalStockKg;
  final double stockTrendPercent;
  final double consumedTodayKg;
  final double weeklyAvgKg;
  final double avgFcr;
  final double fcrTarget;
  final int feedingsPerDay;
  final int feedingsCompleted;
  final int lowStockCount;
  final double monthlyConsumedKg;

  factory FeedKpiDto.fromJson(Map<String, dynamic> json) => FeedKpiDto(
        totalStockKg: (json['totalStockKg'] as num?)?.toDouble() ?? 0,
        stockTrendPercent: (json['stockTrendPercent'] as num?)?.toDouble() ?? 0,
        consumedTodayKg: (json['consumedTodayKg'] as num?)?.toDouble() ?? 0,
        weeklyAvgKg: (json['weeklyAvgKg'] as num?)?.toDouble() ?? 0,
        avgFcr: (json['avgFcr'] as num?)?.toDouble() ?? 1.85,
        fcrTarget: (json['fcrTarget'] as num?)?.toDouble() ?? 2,
        feedingsPerDay: (json['feedingsPerDay'] as num?)?.toInt() ?? 0,
        feedingsCompleted: (json['feedingsCompleted'] as num?)?.toInt() ?? 0,
        lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
        monthlyConsumedKg: (json['monthlyConsumedKg'] as num?)?.toDouble() ?? 0,
      );
}

class FeedInventoryDto {
  const FeedInventoryDto({
    required this.id,
    required this.code,
    required this.name,
    required this.typeLabel,
    required this.stockKg,
    required this.unit,
    required this.expiryDate,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final String typeLabel;
  final double stockKg;
  final String unit;
  final String expiryDate;
  final String status;

  factory FeedInventoryDto.fromJson(Map<String, dynamic> json) => FeedInventoryDto(
        id: (json['id'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        typeLabel: (json['typeLabel'] ?? '').toString(),
        stockKg: (json['stockKg'] as num?)?.toDouble() ?? 0,
        unit: (json['unit'] ?? 'kg').toString(),
        expiryDate: (json['expiryDate'] ?? '—').toString(),
        status: (json['status'] ?? 'normal').toString(),
      );
}

class BatchFeedConsumptionDto {
  const BatchFeedConsumptionDto({
    required this.batchId,
    required this.crabCount,
    required this.totalFeedKg,
    required this.weightGainKg,
    required this.fcr,
  });

  final String batchId;
  final int crabCount;
  final double totalFeedKg;
  final double weightGainKg;
  final double fcr;

  factory BatchFeedConsumptionDto.fromJson(Map<String, dynamic> json) =>
      BatchFeedConsumptionDto(
        batchId: (json['batchId'] ?? '').toString(),
        crabCount: (json['crabCount'] as num?)?.toInt() ?? 0,
        totalFeedKg: (json['totalFeedKg'] as num?)?.toDouble() ?? 0,
        weightGainKg: (json['weightGainKg'] as num?)?.toDouble() ?? 0,
        fcr: (json['fcr'] as num?)?.toDouble() ?? 0,
      );
}

class DailyFeedConsumptionDto {
  const DailyFeedConsumptionDto({
    required this.date,
    required this.morningKg,
    required this.noonKg,
    required this.eveningKg,
    required this.leftoverKg,
    required this.eatRatePercent,
  });

  final String date;
  final double morningKg;
  final double noonKg;
  final double eveningKg;
  final double leftoverKg;
  final double eatRatePercent;

  factory DailyFeedConsumptionDto.fromJson(Map<String, dynamic> json) =>
      DailyFeedConsumptionDto(
        date: (json['date'] ?? '').toString(),
        morningKg: (json['morningKg'] as num?)?.toDouble() ?? 0,
        noonKg: (json['noonKg'] as num?)?.toDouble() ?? 0,
        eveningKg: (json['eveningKg'] as num?)?.toDouble() ?? 0,
        leftoverKg: (json['leftoverKg'] as num?)?.toDouble() ?? 0,
        eatRatePercent: (json['eatRatePercent'] as num?)?.toDouble() ?? 0,
      );
}

class FeedScheduleDto {
  const FeedScheduleDto({
    required this.id,
    required this.scheduledDate,
    required this.time,
    required this.area,
    required this.batchId,
    required this.feedName,
    required this.portionKg,
    required this.completed,
    this.completedAt,
    required this.repeatRule,
  });

  final String id;
  final String scheduledDate;
  final String time;
  final String area;
  final String batchId;
  final String feedName;
  final double portionKg;
  final bool completed;
  final String? completedAt;
  final String repeatRule;

  factory FeedScheduleDto.fromJson(Map<String, dynamic> json) => FeedScheduleDto(
        id: (json['id'] ?? '').toString(),
        scheduledDate: (json['scheduledDate'] ?? '').toString(),
        time: (json['time'] ?? '').toString(),
        area: (json['area'] ?? '').toString(),
        batchId: (json['batchId'] ?? '').toString(),
        feedName: (json['feedName'] ?? '').toString(),
        portionKg: (json['portionKg'] as num?)?.toDouble() ?? 0,
        completed: json['completed'] == true,
        completedAt: json['completedAt']?.toString(),
        repeatRule: (json['repeatRule'] ?? 'Hàng ngày').toString(),
      );
}

class FeedPortionDto {
  const FeedPortionDto({
    required this.batchId,
    required this.aliveCount,
    required this.avgWeightG,
    required this.totalBiomassKg,
    required this.dailyPercent,
    required this.dailyFeedKg,
  });

  final String batchId;
  final int aliveCount;
  final double avgWeightG;
  final double totalBiomassKg;
  final double dailyPercent;
  final double dailyFeedKg;

  factory FeedPortionDto.fromJson(Map<String, dynamic> json) => FeedPortionDto(
        batchId: (json['batchId'] ?? '').toString(),
        aliveCount: (json['aliveCount'] as num?)?.toInt() ?? 0,
        avgWeightG: (json['avgWeightG'] as num?)?.toDouble() ?? 0,
        totalBiomassKg: (json['totalBiomassKg'] as num?)?.toDouble() ?? 0,
        dailyPercent: (json['dailyPercent'] as num?)?.toDouble() ?? 3.5,
        dailyFeedKg: (json['dailyFeedKg'] as num?)?.toDouble() ?? 0,
      );
}

class FeedBatchOptionDto {
  const FeedBatchOptionDto({
    required this.id,
    required this.batchCode,
    required this.areaName,
  });

  final String id;
  final String batchCode;
  final String areaName;

  factory FeedBatchOptionDto.fromJson(Map<String, dynamic> json) =>
      FeedBatchOptionDto(
        id: (json['id'] ?? '').toString(),
        batchCode: (json['batchCode'] ?? '').toString(),
        areaName: (json['areaName'] ?? '').toString(),
      );
}
