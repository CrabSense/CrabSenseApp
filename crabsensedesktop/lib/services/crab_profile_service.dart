import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import 'cloud_api_client.dart';

class CrabProfileData {
  const CrabProfileData({
    required this.crabCode,
    required this.gender,
    required this.weight,
    required this.shellWidth,
    required this.status,
    required this.batchCode,
    required this.startDate,
    this.moltCount = 0,
    this.lastMoltDate,
    this.healthStatus,
    this.growthStage,
    this.profileNote,
    this.meatQuality,
    this.roeQuality,
    this.estimatedPrice,
    this.moltLogs = const [],
    this.feedingLogs = const [],
    this.healthRecords = const [],
  });

  final String crabCode;
  final String gender;
  final double? weight;
  final double? shellWidth;
  final String status;
  final String batchCode;
  final String startDate;
  final int moltCount;
  final String? lastMoltDate;
  final String? healthStatus;
  final String? growthStage;
  final String? profileNote;
  final double? meatQuality;
  final double? roeQuality;
  final double? estimatedPrice;
  final List<MoltLogEntry> moltLogs;
  final List<FeedingLogEntry> feedingLogs;
  final List<HealthRecordEntry> healthRecords;

  String get genderLabel => gender == 'male' ? 'Đực' : gender == 'female' ? 'Cái' : 'Chưa xác định';
  String get statusLabel => switch (status) {
        'alive' => 'Đang sống',
        'dead' => 'Đã chết',
        'sold' => 'Đã bán',
        'molting' => 'Đang lột xác',
        _ => status,
      };
  String get growthStageLabel => switch (growthStage) {
        'juvenile' => 'Ấu trùng',
        'growing' => 'Đang lớn',
        'pre_harvest' => 'Gần thu hoạch',
        'harvest_ready' => 'Sẵn thu hoạch',
        _ => growthStage ?? '—',
      };
  String get healthStatusLabel => switch (healthStatus) {
        'healthy' => 'Khỏe mạnh',
        'monitoring' => 'Theo dõi',
        'at_risk' => 'Nguy cơ',
        'molting' => 'Đang lột xác',
        _ => healthStatus ?? '—',
      };

  factory CrabProfileData.fromJson(Map<String, dynamic> json) {
    final crab = json['crab'] as Map<String, dynamic>? ?? {};
    final profile = json['profile'] as Map<String, dynamic>?;
    final value = json['value'] as Map<String, dynamic>?;
    final molts = (json['moltLogs'] as List?)
            ?.map((e) => MoltLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final feeds = (json['feedingLogs'] as List?)
            ?.map((e) => FeedingLogEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final health = (json['healthRecords'] as List?)
            ?.map((e) => HealthRecordEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CrabProfileData(
      crabCode: crab['crabCode'] as String? ?? '',
      gender: crab['gender'] as String? ?? 'unknown',
      weight: (crab['weight'] as num?)?.toDouble(),
      shellWidth: (crab['shellWidth'] as num?)?.toDouble(),
      status: crab['status'] as String? ?? 'alive',
      batchCode: crab['batchCode'] as String? ?? '',
      startDate: crab['startDate'] as String? ?? '',
      moltCount: profile?['moltCount'] as int? ?? 0,
      lastMoltDate: profile?['lastMoltDate'] as String?,
      healthStatus: profile?['healthStatus'] as String?,
      growthStage: profile?['growthStage'] as String?,
      profileNote: profile?['note'] as String?,
      meatQuality: (value?['meatQuality'] as num?)?.toDouble(),
      roeQuality: (value?['roeQuality'] as num?)?.toDouble(),
      estimatedPrice: (value?['estimatedPrice'] as num?)?.toDouble(),
      moltLogs: molts,
      feedingLogs: feeds,
      healthRecords: health,
    );
  }
}

class MoltLogEntry {
  const MoltLogEntry({
    required this.moltNumber,
    required this.moltDate,
    required this.condition,
    this.note,
  });

  final int moltNumber;
  final String moltDate;
  final String condition;
  final String? note;

  String get conditionLabel => switch (condition) {
        'normal' => 'Bình thường',
        'weak' => 'Yếu',
        'needs_watch' => 'Cần theo dõi',
        _ => condition,
      };

  factory MoltLogEntry.fromJson(Map<String, dynamic> json) => MoltLogEntry(
        moltNumber: json['moltNumber'] as int? ?? 0,
        moltDate: json['moltDate'] as String? ?? '',
        condition: json['condition'] as String? ?? 'normal',
        note: json['note'] as String?,
      );
}

class FeedingLogEntry {
  const FeedingLogEntry({
    required this.foodType,
    required this.quantity,
    required this.unit,
    required this.fedAt,
    this.note,
  });

  final String foodType;
  final double quantity;
  final String unit;
  final String fedAt;
  final String? note;

  factory FeedingLogEntry.fromJson(Map<String, dynamic> json) =>
      FeedingLogEntry(
        foodType: json['foodType'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? '',
        fedAt: json['fedAt'] as String? ?? '',
        note: json['note'] as String?,
      );
}

class HealthRecordEntry {
  const HealthRecordEntry({
    required this.weight,
    required this.shellStatus,
    required this.diseaseStatus,
    required this.recordedAt,
  });

  final double? weight;
  final String? shellStatus;
  final String? diseaseStatus;
  final String recordedAt;

  factory HealthRecordEntry.fromJson(Map<String, dynamic> json) =>
      HealthRecordEntry(
        weight: (json['weight'] as num?)?.toDouble(),
        shellStatus: json['shellStatus'] as String?,
        diseaseStatus: json['diseaseStatus'] as String?,
        recordedAt: json['recordedAt'] as String? ?? '',
      );
}

class CrabProfileService extends ChangeNotifier {
  CrabProfileService({required AuthSession session, CloudApiClient? api})
      : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;
  CrabProfileData? _data;
  bool _loading = false;
  String? _error;

  CrabProfileData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  void updateSession(AuthSession session) {
    _session = session;
  }

  Future<void> loadByBox(String boxId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final crabs = await _api.fetchBoxCrabs(_session.token, boxId);
      if (crabs.isEmpty) {
        _data = null;
      } else {
        final json = crabs.first;
        final tag = (json['tag'] ?? json['Tag'] ?? json['id'] ?? '').toString();
        final weightRaw = json['weightGram'] ??
            json['WeightGram'] ??
            json['weight'] ??
            json['Weight'];
        final weight = weightRaw is num ? weightRaw.toDouble() : null;
        final added = (json['addedAt'] ?? json['AddedAt'] ?? '').toString();
        List<MoltLogEntry> molts = const [];
        try {
          final detail = await _api.fetchCrabDetail(
            _session.token,
            (json['id'] ?? json['Id']).toString(),
          );
          final raw = detail['moltLogs'];
          if (raw is List) {
            molts = raw
                .whereType<Map>()
                .map((e) => MoltLogEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        } catch (_) {}
        _data = CrabProfileData(
          crabCode: tag,
          gender: 'unknown',
          weight: weight,
          shellWidth: null,
          status: (json['healthStatus'] ??
                  json['HealthStatus'] ??
                  json['moltingStatus'] ??
                  json['MoltingStatus'] ??
                  'alive')
              .toString(),
          batchCode: '',
          startDate: added,
          moltCount: molts.length,
          lastMoltDate: molts.isNotEmpty ? molts.last.moltDate : null,
          healthStatus: (json['healthStatus'] ?? json['HealthStatus'])?.toString(),
          growthStage:
              (json['moltingStage'] ?? json['MoltingStage'])?.toString(),
          moltLogs: molts,
        );
      }
    } catch (e) {
      _error = '$e';
      debugPrint('CrabProfileService error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
