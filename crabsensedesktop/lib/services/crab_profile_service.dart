import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/crab_feeding_activity.dart';
import '../models/crab_growth_molt.dart';
import '../models/crab_lifecycle_event.dart';
import 'cloud_api_client.dart';

class CrabProfileData {
  const CrabProfileData({
    this.id,
    required this.crabCode,
    required this.gender,
    required this.weight,
    required this.shellWidth,
    this.shellLength,
    required this.status,
    required this.batchCode,
    required this.startDate,
    this.moltCount = 0,
    this.lastMoltDate,
    this.healthStatus,
    this.growthStage,
    this.crabType,
    this.profileNote,
    this.meatQuality,
    this.roeQuality,
    this.estimatedPrice,
    this.imageUrls = const [],
    this.moltLogs = const [],
    this.feedingLogs = const [],
    this.healthRecords = const [],
  });

  final String? id;
  final String crabCode;
  final String gender;
  final double? weight;
  final double? shellWidth;
  final double? shellLength;
  final String status;
  final String batchCode;
  final String startDate;
  final int moltCount;
  final String? lastMoltDate;
  final String? healthStatus;
  final String? growthStage;
  final String? crabType;
  final String? profileNote;
  final double? meatQuality;
  final double? roeQuality;
  final double? estimatedPrice;
  final List<String> imageUrls;
  final List<MoltLogEntry> moltLogs;
  final List<FeedingLogEntry> feedingLogs;
  final List<HealthRecordEntry> healthRecords;

  String get genderLabel {
    final g = gender.trim().toLowerCase();
    if (g == 'male' || g == 'm' || g == 'đực' || g == 'duc') return 'Đực';
    if (g == 'female' || g == 'f' || g == 'cái' || g == 'cai') return 'Cái';
    return 'Chưa xác định';
  }

  String get typeLabel {
    final t = (crabType ?? '').trim();
    if (t.isEmpty) return 'Cua biển';
    final l = t.toLowerCase();
    if (l == 'mudcrab' || l == 'mud_crab' || l == 'cua biển' || l == 'cua bien') {
      return 'Cua biển';
    }
    if (l == 'green' || l == 'cua xanh') return 'Cua xanh';
    return t;
  }

  String get statusLabel => switch (status.toLowerCase()) {
        'alive' || 'growing' || 'normal' => 'Đang nuôi',
        'dead' => 'Đã chết',
        'sold' || 'harvested' => 'Đã bán',
        'molting' => 'Đang lột xác',
        'quarantined' => 'Cách ly',
        _ => status.isEmpty ? 'Đang nuôi' : status,
      };

  String get growthStageLabel {
    final raw = (growthStage ?? '').trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '');
    return switch (raw) {
      'juvenile' => 'Ấu trùng',
      'growing' => 'Đang nuôi',
      'premolt' || 'pre-molt' => 'Sắp lột',
      'molting' => 'Đang lột xác',
      'postmolt' || 'softshell' || 'soft-shell' => 'Vỏ mềm',
      'hardshell' || 'hard-shell' => 'Vỏ cứng',
      'preharvest' || 'pre-harvest' => 'Gần thu hoạch',
      'harvestready' || 'harvest-ready' => 'Sẵn thu hoạch',
      '' => 'Vỏ cứng',
      _ => growthStage!,
    };
  }

  String get healthStatusLabel {
    final raw = (healthStatus ?? '').trim().toLowerCase();
    return switch (raw) {
      'healthy' || 'normal' || 'good' => 'Khỏe mạnh',
      'monitoring' || 'watch' || 'weak' => 'Theo dõi',
      'at_risk' || 'atrisk' || 'problem' || 'disease' || 'stress' => 'Bệnh / Yếu',
      'molting' => 'Đang lột xác',
      '' => 'Khỏe mạnh',
      _ => healthStatus!,
    };
  }

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
      id: (crab['id'] ?? crab['Id'])?.toString(),
      crabCode: (crab['code'] ?? crab['Code'] ?? crab['crabCode'] ?? crab['tag'] ?? '').toString(),
      gender: (crab['gender'] ?? crab['Gender'] ?? 'unknown').toString(),
      weight: (crab['weightGram'] ?? crab['weight'] as num?)?.toDouble(),
      shellWidth: (crab['carapaceWidthMm'] ?? crab['shellWidth'] as num?)?.toDouble(),
      shellLength: (crab['carapaceLengthMm'] as num?)?.toDouble(),
      status: (crab['status'] ?? crab['Status'] ?? 'alive').toString(),
      batchCode: crab['batchCode'] as String? ?? '',
      startDate: crab['startDate'] as String? ?? '',
      moltCount: profile?['moltCount'] as int? ?? 0,
      lastMoltDate: profile?['lastMoltDate'] as String?,
      healthStatus: (profile?['healthStatus'] ?? crab['condition'] ?? crab['initialCondition'])?.toString(),
      growthStage: (profile?['growthStage'] ?? crab['moltingStage'])?.toString(),
      crabType: (crab['crabType'] ?? crab['CrabType'])?.toString(),
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
  String get token => _session.token;
  String get userId => _session.user.id;
  String get userName => _session.user.displayName;

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
        final crabId = (json['id'] ?? json['Id'] ?? '').toString();
        final tag = (json['tag'] ?? json['Tag'] ?? json['code'] ?? json['Code'] ?? crabId).toString();
        final weightRaw = json['weightGram'] ??
            json['WeightGram'] ??
            json['weight'] ??
            json['Weight'];
        final weight = weightRaw is num ? weightRaw.toDouble() : null;
        final added = (json['addedAt'] ?? json['AddedAt'] ?? '').toString();
        final images = _stringList(json['imageUrls'] ?? json['ImageUrls']);
        List<MoltLogEntry> molts = const [];
        List<FeedingLogEntry> feeds = const [];
        Map<String, dynamic> detail = const {};
        try {
          detail = await _api.fetchCrabDetail(_session.token, crabId);
          final raw = detail['moltLogs'];
          if (raw is List) {
            molts = raw
                .whereType<Map>()
                .map((e) => MoltLogEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
          final feedRaw = detail['feedingLogs'] ?? detail['FeedingLogs'];
          if (feedRaw is List) {
            feeds = feedRaw
                .whereType<Map>()
                .map((e) => FeedingLogEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        } catch (_) {}
        final widthRaw = detail['carapaceWidthMm'] ??
            detail['CarapaceWidthMm'] ??
            json['carapaceWidthMm'] ??
            json['CarapaceWidthMm'];
        final lengthRaw = detail['carapaceLengthMm'] ??
            detail['CarapaceLengthMm'] ??
            json['carapaceLengthMm'] ??
            json['CarapaceLengthMm'];
        _data = CrabProfileData(
          id: crabId.isEmpty ? null : crabId,
          crabCode: (detail['code'] ?? detail['Code'] ?? tag).toString(),
          gender: (detail['gender'] ?? detail['Gender'] ?? json['gender'] ?? 'unknown').toString(),
          weight: (detail['weightGram'] ?? detail['WeightGram'] as num?)?.toDouble() ?? weight,
          shellWidth: widthRaw is num ? widthRaw.toDouble() : null,
          shellLength: lengthRaw is num ? lengthRaw.toDouble() : null,
          status: (detail['status'] ??
                  detail['Status'] ??
                  json['healthStatus'] ??
                  json['HealthStatus'] ??
                  'alive')
              .toString(),
          batchCode: (detail['lotCode'] ?? detail['LotCode'] ?? '').toString(),
          startDate: added,
          moltCount: molts.length,
          lastMoltDate: molts.isNotEmpty ? molts.last.moltDate : null,
          healthStatus: (detail['condition'] ??
                  detail['Condition'] ??
                  detail['initialCondition'] ??
                  json['healthStatus'] ??
                  json['HealthStatus'])
              ?.toString(),
          growthStage: (detail['moltingStage'] ??
                  detail['MoltingStage'] ??
                  json['moltingStage'] ??
                  json['MoltingStage'])
              ?.toString(),
          crabType: (detail['crabType'] ?? detail['CrabType'])?.toString(),
          imageUrls: images.isNotEmpty ? images : _stringList(detail['imageUrls'] ?? detail['ImageUrls']),
          moltLogs: molts,
          feedingLogs: feeds,
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

  Future<List<Map<String, dynamic>>> fetchBoxAlerts({
    required String boxId,
    String? farmingAreaId,
  }) {
    return _api.fetchAlerts(
      _session.token,
      boxId: boxId,
      farmingAreaId: farmingAreaId,
      activeOnly: false,
    );
  }

  Future<void> acknowledgeAlert(String alertId, {String? note}) {
    return _api.acknowledgeAlert(
      _session.token,
      alertId,
      userId: _session.user.id,
      note: note,
    );
  }

  Future<void> resolveAlert(String alertId, {String? resolutionCode, String? note}) {
    return _api.resolveAlert(
      _session.token,
      alertId,
      resolutionCode: resolutionCode,
      note: note,
    );
  }

  Future<List<Map<String, dynamic>>> fetchBoxStatusHistory(String boxId) {
    return _api.fetchBoxStatusHistory(_session.token, boxId);
  }

  Future<CrabLifecyclePage> fetchCrabLifecycle(String crabId, {int take = 20}) {
    return _api.fetchCrabLifecycleEvents(_session.token, crabId, take: take);
  }

  Future<CrabGrowthMoltData> fetchCrabGrowth(String crabId) {
    return _api.fetchCrabGrowthMolt(_session.token, crabId);
  }

  Future<List<Map<String, dynamic>>> fetchAreaOperations(String? farmingAreaId) {
    return _api.fetchOperations(_session.token, farmingAreaId: farmingAreaId);
  }

  Future<List<Map<String, dynamic>>> fetchBoxAllocations(String boxId) {
    return _api.fetchBoxAllocations(_session.token, boxId);
  }

  Future<CrabFeedingActivityData> fetchCrabFeeding(String crabId, {int days = 30, int limit = 20}) {
    final to = DateTime.now();
    return _api.fetchCrabFeedingActivity(
      _session.token,
      crabId,
      from: to.subtract(Duration(days: days)),
      to: to,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> fetchAiDetections({String? boxId, int take = 8}) {
    return _api.fetchAiDetections(_session.token, boxId: boxId, take: take);
  }

  Future<Map<String, dynamic>> fetchCrabDetail(String crabId) {
    return _api.fetchCrabDetail(_session.token, crabId);
  }

  Future<void> recordFeeding({
    required String crabId,
    required String boxId,
    required NewFeedingInput input,
    String? operatorName,
  }) async {
    await _api.createFeedingEvent(
      _session.token,
      crabId: crabId,
      boxId: boxId,
      input: input,
      operatorName: operatorName,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty && s != 'null').toList();
    }
    return const [];
  }
}
