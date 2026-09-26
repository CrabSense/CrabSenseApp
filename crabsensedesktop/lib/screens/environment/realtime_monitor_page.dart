import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../models/farm_alert.dart';
import '../../models/iot_device.dart';
import '../../models/water_quality.dart';
import '../../navigation/app_route.dart';
import '../../services/alert_service.dart';
import '../../services/controller_service.dart';
import '../../services/water_quality_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';
import '../devices/add_controller_dialog.dart';
import '../devices/edit_controller_dialog.dart';

const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kSlate = Color(0xFF94A3B8);
const _kLive = Duration(seconds: 15);
const _kDelayed = Duration(seconds: 60);

enum _Cloud { online, degraded, offline }

enum _Fresh { live, delayed, stale, noSignal, notConfigured }

class RealtimeMonitorPage extends StatefulWidget {
  const RealtimeMonitorPage({
    super.key,
    required this.service,
    required this.alertService,
    this.controllerService,
    this.session,
    this.onNavigate,
  });

  final WaterQualityService service;
  final AlertService alertService;
  final ControllerService? controllerService;
  final AuthSession? session;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<RealtimeMonitorPage> createState() => _RealtimeMonitorPageState();
}

class _RealtimeMonitorPageState extends State<RealtimeMonitorPage> {
  WaterQualityService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    widget.alertService.addListener(_onUpdate);
    widget.controllerService?.addListener(_onUpdate);
    _svc.startLiveUpdates();
    widget.alertService.load();
    widget.controllerService?.load();
  }

  @override
  void dispose() {
    _svc.stopLiveUpdates();
    _svc.removeListener(_onUpdate);
    widget.alertService.removeListener(_onUpdate);
    widget.controllerService?.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  List<FarmSummary> get _areas {
    final farms = widget.session?.farms ?? const <FarmSummary>[];
    if (farms.isNotEmpty) return farms;
    final selected = widget.session?.selectedFarm;
    return selected == null ? const [] : [selected];
  }

  List<String> get _deviceCodes {
    final fromLive = _svc.devices.map((d) => d.code).where((e) => e.isNotEmpty);
    final fromCtrl = (widget.controllerService?.items ?? const <IoTDevice>[])
        .map((d) => d.deviceCode)
        .where((e) => e.isNotEmpty);
    return {...fromLive, ...fromCtrl}.toList()..sort();
  }

  IoTDevice? get _controller {
    final code = _svc.deviceFilter ?? _svc.deviceCode;
    if (code == null) return null;
    for (final d in widget.controllerService?.items ?? const <IoTDevice>[]) {
      if (d.deviceCode == code || d.deviceName == code) return d;
    }
    return null;
  }

  _Cloud get _cloud {
    if (_svc.cloudLive) {
      final ok = _svc.lastCloudOkAt;
      if (ok != null && DateTime.now().difference(ok) > _kLive) {
        return _Cloud.degraded;
      }
      return _Cloud.online;
    }
    return _Cloud.offline;
  }

  bool get _controllerOnline {
    final d = _controller;
    if (d != null) return d.isOnline;
    return _svc.deviceOnline;
  }

  _Fresh _freshOf(WaterSensorReading? r) {
    if (r == null) return _Fresh.notConfigured;
    if (r.measuredAt == null) return _Fresh.noSignal;
    final age = DateTime.now().difference(r.measuredAt!.toLocal());
    if (!_controllerOnline) return _Fresh.stale;
    if (age <= _kLive) return _Fresh.live;
    if (age <= _kDelayed) return _Fresh.delayed;
    return _Fresh.stale;
  }

  int get _liveCount => [
        WaterSensorType.temperature,
        WaterSensorType.ph,
        WaterSensorType.tds,
      ].where((t) => _freshOf(_svc.readingOf(t)) == _Fresh.live).length;

  int get _sensorTotal {
    final n = [
      _svc.readingOf(WaterSensorType.temperature),
      _svc.readingOf(WaterSensorType.ph),
      _svc.readingOf(WaterSensorType.tds),
    ].whereType<WaterSensorReading>().length;
    return n == 0 ? 3 : n;
  }

  List<FarmAlert> get _relatedAlerts {
    final code = (_svc.deviceFilter ?? _svc.deviceCode ?? '').toLowerCase();
    final name = (_controller?.deviceName ?? '').toLowerCase();
    return widget.alertService.filteredAlerts.where((a) {
      final hay = '${a.device} ${a.location} ${a.title}'.toLowerCase();
      if (hay.contains('camera') || hay.contains('cua ') || hay.contains('harvest')) {
        return false;
      }
      if (code.isNotEmpty && hay.contains(code)) return true;
      if (name.isNotEmpty && hay.contains(name)) return true;
      if (a.type == AlertTypeCategory.temperature ||
          a.type == AlertTypeCategory.phAbnormal ||
          a.type == AlertTypeCategory.salinity) {
        return code.isEmpty || hay.contains(code) || hay.contains('sensor');
      }
      return false;
    }).take(6).toList();
  }

  Future<void> _exportCsv() async {
    final csv = _svc.exportRecentCsv();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất dữ liệu gần đây',
      fileName: 'crabsense-realtime-${_svc.deviceFilter ?? _svc.deviceCode ?? 'controller'}.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null) return;
    await File(path).writeAsString(csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xuất CSV theo Controller đang xem.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1180;
    final loading = _svc.isLoading && _svc.allReadings.isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 14),
          if (loading) _skeleton() else ...[
            if (_svc.cloudError != null && !_svc.cloudLive) ...[
              _banner('⚠ Không thể tải dữ liệu realtime.\n${_svc.cloudError}', _kAmber, onRetry: () => _svc.refresh(full: true)),
              const SizedBox(height: 12),
            ],
            if (!_controllerOnline && _svc.readings.isNotEmpty) ...[
              _banner(
                '⚠ ${_svc.deviceFilter ?? _svc.deviceCode ?? 'Controller'} đang mất kết nối.\nDữ liệu hiển thị là giá trị cuối cùng nhận được.',
                _kAmber,
                action: 'Kiểm tra Controller',
                onAction: () => widget.onNavigate?.call(AppRoute.controllers),
              ),
              const SizedBox(height: 12),
            ],
            _sensorCards(),
            const SizedBox(height: 16),
            if (compact) ...[
              _chartCard(),
              const SizedBox(height: 14),
              _recentTable(),
              const SizedBox(height: 14),
              _controllerCard(),
              const SizedBox(height: 14),
              _alertsCard(),
              const SizedBox(height: 14),
              _qualityCard(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 72,
                    child: Column(
                      children: [
                        _chartCard(),
                        const SizedBox(height: 14),
                        _recentTable(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 28,
                    child: Column(
                      children: [
                        _controllerCard(),
                        const SizedBox(height: 14),
                        _alertsCard(),
                        const SizedBox(height: 14),
                        _qualityCard(),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    final farms = _areas;
    final areaId = _svc.areaFilterId;
    final areaValue = farms.any((f) => f.id == areaId) ? areaId : (farms.isEmpty ? null : farms.first.id);
    final devices = _deviceCodes;
    final deviceValue = _svc.deviceFilter ?? (devices.contains(_svc.deviceCode) ? _svc.deviceCode : null);
    final last = _svc.lastRealtimeAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.ssid_chart, color: DashboardColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giám sát thời gian thực', style: bvText(fontSize: 20, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                    Text(
                      'Theo dõi dữ liệu môi trường trực tiếp từ Controller ESP32.',
                      style: bvText(color: DashboardColors.textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              MgmtOutlineButton(
                icon: Icons.refresh_rounded,
                label: 'Làm mới',
                onTap: () => _svc.refresh(full: true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _drop<String>(
                label: 'Khu vực',
                value: areaValue,
                items: [
                  for (final f in farms) (f.id, f.toString()),
                ],
                onChanged: _svc.setAreaId,
              ),
              _drop<String?>(
                label: 'Controller',
                value: deviceValue,
                items: [
                  (null, 'Tất cả Controller'),
                  for (final c in devices) (c, c),
                ],
                onChanged: _svc.setDeviceCode,
              ),
              _drop<String>(
                label: 'Nhóm sensor',
                value: _svc.sensorGroup,
                items: const [
                  ('all', 'Tất cả sensor'),
                  ('water', 'Chất lượng nước'),
                  ('temp', 'Nhiệt độ'),
                  ('other', 'Khác'),
                ],
                onChanged: (v) {
                  if (v != null) _svc.setSensorGroup(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statusTile(
                'Cloud',
                switch (_cloud) {
                  _Cloud.online => ('Online', DashboardColors.brand, 'API hệ thống hoạt động'),
                  _Cloud.degraded => ('Không ổn định', _kAmber, 'Phản hồi chậm'),
                  _Cloud.offline => ('Offline', _kRed, _svc.cloudError ?? 'Không gọi được API'),
                },
              ),
              _statusTile(
                'Controller',
                _controllerOnline
                    ? ('Online', DashboardColors.brand, 'Live • ${_svc.lastUpdateLabel}')
                    : ('Offline', _kRed, 'Mất kết nối thiết bị'),
              ),
              _statusTile(
                'Sensor realtime',
                ('$_liveCount / $_sensorTotal', _liveCount == _sensorTotal && _controllerOnline ? DashboardColors.brand : _kAmber, 'Đang nhận dữ liệu'),
              ),
              _statusTile(
                'Cập nhật lần cuối',
                (last == null ? '—' : fmtDateTimeVn(last), DashboardColors.textPrimary, last == null ? 'Chưa có mẫu' : _svc.lastUpdateLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorCards() {
    if (_svc.readings.isEmpty && !_svc.isLoading) {
      final never = _svc.lastRealtimeAt == null;
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: mgmtCardDeco(radius: 16),
        child: Column(
          children: [
            Icon(Icons.sensors_off, color: DashboardColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(
              never ? 'Controller chưa có Sensor.' : 'Chưa nhận được dữ liệu từ sensor.',
              style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
            ),
            const SizedBox(height: 8),
            MgmtOutlineButton(
              label: 'Quản lý Controller →',
              onTap: () => widget.onNavigate?.call(AppRoute.controllers),
            ),
          ],
        ),
      );
    }
    final types = _svc.sensorGroup == 'other'
        ? _svc.readings.map((r) => r.type).toList()
        : const [WaterSensorType.temperature, WaterSensorType.ph, WaterSensorType.tds];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 900 ? (types.length.clamp(1, 3)) : (c.maxWidth > 560 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: types.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.85,
          ),
          itemBuilder: (_, i) => _SensorCard(
            type: types[i],
            reading: _svc.readingOf(types[i]),
            fresh: _freshOf(_svc.readingOf(types[i])),
            controllerOnline: _controllerOnline,
          ),
        );
      },
    );
  }

  Widget _chartCard() {
    final metric = _svc.chartMetric;
    final segs = _svc.chartSegments;
    final points = _svc.chartSeries;
    final reading = metric == null ? null : _svc.readingOf(metric);
    final minV = points.isEmpty ? null : points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxV = points.isEmpty ? null : points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final avg = points.isEmpty ? null : points.map((e) => e.value).reduce((a, b) => a + b) / points.length;
    var over = 0;
    final lo = reading?.threshold.min;
    final hi = reading?.threshold.max;
    if (lo != null && hi != null) {
      for (final p in points) {
        if (p.value < lo || p.value > hi) over++;
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            metric == null ? 'Biểu đồ' : 'Biểu đồ ${metric.label}',
            style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
          ),
          Text(
            metric == null ? 'Chọn chỉ số để xem diễn biến.' : 'Diễn biến ${metric.label.toLowerCase()} theo thời gian.',
            style: bvText(color: DashboardColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _drop<WaterSensorType>(
                label: 'Chỉ số',
                value: metric ?? (_svc.availableMetrics.isEmpty ? null : _svc.availableMetrics.first),
                items: [
                  for (final m in _svc.availableMetrics) (m, m.label),
                ],
                onChanged: (v) {
                  if (v != null) _svc.setChartMetric(v);
                },
              ),
              for (var i = 0; i < WaterQualityService.chartRangeLabels.length; i++)
                _rangeChip(WaterQualityService.chartRangeLabels[i], i == _svc.chartRangeIndex, () => _svc.setChartRangeIndex(i)),
              FilterChip(
                selected: _svc.showThreshold,
                label: Text('Hiện ngưỡng', style: bvText(fontWeight: FontWeight.w700, fontSize: 12)),
                selectedColor: DashboardColors.mint,
                onSelected: _svc.setShowThreshold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: [
              _stat('THẤP NHẤT', _fmt(metric, minV)),
              _stat('TRUNG BÌNH', _fmt(metric, avg)),
              _stat('CAO NHẤT', _fmt(metric, maxV)),
              _stat('NGOÀI NGƯỠNG', '$over lần'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: _svc.chartLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : points.isEmpty
                    ? _chartEmpty()
                    : _HistoryChart(
                        segments: segs,
                        rangeMinutes: _svc.chartRangeMinutesValue,
                        color: metric?.accent ?? DashboardColors.brand,
                        minTh: _svc.showThreshold ? lo : null,
                        maxTh: _svc.showThreshold ? hi : null,
                        unit: metric == WaterSensorType.temperature
                            ? '°C'
                            : metric == WaterSensorType.tds
                                ? 'ppm'
                                : '',
                      ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _legend(metric?.accent ?? DashboardColors.brand, metric?.label ?? 'Sensor'),
              if (_svc.showThreshold) ...[
                _legend(_kSlate, 'Ngưỡng thấp'),
                _legend(_kRed, 'Ngưỡng cao'),
              ],
              _legend(const Color(0xFFCBD5E1), 'Mất dữ liệu'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartEmpty() {
    final had = _svc.lastRealtimeAt != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            had
                ? 'Không có dữ liệu trong ${_svc.chartRangeLabel} gần đây'
                : 'Sensor chưa ghi nhận dữ liệu.',
            style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (had) ...[
            const SizedBox(height: 4),
            Text(
              '${_svc.deviceFilter ?? _svc.deviceCode ?? 'Controller'} đã mất kết nối từ ${_svc.lastUpdateClock}.',
              style: bvText(color: DashboardColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                MgmtOutlineButton(label: 'Xem 24 giờ', onTap: () => _svc.setChartRangeIndex(2)),
                MgmtOutlineButton(
                  label: 'Kiểm tra Controller',
                  onTap: () => widget.onNavigate?.call(AppRoute.controllers),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _recentTable() {
    final rows = _svc.recentRows;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Dữ liệu gần đây', style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
              MgmtOutlineButton(icon: Icons.download_outlined, label: 'Xuất CSV', onTap: rows.isEmpty ? null : _exportCsv),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text('Chưa có mẫu trong 1 giờ gần đây.', style: bvText(color: DashboardColors.textMuted))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: bvText(fontWeight: FontWeight.w800, fontSize: 11.5, color: DashboardColors.textMuted),
                dataTextStyle: bvText(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
                columns: const [
                  DataColumn(label: Text('THỜI GIAN')),
                  DataColumn(label: Text('NHIỆT ĐỘ (°C)')),
                  DataColumn(label: Text('pH')),
                  DataColumn(label: Text('TDS (ppm)')),
                  DataColumn(label: Text('TRẠNG THÁI')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(cells: [
                      DataCell(Text(fmtDateTimeVn(r.at))),
                      DataCell(Text(r.temperature?.toStringAsFixed(1) ?? '—')),
                      DataCell(Text(r.ph == null ? '—' : r.ph!.toStringAsFixed(2))),
                      DataCell(Text(r.tds?.round().toString() ?? '—')),
                      DataCell(MgmtStatusBadge(
                        label: r.status,
                        color: r.outOfRange ? _kRed : DashboardColors.brand,
                      )),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _controllerCard() {
    final d = _controller;
    final online = _controllerOnline;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Thông tin Controller', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
              Text('🔒 Chỉ đọc', style: bvText(fontSize: 11, color: DashboardColors.textMuted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.memory, color: DashboardColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d?.deviceName ?? _svc.deviceCode ?? '—', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                    MgmtStatusBadge(label: online ? 'Online' : 'Offline', color: online ? DashboardColors.brand : _kRed),
                    Text(
                      controllerTypeLabel(d?.deviceType ?? controllerTypeRealtime),
                      style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Board', (d?.deviceType ?? '').toLowerCase().contains('s3') ? 'ESP32-S3' : 'ESP32'),
          _kv('Firmware', d?.firmwareVersion ?? '—'),
          _kv('IP', d?.ipLan ?? '—'),
          _kv('MAC', d?.macAddress ?? '—'),
          _kv('Device ID', d?.deviceCode ?? _svc.deviceCode ?? '—'),
          _kv('RSSI', d?.rssiDbm == null ? '—' : '${d!.rssiDbm!.round()} dBm'),
          _kv('Heartbeat', _svc.lastUpdateLabel),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message: online ? 'Gửi cấu hình tới thiết bị' : 'Controller cần online để cấu hình mạng từ xa.',
                child: MgmtOutlineButton(
                  icon: Icons.settings_outlined,
                  label: 'Cấu hình mạng',
                  onTap: !online || d == null || widget.controllerService == null
                      ? null
                      : () => showControllerNetworkDialog(context, service: widget.controllerService!, device: d, online: online),
                ),
              ),
              Tooltip(
                message: online ? 'Firmware không sửa bằng text version' : 'Controller cần online để cập nhật firmware từ xa.',
                child: MgmtOutlineButton(
                  icon: Icons.system_update_alt,
                  label: 'Cập nhật FW',
                  onTap: d == null
                      ? null
                      : () => showControllerFirmwareDialog(context, device: d, online: online),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alertsCard() {
    final alerts = _relatedAlerts;
    final offline = !_controllerOnline;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Cảnh báo liên quan (${offline ? 1 : alerts.length})', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
              TextButton(
                onPressed: () => widget.onNavigate?.call(AppRoute.alerts),
                child: Text('Xem tất cả →', style: bvText(color: DashboardColors.brand, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          if (offline) ...[
            Text('CrabSense mất kết nối', style: bvText(fontWeight: FontWeight.w800, color: _kAmber)),
            Text('Ảnh hưởng: $_sensorTotal sensor', style: bvText(color: DashboardColors.textMuted)),
            Text('Bắt đầu: ${_svc.lastUpdateClock}', style: bvText(color: DashboardColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            MgmtOutlineButton(label: 'Xem Controller', onTap: () => widget.onNavigate?.call(AppRoute.controllers)),
          ] else if (alerts.isEmpty)
            Text('Không có cảnh báo liên quan Controller đang chọn.', style: bvText(color: DashboardColors.textMuted))
          else
            for (final a in alerts.take(4)) ...[
              const SizedBox(height: 8),
              Text(_alertTitle(a), style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              if (a.currentValue != '—') Text('Giá trị: ${a.currentValue}', style: bvText(color: DashboardColors.textMuted, fontSize: 12.5)),
              if (a.threshold.isNotEmpty) Text('Ngưỡng: ${a.threshold}', style: bvText(color: DashboardColors.textMuted, fontSize: 12.5)),
              Text('${a.time} · ${_severity(a)} · ${_alertStatus(a)}', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            ],
        ],
      ),
    );
  }

  Widget _qualityCard() {
    final rssi = _controller?.rssiDbm;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chất lượng dữ liệu', style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
          const SizedBox(height: 8),
          _kv('Trạng thái Controller', _controllerOnline ? 'Online' : 'Offline'),
          _kv('Sensor realtime', '$_liveCount / $_sensorTotal'),
          _kv('Heartbeat', _svc.lastUpdateLabel),
          _kv('Tần suất mẫu', _controllerOnline ? '3–5 giây' : '—'),
          _kv('Gói dữ liệu gần nhất', _svc.lastRealtimeAt == null ? '—' : fmtDateTimeVn(_svc.lastRealtimeAt)),
          _kv(
            'Chất lượng kết nối',
            !_controllerOnline
                ? 'Không có dữ liệu'
                : rssi == null
                    ? '—'
                    : (rssi >= -60 ? 'Tốt (${rssi.round()} dBm)' : '${rssi.round()} dBm'),
          ),
        ],
      ),
    );
  }

  Widget _skeleton() {
    Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(color: DashboardColors.lightMint, borderRadius: BorderRadius.circular(14)),
        );
    return Column(
      children: [
        box(120),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: box(110)), const SizedBox(width: 10), Expanded(child: box(110)), const SizedBox(width: 10), Expanded(child: box(110))]),
        const SizedBox(height: 12),
        box(220),
      ],
    );
  }

  Widget _drop<T>({
    required String label,
    required T? value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    final ink = bvText(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary);
    final safe = items.any((e) => e.$1 == value) ? value : (items.isEmpty ? null : items.first.$1);
    return SizedBox(
      width: 240,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: bvText(color: DashboardColors.textMuted),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardColors.cardBorder)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.isEmpty ? null : safe,
            isExpanded: true,
            isDense: true,
            style: ink,
            dropdownColor: Colors.white,
            hint: Text('—', style: bvText(color: DashboardColors.textMuted)),
            items: [
              for (final (v, t) in items)
                DropdownMenuItem(value: v, child: Text(t, style: ink)),
            ],
            onChanged: items.isEmpty ? null : onChanged,
          ),
        ),
      ),
    );
  }

  Widget _statusTile(String title, (String, Color, String) data) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: data.$2, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(data.$1, style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
            ],
          ),
          Text(data.$3, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, bool on, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: on ? DashboardColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? DashboardColors.brand : DashboardColors.cardBorder),
        ),
        child: Text(label, style: bvText(fontWeight: FontWeight.w700, fontSize: 12, color: on ? Colors.white : DashboardColors.textPrimary)),
      ),
    );
  }

  Widget _stat(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: bvText(fontSize: 10.5, color: DashboardColors.textMuted, fontWeight: FontWeight.w700)),
          Text(v, style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
        ],
      );

  Widget _legend(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(t, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(child: Text(k, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
            Text(v, style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary, fontSize: 12.5)),
          ],
        ),
      );

  Widget _banner(String msg, Color color, {VoidCallback? onRetry, String? action, VoidCallback? onAction}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(msg, style: bvText(color: color, fontWeight: FontWeight.w600, height: 1.4))),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text('Thử lại', style: bvText(color: DashboardColors.brand, fontWeight: FontWeight.w800))),
          if (onAction != null) TextButton(onPressed: onAction, child: Text(action ?? 'Mở', style: bvText(color: DashboardColors.brand, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  String _fmt(WaterSensorType? t, double? v) {
    if (v == null || t == null) return '—';
    if (t == WaterSensorType.temperature) return '${v.toStringAsFixed(1)}°C';
    if (t == WaterSensorType.ph) return v.toStringAsFixed(2);
    if (t == WaterSensorType.tds) return '${v.round()} ppm';
    return v.toStringAsFixed(1);
  }

  String _alertTitle(FarmAlert a) {
    final t = a.title.toLowerCase();
    if (t.contains('realtime_sensor') || t.contains('sensor_timeout')) return 'Sensor không gửi dữ liệu';
    if (t.contains('controller_disconnect') || t.contains('disconnect')) return 'Controller mất kết nối';
    if (t.contains('stale') || t.contains('timeout')) return 'Dữ liệu đã cũ';
    return a.title;
  }

  String _severity(FarmAlert a) => switch (a.level) {
        AlertLevel.critical => 'Cao',
        AlertLevel.warning => 'Trung bình',
        AlertLevel.info => 'Thấp',
      };

  String _alertStatus(FarmAlert a) => switch (a.status) {
        AlertWorkflowStatus.newAlert => 'Đang mở',
        AlertWorkflowStatus.notified => 'Đã xác nhận',
        AlertWorkflowStatus.inProgress => 'Đang mở',
        AlertWorkflowStatus.resolved => 'Đã xử lý',
        AlertWorkflowStatus.ignored => 'Đã xử lý',
        AlertWorkflowStatus.falseAlarm => 'Đã khôi phục',
      };
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.type,
    required this.reading,
    required this.fresh,
    required this.controllerOnline,
  });

  final WaterSensorType type;
  final WaterSensorReading? reading;
  final _Fresh fresh;
  final bool controllerOnline;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final out = r != null &&
        r.threshold.min != null &&
        r.threshold.max != null &&
        (r.value < r.threshold.min! || r.value > r.threshold.max!);
    final (badge, color) = switch (fresh) {
      _Fresh.live when out => ('Vượt ngưỡng', _kRed),
      _Fresh.live => ('Bình thường', DashboardColors.brand),
      _Fresh.delayed => ('Dữ liệu chậm', _kAmber),
      _Fresh.stale => ('Dữ liệu cũ', _kAmber),
      _Fresh.noSignal => ('Mất tín hiệu', _kRed),
      _Fresh.notConfigured => ('Chưa cấu hình', _kSlate),
    };
    final staleLook = fresh == _Fresh.stale || fresh == _Fresh.delayed || !controllerOnline;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, size: 18, color: out ? _kRed : DashboardColors.brand),
              const SizedBox(width: 6),
              Expanded(child: Text(type.label, style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))),
              MgmtStatusBadge(label: badge, color: color),
            ],
          ),
          const SizedBox(height: 8),
          if (fresh == _Fresh.noSignal || fresh == _Fresh.notConfigured)
            Text(fresh == _Fresh.notConfigured ? '—' : '—', style: bvText(fontSize: 28, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary))
          else ...[
            if (staleLook) Text('Giá trị cuối', style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
            Text(
              r?.displayValue ?? '—',
              style: bvText(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: out ? _kRed : DashboardColors.textPrimary,
              ),
            ),
          ],
          const Spacer(),
          if (r?.threshold.min != null && r?.threshold.max != null)
            Text('Ngưỡng: ${_range(type, r!.threshold.min!, r.threshold.max!)}', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          Text(
            switch (fresh) {
              _Fresh.live => 'Cập nhật: ${_ago(r?.measuredAt)}',
              _Fresh.delayed => 'Cập nhật: ${_ago(r?.measuredAt)}',
              _Fresh.stale => 'Nhận lúc: ${r?.measuredAt == null ? '—' : fmtDateTimeVn(r!.measuredAt)} · ${_ago(r?.measuredAt)}${controllerOnline ? '' : '\nNguyên nhân: Controller mất kết nối'}',
              _Fresh.noSignal => 'Chưa nhận được dữ liệu từ sensor.',
              _Fresh.notConfigured => 'Sensor chưa được gắn trên Controller.',
            },
            style: bvText(fontSize: 11.5, color: DashboardColors.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }

  String _range(WaterSensorType t, double min, double max) {
    if (t == WaterSensorType.temperature) return '${min.toStringAsFixed(0)} – ${max.toStringAsFixed(0)}°C';
    if (t == WaterSensorType.tds) return '${min.round()} – ${max.round()} ppm';
    return '${min.toStringAsFixed(1)} – ${max.toStringAsFixed(1)}';
  }

  String _ago(DateTime? at) {
    if (at == null) return '—';
    final d = DateTime.now().difference(at.toLocal());
    if (d.inSeconds < 15) return 'vừa xong';
    if (d.inMinutes < 1) return '${d.inSeconds} giây trước';
    if (d.inHours < 1) return '${d.inMinutes} phút trước';
    return '${d.inHours} giờ trước';
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({
    required this.segments,
    required this.rangeMinutes,
    required this.color,
    required this.unit,
    this.minTh,
    this.maxTh,
  });

  final List<List<RealtimeChartPoint>> segments;
  final int rangeMinutes;
  final Color color;
  final String unit;
  final double? minTh;
  final double? maxTh;

  @override
  Widget build(BuildContext context) {
    final all = segments.expand((e) => e).toList();
    if (all.isEmpty) return const SizedBox.shrink();
    var minY = all.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    var maxY = all.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (minTh != null) minY = minY < minTh! ? minY : minTh!;
    if (maxTh != null) maxY = maxY > maxTh! ? maxY : maxTh!;
    final pad = (maxY - minY).abs() < 0.2 ? 0.4 : (maxY - minY) * 0.15;
    final bars = <LineChartBarData>[
      for (final seg in segments)
        if (seg.isNotEmpty)
          LineChartBarData(
            spots: [for (final p in seg) FlSpot(p.xMinutes, p.value)],
            isCurved: false,
            color: color,
            barWidth: 2.2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
          ),
      if (minTh != null)
        LineChartBarData(
          spots: [FlSpot(0, minTh!), FlSpot(rangeMinutes.toDouble(), minTh!)],
          color: _kSlate,
          barWidth: 1,
          dashArray: const [6, 4],
          dotData: const FlDotData(show: false),
        ),
      if (maxTh != null)
        LineChartBarData(
          spots: [FlSpot(0, maxTh!), FlSpot(rangeMinutes.toDouble(), maxTh!)],
          color: _kRed.withValues(alpha: 0.7),
          barWidth: 1,
          dashArray: const [6, 4],
          dotData: const FlDotData(show: false),
        ),
    ];
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: rangeMinutes.toDouble(),
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: DashboardColors.cardBorder, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(v.abs() < 10 ? 1 : 0), style: bvText(fontSize: 10, color: DashboardColors.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: rangeMinutes / 4,
              getTitlesWidget: (v, _) => Text('${v.round()}p', style: bvText(fontSize: 10, color: DashboardColors.textMuted)),
            ),
          ),
        ),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              // Must return same length as spots (null = skip). Filtering
              // drops threshold-line hits and crashes fl_chart paint.
              final dataBarCount = segments.where((s) => s.isNotEmpty).length;
              return [
                for (final s in spots)
                  s.barIndex < dataBarCount
                      ? LineTooltipItem(
                          '${s.y.toStringAsFixed(2)} $unit',
                          bvText(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        )
                      : null,
              ];
            },
          ),
        ),
      ),
    );
  }
}
