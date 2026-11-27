import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/water_quality.dart';
import 'qualified_live_water.dart';
import '../models/dashboard_ui.dart';
import '../models/farm_dashboard_overview.dart';
import '../services/dashboard_env_trend_service.dart';
import '../theme/dashboard_theme.dart';
import '../utils/farm_dashboard_mapper.dart';
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
  List<WaterSensorReading> _qualified = const [];
  DateTime? _qualifiedAt;
  String? _qualifiedArea;
  int _pollGeneration=0;
  bool _pollBusy=false;

  List<WaterSensorReading> qualifiedReadingsFor(String area) {
    final age=_qualifiedAt==null ? null : DateTime.now().difference(_qualifiedAt!);
    return area.isNotEmpty && area==farmId && area==_qualifiedArea && age!=null &&
        !age.isNegative && age<const Duration(seconds:15) ? List.unmodifiable(_qualified) : const [];
  }

  void _clearQualified() {
    _qualified=const [];_qualifiedAt=null;_qualifiedArea=null;
    lastSensorAt=null;_liveEnvParams=const [];_liveDoSeries.clear();
  }

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
    ++_pollGeneration;_pollBusy=false;_clearQualified();
  }

  Future<void> _pollSensors({bool silent = true}) async {
    if(_pollBusy)return;
    final generation=_pollGeneration,area=farmId,bearer=token;
    if(area.isEmpty || area=='default' || bearer.isEmpty){_clearQualified();return;}
    _pollBusy=true;
    bool current()=>generation==_pollGeneration && area==farmId && bearer==token;
    try {
      final live=await _api.fetchIotLive(bearer,farmingAreaId:area).timeout(const Duration(seconds:10));
      if(!current())return;
      _qualified=decodeQualifiedDesktopLive(live,areaId:area,now:DateTime.now().toUtc());
      _qualifiedAt=DateTime.now();_qualifiedArea=area;
      lastSensorAt=null;
      for(final r in _qualified){
        if(lastSensorAt==null || r.measuredAt!.isAfter(lastSensorAt!))lastSensorAt=r.measuredAt;
      }
      // Legacy status widget cannot express unknown as green: use warning
      // unless a current configured limit explicitly qualifies the value.
      _liveEnvParams=[
        for(final r in _qualified)
          EnvParameter(icon:r.type.icon,label:r.type.label+' · '+(r.sensorCode??r.sensorId??'—'),
            value:(r.value==0?'0':r.value.toString())+' '+r.unit,
            status:r.status==WaterSensorStatus.normal ? ParamStatus.good : ParamStatus.warning),
      ];
      notifyListeners();
    } catch(e) {
      if(!current())return;
      _clearQualified();
      if(e is CloudApiException && e.statusCode==401){
        error='Phiên đăng nhập hết hạn';stopLiveRefresh();
      }
      notifyListeners();
      if(!silent)rethrow;
    } finally {
      if(current())_pollBusy=false;
    }
  }

  Future<void> _refreshOverviewSilent() async {
    try {
      final next = await _api.fetchFarmDashboardOverview(token, farmId);
      overview = next;
      notifyListeners();
    } catch (_) {}
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
      qualifiedReadingsFor(farmId).isNotEmpty ? _liveEnvParams : const [];

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
