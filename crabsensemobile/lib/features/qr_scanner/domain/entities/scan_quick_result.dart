import 'package:flutter/foundation.dart';

/// Alert chip shown on the QR quick-result sheet.
@immutable
class ScanAlertItem {
  const ScanAlertItem({
    required this.title,
    required this.severity,
  });

  final String title;

  /// low | medium | high | critical
  final String severity;
}

/// Enriched box snapshot shown after a successful QR scan.
@immutable
class ScanQuickResult {
  const ScanQuickResult({
    required this.boxId,
    required this.code,
    required this.rawValue,
    required this.scannedAt,
    this.farmId = '',
    this.farmName = '',
    this.statusLabel = '—',
    this.healthScore = 0,
    this.aiScore = 0,
    this.crabCount = 0,
    this.temperature,
    this.ph,
    this.updatedAt,
    this.aiRecommendation,
    this.aiConfidence,
    this.alerts = const [],
    this.isOffline = false,
  });

  final String boxId;
  final String code;
  final String rawValue;
  final DateTime scannedAt;
  final String farmId;
  final String farmName;
  final String statusLabel;
  final int healthScore;
  final int aiScore;
  final int crabCount;
  final double? temperature;
  final double? ph;
  final DateTime? updatedAt;
  final String? aiRecommendation;
  final double? aiConfidence;
  final List<ScanAlertItem> alerts;
  final bool isOffline;

  bool get hasAiRecommendation =>
      aiRecommendation != null && aiRecommendation!.trim().isNotEmpty;

  bool get hasAlerts => alerts.isNotEmpty;

  String get relativeUpdatedLabel {
    final at = updatedAt ?? scannedAt;
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  ScanQuickResult copyWith({
    String? boxId,
    String? code,
    String? rawValue,
    DateTime? scannedAt,
    String? farmId,
    String? farmName,
    String? statusLabel,
    int? healthScore,
    int? aiScore,
    int? crabCount,
    double? temperature,
    double? ph,
    DateTime? updatedAt,
    String? aiRecommendation,
    double? aiConfidence,
    List<ScanAlertItem>? alerts,
    bool? isOffline,
  }) =>
      ScanQuickResult(
        boxId: boxId ?? this.boxId,
        code: code ?? this.code,
        rawValue: rawValue ?? this.rawValue,
        scannedAt: scannedAt ?? this.scannedAt,
        farmId: farmId ?? this.farmId,
        farmName: farmName ?? this.farmName,
        statusLabel: statusLabel ?? this.statusLabel,
        healthScore: healthScore ?? this.healthScore,
        aiScore: aiScore ?? this.aiScore,
        crabCount: crabCount ?? this.crabCount,
        temperature: temperature ?? this.temperature,
        ph: ph ?? this.ph,
        updatedAt: updatedAt ?? this.updatedAt,
        aiRecommendation: aiRecommendation ?? this.aiRecommendation,
        aiConfidence: aiConfidence ?? this.aiConfidence,
        alerts: alerts ?? this.alerts,
        isOffline: isOffline ?? this.isOffline,
      );
}

/// One entry in recent scan history (max 10).
@immutable
class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.boxId,
    required this.code,
    required this.scannedAt,
    required this.rawValue,
  });

  final String boxId;
  final String code;
  final DateTime scannedAt;
  final String rawValue;

  Map<String, dynamic> toJson() => {
        'boxId': boxId,
        'code': code,
        'scannedAt': scannedAt.toIso8601String(),
        'rawValue': rawValue,
      };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        boxId: json['boxId']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        scannedAt: DateTime.tryParse(json['scannedAt']?.toString() ?? '') ??
            DateTime.now(),
        rawValue: json['rawValue']?.toString() ?? '',
      );
}
