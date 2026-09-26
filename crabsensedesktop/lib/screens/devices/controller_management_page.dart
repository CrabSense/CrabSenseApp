import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/esp_controller.dart';
import '../../models/farm_activity_log.dart';
import '../../models/farm_alert.dart';
import '../../models/iot_device.dart';
import '../../navigation/app_route.dart';
import '../../services/alert_service.dart';
import '../../services/controller_service.dart';
import '../../services/farm_log_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';
import 'add_controller_dialog.dart';
import 'edit_controller_dialog.dart';

const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF2495E8);
const _kSlate = Color(0xFF94A3B8);
const _kHeartbeatOnline = Duration(seconds: 30);
const _kHeartbeatDegraded = Duration(seconds: 90);
const _kSensorRealtime = Duration(seconds: 30);
const _kSensorSlow = Duration(minutes: 5);

class ControllerManagementPage extends StatefulWidget {
  const ControllerManagementPage({
    super.key,
    required this.service,
    this.areaName,
    this.areaCode,
    this.alertService,
    this.farmLogService,
    this.rowService,
    this.onNavigate,
  });

  final ControllerService service;
  final String? areaName;
  final String? areaCode;
  final AlertService? alertService;
  final FarmLogService? farmLogService;
  final RowManagementService? rowService;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<ControllerManagementPage> createState() =>
      _ControllerManagementPageState();
}

class _ControllerManagementPageState extends State<ControllerManagementPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _areaFilter = 'all';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  late final TabController _tabs;
  bool _checking = false;

  ControllerService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _svc.addListener(_onUpdate);
    widget.alertService?.addListener(_onUpdate);
    widget.farmLogService?.addListener(_onUpdate);
    _svc.load();
    widget.alertService?.load();
    widget.farmLogService?.load();
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    widget.alertService?.removeListener(_onUpdate);
    widget.farmLogService?.removeListener(_onUpdate);
    _svc.stopLiveRefresh();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim().toLowerCase());
    });
  }

  List<IoTDevice> get _filtered {
    return _svc.items.where((d) {
      if (_query.isNotEmpty) {
        final hay = [
          d.deviceName,
          d.deviceCode,
          d.macAddress,
          d.ipLan,
          d.areaName,
          d.areaCode,
        ].whereType<String>().join(' ').toLowerCase();
        if (!hay.contains(_query)) return false;
      }
      if (_areaFilter != 'all') {
        if ((d.areaId ?? d.farmId) != _areaFilter &&
            d.areaCode != _areaFilter) {
          return false;
        }
      }
      if (_statusFilter == 'online' && !d.isOnline) return false;
      if (_statusFilter == 'offline' && !d.isOffline) return false;
      if (_statusFilter == 'alert' && !_hasAlert(d)) return false;
      if (_typeFilter != 'all' &&
          controllerTypeFilterKey(d.deviceType ?? '') != _typeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _hasAlert(IoTDevice d) {
    if (d.status.toLowerCase() == 'error') return true;
    return _alertsOf(d).any((a) => a.isOpen);
  }

  List<FarmAlert> _alertsOf(IoTDevice d) {
    final all = widget.alertService?.alerts ?? const <FarmAlert>[];
    final sensors = _svc.detail?.controller.id == d.id
        ? _svc.detail!.sensors
        : const <ControllerChild>[];
    return all.where((a) {
      final hay = '${a.device} ${a.title} ${a.location}'.toLowerCase();
      if (d.deviceCode.isNotEmpty && hay.contains(d.deviceCode.toLowerCase())) {
        return true;
      }
      final name = (d.deviceName ?? '').toLowerCase();
      if (name.isNotEmpty && hay.contains(name)) return true;
      for (final s in sensors) {
        if (s.code.isNotEmpty && hay.contains(s.code.toLowerCase()))
          return true;
      }
      return false;
    }).toList();
  }

  int get _alertKpi => _svc.items.where(_hasAlert).length;

  List<FarmActivityLogEntry> _logsOf(IoTDevice d) {
    final all =
        widget.farmLogService?.entries ?? const <FarmActivityLogEntry>[];
    return all.where((e) {
      if (e.type == FarmLogType.rasControl) return true;
      final hay =
          '${e.content} ${e.area} ${e.subjectDetail} ${e.note}'.toLowerCase();
      return hay.contains(d.deviceCode.toLowerCase()) ||
          ((d.deviceName ?? '').isNotEmpty &&
              hay.contains(d.deviceName!.toLowerCase()));
    }).toList();
  }

  Future<void> _add() async {
    final result = await showAddControllerDialog(
      context,
      service: _svc,
      session: _svc.session,
      rowService: widget.rowService,
    );
    if (!mounted || result == null) return;
    if (result.deviceId.isNotEmpty) {
      await _svc.select(result.deviceId, force: true);
    }
    if (result.openSensors) _tabs.animateTo(1);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final loading = _svc.loading && _svc.items.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 14),
          if (loading) _kpiSkeleton() else _kpis(),
          if (_svc.error != null && _svc.items.isEmpty) ...[
            const SizedBox(height: 12),
            _errorBanner(_svc.error!, () => _svc.load()),
          ],
          const SizedBox(height: 14),
          Expanded(child: _body(loading)),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.developer_board, color: DashboardColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý Controller',
                style: bvText(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Quản lý các Controller ESP32 trong hệ thống RAS. Mỗi Controller thu thập sensor và điều khiển thiết bị như bơm, drum, van, máy sục khí...',
                style: bvText(
                    fontSize: 13,
                    color: DashboardColors.textMuted,
                    height: 1.4),
              ),
            ],
          ),
        ),
        MgmtPrimaryButton(
          label: 'Thêm Controller',
          icon: Icons.add,
          onTap: _add,
        ),
      ],
    );
  }

  Widget _kpis() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 48) / 5;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: w < 160 ? c.maxWidth : w,
              child: MgmtKpiCard(
                icon: Icons.developer_board,
                label: 'TỔNG CONTROLLER',
                value: '${_svc.totalCount}',
                color: DashboardColors.brand,
              ),
            ),
            SizedBox(
              width: w < 160 ? c.maxWidth : w,
              child: MgmtKpiCard(
                icon: Icons.wifi,
                label: 'ONLINE',
                value: '${_svc.onlineCount}',
                color: DashboardColors.brandGreen,
              ),
            ),
            SizedBox(
              width: w < 160 ? c.maxWidth : w,
              child: MgmtKpiCard(
                icon: Icons.wifi_off,
                label: 'OFFLINE',
                value: '${_svc.offlineCount}',
                color: _kSlate,
              ),
            ),
            SizedBox(
              width: w < 160 ? c.maxWidth : w,
              child: MgmtKpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'CÓ CẢNH BÁO',
                value: '$_alertKpi',
                color: _alertKpi == 0 ? DashboardColors.brand : _kAmber,
              ),
            ),
            SizedBox(
              width: w < 160 ? c.maxWidth : w,
              child: MgmtKpiCard(
                icon: Icons.hub_outlined,
                label: 'TỔNG THIẾT BỊ GẮN',
                value: '${_svc.attachedCount}',
                color: _kBlue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiSkeleton() {
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Expanded(
            child: Container(
              height: 78,
              margin: EdgeInsets.only(right: i == 4 ? 0 : 12),
              decoration: mgmtCardDeco(radius: 16),
            ),
          ),
      ],
    );
  }

  Widget _body(bool loading) {
    if (!loading && _svc.items.isEmpty && _svc.error == null) {
      return MgmtEmptyState(
        icon: Icons.memory_outlined,
        title: 'Chưa có Controller',
        message: 'Thêm Controller đầu tiên để kết nối sensor và thiết bị RAS.',
        action: MgmtPrimaryButton(
            label: 'Thêm Controller', icon: Icons.add, onTap: _add),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 980;
        final list = _listPane(loading);
        final detail = _detailPane();
        if (!wide) {
          return Column(
            children: [
              SizedBox(height: 220, child: list),
              const SizedBox(height: 10),
              Expanded(child: detail),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: c.maxWidth * 0.26, child: list),
            const SizedBox(width: 12),
            Expanded(child: detail),
          ],
        );
      },
    );
  }

  Widget _listPane(bool loading) {
    final areas = {
      for (final d in _svc.items)
        if ((d.areaId ?? d.farmId).isNotEmpty)
          (d.areaId ?? d.farmId): [
            if ((d.areaName ?? '').isNotEmpty) d.areaName,
            if ((d.areaCode ?? '').isNotEmpty) '(${d.areaCode})',
          ].join(' '),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          MgmtSearchField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            hint: 'Tìm tên, mã, MAC, IP...',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _areaFilter == 'all'
                      ? 'Khu vực'
                      : (areas[_areaFilter] ?? 'Khu vực'),
                  items: [
                    ('all', 'Tất cả khu'),
                    ...areas.entries
                        .map((e) => (e.key, e.value.isEmpty ? e.key : e.value)),
                  ],
                  onSelected: (v) => setState(() => _areaFilter = v),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: switch (_statusFilter) {
                    'online' => 'Online',
                    'offline' => 'Offline',
                    'alert' => 'Cảnh báo',
                    _ => 'Trạng thái',
                  },
                  items: const [
                    ('all', 'Tất cả'),
                    ('online', 'Online'),
                    ('offline', 'Offline'),
                    ('alert', 'Cảnh báo'),
                  ],
                  onSelected: (v) => setState(() => _statusFilter = v),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: switch (_typeFilter) {
                    'realtime' => 'Realtime',
                    'ras' => 'RAS',
                    'camera' => 'Camera',
                    'mixed' => 'Mixed',
                    'other' => 'Khác',
                    _ => 'Loại',
                  },
                  items: const [
                    ('all', 'Tất cả loại'),
                    ('realtime', 'Realtime Sensor Controller'),
                    ('ras', 'RAS Controller'),
                    ('camera', 'Camera Controller'),
                    ('mixed', 'Mixed Controller'),
                    ('other', 'Khác'),
                  ],
                  onSelected: (v) => setState(() => _typeFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? ListView(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          height: 88,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: DashboardColors.lightMint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = _filtered[i];
                      return _ControllerCard(
                        device: d,
                        selected: _svc.selectedId == d.id,
                        warning: _hasAlert(d),
                        onTap: () => _svc.select(d.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailPane() {
    if (_svc.detailLoading && _svc.detail == null) {
      return Container(
        decoration: mgmtCardDeco(radius: 16),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
                height: 88,
                decoration: BoxDecoration(
                    color: DashboardColors.lightMint,
                    borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: DashboardColors.lightMint,
                        borderRadius: BorderRadius.circular(12)))),
          ],
        ),
      );
    }
    final detail = _svc.detail;
    if (detail == null) {
      return Container(
        alignment: Alignment.center,
        decoration: mgmtCardDeco(radius: 16),
        child: Text('Chọn một Controller để xem chi tiết.',
            style: bvText(color: DashboardColors.textMuted)),
      );
    }
    final d = detail.controller;
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: _detailHeader(d, detail),
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: DashboardColors.brand,
            unselectedLabelColor: DashboardColors.textMuted,
            indicatorColor: DashboardColors.brand,
            labelStyle: bvText(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [
              const Tab(text: 'Tổng quan'),
              Tab(text: 'Sensors (${detail.sensors.length})'),
              Tab(text: 'Outputs (${detail.actuators.length})'),
              const Tab(text: 'Mạng & hệ thống'),
              const Tab(text: 'Lịch sử'),
            ],
          ),
          Divider(height: 1, color: DashboardColors.cardBorder),
          if (_svc.detailError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _errorBanner(
                  _svc.detailError!, () => _svc.select(d.id, force: true)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _overviewTab(detail),
                _sensorsTab(detail, full: true),
                _outputsTab(detail),
                _networkTab(d),
                _historyTab(d),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailHeader(IoTDevice d, ControllerDetail detail) {
    final canRestart = d.isOnline || (d.ipLan ?? '').trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.memory,
                  color: DashboardColors.brand, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(d.deviceName ?? d.deviceCode,
                          style: bvText(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      _statusBadge(d, warning: _hasAlert(d)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controllerTypeLabel(d.deviceType ?? ''),
                    style: bvText(color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                MgmtOutlineButton(
                  onTap: _checking ? null : () => _check(d),
                  icon: Icons.wifi_tethering,
                  label: _checking ? 'Đang kiểm tra...' : 'Kiểm tra kết nối',
                ),
                MgmtOutlineButton(
                  onTap:
                      !canRestart || _svc.restarting ? null : () => _restart(d),
                  icon: Icons.restart_alt,
                  label: _svc.restarting
                      ? 'Đang khởi động lại...'
                      : 'Khởi động lại',
                ),
                PopupMenuButton<String>(
                  tooltip: 'Thao tác Controller',
                  onSelected: (a) => _onMenu(a, d, detail),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'detail', child: Text('Xem chi tiết')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Chỉnh sửa Controller')),
                    const PopupMenuItem(
                        value: 'wifi', child: Text('Cấu hình WiFi')),
                    const PopupMenuItem(
                        value: 'sensors', child: Text('Quản lý Sensor')),
                    const PopupMenuItem(
                        value: 'outputs', child: Text('Quản lý Output')),
                    const PopupMenuItem(
                        value: 'alerts', child: Text('Xem cảnh báo')),
                    const PopupMenuItem(
                        value: 'history', child: Text('Xem lịch sử')),
                    const PopupMenuItem(
                        value: 'disable',
                        child: Text('Vô hiệu hóa Controller')),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _metaChip('Khu vực', _areaLabel(d)),
            if ((d.firmwareVersion ?? '').isNotEmpty)
              _metaChip('FW', 'v${d.firmwareVersion}'),
            if ((d.macAddress ?? '').isNotEmpty)
              _metaChip('MAC', d.macAddress!),
            if ((d.ipLan ?? '').isNotEmpty) _metaChip('IP', d.ipLan!),
            _metaChip('Last seen',
                d.lastSeenAt == null ? '—' : fmtDateTimeVn(d.lastSeenAt)),
          ],
        ),
        if (d.isOffline) ...[
          const SizedBox(height: 8),
          Text(
            'Controller đang mất kết nối. Dữ liệu Sensor bên dưới là giá trị cuối cùng nhận được.',
            style: bvText(
                fontSize: 12.5, color: _kAmber, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _metaChip(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ',
            style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
        Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _overviewTab(ControllerDetail detail) {
    final d = detail.controller;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            final cards = [
              _infoCard(d),
              _connectionCard(d),
              _healthCard(detail),
            ];
            if (!wide)
              return Column(children: [
                for (final w in cards) ...[w, const SizedBox(height: 10)]
              ]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final sensors = _sensorPreview(detail);
            final outputs = _outputPreview(detail);
            if (c.maxWidth < 800) {
              return Column(
                  children: [sensors, const SizedBox(height: 10), outputs]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sensors),
                const SizedBox(width: 10),
                Expanded(child: outputs),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final alerts = _alertsPanel(d);
            final acts = _activityPanel(d);
            if (c.maxWidth < 800) {
              return Column(
                  children: [alerts, const SizedBox(height: 10), acts]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: alerts),
                const SizedBox(width: 10),
                Expanded(child: acts),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _infoCard(IoTDevice d) {
    return _card('Thông tin thiết bị', Icons.info_outline, [
      _kv('Mã Controller', d.deviceCode),
      _kv('Tên', d.deviceName ?? d.deviceCode),
      _kv('Loại', controllerTypeLabel(d.deviceType ?? '')),
      _kv('Khu vực', _areaLabel(d)),
      if ((d.firmwareVersion ?? '').isNotEmpty)
        _kv('Firmware', 'v${d.firmwareVersion}'),
      if ((d.macAddress ?? '').isNotEmpty) _kv('MAC', d.macAddress!),
    ]);
  }

  Widget _connectionCard(IoTDevice d) {
    final ago = d.lastSeenAt == null
        ? null
        : DateTime.now().difference(d.lastSeenAt!.toLocal());
    final rows = <Widget>[
      _kv('Trạng thái', d.isOnline ? 'Online' : 'Mất kết nối',
          color: d.isOnline ? DashboardColors.brand : _kRed),
    ];
    if ((d.ipLan ?? '').isNotEmpty) rows.add(_kv('IP', d.ipLan!));
    if (d.rssiDbm != null && d.isOnline)
      rows.add(_kv('RSSI', '${d.rssiDbm!.round()} dBm'));
    if (d.lastSeenAt != null) {
      rows.add(
          _kv(d.isOnline ? 'Heartbeat' : 'Heartbeat cuối', _rel(d.lastSeenAt)));
    }
    if (!d.isOnline && ago != null) {
      rows.add(_kv('Đã mất kết nối', _dur(ago)));
    }
    if (_svc.restarting) {
      rows.add(_kv('Trạng thái lệnh', 'Đang khởi động lại...'));
    }
    return _card('Kết nối & trạng thái', Icons.wifi, rows);
  }

  Widget _healthCard(ControllerDetail detail) {
    final d = detail.controller;
    final liveSensors = detail.sensors
        .where((s) => _sensorFreshness(s, d) == _Fresh.realtime)
        .length;
    final apiOk = d.isOnline &&
        d.lastSeenAt != null &&
        DateTime.now().difference(d.lastSeenAt!.toLocal()) <=
            _kHeartbeatDegraded;
    return _card('Sức khỏe thiết bị', Icons.monitor_heart_outlined, [
      _kv('Controller', d.isOnline ? 'Online' : 'Offline',
          color: d.isOnline ? DashboardColors.brand : _kRed),
      _kv('WiFi', d.isOnline ? 'Tốt' : 'Mất kết nối',
          color: d.isOnline ? DashboardColors.brand : _kRed),
      _kv('API', apiOk ? 'Bình thường' : 'Không nhận heartbeat',
          color: apiOk ? DashboardColors.brand : _kAmber),
      _kv(
          'Sensors',
          d.isOnline
              ? '$liveSensors / ${detail.sensors.length} hoạt động'
              : '0 / ${detail.sensors.length} realtime'),
      _kv('Outputs', '${detail.actuators.length}'),
      if ((d.firmwareVersion ?? '').isNotEmpty)
        _kv('Firmware', 'v${d.firmwareVersion}'),
    ]);
  }

  Widget _sensorPreview(ControllerDetail detail) {
    return _card(
      'Sensors (${detail.sensors.length})',
      Icons.sensors,
      [
        if (detail.sensors.isEmpty)
          Text('Controller chưa có Sensor.',
              style: bvText(color: DashboardColors.textMuted))
        else
          _sensorTable(detail, compact: true),
      ],
      action: 'Xem tất cả →',
      onAction: () => _tabs.animateTo(1),
    );
  }

  Widget _outputPreview(ControllerDetail detail) {
    return _card(
      'Outputs / Thiết bị điều khiển (${detail.actuators.length})',
      Icons.settings_input_component,
      [
        if (detail.actuators.isEmpty)
          _emptyOutput(detail.controller)
        else
          _outputTable(detail, compact: true),
      ],
      action: 'Xem tất cả →',
      onAction: () => _tabs.animateTo(2),
    );
  }

  Widget _sensorsTab(ControllerDetail detail, {required bool full}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.sensors.isEmpty)
          MgmtEmptyState(
            icon: Icons.sensors,
            title: 'Controller chưa có Sensor.',
            message: 'Thêm cảm biến để Controller bắt đầu thu thập dữ liệu.',
            action: MgmtPrimaryButton(
              label: 'Thêm Sensor',
              icon: Icons.add,
              onTap: () => _addSensor(detail.controller),
            ),
          )
        else
          _card(
            'Sensors (${detail.sensors.length})',
            Icons.sensors,
            [_sensorTable(detail, compact: false)],
            action: '+ Thêm Sensor',
            onAction: () => _addSensor(detail.controller),
          ),
      ],
    );
  }

  Widget _outputsTab(ControllerDetail detail) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.actuators.isEmpty)
          MgmtEmptyState(
            icon: Icons.settings_input_component,
            title: 'Chưa có thiết bị đầu ra được liên kết.',
            message: 'Controller này hiện chỉ dùng để đọc cảm biến.',
            action: MgmtPrimaryButton(
              label: 'Liên kết thiết bị',
              icon: Icons.add,
              onTap: () => _linkOutput(),
            ),
          )
        else
          _card(
            'Outputs / Thiết bị điều khiển (${detail.actuators.length})',
            Icons.settings_input_component,
            [_outputTable(detail, compact: false)],
            action: '+ Liên kết thiết bị',
            onAction: _linkOutput,
          ),
      ],
    );
  }

  Widget _networkTab(IoTDevice d) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Mạng & hệ thống', Icons.lan_outlined, [
          if ((d.ipLan ?? '').isNotEmpty) _kv('IP', d.ipLan!),
          if ((d.macAddress ?? '').isNotEmpty) _kv('MAC', d.macAddress!),
          if (d.rssiDbm != null) _kv('RSSI', '${d.rssiDbm!.round()} dBm'),
          if ((d.firmwareVersion ?? '').isNotEmpty)
            _kv('Firmware', 'v${d.firmwareVersion}'),
          if (d.lastSeenAt != null)
            _kv('Heartbeat cuối', fmtDateTimeVn(d.lastSeenAt)),
          _kv('Heartbeat interval', '2 giây (cấu hình UI)'),
          _kv('API', d.isOnline ? 'Bình thường' : 'Không nhận heartbeat'),
          _kv('Trạng thái', d.isOnline ? 'Online' : 'Offline'),
        ]),
      ],
    );
  }

  Widget _historyTab(IoTDevice d) {
    final logs = _logsOf(d);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Lịch sử', Icons.history, [
          if (d.lastSeenAt != null)
            _histRow(
                d.lastSeenAt!,
                'Controller',
                d.isOnline ? 'Controller online' : 'Controller offline',
                'System'),
          if (logs.isEmpty && d.lastSeenAt == null)
            Text('Chưa có lịch sử Controller.',
                style: bvText(color: DashboardColors.textMuted))
          else
            for (final e in logs.take(20))
              _histRow(
                  e.at,
                  e.subjectDetail.isEmpty ? 'Controller' : e.subjectDetail,
                  e.content,
                  e.performer.isEmpty
                      ? (e.isAuto ? 'System' : 'Thủ công')
                      : e.performer),
        ]),
      ],
    );
  }

  Widget _sensorTable(ControllerDetail detail, {required bool compact}) {
    final d = detail.controller;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: bvText(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textMuted),
        dataTextStyle: bvText(fontSize: 12.5),
        columns: [
          const DataColumn(label: Text('TÊN SENSOR')),
          const DataColumn(label: Text('LOẠI')),
          if (!compact) const DataColumn(label: Text('INTERFACE')),
          const DataColumn(label: Text('CHANNEL')),
          DataColumn(label: Text(d.isOffline ? 'GIÁ TRỊ CUỐI' : 'GIÁ TRỊ')),
          const DataColumn(label: Text('ĐƠN VỊ')),
          if (!compact) const DataColumn(label: Text('HIỆU CHUẨN')),
          const DataColumn(label: Text('CẬP NHẬT')),
          const DataColumn(label: Text('TRẠNG THÁI')),
          if (!compact) const DataColumn(label: Text('')),
        ],
        rows: [
          for (final s in detail.sensors)
            DataRow(cells: [
              DataCell(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_sensorTitle(s),
                      style:
                          bvText(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  Text(s.code,
                      style: bvText(
                          fontSize: 11, color: DashboardColors.textMuted)),
                ],
              )),
              DataCell(Text(s.type ?? '—')),
              if (!compact) const DataCell(Text('—')),
              const DataCell(Text('—')),
              DataCell(Text(_fmtValue(s))),
              DataCell(Text(s.unit ?? '—')),
              if (!compact)
                DataCell(Text([
                  if (s.minThreshold != null) 'Min ${s.minThreshold}',
                  if (s.maxThreshold != null) 'Max ${s.maxThreshold}',
                ].join(' · ').ifEmpty('—'))),
              DataCell(Text(
                  s.lastUpdatedAt == null ? '—' : _hhmmss(s.lastUpdatedAt!))),
              DataCell(_sensorStatus(s, d)),
              if (!compact)
                DataCell(PopupMenuButton<String>(
                  tooltip: 'Thao tác sensor',
                  onSelected: (a) => _onSensorMenu(a, s, detail.controller),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'detail', child: Text('Xem chi tiết')),
                    const PopupMenuItem(
                        value: 'edit', child: Text('Chỉnh sửa sensor')),
                    const PopupMenuItem(
                        value: 'cal', child: Text('Hiệu chuẩn')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Xóa sensor')),
                    const PopupMenuItem(
                        value: 'off', child: Text('Tắt sensor')),
                    const PopupMenuItem(
                        value: 'hist', child: Text('Xem lịch sử')),
                  ],
                )),
            ]),
        ],
      ),
    );
  }

  Widget _outputTable(ControllerDetail detail, {required bool compact}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: bvText(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textMuted),
        dataTextStyle: bvText(fontSize: 12.5),
        columns: const [
          DataColumn(label: Text('TÊN THIẾT BỊ')),
          DataColumn(label: Text('LOẠI')),
          DataColumn(label: Text('RELAY')),
          DataColumn(label: Text('GPIO')),
          DataColumn(label: Text('KẾT NỐI')),
          DataColumn(label: Text('OPERATING')),
          DataColumn(label: Text('RAS')),
        ],
        rows: [
          for (final a in detail.actuators)
            DataRow(cells: [
              DataCell(Text(a.name.isEmpty ? a.code : a.name,
                  style: bvText(fontWeight: FontWeight.w700))),
              DataCell(Text(a.type ?? '—')),
              DataCell(
                  Text((a.relayChannel ?? '').isEmpty ? '—' : a.relayChannel!)),
              const DataCell(Text('—')),
              DataCell(Text(
                detail.controller.isOnline ? 'Online' : 'Offline',
                style: bvText(
                    color: detail.controller.isOnline
                        ? DashboardColors.brand
                        : _kSlate,
                    fontWeight: FontWeight.w700),
              )),
              DataCell(Text(
                a.isOn == null ? '—' : (a.isOn! ? 'ON' : 'OFF'),
                style: bvText(
                    fontWeight: FontWeight.w800,
                    color: a.isOn == true
                        ? DashboardColors.brand
                        : DashboardColors.textMuted),
              )),
              DataCell(Text(a.name.isEmpty ? a.code : a.name)),
            ]),
        ],
      ),
    );
  }

  Widget _emptyOutput(IoTDevice d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chưa có thiết bị đầu ra được liên kết.',
            style: bvText(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Controller này hiện chỉ dùng để đọc cảm biến.',
            style: bvText(color: DashboardColors.textMuted, fontSize: 12.5)),
        const SizedBox(height: 8),
        MgmtOutlineButton(
            onTap: _linkOutput, icon: Icons.add, label: 'Liên kết thiết bị'),
      ],
    );
  }

  Widget _alertsPanel(IoTDevice d) {
    final alerts = _alertsOf(d);
    return _card(
      'Cảnh báo gần đây',
      Icons.warning_amber_rounded,
      [
        if (alerts.isEmpty)
          Text('Không có cảnh báo gắn với Controller này.',
              style: bvText(
                  color: DashboardColors.brand, fontWeight: FontWeight.w600))
        else
          for (final a in alerts.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                      width: 72,
                      child: Text(a.detectedAt.isEmpty ? a.time : a.time,
                          style: bvText(
                              fontSize: 12, color: DashboardColors.textMuted))),
                  Expanded(
                      child: Text(a.device.isEmpty ? 'Controller' : a.device,
                          style: bvText(
                              fontSize: 12.5, fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 2,
                      child: Text(a.title, style: bvText(fontSize: 12.5))),
                  MgmtStatusBadge(
                    label: a.isOpen ? 'Đang mở' : 'Đã xử lý',
                    color: a.isOpen ? _kAmber : DashboardColors.brand,
                  ),
                ],
              ),
            ),
      ],
      action: 'Xem tất cả →',
      onAction: () => widget.onNavigate?.call(AppRoute.alerts),
    );
  }

  Widget _activityPanel(IoTDevice d) {
    final logs = _logsOf(d);
    return _card(
      'Hoạt động gần đây',
      Icons.history,
      [
        if (d.lastSeenAt != null)
          _histRow(d.lastSeenAt!, 'Controller',
              d.isOnline ? 'Nhận heartbeat' : 'Mất kết nối', 'System'),
        if (logs.isEmpty && d.lastSeenAt == null)
          Text('Chưa có hoạt động Controller.',
              style: bvText(color: DashboardColors.textMuted))
        else
          for (final e in logs.take(6))
            _histRow(
                e.at,
                'Controller',
                e.content,
                e.performer.isEmpty
                    ? (e.isAuto ? 'System' : 'Thủ công')
                    : e.performer),
      ],
      action: 'Xem tất cả →',
      onAction: () => widget.onNavigate?.call(AppRoute.farmLogs),
    );
  }

  Widget _histRow(DateTime at, String device, String action, String source) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 52,
              child: Text(_hhmm(at),
                  style:
                      bvText(fontSize: 12, color: DashboardColors.textMuted))),
          Expanded(
              child: Text(device,
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text(action, style: bvText(fontSize: 12.5))),
          Text(source,
              style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children,
      {String? action, VoidCallback? onAction}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 6),
              Expanded(
                  child:
                      Text(title, style: bvText(fontWeight: FontWeight.w800))),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(action,
                      style: bvText(
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.brand,
                          fontSize: 12.5)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Text(k,
                  style: bvText(
                      fontSize: 12.5, color: DashboardColors.textMuted))),
          Expanded(
              child: Text(v,
                  style: bvText(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color))),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('⚠ $msg', style: bvText(color: _kRed))),
          MgmtOutlineButton(onTap: retry, label: 'Thử lại'),
        ],
      ),
    );
  }

  Future<void> _check(IoTDevice d) async {
    setState(() => _checking = true);
    final ok = await _svc.checkConnection(d);
    if (!mounted) return;
    setState(() => _checking = false);
    _toast(ok ? '✓ Controller phản hồi' : '⚠ Không thể kết nối Controller.');
  }

  Future<void> _restart(IoTDevice d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Khởi động lại ${d.deviceName ?? d.deviceCode}?',
            style: bvText(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Controller có thể mất kết nối trong vài giây trong quá trình khởi động lại.',
          style: bvText(height: 1.45),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
            child: const Text('Khởi động lại'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final sent = await _svc.restart(d);
    if (!mounted) return;
    _toast(sent
        ? 'Đã gửi lệnh khởi động lại. Đang chờ heartbeat mới.'
        : '⚠ Không có kênh điều khiển để khởi động lại.');
  }

  void _onMenu(String action, IoTDevice d, ControllerDetail detail) {
    switch (action) {
      case 'detail':
        _tabs.animateTo(0);
      case 'edit':
        _edit(d);
      case 'wifi':
        _wifi(d);
      case 'sensors':
        _tabs.animateTo(1);
      case 'outputs':
        _tabs.animateTo(2);
      case 'alerts':
        widget.onNavigate?.call(AppRoute.alerts);
      case 'history':
        _tabs.animateTo(4);
      case 'disable':
        _deactivate(d, detail);
    }
  }

  Future<void> _deactivate(IoTDevice d, ControllerDetail detail) async {
    final ok = await showDisableControllerDialog(
      context,
      service: _svc,
      device: d,
      sensorCount: detail.sensors.length,
      outputCount: detail.actuators.length,
    );
    if (mounted && ok == true)
      _toast('Đã vô hiệu hóa ${d.deviceName ?? d.deviceCode}.');
  }

  Future<void> _edit(IoTDevice d) async {
    final result = await showEditControllerDialog(
      context,
      service: _svc,
      device: d,
      rowService: widget.rowService,
    );
    if (!mounted || result == null) return;
    switch (result) {
      case EditControllerOutcome.saved:
        _toast('✓ Đã cập nhật ${d.deviceName ?? d.deviceCode}.');
      case EditControllerOutcome.disabled:
        _toast('Đã vô hiệu hóa ${d.deviceName ?? d.deviceCode}.');
    }
  }

  Future<void> _wifi(IoTDevice d) async {
    await showControllerNetworkDialog(
      context,
      service: _svc,
      device: d,
      online: d.isOnline,
    );
  }

  Future<void> _addSensor(IoTDevice d) async {
    final code = TextEditingController(text: '${d.deviceCode}-');
    final type = TextEditingController(text: 'pH');
    final unit = TextEditingController(text: 'pH');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Thêm Sensor', style: bvText(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Mã sensor')),
              TextField(
                  controller: type,
                  decoration: const InputDecoration(labelText: 'Loại')),
              TextField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Đơn vị')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thêm')),
        ],
      ),
    );
    if (ok != true) return;
    final saved = await _svc.addSensor(
      deviceId: d.id,
      sensorCode: code.text.trim(),
      sensorType: type.text.trim(),
      unit: unit.text.trim(),
    );
    if (mounted)
      _toast(saved
          ? 'Đã thêm Sensor.'
          : (_svc.detailError ?? 'Không thêm được sensor.'));
  }

  void _linkOutput() {
    _toast(
        'Liên kết output thực hiện trên Điều khiển RAS — không gán RelayDeviceId trên UI này.');
    widget.onNavigate?.call(AppRoute.devices);
  }

  Future<void> _onSensorMenu(String a, ControllerChild s, IoTDevice d) async {
    switch (a) {
      case 'detail':
        _tabs.animateTo(1);
      case 'edit':
        await _editSensor(s);
      case 'cal':
        await _calibrate(s);
      case 'delete':
        await _deleteSensor(s);
      case 'off':
        await _svc.updateSensor(sensorId: s.id, isActive: false);
        if (mounted) _toast('Đã tắt sensor ${s.code}.');
      case 'hist':
        widget.onNavigate?.call(AppRoute.environment);
    }
  }

  Future<void> _editSensor(ControllerChild s) async {
    final type = TextEditingController(text: s.type ?? s.name);
    final unit = TextEditingController(text: s.unit ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chỉnh sửa ${s.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: s.code),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Mã sensor'),
            ),
            TextField(
              controller: type,
              decoration: const InputDecoration(labelText: 'Loại'),
            ),
            TextField(
              controller: unit,
              decoration: const InputDecoration(labelText: 'Đơn vị'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    final saved = await _svc.updateSensor(
      sensorId: s.id,
      sensorType: type.text.trim(),
      unit: unit.text.trim(),
    );
    if (mounted)
      _toast(saved
          ? 'Đã cập nhật ${s.code}.'
          : (_svc.detailError ?? 'Không cập nhật được sensor.'));
  }

  Future<void> _deleteSensor(ControllerChild s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa ${s.code}?'),
        content: const Text(
          'Sensor đã có dữ liệu đo sẽ không thể xóa; hãy tắt sensor thay thế.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await _svc.deleteSensor(s.id);
    if (mounted)
      _toast(deleted
          ? 'Đã xóa ${s.code}.'
          : (_svc.detailError ?? 'Không xóa được sensor.'));
  }

  Future<void> _calibrate(ControllerChild s) async {
    final min = TextEditingController(text: s.minThreshold?.toString() ?? '');
    final max = TextEditingController(text: s.maxThreshold?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Hiệu chuẩn ${_sensorTitle(s)}',
            style: bvText(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ngưỡng lấy từ backend. UI không tự nhân/chia giá trị đo.',
                  style: bvText(color: DashboardColors.textMuted)),
              TextField(
                  controller: min,
                  decoration:
                      const InputDecoration(labelText: 'Min threshold')),
              TextField(
                  controller: max,
                  decoration:
                      const InputDecoration(labelText: 'Max threshold')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    await _svc.updateSensor(
      sensorId: s.id,
      minThreshold: double.tryParse(min.text.trim()),
      maxThreshold: double.tryParse(max.text.trim()),
    );
  }
}

class _ControllerCard extends StatelessWidget {
  const _ControllerCard({
    required this.device,
    required this.selected,
    required this.warning,
    required this.onTap,
  });

  final IoTDevice device;
  final bool selected;
  final bool warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = device.isOnline &&
        device.lastSeenAt != null &&
        DateTime.now().difference(device.lastSeenAt!.toLocal()) <=
            _kHeartbeatOnline;
    final border = selected
        ? (warning ? _kAmber : DashboardColors.brand)
        : (warning
            ? _kAmber.withValues(alpha: 0.55)
            : DashboardColors.cardBorder);
    return Material(
      color: selected ? DashboardColors.lightMint : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.memory,
                      size: 18, color: DashboardColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.deviceName ?? device.deviceCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _statusBadge(device, warning: warning),
                ],
              ),
              const SizedBox(height: 6),
              Text(_areaLabel(device),
                  style:
                      bvText(fontSize: 12, color: DashboardColors.textMuted)),
              const SizedBox(height: 4),
              Text(
                '${device.sensorCount} sensors • ${device.actuatorCount} outputs',
                style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                live
                    ? '● Live • 2s'
                    : (device.isOnline
                        ? 'Cập nhật: ${_rel(device.lastSeenAt)}'
                        : 'Last seen: ${_rel(device.lastSeenAt)}'),
                style: bvText(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color:
                      live ? DashboardColors.brand : DashboardColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _statusBadge(IoTDevice d, {required bool warning}) {
  final label = warning && d.isOnline
      ? 'Cảnh báo'
      : d.status.toLowerCase() == 'error'
          ? 'Lỗi'
          : d.isOnline
              ? 'Online'
              : 'Offline';
  final color = warning
      ? _kAmber
      : d.isOnline
          ? DashboardColors.brand
          : _kSlate;
  return MgmtStatusBadge(label: label, color: color);
}

Widget _sensorStatus(ControllerChild s, IoTDevice controller) {
  if (!s.isActive) return const MgmtStatusBadge(label: 'Tắt', color: _kSlate);
  if (controller.isOffline) {
    return const MgmtStatusBadge(label: 'Dữ liệu cũ', color: _kAmber);
  }
  return switch (_sensorFreshness(s, controller)) {
    _Fresh.realtime =>
      const MgmtStatusBadge(label: 'Realtime', color: DashboardColors.brand),
    _Fresh.slow =>
      const MgmtStatusBadge(label: 'Chậm cập nhật', color: _kAmber),
    _Fresh.stale => const MgmtStatusBadge(label: 'Dữ liệu cũ', color: _kAmber),
  };
}

enum _Fresh { realtime, slow, stale }

_Fresh _sensorFreshness(ControllerChild s, IoTDevice controller) {
  final at = s.lastUpdatedAt;
  if (at == null) return _Fresh.stale;
  final age = DateTime.now().difference(at.toLocal());
  if (age <= _kSensorRealtime) return _Fresh.realtime;
  if (age <= _kSensorSlow) return _Fresh.slow;
  return _Fresh.stale;
}

String _sensorTitle(ControllerChild s) {
  final t = (s.type ?? s.name).toLowerCase();
  if (t.contains('ph')) return 'pH';
  if (t.contains('tds')) return 'TDS';
  if (t.contains('temp')) return 'Nhiệt độ';
  if (t.contains('do') || t.contains('oxy')) return 'DO';
  return s.name.isEmpty ? s.code : s.name;
}

String _fmtValue(ControllerChild s) {
  final v = s.latestValue;
  if (v == null) return '—';
  final t = (s.type ?? s.unit ?? s.name).toLowerCase();
  if (t.contains('tds')) return v.round().toString();
  if (t.contains('ph')) return v.toStringAsFixed(2);
  return v.toStringAsFixed(2);
}

String _areaLabel(IoTDevice d) {
  final name = d.areaName ?? '';
  final code = d.areaCode ?? '';
  if (name.isEmpty && code.isEmpty) return '—';
  if (code.isEmpty) return name;
  if (name.isEmpty) return code;
  return '$name ($code)';
}

String _rel(DateTime? at) {
  if (at == null) return 'Chưa từng';
  final d = DateTime.now().difference(at.toLocal());
  if (d.inSeconds < 15) return 'vừa xong';
  if (d.inMinutes < 1) return '${d.inSeconds} giây trước';
  if (d.inHours < 1) return '${d.inMinutes} phút trước';
  if (d.inHours < 48) return '${d.inHours} giờ trước';
  return fmtDateTimeVn(at);
}

String _dur(Duration d) {
  if (d.inHours >= 1) return '${d.inHours} giờ ${d.inMinutes % 60} phút';
  if (d.inMinutes >= 1) return '${d.inMinutes} phút';
  return '${d.inSeconds} giây';
}

String _hhmm(DateTime at) {
  final l = at.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String _hhmmss(DateTime at) {
  final l = at.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
