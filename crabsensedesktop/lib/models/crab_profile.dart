import 'dart:convert';

class CrabProfile {
  const CrabProfile({
    required this.crabId,
    required this.code,
    required this.condition,
    required this.status,
    required this.gender,
    required this.weightGram,
    required this.initialWeightGram,
    required this.carapaceWidthMm,
    required this.carapaceLengthMm,
    required this.healthNote,
    required this.stockedAt,
    required this.lotId,
    required this.lotCode,
    required this.lotName,
    required this.importDate,
    required this.areaName,
    required this.areaCode,
    required this.rowName,
    required this.rowCode,
    required this.boxCode,
    required this.boxId,
    required this.aiPrediction,
    required this.aiConfidence,
    required this.aiAnalyzedAt,
    required this.aiRecommendation,
    required this.aiActivityLevel,
    required this.imageUrls,
    required this.avatarUrl,
    required this.timeline,
    required this.alerts,
    this.notes,
    this.crabType,
  });

  final String crabId;
  final String code;
  final String condition;
  final String status;
  final String gender;
  final double weightGram;
  final double initialWeightGram;
  final double carapaceWidthMm;
  final double carapaceLengthMm;
  final String healthNote;
  final DateTime? stockedAt;
  final String lotId;
  final String lotCode;
  final String lotName;
  final DateTime? importDate;
  final String areaName;
  final String areaCode;
  final String rowName;
  final String rowCode;
  final String boxCode;
  final String boxId;
  final String? aiPrediction;
  final double? aiConfidence;
  final DateTime? aiAnalyzedAt;
  final String? aiRecommendation;
  final String? aiActivityLevel;
  final List<String> imageUrls;
  final String? avatarUrl;
  final List<CrabTimelineEvent> timeline;
  final List<CrabProfileAlert> alerts;
  final String? notes;
  final String? crabType;

  String get locationPath {
    final khu = areaName.isNotEmpty ? areaName : areaCode;
    final day = rowName.isNotEmpty ? rowName : rowCode;
    final hop = boxCode.isNotEmpty ? boxCode : '—';
    return [khu, day, hop].where((s) => s.isNotEmpty).join(' → ');
  }

  factory CrabProfile.fromJson(Map<String, dynamic> json) {
    final crab = _map(json['crab'] ?? json['Crab']);
    final loc = _map(json['location'] ?? json['Location']);
    final lot = _map(json['lot'] ?? json['Lot']);
    final ai = _map(json['ai'] ?? json['Ai']);
    final images = parseCrabImageUrls(
      json['imageUrls'] ?? json['ImageUrls'] ?? crab['imageUrls'] ?? crab['ImageUrls'],
    );
    return CrabProfile(
      crabId: _str(crab, const ['id', 'Id']),
      code: _str(crab, const ['code', 'Code', 'tag', 'Tag']),
      condition: _str(crab, const ['condition', 'Condition'], fallback: 'normal'),
      status: _str(crab, const ['status', 'Status']),
      gender: _str(crab, const ['gender', 'Gender'], fallback: 'unknown'),
      weightGram: _num(crab, const ['weightGram', 'WeightGram']),
      initialWeightGram: _num(crab, const ['initialWeightGram', 'InitialWeightGram']),
      carapaceWidthMm: _num(crab, const ['carapaceWidthMm', 'CarapaceWidthMm']),
      carapaceLengthMm: _num(crab, const ['carapaceLengthMm', 'CarapaceLengthMm']),
      healthNote: _str(crab, const ['initialCondition', 'InitialCondition']),
      stockedAt: _date(crab['stockedAt'] ?? crab['StockedAt']),
      lotId: _str(lot, const ['id', 'Id'], fallback: _str(crab, const ['crabLotId', 'CrabLotId'])),
      lotCode: _str(lot, const ['lotCode', 'LotCode'], fallback: _str(crab, const ['lotCode', 'LotCode'])),
      lotName: _str(lot, const ['name', 'Name']),
      importDate: _date(lot['importDate'] ?? lot['ImportDate'] ?? crab['importDate'] ?? crab['ImportDate']),
      areaName: _str(loc, const ['areaName', 'AreaName'], fallback: _str(crab, const ['areaName', 'AreaName'])),
      areaCode: _str(loc, const ['areaCode', 'AreaCode'], fallback: _str(crab, const ['areaCode', 'AreaCode'])),
      rowName: _str(loc, const ['rowName', 'RowName'], fallback: _str(crab, const ['rowName', 'RowName'])),
      rowCode: _str(loc, const ['rowCode', 'RowCode'], fallback: _str(crab, const ['rowCode', 'RowCode'])),
      boxCode: _str(loc, const ['boxCode', 'BoxCode'], fallback: _str(crab, const ['boxCode', 'BoxCode'])),
      boxId: _str(loc, const ['boxId', 'BoxId'], fallback: _str(crab, const ['boxId', 'BoxId'])),
      aiPrediction: _opt(ai['prediction'] ?? ai['Prediction'] ?? crab['aiPrediction'] ?? crab['AiPrediction']),
      aiConfidence: _numOrNull(ai['confidence'] ?? ai['Confidence'] ?? crab['aiConfidence'] ?? crab['AiConfidence']),
      aiAnalyzedAt: _date(ai['analyzedAt'] ?? ai['AnalyzedAt'] ?? crab['aiAnalyzedAt'] ?? crab['AiAnalyzedAt']),
      aiRecommendation: _opt(ai['recommendation'] ?? ai['Recommendation'] ?? crab['aiRecommendation'] ?? crab['AiRecommendation']),
      aiActivityLevel: _opt(ai['activityLevel'] ?? ai['ActivityLevel']),
      imageUrls: images,
      avatarUrl: _opt(crab['avatarUrl'] ?? crab['AvatarUrl']) ?? (images.isEmpty ? null : images.first),
      timeline: _list(json['timeline'] ?? json['Timeline'], CrabTimelineEvent.fromJson),
      alerts: _list(json['alerts'] ?? json['Alerts'], CrabProfileAlert.fromJson),
      notes: _opt(crab['notes'] ?? crab['Notes']),
      crabType: _opt(crab['crabType'] ?? crab['CrabType']),
    );
  }

  CrabProfile withImageUrls(List<String> extra) {
    if (extra.isEmpty) return this;
    final merged = [...imageUrls];
    for (final u in extra) {
      if (u.isNotEmpty && !merged.contains(u)) merged.add(u);
    }
    if (merged.length == imageUrls.length) return this;
    return CrabProfile(
      crabId: crabId,
      code: code,
      condition: condition,
      status: status,
      gender: gender,
      weightGram: weightGram,
      initialWeightGram: initialWeightGram,
      carapaceWidthMm: carapaceWidthMm,
      carapaceLengthMm: carapaceLengthMm,
      healthNote: healthNote,
      stockedAt: stockedAt,
      lotId: lotId,
      lotCode: lotCode,
      lotName: lotName,
      importDate: importDate,
      areaName: areaName,
      areaCode: areaCode,
      rowName: rowName,
      rowCode: rowCode,
      boxCode: boxCode,
      boxId: boxId,
      aiPrediction: aiPrediction,
      aiConfidence: aiConfidence,
      aiAnalyzedAt: aiAnalyzedAt,
      aiRecommendation: aiRecommendation,
      aiActivityLevel: aiActivityLevel,
      imageUrls: merged,
      avatarUrl: avatarUrl ?? merged.first,
      timeline: timeline,
      alerts: alerts,
      notes: notes,
      crabType: crabType,
    );
  }
}

List<String> parseCrabImageUrls(dynamic raw) {
  if (raw is List) {
    return [
      for (final u in raw)
        if ((u?.toString() ?? '').trim().isNotEmpty) u.toString().trim(),
    ];
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final s = raw.trim();
    if (s.startsWith('[')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return parseCrabImageUrls(decoded);
      } catch (_) {}
    }
    if (s.startsWith('http') || s.startsWith('file:')) return [s];
  }
  return const [];
}

class CrabTimelineEvent {
  const CrabTimelineEvent({
    required this.at,
    required this.kind,
    required this.title,
    this.detail,
  });

  final DateTime at;
  final String kind;
  final String title;
  final String? detail;

  factory CrabTimelineEvent.fromJson(Map<String, dynamic> json) {
    return CrabTimelineEvent(
      at: _date(json['at'] ?? json['At']) ?? DateTime.now(),
      kind: _str(json, const ['kind', 'Kind']),
      title: _str(json, const ['title', 'Title']),
      detail: _opt(json['detail'] ?? json['Detail']),
    );
  }
}

class CrabProfileAlert {
  const CrabProfileAlert({
    required this.at,
    required this.title,
    this.detail,
    this.severity = 'warning',
  });

  final DateTime at;
  final String title;
  final String? detail;
  final String severity;

  factory CrabProfileAlert.fromJson(Map<String, dynamic> json) {
    return CrabProfileAlert(
      at: _date(json['at'] ?? json['At']) ?? DateTime.now(),
      title: _str(json, const ['title', 'Title']),
      detail: _opt(json['detail'] ?? json['Detail']),
      severity: _str(json, const ['severity', 'Severity'], fallback: 'warning'),
    );
  }
}

Map<String, dynamic> _map(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return {};
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map) parse(Map<String, dynamic>.from(e)),
  ];
}

String _str(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty && s != '00000000-0000-0000-0000-000000000000') return s;
  }
  return fallback;
}

String? _opt(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

double _num(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toDouble();
    final p = double.tryParse('${v ?? ''}');
    if (p != null) return p;
  }
  return 0;
}

double? _numOrNull(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}');
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
