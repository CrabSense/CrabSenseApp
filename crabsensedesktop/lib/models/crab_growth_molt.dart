import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

const kGrowthBlue = Color(0xFF2495E8);
const kGrowthAmber = Color(0xFFF5B700);

enum GrowthPeriod {
  d30('30 ngày', Duration(days: 30)),
  d90('90 ngày', Duration(days: 90)),
  all('Toàn bộ', null);

  const GrowthPeriod(this.label, this.duration);
  final String label;
  final Duration? duration;
}

enum MoltEventStatus {
  normal,
  monitoring,
  abnormal,
  failed;

  String get label => switch (this) {
        MoltEventStatus.normal => 'Bình thường',
        MoltEventStatus.monitoring => 'Theo dõi',
        MoltEventStatus.abnormal => 'Bất thường',
        MoltEventStatus.failed => 'Lột thất bại',
      };

  Color get color => switch (this) {
        MoltEventStatus.normal => DashboardColors.brand,
        MoltEventStatus.monitoring => kGrowthAmber,
        MoltEventStatus.abnormal => const Color(0xFFF97316),
        MoltEventStatus.failed => DashboardColors.risk,
      };

  String get api => switch (this) {
        MoltEventStatus.normal => 'success',
        MoltEventStatus.monitoring => 'monitoring',
        MoltEventStatus.abnormal => 'abnormal',
        MoltEventStatus.failed => 'failed',
      };

  static MoltEventStatus parse(String? raw) {
    final s = (raw ?? '').toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
    if (s.contains('fail') || s.contains('thatbai') || s.contains('dead')) {
      return MoltEventStatus.failed;
    }
    if (s.contains('abnormal') || s.contains('batthuong')) {
      return MoltEventStatus.abnormal;
    }
    if (s.contains('monitor') ||
        s.contains('watch') ||
        s.contains('incomplete') ||
        s.contains('weak') ||
        s.contains('theodoi')) {
      return MoltEventStatus.monitoring;
    }
    return MoltEventStatus.normal;
  }
}

class GrowthMeasurement {
  const GrowthMeasurement({
    required this.id,
    required this.measuredAt,
    required this.weightGram,
    this.shellWidthMm,
    this.shellLengthMm,
    this.recordedBy,
    this.note,
    this.photoUrls = const [],
    this.source = 'manual',
  });

  final String id;
  final DateTime measuredAt;
  final double weightGram;
  final double? shellWidthMm;
  final double? shellLengthMm;
  final String? recordedBy;
  final String? note;
  final List<String> photoUrls;
  final String source;

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) {
    DateTime at(dynamic v) {
      final p = DateTime.tryParse('$v');
      return p == null ? DateTime.now() : (p.isUtc ? p.toLocal() : p);
    }

    double? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    final photos = json['photoUrls'] ?? json['PhotoUrls'];
    return GrowthMeasurement(
      id: '${json['id'] ?? json['Id'] ?? ''}',
      measuredAt: at(json['measuredAt'] ?? json['MeasuredAt']),
      weightGram: n(json['weightGram'] ?? json['WeightGram']) ?? 0,
      shellWidthMm: n(json['carapaceWidthMm'] ?? json['CarapaceWidthMm'] ?? json['shellWidthMm']),
      shellLengthMm: n(json['carapaceLengthMm'] ?? json['CarapaceLengthMm'] ?? json['shellLengthMm']),
      recordedBy: (json['recordedByName'] ?? json['RecordedByName'] ?? json['recordedBy'])?.toString(),
      note: (json['notes'] ?? json['Notes'] ?? json['note'])?.toString(),
      photoUrls: photos is List ? photos.map((e) => '$e').where((s) => s.isNotEmpty).toList() : const [],
      source: (json['source'] ?? json['Source'] ?? 'manual').toString(),
    );
  }

  String get recorderLabel {
    final n = (recordedBy ?? '').trim();
    if (n.isEmpty) return source.toLowerCase() == 'stocking' ? 'Hệ thống' : 'Hệ thống';
    return n;
  }
}

class MoltEvent {
  const MoltEvent({
    required this.id,
    required this.number,
    required this.at,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.weightBeforeGram,
    this.weightAfterGram,
    this.shellWidthBeforeMm,
    this.shellLengthBeforeMm,
    this.shellWidthAfterMm,
    this.shellLengthAfterMm,
    this.source = 'manual',
    this.cameraId,
    this.note,
    this.photoUrls = const [],
  });

  final String id;
  final int number;
  final DateTime at;
  final MoltEventStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? weightBeforeGram;
  final double? weightAfterGram;
  final double? shellWidthBeforeMm;
  final double? shellLengthBeforeMm;
  final double? shellWidthAfterMm;
  final double? shellLengthAfterMm;
  final String source;
  final String? cameraId;
  final String? note;
  final List<String> photoUrls;

  factory MoltEvent.fromJson(Map<String, dynamic> json, {int number = 1}) {
    DateTime? t(dynamic v) {
      final p = DateTime.tryParse('$v');
      if (p == null) return null;
      return p.isUtc ? p.toLocal() : p;
    }

    double? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    final photos = json['photoUrls'] ?? json['PhotoUrls'] ?? json['mediaUrls'];
    final at = t(json['moltTime'] ?? json['MoltTime'] ?? json['completedAt']) ?? DateTime.now();
    return MoltEvent(
      id: '${json['id'] ?? json['Id'] ?? ''}',
      number: number,
      at: at,
      status: MoltEventStatus.parse('${json['result'] ?? json['Result'] ?? json['status'] ?? ''}'),
      startedAt: t(json['startedAt'] ?? json['StartedAt']),
      completedAt: t(json['completedAt'] ?? json['CompletedAt']) ?? at,
      weightBeforeGram: n(json['weightBeforeGram'] ?? json['WeightBeforeGram']),
      weightAfterGram: n(json['weightAfterGram'] ?? json['WeightAfterGram']),
      shellWidthBeforeMm: n(json['shellWidthBeforeMm'] ?? json['ShellWidthBeforeMm']),
      shellLengthBeforeMm: n(json['shellLengthBeforeMm'] ?? json['ShellLengthBeforeMm']),
      shellWidthAfterMm: n(json['shellWidthAfterMm'] ?? json['ShellWidthAfterMm']),
      shellLengthAfterMm: n(json['shellLengthAfterMm'] ?? json['ShellLengthAfterMm']),
      source: (json['source'] ?? json['Source'] ?? 'manual').toString(),
      cameraId: (json['cameraId'] ?? json['CameraId'])?.toString(),
      note: (json['notes'] ?? json['Notes'] ?? json['note'])?.toString(),
      photoUrls: photos is List ? photos.map((e) => '$e').where((s) => s.isNotEmpty).toList() : const [],
    );
  }

  Duration? get duration {
    final a = startedAt;
    final b = completedAt;
    if (a == null || b == null) return null;
    final d = b.difference(a);
    return d.isNegative ? null : d;
  }

  double? get weightDelta {
    if (weightBeforeGram == null || weightAfterGram == null) return null;
    return weightAfterGram! - weightBeforeGram!;
  }

  String get sourceLabel {
    final s = source.toLowerCase();
    if (s.contains('ai') && s.contains('manual')) return 'AI Camera / Manual';
    if (s.contains('ai')) return 'AI Camera';
    if (s.contains('desktop') || s.contains('manual')) return 'Manual';
    return source;
  }
}

class GrowthInsight {
  const GrowthInsight({
    required this.stable,
    required this.title,
    required this.body,
  });

  final bool stable;
  final String title;
  final String body;
}

class CrabGrowthMoltData {
  const CrabGrowthMoltData({
    required this.measurements,
    required this.molts,
    this.currentWeightGram,
    this.currentWidthMm,
    this.currentLengthMm,
  });

  final List<GrowthMeasurement> measurements;
  final List<MoltEvent> molts;
  final double? currentWeightGram;
  final double? currentWidthMm;
  final double? currentLengthMm;

  factory CrabGrowthMoltData.fromJson(Map<String, dynamic> json) {
    double? n(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    final rawM = json['measurements'] ?? json['Measurements'] ?? const [];
    final rawMolts = json['molts'] ?? json['Molts'] ?? const [];
    final measures = <GrowthMeasurement>[];
    if (rawM is List) {
      for (final e in rawM.whereType<Map>()) {
        measures.add(GrowthMeasurement.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    measures.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final moltMaps = rawMolts.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    moltMaps.sort((a, b) {
      final da = DateTime.tryParse('${a['moltTime'] ?? a['MoltTime'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse('${b['moltTime'] ?? b['MoltTime'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    final molts = [
      for (var i = 0; i < moltMaps.length; i++) MoltEvent.fromJson(moltMaps[i], number: i + 1),
    ];

    return CrabGrowthMoltData(
      measurements: measures,
      molts: molts,
      currentWeightGram: n(json['currentWeightGram'] ?? json['CurrentWeightGram']),
      currentWidthMm: n(json['currentWidthMm'] ?? json['CurrentWidthMm']),
      currentLengthMm: n(json['currentLengthMm'] ?? json['CurrentLengthMm']),
    );
  }

  GrowthMeasurement? get latest => measurements.isEmpty ? null : measurements.last;
  GrowthMeasurement? get previous => measurements.length < 2 ? null : measurements[measurements.length - 2];
  GrowthMeasurement? get baseline => measurements.isEmpty ? null : measurements.first;

  double? get weightDelta {
    final a = latest;
    final b = previous;
    if (a == null || b == null) return null;
    return a.weightGram - b.weightGram;
  }

  double? get widthDelta {
    final a = latest?.shellWidthMm;
    final b = previous?.shellWidthMm;
    if (a == null || b == null) return null;
    return a - b;
  }

  double? get lengthDelta {
    final a = latest?.shellLengthMm;
    final b = previous?.shellLengthMm;
    if (a == null || b == null) return null;
    return a - b;
  }

  double? get periodGrowthPercent {
    final a = latest;
    final b = baseline;
    if (a == null || b == null || b.weightGram <= 0 || identical(a, b)) return null;
    return (a.weightGram - b.weightGram) / b.weightGram * 100;
  }

  double? get averageGrowthPerDay {
    final a = latest;
    final b = previous;
    if (a == null || b == null) return null;
    final days = a.measuredAt.difference(b.measuredAt).inMinutes / 1440;
    if (days <= 0) return null;
    return (a.weightGram - b.weightGram) / days;
  }

  int get periodDays {
    final a = latest;
    final b = baseline;
    if (a == null || b == null) return 0;
    return a.measuredAt.difference(b.measuredAt).inDays.abs();
  }

  MoltEvent? get lastMolt => molts.isEmpty ? null : molts.last;

  GrowthInsight? insight() {
    if (measurements.length < 2) return null;
    final pct = periodGrowthPercent;
    final days = periodDays;
    final delta = weightDelta;
    final daily = averageGrowthPerDay;

    var slowing = false;
    if (measurements.length >= 3) {
      final mid = measurements[measurements.length - 2];
      final older = measurements[measurements.length - 3];
      final d1 = latest!.measuredAt.difference(mid.measuredAt).inMinutes / 1440;
      final d0 = mid.measuredAt.difference(older.measuredAt).inMinutes / 1440;
      if (d1 > 0 && d0 > 0) {
        final r1 = (latest!.weightGram - mid.weightGram) / d1;
        final r0 = (mid.weightGram - older.weightGram) / d0;
        if (r0 > 0 && r1 < r0 * 0.5) slowing = true;
      }
    }
    if (delta != null && delta < 0) slowing = true;

    if (slowing) {
      return GrowthInsight(
        stable: false,
        title: 'Tốc độ tăng trưởng giảm',
        body: delta != null && delta < 0
            ? 'Cân nặng giảm ${delta.abs().toStringAsFixed(delta.abs() % 1 == 0 ? 0 : 1)} g so với lần đo trước.'
            : 'Cân nặng tăng chậm hơn so với các lần đo trước.',
      );
    }

    final buf = StringBuffer('Cân nặng');
    if (delta != null) {
      final sign = delta >= 0 ? '+' : '';
      buf.write(' tăng $sign${delta.toStringAsFixed(delta.abs() % 1 == 0 ? 0 : 1)} g');
      if (pct != null) buf.write(' (${pct.toStringAsFixed(1)}%)');
      if (days > 0) {
        buf.write(' trong $days ngày.');
      } else {
        buf.write('.');
      }
    } else {
      buf.write(' đã có ít nhất 2 lần đo.');
    }
    if (daily != null) {
      buf.write(' Trung bình ${daily.toStringAsFixed(2)} g/ngày.');
    }
    buf.write(' Chưa phát hiện bất thường.');
    return GrowthInsight(stable: true, title: 'Sinh trưởng ổn định', body: buf.toString());
  }
}

String fmtGram(double? v) {
  if (v == null) return '—';
  final n = v.abs() % 1 == 0;
  return '${v.toStringAsFixed(n ? 0 : 1)} g';
}

String fmtSignedGram(double? v) {
  if (v == null) return '—';
  final sign = v > 0 ? '+' : '';
  return '$sign${fmtGram(v)}';
}

String fmtMm(double? v) {
  if (v == null) return '—';
  final n = v.abs() % 1 == 0;
  return '${v.toStringAsFixed(n ? 0 : 1)} mm';
}

String fmtShellSize(double? w, double? l) {
  if (w == null && l == null) return '—';
  String n(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '${w == null ? '—' : n(w)} × ${l == null ? '—' : n(l)} mm';
}

String fmtSignedMmPair(double? dw, double? dl) {
  if (dw == null && dl == null) return '—';
  String n(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}';
  }
  return '${dw == null ? '—' : n(dw)} × ${dl == null ? '—' : n(dl)} mm';
}

String fmtRelativeAgo(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'Vừa xong';
  if (d.inHours < 1) return '${d.inMinutes} phút trước';
  if (d.inHours < 24) return '${d.inHours} giờ trước';
  if (d.inDays == 1) return '1 ngày trước';
  return '${d.inDays} ngày trước';
}

String fmtDurationVn(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h <= 0) return '$m phút';
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}

class NewGrowthInput {
  const NewGrowthInput({
    required this.measuredAt,
    required this.weightGram,
    this.shellWidthMm,
    this.shellLengthMm,
    this.note,
    this.photoUrls = const [],
    this.isMolt = false,
    this.moltStartedAt,
    this.moltCompletedAt,
    this.moltStatus = MoltEventStatus.normal,
    this.moltNote,
    this.moltPhotoUrls = const [],
    this.cameraId,
  });

  final DateTime measuredAt;
  final double weightGram;
  final double? shellWidthMm;
  final double? shellLengthMm;
  final String? note;
  final List<String> photoUrls;
  final bool isMolt;
  final DateTime? moltStartedAt;
  final DateTime? moltCompletedAt;
  final MoltEventStatus moltStatus;
  final String? moltNote;
  final List<String> moltPhotoUrls;
  final String? cameraId;
}
