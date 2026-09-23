import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Ngưỡng cấu hình cho tab "Ăn & Vận động" (không hardcode trong widget).
class FeedingThresholds {
  const FeedingThresholds({
    this.finishPercent = 80,
    this.watchPercent = 50,
    this.alertPercent = 25,
    this.lowActivity = 30,
    this.normalActivityMax = 70,
  });

  /// feedingPercent ≥ finishPercent → "ăn hết".
  final int finishPercent;

  /// feedingPercent < watchPercent → Theo dõi.
  final int watchPercent;

  /// feedingPercent < alertPercent → Cảnh báo.
  final int alertPercent;

  /// activityScore < lowActivity → Vận động thấp.
  final int lowActivity;

  /// activityScore ≤ normalActivityMax → Bình thường, còn lại → Cao.
  final int normalActivityMax;

  static const defaults = FeedingThresholds();

  String activityLabel(int score) {
    if (score <= lowActivity) return 'Thấp';
    if (score <= normalActivityMax) return 'Bình thường';
    return 'Cao';
  }

  Color activityColor(int score) {
    if (score <= lowActivity) return DashboardColors.risk;
    if (score <= normalActivityMax) return kFeedingBlue;
    return DashboardColors.brand;
  }

  /// Màu badge Mức ăn: 80–100 emerald, 50–79 amber, 1–49 cam đỏ nhạt, 0 đỏ.
  Color feedingColor(int pct) {
    if (pct <= 0) return DashboardColors.risk;
    if (pct < watchPercent) return const Color(0xFFF97316);
    if (pct < finishPercent) return const Color(0xFFF5B700);
    return DashboardColors.brand;
  }

  bool isLowFeeding(int pct) => pct < watchPercent;
}

const kFeedingBlue = Color(0xFF2495E8);

enum FeedingPeriod {
  h24('24 giờ', Duration(hours: 24)),
  d7('7 ngày', Duration(days: 7)),
  d30('30 ngày', Duration(days: 30)),
  custom('Tùy chọn', null);

  const FeedingPeriod(this.label, this.duration);
  final String label;
  final Duration? duration;
}

enum FeedingSort { time, feedingPercent, served, activity }

/// Một lần cho ăn (FarmOperation type=feeding của BE).
class FeedingEvent {
  const FeedingEvent({
    required this.id,
    required this.time,
    required this.foodType,
    this.servedGram,
    this.eatenGram,
    this.feedingPercent,
    this.appetite,
    this.activityBefore,
    this.activityAfter,
    this.durationMinutes,
    this.cameraId,
    this.note,
    required this.operatorName,
    required this.source,
    this.photoUrls = const [],
    this.boxIds = const [],
  });

  final String id;
  final DateTime time;
  final String foodType;
  final double? servedGram;
  final double? eatenGram;

  /// 0–100, null = không xác định được.
  final int? feedingPercent;
  final String? appetite;
  final int? activityBefore;
  final int? activityAfter;
  final int? durationMinutes;
  final String? cameraId;
  final String? note;
  final String operatorName;
  final String source;
  final List<String> photoUrls;
  final List<String> boxIds;

  double? get leftoverGram =>
      servedGram != null && eatenGram != null ? (servedGram! - eatenGram!).clamp(0, double.infinity) : null;

  bool get isAi => source.toLowerCase() == 'ai' || source.toLowerCase() == 'auto';

  String get performerLabel {
    if (isAi) return 'AI Camera';
    if (source.toLowerCase() == 'system') return 'System';
    return operatorName.trim().isEmpty ? 'Operator' : operatorName;
  }

  String get sourceLabel => switch (source.toLowerCase()) {
        'ai' || 'auto' => 'AI Camera',
        'system' => 'Hệ thống',
        _ => 'Thủ công',
      };

  /// Điểm vận động đại diện cho event (ưu tiên sau ăn).
  int? get activityScore => activityAfter ?? activityBefore;

  FeedingEvent copyWith({String? note}) => FeedingEvent(
        id: id,
        time: time,
        foodType: foodType,
        servedGram: servedGram,
        eatenGram: eatenGram,
        feedingPercent: feedingPercent,
        appetite: appetite,
        activityBefore: activityBefore,
        activityAfter: activityAfter,
        durationMinutes: durationMinutes,
        cameraId: cameraId,
        note: note ?? this.note,
        operatorName: operatorName,
        source: source,
        photoUrls: photoUrls,
        boxIds: boxIds,
      );

  factory FeedingEvent.fromJson(Map<String, dynamic> j) {
    double? num_(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    int? int_(dynamic v) => v is num ? v.round() : int.tryParse('${v ?? ''}');
    List<String> list_(dynamic v) =>
        v is List ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : const [];
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k];
      }
      return null;
    }

    final rawTime = pick(['timestamp', 'Timestamp', 'fedAt', 'FedAt']);
    final parsed = DateTime.tryParse('${rawTime ?? ''}') ?? DateTime.now();
    final served = num_(pick(['quantity', 'Quantity']));
    final eaten = num_(pick(['eatenQuantity', 'EatenQuantity']));
    var pct = int_(pick(['feedingPercent', 'FeedingPercent']));
    if (pct == null && served != null && served > 0 && eaten != null) {
      pct = (eaten / served * 100).clamp(0, 100).round();
    }
    final note = pick(['notes', 'Notes', 'note', 'Note'])?.toString().trim();
    return FeedingEvent(
      id: '${pick(['id', 'Id']) ?? ''}',
      time: parsed.isUtc ? parsed.toLocal() : parsed,
      foodType: '${pick(['foodType', 'FoodType']) ?? ''}'.trim(),
      servedGram: served,
      eatenGram: eaten,
      feedingPercent: pct,
      appetite: pick(['appetite', 'Appetite'])?.toString(),
      activityBefore: int_(pick(['activityBefore', 'ActivityBefore'])),
      activityAfter: int_(pick(['activityAfter', 'ActivityAfter'])),
      durationMinutes: int_(pick(['feedingDurationMinutes', 'FeedingDurationMinutes'])),
      cameraId: pick(['cameraId', 'CameraId'])?.toString(),
      note: note == null || note.isEmpty ? null : note,
      operatorName: '${pick(['operatorName', 'OperatorName']) ?? ''}',
      source: '${pick(['source', 'Source']) ?? 'manual'}',
      photoUrls: list_(pick(['photoUrls', 'PhotoUrls'])),
      boxIds: list_(pick(['boxIds', 'BoxIds'])),
    );
  }
}

class FeedingActivitySummary {
  const FeedingActivitySummary({
    required this.feedingCount,
    this.finishRate,
    this.avgFeedingPercent,
    this.avgActivityScore,
    this.feedingCountDelta,
    this.finishRateDelta,
  });

  final int feedingCount;
  final int? finishRate;
  final int? avgFeedingPercent;
  final int? avgActivityScore;
  final int? feedingCountDelta;
  final int? finishRateDelta;

  static const empty = FeedingActivitySummary(feedingCount: 0);

  factory FeedingActivitySummary.fromJson(Map<String, dynamic> j) {
    int? i(String a, String b) {
      final v = j[a] ?? j[b];
      return v is num ? v.round() : null;
    }
    return FeedingActivitySummary(
      feedingCount: i('feedingCount', 'FeedingCount') ?? 0,
      finishRate: i('finishRate', 'FinishRate'),
      avgFeedingPercent: i('avgFeedingPercent', 'AvgFeedingPercent'),
      avgActivityScore: i('avgActivityScore', 'AvgActivityScore'),
      feedingCountDelta: i('feedingCountDelta', 'FeedingCountDelta'),
      finishRateDelta: i('finishRateDelta', 'FinishRateDelta'),
    );
  }
}

class FeedingTrendPoint {
  const FeedingTrendPoint({
    required this.bucket,
    this.feedingPercent,
    this.servedGram,
    this.eatenGram,
    this.count = 0,
  });

  final DateTime bucket;
  final int? feedingPercent;
  final double? servedGram;
  final double? eatenGram;
  final int count;

  factory FeedingTrendPoint.fromJson(Map<String, dynamic> j) {
    final t = DateTime.tryParse('${j['bucket'] ?? j['Bucket'] ?? ''}') ?? DateTime.now();
    double? d(String a, String b) {
      final v = j[a] ?? j[b];
      return v is num ? v.toDouble() : null;
    }
    final pct = j['feedingPercent'] ?? j['FeedingPercent'];
    final c = j['feedingCount'] ?? j['FeedingCount'];
    return FeedingTrendPoint(
      bucket: t.isUtc ? t.toLocal() : t,
      feedingPercent: pct is num ? pct.round() : null,
      servedGram: d('servedGram', 'ServedGram'),
      eatenGram: d('eatenGram', 'EatenGram'),
      count: c is num ? c.round() : 0,
    );
  }
}

class ActivityTrendPoint {
  const ActivityTrendPoint({required this.bucket, this.score, this.samples = 0});

  final DateTime bucket;
  final int? score;
  final int samples;

  factory ActivityTrendPoint.fromJson(Map<String, dynamic> j) {
    final t = DateTime.tryParse('${j['bucket'] ?? j['Bucket'] ?? ''}') ?? DateTime.now();
    final s = j['activityScore'] ?? j['ActivityScore'];
    final n = j['sampleCount'] ?? j['SampleCount'];
    return ActivityTrendPoint(
      bucket: t.isUtc ? t.toLocal() : t,
      score: s is num ? s.round() : null,
      samples: n is num ? n.round() : 0,
    );
  }
}

class CrabFeedingActivityData {
  const CrabFeedingActivityData({
    required this.from,
    required this.to,
    required this.hourly,
    required this.summary,
    required this.feedingTrend,
    required this.activityTrend,
    required this.events,
    required this.totalEvents,
    this.insight,
    this.insightLevel = 'none',
  });

  final DateTime from;
  final DateTime to;
  final bool hourly;
  final FeedingActivitySummary summary;
  final List<FeedingTrendPoint> feedingTrend;
  final List<ActivityTrendPoint> activityTrend;
  final List<FeedingEvent> events;
  final int totalEvents;
  final String? insight;

  /// none | ok | watch | warning
  final String insightLevel;

  bool get hasActivityData => activityTrend.any((p) => p.score != null);

  factory CrabFeedingActivityData.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> maps(dynamic v) =>
        v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
    final from = DateTime.tryParse('${j['from'] ?? j['From'] ?? ''}') ?? DateTime.now();
    final to = DateTime.tryParse('${j['to'] ?? j['To'] ?? ''}') ?? DateTime.now();
    final gran = '${j['granularity'] ?? j['Granularity'] ?? 'day'}';
    final summaryRaw = j['summary'] ?? j['Summary'];
    final total = j['totalEvents'] ?? j['TotalEvents'];
    return CrabFeedingActivityData(
      from: from.toLocal(),
      to: to.toLocal(),
      hourly: gran == 'hour',
      summary: summaryRaw is Map
          ? FeedingActivitySummary.fromJson(Map<String, dynamic>.from(summaryRaw))
          : FeedingActivitySummary.empty,
      feedingTrend: maps(j['feedingTrend'] ?? j['FeedingTrend']).map(FeedingTrendPoint.fromJson).toList(),
      activityTrend:
          maps(j['activityTrend'] ?? j['ActivityTrend']).map(ActivityTrendPoint.fromJson).toList(),
      events: maps(j['events'] ?? j['Events']).map(FeedingEvent.fromJson).toList(),
      totalEvents: total is num ? total.round() : 0,
      insight: j['insight']?.toString() ?? j['Insight']?.toString(),
      insightLevel: '${j['insightLevel'] ?? j['InsightLevel'] ?? 'none'}',
    );
  }
}

/// Payload tạo lần cho ăn mới (modal "Ghi nhận cho ăn").
class NewFeedingInput {
  const NewFeedingInput({
    required this.time,
    required this.foodType,
    required this.servedGram,
    this.eatenGram,
    this.activityBefore,
    this.activityAfter,
    this.cameraId,
    this.note,
    this.photoUrls = const [],
  });

  final DateTime time;
  final String foodType;
  final double servedGram;
  final double? eatenGram;
  final int? activityBefore;
  final int? activityAfter;
  final String? cameraId;
  final String? note;
  final List<String> photoUrls;

  int? get feedingPercent =>
      eatenGram == null || servedGram <= 0 ? null : (eatenGram! / servedGram * 100).clamp(0, 100).round();
}
