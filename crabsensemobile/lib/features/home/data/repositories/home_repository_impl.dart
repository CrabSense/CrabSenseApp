import 'dart:async';

import 'package:dio/dio.dart';
import '../../../water_quality/data/datasources/water_quality_remote_data_source.dart';
import '../../../water_quality/data/repositories/scoped_history_service.dart';
import '../../../water_quality/domain/entities/water_quality.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';

/// Production Implementation of HomeRepository wired to CrabSense Backend APIs.
/// Scopes dashboard / boxes / ops by selected [farmingAreaId].
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required ApiClient api,
    required Future<HistoryIdentity> Function() identity,
    required int Function() revision,
    required bool Function(String) boundUser,
    required Future<bool> Function() networkAvailable,
  }) : _api = api, _identity = identity, _revision = revision,
       _boundUser = boundUser, _networkAvailable = networkAvailable;

  final ApiClient _api;
  final Future<HistoryIdentity> Function() _identity;
  final int Function() _revision;
  final bool Function(String) _boundUser;
  final Future<bool> Function() _networkAvailable;
  int _generation = 0;

  void invalidate() => ++_generation;

  @override
  Future<HomeStateData> getHomeSummary({
    bool forceRefresh = false, String? farmingAreaId,
  }) async {
    final generation = ++_generation;
    final revision = _revision();
    final identity = await _identity();
    Future<void> verify() async {
      if (generation != _generation || revision != _revision() ||
          !_boundUser(identity.userId) || !await _networkAvailable()) {
        throw StateError('Home session or transport unavailable');
      }
      final current = await _identity();
      if (generation != _generation || revision != _revision() ||
          !_boundUser(identity.userId) || !identity.matches(current)) {
        throw StateError('Home session changed');
      }
    }
    await verify();
    final result = await _HomeRead(_api, identity, revision, verify)
        .load(farmingAreaId);
    await verify();
    return result;
  }

  @override
  Future<HomeStateData> switchFarm(String farmId) =>
      getHomeSummary(forceRefresh: true, farmingAreaId: farmId);

  @override
  Future<void> dismissRecommendation(String recommendationId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

/// A read owns its credential and revision; overlapping reads never share them.
class _HomeRead {
  _HomeRead(this._api, this._identity, this._revision, this._verify);
  final ApiClient _api;
  final HistoryIdentity _identity;
  final int _revision;
  final Future<void> Function() _verify;

  Future<Response<T>> _get<T>(String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _verify();
    final res = await _api.get<T>(path, queryParameters: queryParameters,
      options: Options(
        followRedirects: false,
        validateStatus: (status) => status == 200,
        headers: {'Authorization': 'Bearer ${_identity.accessToken}'},
        extra: const {'skipAuthInterceptor': true, 'skipTokenRefresh': true,
          'skipSensitiveLogging': true},
      ));
    await _verify();
    final body = _asStringKeyedMap(res.data);
    if (body == null || body['success'] != true || !body.containsKey('data')) {
      throw const FormatException('Invalid Home API envelope');
    }
    return res;
  }

  Map<String, dynamic> _areaQuery(String? farmingAreaId) {
    if (farmingAreaId == null || farmingAreaId.isEmpty || farmingAreaId == 'default') {
      throw StateError('Home area unavailable');
    }
    return {'farmingAreaId': farmingAreaId};
  }

  Future<HomeStateData> load(String? requestedAreaId) async {
      final now = DateTime.now();
      final userInfo = await _fetchUserInfo();
      final farmsList = await _fetchFarms();
      final selectedFarm = _resolveSelectedFarm(farmsList, requestedAreaId);
      if (selectedFarm == null) {
        throw StateError('Chưa có khu nuôi được xác minh quyền truy cập.');
      }
      final areaId = selectedFarm.id;

      final results = await Future.wait(
        [
          _fetchBoxes(areaId),
          _fetchAlerts(areaId),
          _fetchWaterMetrics(areaId),
          _fetchDevices(areaId),
          _fetchOverview(areaId),
          _fetchHealthMetrics(areaId),
          _fetchAiRecommendation(areaId),
          _fetchTodayTasks(areaId),
          _fetchScheduledTasksToday(areaId),
          _fetchRecentActivities(areaId),
          _fetchUnreadNotificationsCount(),
        ],
      );

      final boxInfo = results[0] as Map<String, int>?;
      final alertsData = results[1] as Map<String, dynamic>?;
      final waterMetrics = results[2] as List<WaterMetricItem>?;
      final deviceSummary = results[3] as DeviceSummary?;
      final overview = results[4] as FarmSummary?;
      if (overview == null) throw const FormatException('Missing Home overview');
      final healthScore = results[5] as FarmHealthScore?;
      final aiRecommendation = results[6] as AiRecommendation?;
      final todayTasks = results[7] as List<TodayTaskItem>?;
      final scheduledTasks = results[8] as List<TodayTaskItem>? ?? const [];
      final recentActivities = results[9] as List<RecentActivityItem>?;
      final unreadFromApi = results[10] as int?;

      final operatorName =
          userInfo['fullName']?.toString() ??
          userInfo['name']?.toString() ??
          userInfo['username']?.toString() ??
          'Cán bộ vận hành';
      final alertsList =
          alertsData?['items'] as List<AlertSummaryItem>? ?? const [];
      final summary = HomeStateData(
        operatorName: operatorName,
        selectedFarmId: selectedFarm.id,
        selectedFarmName: selectedFarm.name,
        availableFarms: farmsList,
        isOnline: true,
        unreadNotificationsCount: unreadFromApi ?? 0,
        farmSummary: overview,
        healthScore:
            healthScore ??
            FarmHealthScore(
              score: 0,
              statusLevel: HealthStatusLevel.good,
              statusLabel: 'Chưa có chỉ số',
              deltaVsYesterday: 0.0,
              lastAiUpdated: now,
              waterQualityScore: 0,
              crabHealthScore: 0,
              deviceStatusScore: 0,
              explanation: 'Chưa tải được /api/dashboard/metrics.',
            ),
        aiRecommendation: aiRecommendation ?? AiRecommendation.empty,
        topAlerts: alertsList,
        waterMetrics: waterMetrics ?? const [],
          todayTasks: [...?todayTasks, ...scheduledTasks],
        // These history routes lack an explicit area contract. Never show
        // authorized-all-area history under a specific area selection.
        feedingHistory: const [],
        boxStatusHistory: const [],
        boxStatusCounts: boxInfo ?? const {},
        deviceSummary:
            deviceSummary ??
            const DeviceSummary(
              esp32Online: 0,
              esp32Total: 0,
              cameraOnline: 0,
              cameraTotal: 0,
              pumpRunning: 0,
              pumpTotal: 0,
              valveReady: 0,
              valveTotal: 0,
            ),
        recentActivities: recentActivities ?? const [],
        isOfflineCached: false,
        lastSyncedAt: now,
      );

      return summary;
  }

  FarmOption? _resolveSelectedFarm(
    List<FarmOption> farms,
    String? preferredId,
  ) {
    if (preferredId != null && preferredId.isNotEmpty) {
      for (final farm in farms) {
        if (farm.id.toLowerCase() == preferredId.toLowerCase()) {
          return farm;
        }
      }
      // A persisted selection may have been revoked. Only use a fresh allowed area.
    }
    if (farms.isEmpty) return null;
    return farms.first;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  List? _extractList(dynamic data) {
    if (data == null) return null;
    if (data is List) return data;
    final map = _asStringKeyedMap(data);
    if (map == null) return null;
    if (map['data'] != null) return _extractList(map['data']);
    if (map['items'] is List) return map['items'] as List;
    if (map['readings'] is List) return map['readings'] as List;
    return null;
  }

  List<FarmOption> _mapFarms(List list) {
    final farms = <FarmOption>[];
    for (final item in list) {
      final map = _asStringKeyedMap(item);
      if (map == null) continue;
      final id = map['id']?.toString().trim() ?? '';
      final name = map['name']?.toString().trim() ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      final boxCount = (map['boxCount'] as num?)?.toInt() ?? 0;
      farms.add(FarmOption(id: id, name: name, boxCount: boxCount));
    }
    return farms;
  }

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    final res = await _get(ApiConstants.currentUser);
    final root = _asStringKeyedMap(res.data);
    final user = _asStringKeyedMap(root?['data']);
    if (user == null || user['id']?.toString().toLowerCase() != _identity.userId.toLowerCase()) {
      throw StateError('Home actor mismatch');
    }
    return user;
  }

  Future<List<FarmOption>> _fetchFarms() async {
    final res = await _get(ApiConstants.farmingAreas,
      queryParameters: const {'page': 1, 'pageSize': 200});
    final list = _extractList(res.data);
    if (list == null) throw const FormatException('Invalid area inventory');
    final farms = _mapFarms(list);
    if (farms.length != list.length ||
        farms.map((f) => f.id.toLowerCase()).toSet().length != farms.length ||
        farms.any((f) => f.id.toLowerCase() == 'default')) {
      throw const FormatException('Invalid area inventory identity');
    }
    return farms;
  }

  Future<Map<String, int>?> _fetchBoxes(String? farmingAreaId) async {
    final res = await _get(
      ApiConstants.boxesOverview,
      queryParameters: _areaQuery(farmingAreaId),
    );
      if (res.statusCode == 200 && res.data != null) {
        final root = _asStringKeyedMap(res.data);
        final raw = _asStringKeyedMap(root?['data']) ?? root;
        if (raw != null) {
          if (raw['farmingAreaId']?.toString().toLowerCase() != farmingAreaId?.toLowerCase() || raw['items'] is! List) {
            throw const FormatException('Invalid scoped boxes overview');
          }
          final items = raw['items'] as List;
          final summary = _asStringKeyedMap(raw['summary']);
          if (summary?['total'] != items.length) throw const FormatException('Incomplete boxes overview');
          final total = items.length;
          final ids = <String>{};
          final counts = <String, int>{
            'normal': 0,
            'watch': 0,
            'molting': 0,
            'alert': 0,
            'empty': 0,
          };
          for (final item in items) {
            final map = _asStringKeyedMap(item);
            final id = map?['id']?.toString();
            if (map == null || id == null || id.isEmpty || !ids.add(id.toLowerCase()) ||
                map['farmingAreaId']?.toString().toLowerCase() != farmingAreaId?.toLowerCase()) {
              throw const FormatException('Box outside Home area or duplicate');
            }
            final occupied = map['isOccupied'] == true ||
                ((map['crabCount'] as num?)?.toInt() ?? 0) > 0;
            final cc = (map['crabCondition'] ?? map['CrabCondition'] ?? '')
                .toString()
                .toLowerCase();
            // Đếm theo tình trạng CUA, không theo Box.Status (Molting) hay
            // "soft" trên mã hộp — nếu không 2 hộp lột mềm thành Lột xác dù
            // phiếu 19h đã ghi ăn / không ăn.
            final key = !occupied || cc.contains('empty')
                ? 'empty'
                : (cc.contains('problem') ||
                      cc.contains('attention') ||
                      cc.contains('alert'))
                    ? 'alert'
                    : (cc.contains('premolt') ||
                          cc.contains('molting') ||
                          cc.contains('soft'))
                    ? 'molting'
                    : cc.contains('weak')
                    ? 'watch'
                    : 'normal';
            counts[key] = counts[key]! + 1;
          }
          final active =
              counts.values.fold<int>(0, (sum, value) => sum + value) -
              counts['empty']!;
          return {'total': total, 'active': active, ...counts};
        }
      }
    throw const FormatException('Invalid scoped boxes overview');
  }

  Future<Map<String, dynamic>?> _fetchAlerts(String? farmingAreaId) async {
    final query = <String, dynamic>{'activeOnly': true};
    final area = _areaQuery(farmingAreaId);
    query.addAll(area);

    final res = await _get(ApiConstants.alerts, queryParameters: query);
    if (res.statusCode == 200 && res.data != null) {
      final list = _extractList(res.data);
      if (list != null) {
        final now = DateTime.now();
        final mapped = list
            .map((item) {
              final map = _asStringKeyedMap(item);
              if (map == null) return null;

              final severityStr =
                  map['severity']?.toString().toLowerCase() ?? '';
              AlertSeverityLevel level = AlertSeverityLevel.warning;
              if (severityStr.contains('critical') ||
                  severityStr.contains('danger') ||
                  severityStr.contains('high')) {
                level = AlertSeverityLevel.critical;
              } else if (severityStr.contains('info') ||
                  severityStr.contains('low')) {
                level = AlertSeverityLevel.info;
              }

              return AlertSummaryItem(
                id: map['id']?.toString() ?? 'alt_01',
                title:
                    map['title']?.toString() ??
                    map['message']?.toString() ??
                    'Cảnh báo hệ thống',
                location:
                    map['location']?.toString() ??
                    map['sensorName']?.toString() ??
                    'Trang trại',
                severity: level,
                timestamp: map['createdAt'] != null
                    ? DateTime.tryParse(map['createdAt'].toString()) ?? now
                    : now,
                status: map['status']?.toString() ?? 'Cần theo dõi',
              );
            })
            .whereType<AlertSummaryItem>()
            .toList();

        return {'items': mapped, 'openCount': mapped.length};
      }
    }
    return null;
  }

  Future<int?> _fetchUnreadNotificationsCount() async {
    final res = await _get(ApiConstants.unreadNotificationCount);
    if (res.statusCode != 200 || res.data == null) return null;
    final raw = res.data;
    Map<String, dynamic>? body;
    if (raw is Map<String, dynamic>) {
      body = raw;
    } else if (raw is Map) {
      body = raw.map((k, v) => MapEntry(k.toString(), v));
    }
    if (body == null) return null;
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;
    final count = data['count'] ?? data['unreadCount'] ?? data['unread_count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    return int.tryParse('$count');
  }

  Future<List<WaterMetricItem>?> _fetchWaterMetrics(String? farmingAreaId) async {
    if (farmingAreaId == null || farmingAreaId.isEmpty || farmingAreaId == 'default') {
      throw StateError('Home area unavailable');
    }
    final res = await _get<Map<String, dynamic>>(ApiConstants.waterQualityLatest,
      queryParameters: _areaQuery(farmingAreaId));
    final body = res.data!;
    if (body['data'] is! List) throw const FormatException('Invalid live water payload');
    return decodeHomeWaterMetrics(body['data'] as List,
      areaId: farmingAreaId, revision: _revision);
  }

  Future<DeviceSummary?> _fetchDevices(String? farmingAreaId) async {
    final res = await _get(
      ApiConstants.devices,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode == 200 && res.data != null) {
      final list = _extractList(res.data);
      if (list != null) {
        int espOnline = 0, espTotal = 0;
        int camOnline = 0, camTotal = 0;
        int pumpRunning = 0, pumpTotal = 0;
        int valveReady = 0, valveTotal = 0;

        for (final item in list) {
          final map = _asStringKeyedMap(item);
          if (map == null) continue;
          final type = map['deviceType']?.toString().toLowerCase() ?? '';
          final status = map['status']?.toString().toLowerCase() ?? '';
          final isOnline =
              map['isOnline'] == true ||
              status == 'active' ||
              status == 'online';
          if (type.contains('esp') || type.contains('controller')) {
            espTotal++;
            if (isOnline) espOnline++;
          } else if (type.contains('camera') || type.contains('cam')) {
            camTotal++;
            if (isOnline) camOnline++;
          } else if (type.contains('pump') || type.contains('bơm')) {
            pumpTotal++;
            if (isOnline) pumpRunning++;
          } else if (type.contains('valve') || type.contains('van')) {
            valveTotal++;
            if (isOnline) valveReady++;
          }
        }

        return DeviceSummary(
          esp32Online: espOnline,
          esp32Total: espTotal,
          cameraOnline: camOnline,
          cameraTotal: camTotal,
          pumpRunning: pumpRunning,
          pumpTotal: pumpTotal,
          valveReady: valveReady,
          valveTotal: valveTotal,
        );
      }
    }
    return null;
  }

  Future<FarmSummary?> _fetchOverview(String? farmingAreaId) async {
    final res = await _get(
      ApiConstants.dashboardOverview,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final root = _asStringKeyedMap(res.data);
    final data = _asStringKeyedMap(root?['data']) ?? root;
    if (data == null) return null;

    return FarmSummary(
      totalBoxes: (data['totalBoxes'] as num?)?.toInt() ?? 0,
      totalCrabs: (data['totalCrabs'] as num?)?.toInt() ?? 0,
      activeBoxes: (data['activeBoxes'] as num?)?.toInt() ?? 0,
      openAlerts: (data['openAlerts'] as num?)?.toInt() ?? 0,
      iotOnlinePercentage:
          (data['iotOnlinePercentage'] as num?)?.toDouble() ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.tryParse(data['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<FarmHealthScore?> _fetchHealthMetrics(String? farmingAreaId) async {
    final res = await _get(
      ApiConstants.dashboardMetrics,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final root = _asStringKeyedMap(res.data);
    final data = _asStringKeyedMap(root?['data']) ?? root;
    if (data == null) return null;

    final score = (data['score'] as num?)?.toInt() ?? 0;
    final levelRaw = data['statusLevel']?.toString().toLowerCase() ?? '';
    final level = switch (levelRaw) {
      'excellent' => HealthStatusLevel.excellent,
      'warning' => HealthStatusLevel.warning,
      'danger' || 'critical' => HealthStatusLevel.danger,
      _ => FarmHealthScore.calculateLevel(score),
    };

    return FarmHealthScore(
      score: score,
      statusLevel: level,
      statusLabel: data['statusLabel']?.toString() ?? level.name,
      deltaVsYesterday: (data['deltaVsYesterday'] as num?)?.toDouble() ?? 0,
      lastAiUpdated: data['lastAiUpdated'] != null
          ? DateTime.tryParse(data['lastAiUpdated'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      waterQualityScore: (data['waterQualityScore'] as num?)?.toInt() ?? 0,
      crabHealthScore: (data['crabHealthScore'] as num?)?.toInt() ?? 0,
      deviceStatusScore: (data['deviceStatusScore'] as num?)?.toInt() ?? 0,
      explanation: data['explanation']?.toString() ?? '',
    );
  }

  Future<AiRecommendation?> _fetchAiRecommendation(
    String? farmingAreaId,
  ) async {
    final res = await _get(
      ApiConstants.aiRecommendations,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final list = _extractList(res.data);
    if (list == null || list.isEmpty) return AiRecommendation.empty;

    final map = _asStringKeyedMap(list.first);
    if (map == null) return AiRecommendation.empty;

    final hasActive = map['hasActiveRecommendation'] != false;
    if (!hasActive) return AiRecommendation.empty;

    final typeRaw = map['type']?.toString().toLowerCase() ?? 'observe';
    final type = switch (typeRaw) {
      'harvest' => AiActionType.harvest,
      'inspect' => AiActionType.inspect,
      'watertreatment' || 'water_treatment' => AiActionType.waterTreatment,
      _ => AiActionType.observe,
    };
    final prioRaw = map['priority']?.toString().toLowerCase() ?? 'low';
    final priority = switch (prioRaw) {
      'high' => ActionPriority.high,
      'medium' => ActionPriority.medium,
      _ => ActionPriority.low,
    };

    return AiRecommendation(
      id: map['id']?.toString() ?? 'rec_1',
      type: type,
      title: map['title']?.toString() ?? 'Khuyến nghị AI',
      description: map['description']?.toString() ?? '',
      targetBoxOrArea: map['targetBoxOrArea']?.toString() ?? 'Trang trại',
      confidencePercentage:
          (map['confidencePercentage'] as num?)?.toInt() ?? 80,
      priority: priority,
      reason: map['reason']?.toString() ?? '',
      optimalTimeframe: map['optimalTimeframe']?.toString() ?? '',
      expectedImpact: map['expectedImpact']?.toString() ?? '',
      hasActiveRecommendation: true,
    );
  }

  Future<List<TodayTaskItem>?> _fetchTodayTasks(String? farmingAreaId) async {
    final res = await _get(
      ApiConstants.operationsToday,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final list = _extractList(res.data);
    if (list == null) return const [];

    return list
        .map((item) {
          final map = _asStringKeyedMap(item);
          if (map == null) return null;
          final prioRaw = map['priority']?.toString().toLowerCase() ?? 'low';
          final priority = switch (prioRaw) {
            'high' => ActionPriority.high,
            'medium' => ActionPriority.medium,
            _ => ActionPriority.low,
          };
          return TodayTaskItem(
            id: map['id']?.toString() ?? 'task',
            title: map['title']?.toString() ?? 'Công việc',
            target: map['target']?.toString() ?? '',
            deadline: map['deadline'] != null
                ? DateTime.tryParse(map['deadline'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            priority: priority,
            isCompleted: map['isCompleted'] == true,
          );
        })
        .whereType<TodayTaskItem>()
        .toList();
  }

  Future<List<TodayTaskItem>?> _fetchScheduledTasksToday(
    String? farmingAreaId,
  ) async {
    final res = await _get(
      ApiConstants.scheduledTasks,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final list = _extractList(res.data);
    if (list == null) return const [];
    final today = DateTime.now();
    return list
        .map((item) {
          final map = _asStringKeyedMap(item);
          if (map == null || map['isEnabled'] != true) return null;
          final nextRun =
              DateTime.tryParse('${map['nextRunAt']}') ?? today;
          return TodayTaskItem(
            id: 'scheduled-${map['id']}',
            title: map['title']?.toString() ?? 'Công việc theo lịch',
            target: map['description']?.toString() ?? 'Theo kế hoạch',
            deadline: nextRun,
            priority: ActionPriority.medium,
            isCompleted: false,
          );
        })
        .whereType<TodayTaskItem>()
        .toList();
  }

  Future<List<RecentActivityItem>?> _fetchRecentActivities(
    String? farmingAreaId,
  ) async {
    final res = await _get(
      ApiConstants.operationsRecent,
      queryParameters: {
        ..._areaQuery(farmingAreaId),
        'limit': 50,
      },
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final list = _extractList(res.data);
    if (list == null) return const [];

    return list
        .map((item) {
          final map = _asStringKeyedMap(item);
          if (map == null) return null;
          final typeRaw = map['type']?.toString().toLowerCase() ?? 'sync';
          final type = switch (typeRaw) {
            'qrscan' || 'qr_scan' => ActivityType.qrScan,
            'sensorupdate' || 'sensor_update' => ActivityType.sensorUpdate,
            'aidetection' || 'ai_detection' => ActivityType.aiDetection,
            'harvest' => ActivityType.harvest,
            'alerthandled' || 'alert_handled' => ActivityType.alertHandled,
            _ => ActivityType.sync,
          };
          return RecentActivityItem(
            id: map['id']?.toString() ?? 'act',
            title: map['title']?.toString() ?? 'Hoạt động',
            description: map['description']?.toString() ?? '',
            type: type,
            timestamp: map['timestamp'] != null
                ? DateTime.tryParse(map['timestamp'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

}

/// Reuse the environment decoder. A summary cannot manufacture an identity,
/// receipt, threshold or measurement from a legacy row.
List<WaterMetricItem> decodeHomeWaterMetrics(List<dynamic> rows, {
  required String areaId, required int revision,
}) {
  if (areaId.isEmpty || areaId == 'default') return [];
  final qualified = <WaterQuality>[];
  for (final raw in rows) {
    if (raw is! Map<String,dynamic>) continue;
    final r = decodeLiveWaterReading(raw, farmId: areaId);
    if (r?.liveMetric != null) qualified.add(r!);
  }
  final counts = <String,int>{};
  for (final r in qualified) {
    counts[r.sensorId] = (counts[r.sensorId] ?? 0) + 1;
  }
  return [
    for (final r in qualified)
      if (counts[r.sensorId] == 1)
        WaterMetricItem(
          code: r.liveMetric!.kind.name, name: r.liveMetric!.kind.label,
          currentValue: r.liveMetric!.value, unit: r.liveMetric!.unit,
          status: r.liveMetric!.alarm != null || r.liveMetric!.outsideThreshold
              ? MetricStatus.danger : MetricStatus.warning,
          trend: MetricTrend.stable, lastUpdated: r.timestamp,
          minThreshold: r.liveMetric!.min, maxThreshold: r.liveMetric!.max,
          qualifiedReading: r, sessionRevision: revision,
        ),
  ];
}
