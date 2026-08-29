import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';

/// Production Implementation of HomeRepository wired to CrabSense Backend APIs.
/// Scopes dashboard / boxes / ops by selected [farmingAreaId].
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({Dio? dio, FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.apiBaseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            String? token;
            token = await _secureStorage.read(key: 'auth_access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  HomeStateData? _cachedData;

  Map<String, dynamic>? _areaQuery(String? farmingAreaId) {
    if (farmingAreaId == null || farmingAreaId.isEmpty) return null;
    return {'farmingAreaId': farmingAreaId};
  }

  @override
  Future<HomeStateData> getHomeSummary({
    bool forceRefresh = false,
    String? farmingAreaId,
  }) async {
    final requestedAreaId = farmingAreaId ?? _cachedData?.selectedFarmId;

    if (_cachedData != null &&
        !forceRefresh &&
        requestedAreaId == _cachedData!.selectedFarmId) {
      return _cachedData!;
    }

    try {
      final now = DateTime.now();

      final userInfo = await _fetchUserInfo();
      final userId = userInfo?['id']?.toString();

      final farmsList = await _fetchFarms(userId);
      final selectedFarm = _resolveSelectedFarm(farmsList, requestedAreaId);
      final areaId = selectedFarm?.id;

      final results = await Future.wait([
        _fetchBoxes(areaId),
        _fetchAlerts(areaId),
        _fetchWaterMetrics(areaId),
        _fetchDevices(areaId),
        _fetchOverview(areaId),
        _fetchHealthMetrics(areaId),
        _fetchAiRecommendation(areaId),
        _fetchTodayTasks(areaId),
        _fetchRecentActivities(areaId),
        _fetchUnreadNotificationsCount(),
      ].map((p) => p.catchError((_) => null)));

      final boxInfo = results[0] as Map<String, int>?;
      final alertsData = results[1] as Map<String, dynamic>?;
      final waterMetrics = results[2] as List<WaterMetricItem>?;
      final deviceSummary = results[3] as DeviceSummary?;
      final overview = results[4] as FarmSummary?;
      final healthScore = results[5] as FarmHealthScore?;
      final aiRecommendation = results[6] as AiRecommendation?;
      final todayTasks = results[7] as List<TodayTaskItem>?;
      final recentActivities = results[8] as List<RecentActivityItem>?;
      final unreadFromApi = results[9] as int?;

      final operatorName = userInfo?['fullName']?.toString() ??
          userInfo?['name']?.toString() ??
          userInfo?['username']?.toString() ??
          'Cán bộ vận hành';
      final alertsList = alertsData?['items'] as List<AlertSummaryItem>? ?? const [];
      final openAlertsCount = unreadFromApi ??
          overview?.openAlerts ??
          alertsData?['openCount'] as int? ??
          alertsList.length;

      final computedIotPct = deviceSummary != null &&
              (deviceSummary.esp32Total + deviceSummary.cameraTotal) > 0
          ? (((deviceSummary.esp32Online + deviceSummary.cameraOnline) /
                      (deviceSummary.esp32Total + deviceSummary.cameraTotal)) *
                  100)
              .roundToDouble()
          : overview?.iotOnlinePercentage ?? 0.0;

      final summary = HomeStateData(
        operatorName: operatorName,
        selectedFarmId: selectedFarm?.id,
        selectedFarmName: selectedFarm?.name ?? 'Chưa có trang trại',
        availableFarms: farmsList,
        isOnline: true,
        unreadNotificationsCount: openAlertsCount,
        farmSummary: overview ??
            FarmSummary(
              totalBoxes: boxInfo?['total'] ?? 0,
              totalCrabs: 0,
              activeBoxes: boxInfo?['active'] ?? 0,
              openAlerts: openAlertsCount,
              iotOnlinePercentage: computedIotPct,
              lastUpdated: now,
            ),
        healthScore: healthScore ??
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
        todayTasks: todayTasks ?? const [],
        deviceSummary: deviceSummary ??
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

      _cachedData = summary;
      return summary;
    } catch (_) {
      if (_cachedData != null) {
        return HomeStateData(
          operatorName: _cachedData!.operatorName,
          selectedFarmId: _cachedData!.selectedFarmId,
          selectedFarmName: _cachedData!.selectedFarmName,
          availableFarms: _cachedData!.availableFarms,
          isOnline: false,
          unreadNotificationsCount: _cachedData!.unreadNotificationsCount,
          farmSummary: _cachedData!.farmSummary,
          healthScore: _cachedData!.healthScore,
          aiRecommendation: _cachedData!.aiRecommendation,
          topAlerts: _cachedData!.topAlerts,
          waterMetrics: _cachedData!.waterMetrics,
          todayTasks: _cachedData!.todayTasks,
          deviceSummary: _cachedData!.deviceSummary,
          recentActivities: _cachedData!.recentActivities,
          isOfflineCached: true,
          lastSyncedAt: _cachedData!.lastSyncedAt ?? DateTime.now(),
        );
      }
      return _emptyDataState();
    }
  }

  @override
  Future<HomeStateData> switchFarm(String farmId) async {
    return getHomeSummary(forceRefresh: true, farmingAreaId: farmId);
  }

  @override
  Future<void> dismissRecommendation(String recommendationId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  FarmOption? _resolveSelectedFarm(List<FarmOption> farms, String? preferredId) {
    if (farms.isEmpty) return null;
    if (preferredId != null && preferredId.isNotEmpty) {
      for (final farm in farms) {
        if (farm.id == preferredId) return farm;
      }
    }
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
      farms.add(FarmOption(id: id, name: name));
    }
    return farms;
  }

  Future<Map<String, dynamic>?> _fetchUserInfo() async {
    final res = await _dio.get(ApiConstants.currentUser);
    if (res.statusCode == 200 && res.data != null) {
      final root = _asStringKeyedMap(res.data);
      final raw = root?['data'] ?? res.data;
      return _asStringKeyedMap(raw);
    }
    return null;
  }

  Future<List<FarmOption>> _fetchFarms([String? ownerId]) async {
    Future<List<FarmOption>> request(Map<String, dynamic>? query) async {
      final res = await _dio.get(
        ApiConstants.farmingAreas,
        queryParameters: query,
      );
      if (res.statusCode == 200 && res.data != null) {
        final list = _extractList(res.data);
        if (list != null && list.isNotEmpty) {
          return _mapFarms(list);
        }
      }
      return const [];
    }

    final hasOwner = ownerId != null && ownerId.isNotEmpty;
    final ownerLooksLikeGuid =
        hasOwner && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(ownerId);

    if (ownerLooksLikeGuid) {
      final scoped = await request({'ownerId': ownerId});
      if (scoped.isNotEmpty) return scoped;
    }

    return request(null);
  }

  Future<Map<String, int>?> _fetchBoxes(String? farmingAreaId) async {
    try {
      final res = await _dio.get(
        ApiConstants.boxes,
        queryParameters: _areaQuery(farmingAreaId),
      );
      if (res.statusCode == 200 && res.data != null) {
        final root = _asStringKeyedMap(res.data);
        final raw = _asStringKeyedMap(root?['data']) ?? root;
        if (raw != null) {
          final items = raw['items'] is List ? raw['items'] as List : [];
          final total = raw['totalCount'] as int? ?? items.length;
          final active = items.where((b) {
            final map = _asStringKeyedMap(b);
            if (map != null) {
              final st = map['status']?.toString().toLowerCase() ?? '';
              return st != 'empty' && st != 'available';
            }
            return true;
          }).length;
          return {'total': total, 'active': active};
        }
        if (res.data is List) {
          final list = res.data as List;
          return {'total': list.length, 'active': list.length};
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchAlerts(String? farmingAreaId) async {
    final query = <String, dynamic>{'activeOnly': true};
    final area = _areaQuery(farmingAreaId);
    if (area != null) query.addAll(area);

    final res = await _dio.get(
      ApiConstants.alerts,
      queryParameters: query,
    );
    if (res.statusCode == 200 && res.data != null) {
      final list = _extractList(res.data);
      if (list != null) {
        final now = DateTime.now();
        final mapped = list.map((item) {
          final map = _asStringKeyedMap(item);
          if (map == null) return null;

          final severityStr = map['severity']?.toString().toLowerCase() ?? '';
          AlertSeverityLevel level = AlertSeverityLevel.warning;
          if (severityStr.contains('critical') ||
              severityStr.contains('danger') ||
              severityStr.contains('high')) {
            level = AlertSeverityLevel.critical;
          } else if (severityStr.contains('info') || severityStr.contains('low')) {
            level = AlertSeverityLevel.info;
          }

          return AlertSummaryItem(
            id: map['id']?.toString() ?? 'alt_01',
            title: map['title']?.toString() ??
                map['message']?.toString() ??
                'Cảnh báo hệ thống',
            location: map['location']?.toString() ??
                map['sensorName']?.toString() ??
                'Trang trại',
            severity: level,
            timestamp: map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString()) ?? now
                : now,
            status: map['status']?.toString() ?? 'Cần theo dõi',
          );
        }).whereType<AlertSummaryItem>().toList();

        return {'items': mapped, 'openCount': mapped.length};
      }
    }
    return null;
  }

  Future<int?> _fetchUnreadNotificationsCount() async {
    final res = await _dio.get(ApiConstants.unreadAlertCount);
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
    final res = await _dio.get(
      ApiConstants.waterQualityLatest,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode == 200 && res.data != null) {
      final list = _extractList(res.data);
      if (list != null) {
        final now = DateTime.now();
        final items = <WaterMetricItem>[];
        for (final item in list) {
          final map = _asStringKeyedMap(item);
          if (map == null) continue;
          final type = map['sensorType']?.toString() ??
              map['code']?.toString() ??
              map['type']?.toString() ??
              '';
          final rawVal = map['latestValue'] ??
              map['value'] ??
              map['currentValue'] ??
              map['reading'] ??
              0.0;
          final val = rawVal is num ? rawVal.toDouble() : double.tryParse('$rawVal') ?? 0.0;
          final alarm = map['alarm']?.toString().toLowerCase() ?? '';
          final min = (map['minThreshold'] as num?)?.toDouble();
          final max = (map['maxThreshold'] as num?)?.toDouble();

          MetricStatus status = MetricStatus.optimal;
          if (alarm.isNotEmpty) {
            status = MetricStatus.danger;
          } else if (min != null && val < min) {
            status = MetricStatus.warning;
          } else if (max != null && val > max) {
            status = MetricStatus.warning;
          }

          final measuredAt = map['latestMeasuredAt'] ?? map['measuredAt'];
          final updated = measuredAt != null
              ? DateTime.tryParse(measuredAt.toString()) ?? now
              : now;

          items.add(WaterMetricItem(
            code: type.toLowerCase(),
            name: _waterMetricLabel(type),
            currentValue: val,
            unit: map['unit']?.toString() ?? _waterMetricUnit(type),
            status: status,
            trend: MetricTrend.stable,
            lastUpdated: updated,
          ));
        }
        return items;
      }
    }
    return null;
  }

  String _waterMetricLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('temp')) return 'Nhiệt độ';
    if (t.contains('ph')) return 'pH';
    if (t.contains('do') || t.contains('oxygen') || t.contains('oxy')) return 'Oxy hòa tan';
    if (t.contains('salin') || t.contains('salt')) return 'Độ mặn';
    if (t.contains('nh3') || t.contains('ammon')) return 'Amoniac';
    if (type.trim().isEmpty) return 'Thông số nước';
    return type;
  }

  String _waterMetricUnit(String type) {
    final t = type.toLowerCase();
    if (t.contains('temp')) return '°C';
    if (t.contains('ph')) return '';
    if (t.contains('do') || t.contains('oxygen')) return 'mg/L';
    if (t.contains('salin') || t.contains('salt')) return 'ppt';
    return '';
  }

  Future<DeviceSummary?> _fetchDevices(String? farmingAreaId) async {
    final res = await _dio.get(
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
              map['isOnline'] == true || status == 'active' || status == 'online';
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
    final res = await _dio.get(
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
      iotOnlinePercentage: (data['iotOnlinePercentage'] as num?)?.toDouble() ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.tryParse(data['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<FarmHealthScore?> _fetchHealthMetrics(String? farmingAreaId) async {
    final res = await _dio.get(
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
          ? DateTime.tryParse(data['lastAiUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      waterQualityScore: (data['waterQualityScore'] as num?)?.toInt() ?? 0,
      crabHealthScore: (data['crabHealthScore'] as num?)?.toInt() ?? 0,
      deviceStatusScore: (data['deviceStatusScore'] as num?)?.toInt() ?? 0,
      explanation: data['explanation']?.toString() ?? '',
    );
  }

  Future<AiRecommendation?> _fetchAiRecommendation(String? farmingAreaId) async {
    final res = await _dio.get(
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
      confidencePercentage: (map['confidencePercentage'] as num?)?.toInt() ?? 80,
      priority: priority,
      reason: map['reason']?.toString() ?? '',
      optimalTimeframe: map['optimalTimeframe']?.toString() ?? '',
      expectedImpact: map['expectedImpact']?.toString() ?? '',
      hasActiveRecommendation: true,
    );
  }

  Future<List<TodayTaskItem>?> _fetchTodayTasks(String? farmingAreaId) async {
    final res = await _dio.get(
      ApiConstants.operationsToday,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final list = _extractList(res.data);
    if (list == null) return const [];

    return list.map((item) {
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
            ? DateTime.tryParse(map['deadline'].toString()) ?? DateTime.now()
            : DateTime.now(),
        priority: priority,
        isCompleted: map['isCompleted'] == true,
      );
    }).whereType<TodayTaskItem>().toList();
  }

  Future<List<RecentActivityItem>?> _fetchRecentActivities(String? farmingAreaId) async {
    final res = await _dio.get(
      ApiConstants.operationsRecent,
      queryParameters: _areaQuery(farmingAreaId),
    );
    if (res.statusCode != 200 || res.data == null) return null;
    final list = _extractList(res.data);
    if (list == null) return const [];

    return list.map((item) {
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
            ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }).whereType<RecentActivityItem>().toList();
  }

  HomeStateData _emptyDataState() {
    final now = DateTime.now();
    return HomeStateData(
      operatorName: 'Cán bộ vận hành',
      selectedFarmId: null,
      selectedFarmName: 'Chưa có dữ liệu trang trại',
      availableFarms: const [],
      isOnline: false,
      unreadNotificationsCount: 0,
      farmSummary: FarmSummary(
        totalBoxes: 0,
        totalCrabs: 0,
        activeBoxes: 0,
        openAlerts: 0,
        iotOnlinePercentage: 0,
        lastUpdated: now,
      ),
      healthScore: FarmHealthScore(
        score: 0,
        statusLevel: HealthStatusLevel.good,
        statusLabel: 'Chưa có chỉ số',
        deltaVsYesterday: 0,
        lastAiUpdated: now,
        waterQualityScore: 0,
        crabHealthScore: 0,
        deviceStatusScore: 0,
        explanation: 'Chưa kết nối dữ liệu từ Server.',
      ),
      aiRecommendation: AiRecommendation.empty,
      topAlerts: const [],
      waterMetrics: const [],
      todayTasks: const [],
      deviceSummary: const DeviceSummary(
        esp32Online: 0,
        esp32Total: 0,
        cameraOnline: 0,
        cameraTotal: 0,
        pumpRunning: 0,
        pumpTotal: 0,
        valveReady: 0,
        valveTotal: 0,
      ),
      recentActivities: const [],
      isOfflineCached: true,
      lastSyncedAt: now,
    );
  }
}
