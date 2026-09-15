import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/dashboard_ui.dart';
import '../models/farm_dashboard_overview.dart';
import '../services/dashboard_env_trend_service.dart';
import '../theme/dashboard_theme.dart';
import '../utils/farm_dashboard_mapper.dart';
import '../models/water_quality.dart';
import '../utils/live_trend_bootstrap.dart';
import 'cloud_api_client.dart';

/// Tổng quan Dashboard + poll cảm biến realtime (3s).
class FarmDashboardService extends ChangeNotifier {
  FarmDashboardService({
    required AuthSession session,
    CloudApiClient? api,
  })  : _session = session,
        _api = api ?? CloudApiClient(),
        envTrend = DashboardEnvTrendService();

  static const livePollInterval = Duration(seconds: 3);
  static const overviewRefreshEvery = 5;

  AuthSession _session;
  final CloudApiClient _api;
  final DashboardEnvTrendService envTrend;

  FarmDashboardOverview? overview;
  bool loading = false;
  String? error;
  DateTime? lastSensorAt;

  Timer? _liveTimer;
  int _liveTicks = 0;
  List<EnvParameter> _liveEnvParams = const [];
  final List<double> _liveDoSeries = [];

  String get token => _session.token;
  String get farmId => _session.selectedFarm.id;

  bool get hasApiData => overview != null;
  bool get isLive => _liveTimer != null;
  List<double> get liveDoSeries =>
      _liveDoSeries.isNotEmpty ? List.unmodifiable(_liveDoSeries) : const [];

  void updateSession(AuthSession session) {
    _session = session;
    stopLiveRefresh();
    overview = null;
    error = null;
    _liveEnvParams = const [];
    _liveDoSeries.clear();
    envTrend.stop();
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (loading && !force) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      overview = await _api.fetchFarmDashboardOverview(token, farmId);
      error = null;
      _seedTrendFromOverview();
      startLiveRefresh();
    } catch (e) {
      error = '$e';
      overview = null;
      stopLiveRefresh();
      envTrend.stop();
      envTrend.start();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void startLiveRefresh() {
    stopLiveRefresh();
    unawaited(_pollSensors(silent: true));
    _liveTimer = Timer.periodic(livePollInterval, (_) {
      unawaited(_pollSensors(silent: true));
      _liveTicks++;
      if (_liveTicks % overviewRefreshEvery == 0) {
        unawaited(_refreshOverviewSilent());
      }
    });
    notifyListeners();
  }

  void stopLiveRefresh() {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveTicks = 0;
  }

  Future<void> _pollSensors({bool silent = true}) async {
    try {
      final live = await _api.fetchIotLive(token, farmingAreaId: farmId);
      if (live.isEmpty) return;

      _liveEnvParams = FarmDashboardOverview.envFromLive(live)
          .map(mapEnvParam)
          .toList();
      DateTime? latest;
      for (final row in live) {
        final raw = row['latestMeasuredAt'] ?? row['LatestMeasuredAt'];
        final dt = raw == null ? null : DateTime.tryParse(raw.toString());
        if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
      }
      lastSensorAt = latest ?? DateTime.now();

      double? doVal;
      for (final row in live) {
        final type = (row['sensorType'] ?? '').toString().toLowerCase();
        if (type.contains('do') || type.contains('oxy')) {
          doVal = (row['latestValue'] as num?)?.toDouble();
          break;
        }
      }
      if (doVal != null) {
        _liveDoSeries.add(doVal);
        while (_liveDoSeries.length > 12) {
          _liveDoSeries.removeAt(0);
        }
      }

      notifyListeners();
    } catch (e) {
      if (e is CloudApiException && e.statusCode == 401) {
        // Token hết hạn: dừng poll, nếu không Timer sẽ gọi 401 mãi mãi.
        error = 'Phiên đăng nhập hết hạn';
        stopLiveRefresh();
      } else if (!silent) {
        rethrow;
      }
    }
  }

  Future<void> _refreshOverviewSilent() async {
    try {
      final next = await _api.fetchFarmDashboardOverview(token, farmId);
      overview = next;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _bootstrapLiveTrend(String areaId, WaterTrendPoint anchor) async {
    try {
      final history = await _api.fetchAreaSensorTrend(token, areaId, minutes: 30);
      if (history.length >= 8) {
        envTrend.startLiveFromHistory(history);
      } else {
        envTrend.startLiveFromAnchor(
          ph: anchor.ph,
          temp: anchor.temperature,
          dissolvedOxygen: anchor.dissolvedOxygen,
        );
      }
    } catch (_) {
      envTrend.startLiveFromAnchor(
        ph: anchor.ph,
        temp: anchor.temperature,
        dissolvedOxygen: anchor.dissolvedOxygen,
      );
    }
    _liveDoSeries
      ..clear()
      ..addAll(doSeriesFromBuffer(envTrend.rawBuffer));
    if (_liveDoSeries.isEmpty && anchor.dissolvedOxygen != null) {
      _liveDoSeries.add(anchor.dissolvedOxygen!);
    }
  }

  void _seedTrendFromOverview() {
    envTrend.stop();
    envTrend.start();
    _liveDoSeries.clear();
  }

  @override
  void dispose() {
    stopLiveRefresh();
    envTrend.dispose();
    super.dispose();
  }

  int get healthScore => overview?.healthScore ?? 0;

  String get statusMessage => overview?.statusMessage ??
      (error != null
          ? 'Không tải được dữ liệu — kiểm tra Cloud và thử lại'
          : 'Đang tải tổng quan trại...');

  String get assistantHint =>
      overview?.assistantHint ??
      'Kết nối API để xem gợi ý vận hành theo dữ liệu thật.';

  String get devicesOnline => overview?.devicesOnline ?? '—';

  int get alertCount => overview?.alertCount ?? 0;

  List<KpiItem> get summaryKpis =>
      _mapKpis(overview?.summaryKpis, _emptySummaryKpis);

  List<KpiItem> get kpiRow1 => _mapKpis(overview?.kpiRow1, _emptyDetailKpis1);

  List<KpiItem> get kpiRow2 => _mapKpis(overview?.kpiRow2, _emptyDetailKpis2);

  List<StatusSegment> get statusSegments => hasApiData
      ? overview!.statusSegments.map(mapStatusSegment).toList()
      : _emptyStatusSegments;

  List<EnvParameter> get environmentParams =>
      _liveEnvParams.isNotEmpty
          ? _liveEnvParams
          : (hasApiData && overview!.environmentParams.isNotEmpty
              ? overview!.environmentParams.map(mapEnvParam).toList()
              : const []);

  List<AlertItem> get alerts => hasApiData && overview!.alerts.isNotEmpty
      ? overview!.alerts.map(mapAlert).toList()
      : const [];

  DashboardChartsDto? get charts => overview?.charts;

  List<KpiItem> _mapKpis(
    List<DashboardKpiDto>? dtos,
    List<KpiItem> emptyFallback,
  ) {
    if (!hasApiData) return emptyFallback;
    if (dtos == null || dtos.isEmpty) return emptyFallback;
    return dtos.map(mapKpi).toList();
  }

  static final _emptySummaryKpis = [
    const KpiItem(label: 'Tổng Số Cua', value: '0'),
    const KpiItem(label: 'Lứa Nuôi', value: '0'),
    const KpiItem(label: 'Tỷ Lệ Sống', value: '—'),
    const KpiItem(label: 'Doanh Thu (Dự kiến)', value: '—'),
  ];

  static final _emptyDetailKpis1 = [
    const KpiItem(label: 'Tổng cua', value: '0'),
    const KpiItem(label: 'Lứa nuôi', value: '0'),
    const KpiItem(label: 'Cua khỏe', value: '0'),
    const KpiItem(label: 'Theo dõi', value: '0'),
    const KpiItem(label: 'Nguy cơ', value: '0'),
    const KpiItem(label: 'Lột xác', value: '0'),
  ];

  static final _emptyDetailKpis2 = [
    const KpiItem(label: 'Cua chết', value: '0'),
    const KpiItem(label: 'Thu hoạch', value: '0'),
    const KpiItem(label: 'Tỷ lệ sống', value: '—'),
    const KpiItem(label: 'Doanh thu', value: '—'),
    const KpiItem(label: 'Health', value: '—'),
    const KpiItem(label: 'Thiết bị', value: '—'),
    const KpiItem(label: 'Cảnh báo', value: '0'),
  ];

  static final _emptyStatusSegments = [
    StatusSegment(label: 'CUA KHỎE', count: 0, color: DashboardColors.healthy),
    StatusSegment(label: 'THEO DÕI', count: 0, color: DashboardColors.monitoring),
    StatusSegment(label: 'LỘT XÁC', count: 0, color: DashboardColors.molting),
    StatusSegment(label: 'NGUY CƠ', count: 0, color: DashboardColors.risk),
    StatusSegment(label: 'CUA CHẾT', count: 0, color: DashboardColors.dead),
  ];
}
