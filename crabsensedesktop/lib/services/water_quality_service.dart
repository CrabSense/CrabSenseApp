import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/water_quality.dart';
import 'cloud_api_client.dart';
import 'qualified_live_water.dart';
import '../models/scoped_history_snapshot.dart';
import '../models/verified_history_table.dart';
import 'water_quality_cloud_merge.dart';

/// Poll `/api/iot/live` — chỉ giữ cảm biến thật, không mock.
class WaterQualityService extends ChangeNotifier {
  WaterQualityService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient();

  AuthSession _session;
  final CloudApiClient _api;

  void updateSession(AuthSession session) {
    if (_disposed) return;
    _session = session;
    _areaFilterId = null;
    _deviceFilter = null;
    _reset();
    if (_pollActive) {
      unawaited(_liveCycle(full: true));
    } else {
      _notifyDeferred();
    }
  }

  static const _pollInterval = Duration(seconds: 3);
  static const _staleAfter = Duration(minutes: 2);

  static const chartRangeLabels = ['1H', '6H', '24H', '7 Ngày', '30 Ngày'];
  static const chartRangeMinutes = [60, 6 * 60, 24 * 60, 7 * 24 * 60, 30 * 24 * 60];

  List<WaterSensorReading> _readings = [];
  List<RealtimeChartPoint> _chartSeries = [];
  List<RealtimeTableRow> _recentRows = [];
  List<RealtimeDeviceLink> _devices = [];
  String? _historySensorId;
  int _historyGeneration = 0;
  bool _historyBusy = false;
  DateTime? _historyAsOf;
  DateTime? _historyLoadedAt;
  VerifiedHistoryTable? _historyTable;
  Timer? _historyExpiry;
  String? _historyError;
  int _chartRangeIndex = 0;
  String? _areaFilterId;
  String? _deviceFilter;
  String _sensorGroup = 'all';
  bool _showThreshold = true;
  DateTime? _lastCloudOkAt;

  bool _loading = false;
  bool _cloudLive = false;
  String? _cloudError;
  String? _deviceCode;
  DateTime? _lastRealtimeAt;

  Timer? _pollTimer;
  bool _pollActive = false;
  bool _realtimeBusy = false;
  bool _disposed = false;
  int _generation = 0;
  bool _current(int generation) => !_disposed && generation == _generation;
  void _notifyDeferred() {
    if (!_disposed) Future.microtask(() { if (!_disposed) notifyListeners(); });
  }
  void _reset() {
    ++_generation;
    _readings = [];
    _devices = [];
    _chartSeries = [];
    _recentRows = [];
    _lastRealtimeAt = null;
    _lastCloudOkAt = null;
    _deviceCode = null;
    _clearHistory(resetSelection: true);
    _cloudLive = false;
    _cloudError = null;
    _loading = false;
    _realtimeBusy = false;
  }

  List<WaterSensorReading> get readings => List.unmodifiable(_scoped(_readings));
  List<WaterSensorReading> get allReadings => List.unmodifiable(_readings);
  bool _within(DateTime? at, Duration limit) {
    if(at==null) return false;
    final age=DateTime.now().difference(at);
    return !age.isNegative && age<limit;
  }
  bool get _liveProofFresh => _cloudLive &&
      _within(_lastCloudOkAt,const Duration(seconds:15));
  int get historyRevision => _historyGeneration;
  VerifiedHistoryTable? get historyTable => !_disposed &&
      _within(_historyLoadedAt,const Duration(minutes:1)) &&
      _liveProofFresh && chartReading!=null ? _historyTable : null;
  List<RealtimeChartPoint> get chartSeries =>
      historyTable!=null ? List.unmodifiable(_chartSeries) : const [];

  String? exportScopedCsv(int expectedRevision) {
    final table=historyTable;
    if(expectedRevision!=historyRevision || table==null || table.rows.isEmpty) return null;
    return table.toCsv();
  }
  List<RealtimeTableRow> get recentRows => List.unmodifiable(_recentRows);
  List<RealtimeDeviceLink> get devices => List.unmodifiable(_devices);
  String? get areaFilterId => _areaFilterId ?? _session.selectedFarm.id;
  String? get deviceFilter => _deviceFilter;
  String get sensorGroup => _sensorGroup;
  bool get showThreshold => _showThreshold;
  DateTime? get lastCloudOkAt => _lastCloudOkAt;
  List<WaterSensorType> get availableMetrics =>
      {for (final r in _readings) r.type}.toList()
        ..sort(
          (a, b) => WaterSensorType.cloudFirst
              .indexOf(a)
              .compareTo(WaterSensorType.cloudFirst.indexOf(b)),
        );

  WaterSensorType? get chartMetric => chartReading?.type;
  String? get historySensorId => _historySensorId;
  DateTime? get historyAsOf => _historyAsOf;
  String? get historyError => _historyError;
  List<WaterSensorReading> get historySensors => readings.where((r) =>
      r.historyScopeKnown && r.sensorId != null && r.wireSensorType != null &&
      (r.wireUnit?.isNotEmpty ?? false)).toList();
  WaterSensorReading? get chartReading => historySensors.where((r) =>
      r.sensorId == _historySensorId).firstOrNull;
  int get chartRangeIndex => _chartRangeIndex;
  String get chartRangeLabel => chartRangeLabels[_chartRangeIndex];
  int get chartRangeMinutesValue => chartRangeMinutes[_chartRangeIndex];
  bool get isLoading => _loading;
  bool get chartLoading => _historyBusy;
  bool get cloudLive => _cloudLive;
  String? get cloudError => _cloudError;
  String? get deviceCode => _deviceCode;
  DateTime? get lastRealtimeAt => _lastRealtimeAt;

  bool get isFresh {
    final at = _lastRealtimeAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < _staleAfter;
  }

  bool get isLive => _cloudLive && isFresh && _readings.isNotEmpty;

  bool get deviceOnline =>
      _devices.any((d) => d.online);

  String get lastUpdateLabel {
    final at = _lastRealtimeAt;
    if (at == null) return 'Chưa có dữ liệu';
    final ago = DateTime.now().difference(at);
    if (ago.inSeconds < 15) return 'Vừa xong';
    if (ago.inMinutes < 1) return '${ago.inSeconds} giây trước';
    if (ago.inMinutes < 60) return '${ago.inMinutes} phút trước';
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
  }

  String get lastUpdateClock {
    final at = _lastRealtimeAt;
    if (at == null) return '—';
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:'
        '${at.second.toString().padLeft(2, '0')}';
  }

  List<RealtimeLocationGroup> get locationGroups {
    final byLoc = <String, List<WaterSensorReading>>{};
    for (final r in _readings) {
      final key = (r.location ?? '').trim();
      if (key.isEmpty) continue;
      byLoc.putIfAbsent(key, () => []).add(r);
    }
    if (byLoc.length < 2) return const [];
    return byLoc.entries
        .map((e) => RealtimeLocationGroup(name: e.key, readings: e.value))
        .toList();
  }

  List<RealtimeWaterAlert> get thresholdAlerts {
    return _readings
        .where(
          (r) =>
              r.status == WaterSensorStatus.exceeded ||
              r.status == WaterSensorStatus.danger ||
              r.status == WaterSensorStatus.offline,
        )
        .map(
          (r) => RealtimeWaterAlert(
            title: r.status == WaterSensorStatus.offline
                ? '${r.type.label} mất tín hiệu'
                : '${r.type.label} ${r.status.label.toLowerCase()}',
            detail: r.offline ? 'Không nhận được mẫu' : 'Hiện tại: ${r.displayValue}',
            status: r.status,
          ),
        )
        .toList();
  }

  void startLiveUpdates() {
    if (_disposed || _pollActive) return;
    _pollActive = true;
    _pollTimer?.cancel();
    unawaited(_liveCycle(full: true));
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_liveCycle(full: false));
    });
  }

  void stopLiveUpdates() {
    _pollActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _reset();
  }

  Future<void> _liveCycle({required bool full}) => refresh(full: full);

  @override
  void dispose() {
    _disposed = true;
    stopLiveUpdates();
    super.dispose();
  }

  Future<void> refresh({bool full = true}) async {
    if (_disposed || (!full && _realtimeBusy)) return;
    final generation = ++_generation;
    final area = areaFilterId;
    final token = _session.token;
    if (area == null || area.isEmpty ||
        !UserRoles.canUseDesktop(_session.user.role) ||
        !_session.farms.any((f) => f.id == area) && _session.selectedFarm.id != area) {
      _reset();
      _cloudError = 'Chưa có khu được xác minh.';
      _notifyDeferred();
      return;
    }
    _realtimeBusy = true;
    _loading = full;
    if (full) {
      _clearHistory(resetSelection: true);
      _readings = [];
      _devices = [];
      _lastRealtimeAt = null;
      _cloudLive = false;
      _cloudError = null;
      _notifyDeferred();
    }
    try {
      final live = await _api.fetchIotLive(token, farmingAreaId: area)
          .timeout(const Duration(seconds:10));
      if (!_current(generation)) return;
      final now = DateTime.now().toUtc();
      final previousSelection = _historyKey(chartReading);
      final hadFreshLive = _liveProofFresh;
      _readings = decodeQualifiedDesktopLive(live, areaId: area, now: now);
      _devices = _devicesFromLive(live.where((r) => r['farmingAreaId'] == area).toList());
      _deviceCode = _devices.isEmpty ? null : _devices.first.code;
      if (_deviceFilter != null && !_devices.any((d) => d.code == _deviceFilter)) {
        _deviceFilter = null;
      }
      _lastRealtimeAt = null;
      for (final r in _readings) {
        final at = r.measuredAt!;
        if (_lastRealtimeAt == null || at.isAfter(_lastRealtimeAt!)) {
          _lastRealtimeAt = at;
        }
      }
      _cloudLive = true;
      _cloudError = null;
      _lastCloudOkAt = now;
      if (!hadFreshLive || previousSelection != _historyKey(chartReading)) {
        _clearHistory(resetSelection: true);
      }
    } catch (_) {
      if (!_current(generation)) return;
      _readings = [];
      _devices = [];
      _clearHistory(resetSelection: true);
      _recentRows = [];
      _lastRealtimeAt = null;
      _lastCloudOkAt = null;
      _deviceCode = null;
      _cloudLive = false;
      _cloudError = 'Không thể xác minh dữ liệu realtime.';
    } finally {
      if (_current(generation)) {
        _loading = false;
        _realtimeBusy = false;
        _notifyDeferred();
      }
    }
  }

  List<RealtimeDeviceLink> _devicesFromLive(List<Map<String, dynamic>> live) {
    final map = <String, RealtimeDeviceLink>{};
    for (final row in live) {
      final code = (row['deviceCode'] ?? row['DeviceCode'] ?? '').toString();
      if (code.isEmpty) continue;
      final status =
          (row['deviceStatus'] ?? row['DeviceStatus'] ?? '').toString();
      final seen = DateTime.tryParse(
        (row['sensorLastSeenAt'] ??
                row['SensorLastSeenAt'] ??
                row['latestMeasuredAt'] ??
                row['LatestMeasuredAt'] ??
                '')
            .toString(),
      );
      final online = status.toLowerCase() == 'online';
      final prev = map[code];
      if (prev == null || (online && !prev.online)) {
        map[code] = RealtimeDeviceLink(
          code: code,
          online: online,
          lastSeen: seen ?? prev?.lastSeen,
        );
      }
    }
    return map.values.toList();
  }

  String? _historyKey(WaterSensorReading? r) => r == null ? null :
      jsonEncode([r.sensorId,r.observedRowId,r.wireSensorType,r.wireUnit,r.deviceCode]);

  void _clearHistory({bool resetSelection = false}) {
    ++_historyGeneration;
    _historyExpiry?.cancel();
    _historyExpiry = null;
    _historyBusy = false;
    _chartSeries = [];
    _historyAsOf = null;
    _historyLoadedAt = null;
    _historyTable = null;
    _historyError = null;
    if (resetSelection) _historySensorId = null;
  }

  void selectHistorySensor(String? id) {
    _clearHistory(resetSelection: true);
    if (historySensors.any((r) => r.sensorId == id)) _historySensorId = id;
    _notifyDeferred();
  }

  /// Explicit request only. The independent history generation is not advanced
  /// by successful polling of the same sensor scope.
  Future<void> refreshTrend({bool quiet = false}) async {
    if (_disposed || _historyBusy || !_liveProofFresh) return;
    final reading = chartReading;
    final area = areaFilterId;
    if (reading == null || area == null) return;
    final key = _historyKey(reading);
    final token = _session.token;
    final user = _session.user.id;
    final range = chartRangeMinutesValue;
    _clearHistory();
    final generation = _historyGeneration;
    bool current() => !_disposed && generation == _historyGeneration &&
        token == _session.token && user == _session.user.id &&
        area == areaFilterId && key == _historyKey(chartReading) &&
        range == chartRangeMinutesValue && _cloudLive;
    _historyBusy = true;
    _notifyDeferred();
    try {
      final end = DateTime.now().toUtc();
      final query = ScopedHistoryQuery(areaId:area,sensorId:reading.sensorId!,
          rowId:reading.observedRowId,from:end.subtract(Duration(minutes:range)),to:end);
      final pages = <Map<String,dynamic>>[];
      String? cutoff;
      for (var page = 1; page <= 20; page++) {
        if (!current()) return;
        if (!_liveProofFresh) throw const FormatException('Live proof expired');
        final data = await _api.fetchScopedHistoryPage(token,areaId:area,
          sensorId:query.sensorId,rowId:query.rowId,from:query.from,to:query.to,
          page:page,asOf:cutoff);
        if (!current()) return;
        if (!_liveProofFresh) throw const FormatException('Live proof expired');
        if (data['asOf'] is! String || data['hasMore'] is! bool ||
            data['pageSize'] != 250 || data['sensorActive'] != true ||
            data['farmingRowId'] != reading.observedRowId ||
            data['sensorType'] != reading.wireSensorType ||
            data['unit'] != reading.wireUnit) {
          throw const FormatException('Invalid selected sensor history');
        }
        cutoff ??= data['asOf'] as String;
        if (data['asOf'] != cutoff) throw const FormatException('History cutoff changed');
        pages.add(data);
        if (data['hasMore'] == false) break;
      }
      final snapshot = ScopedHistorySnapshot.fromPages(query,pages);
      if (snapshot.asOf.isAfter(DateTime.now().toUtc().add(const Duration(seconds:1)))) {
        throw const FormatException('Invalid history cutoff');
      }
      final table=VerifiedHistoryTable.fromSnapshot(snapshot);
      final points=[
        for(final row in table.rows) RealtimeChartPoint(
          xMinutes:DateTime.parse(row.measuredAt).toUtc().difference(query.from).inMicroseconds/60000000,
          label:WaterQualityCloudMerge.axisLabelFor(DateTime.parse(row.measuredAt),range),
          timestamp:DateTime.parse(row.measuredAt).toUtc(),value:row.value.toDouble()),
      ];
      points.sort((a,b)=>a.timestamp.compareTo(b.timestamp));
      if (!current()) return;
      _chartSeries = points;
      _historyTable = table;
      _historyAsOf = snapshot.asOf;
      _historyLoadedAt = DateTime.now();
      _historyExpiry = Timer.periodic(const Duration(seconds:1), (_) {
        if (!current() || historyTable == null) {
          _clearHistory();
          _historyError = 'Lịch sử hết hạn hoặc mất xác minh online. Hãy tải lại.';
          _notifyDeferred();
        }
      });
    } catch (_) {
      if (current()) {
        _chartSeries = [];
        _historyAsOf = null;
        _historyLoadedAt = null;
        _historyTable = null;
        _historyError = 'Không xác minh được lịch sử hoặc vượt giới hạn 5.000 mẫu.';
      }
    } finally {
      if (current()) {
        _historyBusy = false;
        _notifyDeferred();
      }
    }
  }

  String get area => _session.selectedFarm.name;
  String get device => _deviceCode ?? '';
  String get timeRange => chartRangeLabel;
  String get statusFilter => 'Tất cả';
  List<WaterSensorReading> get filteredReadings => readings;
  List<WaterTrendPoint> get trendPoints => const [];
  List<WaterHistoryRow> get history => const [];
  String get aiInsight => '';
  List<String> get aiRecommendations => const [];
  void setArea(String v) {}
  void setDevice(String v) {}
  void setTimeRange(String v) => refresh(full: true);
  void setStatusFilter(String v) {}

  List<WaterSensorReading> _scoped(List<WaterSensorReading> src) {
    var list = src;
    final device = _deviceFilter;
    if (device != null && device.isNotEmpty) {
      list = list.where((r) => (r.deviceCode ?? '') == device).toList();
    }
    switch (_sensorGroup) {
      case 'water':
        list = list
            .where((r) =>
                r.type == WaterSensorType.ph ||
                r.type == WaterSensorType.tds ||
                r.type == WaterSensorType.salinity ||
                r.type == WaterSensorType.dissolvedOxygen)
            .toList();
      case 'temp':
        list = list.where((r) => r.type == WaterSensorType.temperature).toList();
      case 'other':
        list = list
            .where((r) =>
                r.type != WaterSensorType.temperature &&
                r.type != WaterSensorType.ph &&
                r.type != WaterSensorType.tds)
            .toList();
    }
    return list;
  }

  WaterSensorReading? readingOf(WaterSensorType type) {
    final matches = readings.where((r) => r.type == type).toList();
    return matches.length == 1 ? matches.single : null;
  }

  void setAreaId(String? id) {
    final next = (id == null || id.isEmpty) ? _session.selectedFarm.id : id;
    if (next == areaFilterId) return;
    _areaFilterId = next;
    _deviceFilter = null;
    _reset();
    unawaited(_liveCycle(full: true));
  }

  void setDeviceCode(String? code) {
    final next = (code == null || code.isEmpty) ? null : code;
    if (next == _deviceFilter) return;
    _deviceFilter = next;
    _clearHistory(resetSelection: true);
    notifyListeners();
  }

  void setSensorGroup(String group) {
    if (_sensorGroup == group) return;
    _sensorGroup = group;
    _clearHistory(resetSelection: true);
    notifyListeners();
  }

  void setShowThreshold(bool v) {
    if (_showThreshold == v) return;
    _showThreshold = v;
    notifyListeners();
  }

  List<List<RealtimeChartPoint>> get chartSegments {
    final points = chartSeries;
    if (points.isEmpty) return const [];
    final gap = _gapThreshold;
    final segs = <List<RealtimeChartPoint>>[];
    var cur = <RealtimeChartPoint>[points.first];
    for (var i = 1; i < points.length; i++) {
      final dt = points[i].timestamp.difference(points[i - 1].timestamp);
      if (dt > gap) {
        segs.add(cur);
        cur = [points[i]];
      } else {
        cur.add(points[i]);
      }
    }
    segs.add(cur);
    return segs;
  }

  Duration get _gapThreshold {
    final m = chartRangeMinutesValue;
    if (m <= 60) return const Duration(seconds: 90);
    if (m <= 360) return const Duration(minutes: 8);
    if (m <= 1440) return const Duration(minutes: 20);
    return const Duration(hours: 3);
  }

  Future<void> refreshRecent() async {
    _recentRows = [];
    _notifyDeferred();
  }

  String exportRecentCsv() {
    final buf = StringBuffer('Thoi gian,Nhiet do,pH,TDS,Trang thai\n');
    for (final r in _recentRows) {
      buf.writeln(
        '${r.at.toIso8601String()},'
        '${r.temperature?.toString() ?? ''},'
        '${r.ph?.toString() ?? ''},'
        '${r.tds?.toString() ?? ''},'
        '${r.status}',
      );
    }
    return buf.toString();
  }

  void setChartMetric(WaterSensorType type) {
    final matches = historySensors.where((r)=>r.type==type).toList();
    selectHistorySensor(matches.length == 1 ? matches.single.sensorId : null);
  }

  void setChartRangeIndex(int i) {
    _chartRangeIndex = i.clamp(0,chartRangeLabels.length-1);
    _clearHistory();
    _notifyDeferred();
  }
}
