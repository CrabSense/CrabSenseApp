import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/area_environment_metric.dart';
import '../../models/ras_flow.dart';
import '../../navigation/app_route.dart';
import '../../services/area_environment_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kBlue = Color(0xFF2495E8);
const _kStale = Duration(seconds: 30);

class RasControlPage extends StatefulWidget {
  const RasControlPage({
    super.key,
    required this.service,
    required this.areaId,
    this.areaName,
    this.areaCode,
    this.environment,
    this.onNavigate,
  });

  final RasFlowService service;
  final String areaId;
  final String? areaName;
  final String? areaCode;
  final AreaEnvironmentService? environment;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<RasControlPage> createState() => _RasControlPageState();
}

class _RasControlPageState extends State<RasControlPage> {
  final _pending = <String, String>{};
  var _systemBusy = false;

  RasFlowService get _svc => widget.service;
  AreaEnvironmentService? get _env => widget.environment;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    _env?.addListener(_onUpdate);
    _svc.startLiveRefresh(widget.areaId);
    _env?.startLiveRefresh(widget.areaId);
  }

  @override
  void didUpdateWidget(RasControlPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) {
      _svc.startLiveRefresh(widget.areaId);
      _env?.startLiveRefresh(widget.areaId);
    }
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    _env?.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    final nodes = _svc.diagram?.nodes ?? const <RasFlowNodeLive>[];
    for (final n in nodes) {
      final cmd = _pending[n.id];
      if (cmd == null) continue;
      if (_acked(n, cmd)) _pending.remove(n.id);
    }
    setState(() {});
  }

  bool _acked(RasFlowNodeLive n, String cmd) {
    final c = cmd.toLowerCase();
    if (c == 'auto') return n.isAuto;
    if (c == 'manual') return !n.isAuto;
    if (c == 'on' || c == 'start') return n.isOn == true && !n.isAuto;
    if (c == 'off' || c == 'stop') return n.isOn != true;
    return true;
  }

  List<RasFlowNodeLive> get _nodes => _svc.diagram?.nodes ?? const [];
  List<RasFlowNodeLive> get _devices => _nodes.where((n) => n.hasRelay).toList();

  bool get _systemAuto =>
      _devices.isNotEmpty && _devices.every((n) => n.isAuto);

  bool get _controllerOnline =>
      _devices.isEmpty
          ? _nodes.any((n) => n.isOnline != false)
          : _devices.any((n) => n.isOnline != false);

  int get _running => _devices
      .where((n) => n.isOn == true && !_isError(n) && n.isOnline != false)
      .length;
  int get _off =>
      _devices.where((n) => n.isOn != true && !_isError(n)).length;
  int get _errors => _nodes.where(_isError).length;
  bool _isError(RasFlowNodeLive n) {
    final s = n.status.toLowerCase();
    return s == 'alarm' || s == 'error';
  }

  bool get _stale {
    final at = _svc.lastRefreshedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) > _kStale;
  }

  String get _ago {
    final at = _svc.lastRefreshedAt;
    if (at == null) return '—';
    final s = DateTime.now().difference(at).inSeconds;
    if (s < 2) return 'vừa xong';
    return '$s giây trước';
  }

  Future<void> _cmd(RasFlowNodeLive node, String command) async {
    if (_pending.containsKey(node.id) || _systemBusy) return;
    if (node.isOnline == false) {
      _toast('⚠ Không thể gửi lệnh. Controller / thiết bị mất kết nối.');
      return;
    }
    setState(() => _pending[node.id] = command);
    final ok = await _svc.sendCommand(
      areaId: widget.areaId,
      nodeId: node.id,
      command: command,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _pending.remove(node.id));
      _toast(
        '⚠ Không thể ${_cmdVerb(command)} ${_deviceTitle(node)}.\n'
        '${_svc.error ?? 'Controller không phản hồi.'}',
      );
      return;
    }
    _toast('✓ ${_deviceTitle(node)} ${_cmdDone(command)}.');
  }

  Future<void> _sendOn(RasFlowNodeLive node) async {
    final reason = _interlockBlock(node);
    if (reason != null) {
      _toast('⚠ Không thể bật ${_deviceTitle(node)}.\n$reason');
      return;
    }
    await _cmd(node, node.nodeCode == 'drum' ? 'start' : 'on');
  }

  String? _interlockBlock(RasFlowNodeLive node) {
    final p = _params(node);
    final raw = p?['interlock'] ?? p?['requiresOn'];
    if (raw == null) return null;
    final required = '$raw';
    if (required.isEmpty) return null;
    RasFlowNodeLive? other;
    for (final n in _devices) {
      if (n.id == required ||
          n.nodeCode.toLowerCase() == required.toLowerCase() ||
          n.displayLabel.toLowerCase() == required.toLowerCase()) {
        other = n;
        break;
      }
    }
    if (other == null) return null;
    if (other.isOn == true) return null;
    return '${_deviceTitle(other)} đang OFF.';
  }

  String _cmdVerb(String c) => switch (c) {
        'on' || 'start' => 'bật',
        'off' || 'stop' => 'tắt',
        'auto' => 'chuyển AUTO',
        'manual' => 'chuyển MANUAL',
        _ => 'điều khiển',
      };

  String _cmdDone(String c) => switch (c) {
        'on' || 'start' => 'đã nhận lệnh bật',
        'off' || 'stop' => 'đã nhận lệnh tắt',
        'auto' => 'đã chuyển AUTO',
        'manual' => 'đã chuyển MANUAL',
        _ => 'đã nhận lệnh',
      };

  Future<void> _setSystemMode(bool auto) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          auto ? 'Khôi phục chế độ AUTO?' : 'Chuyển hệ thống sang chế độ MANUAL?',
          style: bvText(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          auto
              ? 'Các rule và lịch tự động sẽ được áp dụng trở lại.'
              : 'Hệ thống sẽ ngừng tự động điều khiển theo lịch/rule cho đến khi quay lại AUTO.',
          style: bvText(height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
            child: Text(auto ? 'Chuyển sang AUTO' : 'Chuyển sang MANUAL'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _systemBusy = true);
    final cmd = auto ? 'auto' : 'manual';
    for (final n in _devices) {
      await _svc.sendCommand(areaId: widget.areaId, nodeId: n.id, command: cmd);
    }
    if (mounted) setState(() => _systemBusy = false);
  }

  Future<void> _emergencyStop() async {
    var typed = false;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Dừng khẩn cấp hệ thống RAS?', style: bvText(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tất cả thiết bị điều khiển được sẽ nhận lệnh dừng nếu trạng thái kết nối cho phép.',
                style: bvText(height: 1.45),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: typed,
                onChanged: (v) => setLocal(() => typed = v == true),
                title: Text('Tôi hiểu đây là lệnh dừng khẩn cấp.', style: bvText(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _kRed,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(
              onPressed: typed ? () => Navigator.pop(ctx, true) : null,
              style: FilledButton.styleFrom(backgroundColor: _kRed),
              child: const Text('Dừng hệ thống'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _systemBusy = true);
    for (final n in _devices.where((e) => e.isOnline != false)) {
      await _svc.sendCommand(areaId: widget.areaId, nodeId: n.id, command: 'off');
    }
    if (mounted) {
      setState(() => _systemBusy = false);
      _toast('Đã gửi lệnh dừng khẩn cấp.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final diagram = _svc.diagram;
    final loading = _svc.loading && diagram == null;
    final areaLabel = [
      if ((widget.areaName ?? diagram?.areaName ?? '').isNotEmpty)
        widget.areaName ?? diagram?.areaName,
      if ((widget.areaCode ?? diagram?.areaCode ?? '').isNotEmpty)
        '(${widget.areaCode ?? diagram?.areaCode})',
    ].join(' ');

    return ListenableBuilder(
      listenable: Listenable.merge([_svc, if (_env != null) _env!]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(areaLabel),
              const SizedBox(height: 12),
              if (loading) _chipSkeleton() else _summaryChips(),
              if (_svc.error != null && diagram == null) ...[
                const SizedBox(height: 14),
                _errorBanner(),
              ],
              const SizedBox(height: 16),
              _flowCard(loading),
              const SizedBox(height: 18),
              _deviceHeader(),
              const SizedBox(height: 12),
              if (loading)
                _deviceSkeleton()
              else if (_devices.isEmpty)
                _emptyDevices()
              else
                _deviceGrid(),
              const SizedBox(height: 18),
              _bottomPanels(),
            ],
          ),
        );
      },
    );
  }

  Widget _header(String areaLabel) {
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
          child: const Icon(Icons.settings_input_component, color: DashboardColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điều khiển hệ thống RAS',
                style: bvText(fontSize: 22, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                areaLabel.isEmpty ? 'Khu vực đang chọn trên thanh trên' : 'Khu vực: $areaLabel',
                style: bvText(fontSize: 13, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: _systemAuto ? 'Chế độ AUTO MODE' : 'Chế độ MANUAL MODE',
          child: _modeBadge(),
        ),
      ],
    );
  }

  Widget _modeBadge() {
    final auto = _systemAuto || _devices.isEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _devices.isEmpty || _systemBusy ? null : () => _setSystemMode(!auto),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (auto ? DashboardColors.brand : _kAmber).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: auto ? DashboardColors.brand : _kAmber),
          ),
          child: Row(
            children: [
              Icon(auto ? Icons.settings_suggest_outlined : Icons.pan_tool_outlined,
                  size: 18, color: auto ? DashboardColors.brand : _kAmber),
              const SizedBox(width: 8),
              Text(
                auto ? 'AUTO MODE' : 'MANUAL MODE',
                style: bvText(
                  fontWeight: FontWeight.w800,
                  color: auto ? DashboardColors.brand : _kAmber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChips() {
    final systemOk = _svc.diagram != null && _errors == 0 && _controllerOnline;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                systemOk ? 'Hệ thống đang hoạt động' : (_controllerOnline ? 'Hệ thống có sự cố' : 'Hệ thống mất kết nối'),
                systemOk ? DashboardColors.brand : _kRed,
              ),
              _chip(
                _controllerOnline ? 'Controller Online' : 'Controller mất kết nối',
                _controllerOnline ? DashboardColors.brand : _kRed,
                icon: Icons.wifi,
              ),
              _chip('$_running Thiết bị đang chạy', DashboardColors.brand, icon: Icons.play_circle_outline),
              _chip('$_off Thiết bị đang tắt', DashboardColors.textMuted, icon: Icons.pause_circle_outline),
              _chip('$_errors Thiết bị lỗi', _errors == 0 ? DashboardColors.brand : _kRed, icon: Icons.error_outline),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          liveRegion: true,
          label: _stale ? 'Dữ liệu đã cũ' : 'Cập nhật $_ago',
          child: Text(
            _stale ? '⚠ Dữ liệu đã cũ' : '● Cập nhật: $_ago',
            style: bvText(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _stale ? _kAmber : DashboardColors.brand,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ] else ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label, style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _flowCard(bool loading) {
    final sensors = _sensorChips();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Sơ đồ tuần hoàn RAS', style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
              ...sensors,
              TextButton(
                onPressed: () => widget.onNavigate?.call(AppRoute.environment),
                child: Text(
                  'Xem giám sát realtime →',
                  style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            _flowSkeleton()
          else if (_nodes.isEmpty)
            Text('Chưa có sơ đồ tuần hoàn cho khu này.', style: bvText(color: DashboardColors.textMuted))
          else
            _RasMintFlow(nodes: _nodes, titleOf: _flowTitle),
        ],
      ),
    );
  }

  List<Widget> _sensorChips() {
    final metrics = _env?.data?.metrics ?? const <AreaEnvironmentMetric>[];
    AreaEnvironmentMetric? find(bool Function(AreaEnvironmentMetric) t) {
      for (final m in metrics) {
        if (t(m)) return m;
      }
      return null;
    }

    final items = [
      find((m) => m.label.contains('Nhiệt') || (m.sensorType ?? '').toLowerCase().contains('temp')),
      find((m) => m.label.toLowerCase() == 'ph' || (m.sensorType ?? '').toLowerCase().contains('ph')),
      find((m) => m.label.contains('Oxy') || (m.sensorType ?? '').toLowerCase().contains('do')),
      find((m) => m.label.contains('TDS') || (m.sensorType ?? '').toLowerCase().contains('tds')),
    ].whereType<AreaEnvironmentMetric>().toList();

    return [
      for (final m in items)
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Tooltip(
            message: [
              if ((m.sensorCode ?? '').isNotEmpty) 'Nguồn: ${m.sensorCode}',
              if ((m.locationName ?? '').isNotEmpty) 'Phạm vi: ${m.locationName}',
            ].join('\n'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: DashboardColors.brand),
                const SizedBox(width: 5),
                Text('${_sensorLabel(m)}  ', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
                Text(
                  '${m.value.toStringAsFixed(1)}${m.unit.isEmpty ? '' : ' ${m.unit}'}',
                  style: bvText(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _deviceHeader() {
    return Row(
      children: [
        Expanded(
          child: Text('Thiết bị điều khiển', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            MgmtOutlineButton(
              onTap: _devices.isEmpty ? null : () => _openAutoConfig(),
              icon: Icons.settings_outlined,
              label: 'Cấu hình AUTO',
            ),
            MgmtOutlineButton(
              onTap: _devices.isEmpty ? null : () => _openSchedule(),
              icon: Icons.calendar_month_outlined,
              label: 'Lịch chạy',
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Dừng khẩn cấp hệ thống RAS',
              child: MgmtOutlineButton(
                onTap: _devices.isEmpty || _systemBusy ? null : _emergencyStop,
                icon: Icons.warning_amber_rounded,
                label: 'Dừng khẩn cấp hệ thống',
                color: _kRed,
                tooltip: 'Dừng tất cả thiết bị điều khiển được',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _deviceGrid() {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final n in _devices)
              SizedBox(
                width: w,
                child: _DeviceCard(
                  node: n,
                  title: _deviceTitle(n),
                  pending: _pending[n.id],
                  commandSource: _commandSource(n),
                  onAuto: () => _cmd(n, 'auto'),
                  onManual: () => _cmd(n, 'manual'),
                  onOn: () => _sendOn(n),
                  onOff: () => _cmd(n, 'off'),
                  onMenu: (a) => _onDeviceMenu(n, a),
                  onOpenController: () => widget.onNavigate?.call(AppRoute.controllers),
                ),
              ),
          ],
        );
      },
    );
  }

  RasFlowNodeLive? _nodeFromEvent(RasControlEvent e) {
    final t = e.title.toLowerCase();
    for (final n in _nodes) {
      if (t.contains(n.displayLabel.toLowerCase()) ||
          t.contains(_deviceTitle(n).toLowerCase()) ||
          (e.detail ?? '').contains(n.id)) {
        return n;
      }
    }
    return null;
  }

  RasControlEvent? _lastEvent(RasFlowNodeLive n) {
    final events = _svc.diagram?.activity ?? const <RasControlEvent>[];
    for (final e in events) {
      if (e.title.toLowerCase().contains(n.displayLabel.toLowerCase()) ||
          e.title.toLowerCase().contains(_deviceTitle(n).toLowerCase()) ||
          (e.detail ?? '').contains(n.id)) {
        return e;
      }
    }
    return events.isEmpty ? null : null;
  }

  void _onDeviceMenu(RasFlowNodeLive n, String action) {
    switch (action) {
      case 'history':
        _openActivityDetail(_lastEvent(n), n);
      case 'controller':
        widget.onNavigate?.call(AppRoute.controllers);
      case 'auto':
        _openAutoConfig(focus: n);
      case 'schedule':
        _openSchedule(focus: n);
      case 'on':
        _sendOn(n);
      case 'off':
        _cmd(n, 'off');
    }
  }

  Widget _emptyDevices() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          const Icon(Icons.settings_outlined, size: 36, color: DashboardColors.brand),
          const SizedBox(height: 10),
          Text('Chưa có thiết bị RAS được cấu hình.', style: bvText(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          MgmtOutlineButton(
            onTap: () => widget.onNavigate?.call(AppRoute.controllers),
            label: 'Quản lý Controller →',
          ),
        ],
      ),
    );
  }

  Widget _bottomPanels() {
    final alerts = _alerts();
    final events = _svc.diagram?.activity ?? const <RasControlEvent>[];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 1000;
        final left = _panel(
          title: 'Cảnh báo thiết bị',
          icon: Icons.warning_amber_rounded,
          action: 'Xem tất cả →',
          onAction: () => widget.onNavigate?.call(AppRoute.alerts),
          child: _svc.loading && _svc.diagram == null
              ? _listSkeleton(2)
              : alerts.isEmpty
                  ? Text('Không có cảnh báo thiết bị đang mở.', style: bvText(color: DashboardColors.brand, fontWeight: FontWeight.w600))
                  : Column(
                      children: [
                        for (final a in alerts.take(6)) _alertRow(a),
                      ],
                    ),
        );
        final right = _panel(
          title: 'Hoạt động gần đây',
          icon: Icons.history_rounded,
          action: 'Xem tất cả →',
          onAction: () => widget.onNavigate?.call(AppRoute.farmLogs),
          child: _svc.loading && _svc.diagram == null
              ? _listSkeleton(5)
              : events.isEmpty
                  ? Text('Chưa có lệnh điều khiển trên khu này.', style: bvText(color: DashboardColors.textMuted))
                  : Column(
                      children: [
                        for (final e in events.take(8))
                          InkWell(
                            onTap: () => _openActivityDetail(e, null),
                            child: _activityRow(e),
                          ),
                      ],
                    ),
        );
        if (!wide) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 55, child: left),
            const SizedBox(width: 12),
            Expanded(flex: 45, child: right),
          ],
        );
      },
    );
  }

  List<_RasAlert> _alerts() {
    final out = <_RasAlert>[];
    for (final n in _nodes) {
      if (_isError(n) || (n.alertMessage != null && n.alertMessage!.isNotEmpty)) {
        out.add(_RasAlert(
          title: n.alertMessage?.isNotEmpty == true
              ? n.alertMessage!
              : '${_deviceTitle(n)} đang lỗi',
          device: _deviceTitle(n),
          at: n.lastCommandAt,
          value: n.currentA,
          threshold: _ruleNum(n, const ['currentMax', 'maxCurrentA', 'ampThreshold']),
          unit: n.currentA != null ? 'A' : null,
        ));
      }
      final maxA = _ruleNum(n, const ['currentMax', 'maxCurrentA', 'ampThreshold']);
      if (maxA != null && n.currentA != null && n.currentA! > maxA) {
        out.add(_RasAlert(
          title: '${_deviceTitle(n)} tiêu thụ điện cao',
          device: _deviceTitle(n),
          at: n.lastCommandAt,
          value: n.currentA,
          threshold: maxA,
          unit: 'A',
        ));
      }
      final maxH = _ruleNum(n, const ['runtimeMaxHours', 'maxRuntimeHours']);
      if (maxH != null && n.isOn == true && n.runStartedAt != null) {
        final h = DateTime.now().toUtc().difference(n.runStartedAt!.toUtc()).inHours;
        if (h >= maxH) {
          out.add(_RasAlert(
            title: '${_deviceTitle(n)} chạy liên tục vượt ngưỡng',
            device: _deviceTitle(n),
            at: DateTime.now(),
            value: h.toDouble(),
            threshold: maxH,
            unit: 'giờ',
          ));
        }
      }
    }
    return out;
  }

  double? _ruleNum(RasFlowNodeLive n, List<String> keys) {
    final map = _params(n);
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  Map<String, dynamic>? _params(RasFlowNodeLive n) {
    final raw = n.paramDefaultsJson;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  Widget _alertRow(_RasAlert a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kAmber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: bvText(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  [
                    if (a.value != null) '${a.value!.toStringAsFixed(a.unit == 'A' ? 1 : 0)}${a.unit == null ? '' : ' ${a.unit}'}',
                    if (a.threshold != null) 'Ngưỡng: ${a.threshold}${a.unit == null ? '' : ' ${a.unit}'}',
                    if (a.at != null) _fmt(a.at!),
                  ].join('  ·  '),
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          const MgmtStatusBadge(label: 'Đang mở', color: _kAmber),
        ],
      ),
    );
  }

  Widget _activityRow(RasControlEvent e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(_hhmm(e.at), style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          ),
          Expanded(child: Text(e.title, style: bvText(fontSize: 13))),
          _sourceBadge(_eventSource(e)),
        ],
      ),
    );
  }

  Widget _sourceBadge(String source) {
    final auto = source == 'AUTO SYSTEM';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (auto ? DashboardColors.brand : _kBlue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source,
        style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: auto ? DashboardColors.brand : _kBlue),
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required String action,
    required VoidCallback onAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: bvText(fontWeight: FontWeight.w800))),
              TextButton(
                onPressed: onAction,
                child: Text(action, style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.brand, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  void _openAutoConfig({RasFlowNodeLive? focus}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _RuleSheet(
        title: 'Cấu hình AUTO RAS',
        devices: _devices,
        focusId: focus?.id,
        nameOf: _deviceTitle,
        describe: _autoRuleLabel,
      ),
    );
  }

  void _openSchedule({RasFlowNodeLive? focus}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _RuleSheet(
        title: 'Lịch chạy',
        devices: _devices,
        focusId: focus?.id,
        nameOf: _deviceTitle,
        describe: _scheduleLabel,
      ),
    );
  }

  String _autoRuleLabel(RasFlowNodeLive n) {
    final p = _params(n);
    if (p == null || p.isEmpty) return 'Chưa có rule AUTO trên backend.';
    if (p['alwaysOn'] == true) return 'Luôn bật';
    if (p['alwaysOff'] == true) return 'Luôn tắt';
    if (p['schedule'] != null || p['windows'] != null) return 'AUTO theo lịch';
    if (p['runRest'] != null || p['onMinutes'] != null) return 'AUTO theo thời gian chạy/nghỉ';
    if (p['sensor'] != null || p['doMin'] != null || p['doMax'] != null) {
      final min = p['doMin'];
      final max = p['doMax'];
      if (min != null || max != null) {
        return [
          if (min != null) 'Nếu DO < $min mg/L → Bật',
          if (max != null) 'Nếu DO > $max mg/L → Tắt',
        ].join('\n');
      }
      return 'AUTO theo sensor';
    }
    if (p['interlock'] != null || p['requiresOn'] != null) {
      return 'Điều kiện an toàn: ${p['interlock'] ?? p['requiresOn']} đang ON';
    }
    if (p['rule'] != null) return '${p['rule']}';
    return p.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
  }

  String _scheduleLabel(RasFlowNodeLive n) {
    final p = _params(n);
    final s = p?['schedule'] ?? p?['windows'] ?? p?['hours'];
    if (s == null) return 'Chưa có lịch chạy cấu hình.';
    return '$s';
  }

  void _openActivityDetail(RasControlEvent? e, RasFlowNodeLive? node) {
    if (e == null) {
      _toast('Chưa có lịch sử lệnh cho thiết bị này.');
      return;
    }
    node ??= _nodeFromEvent(e);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết hoạt động', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _kv('Thời gian', _fmt(e.at)),
            _kv('Thiết bị', node == null ? '—' : _deviceTitle(node)),
            _kv('Action', e.kind),
            _kv('Mô tả', e.title),
            if (e.detail != null && e.detail!.isNotEmpty) _kv('Chi tiết', e.detail!),
            _kv('Actor', _eventSource(e)),
            _kv('Nguồn', _eventSource(e)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: bvText(color: DashboardColors.textMuted))),
          Expanded(child: Text(v, style: bvText(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('⚠ Không thể tải trạng thái RAS.\n${_svc.error}', style: bvText(color: _kRed))),
          MgmtOutlineButton(
            onTap: () => _svc.loadDiagram(widget.areaId),
            label: 'Thử lại',
          ),
        ],
      ),
    );
  }

  Widget _listSkeleton(int count) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ],
    );
  }

  Widget _chipSkeleton() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 140,
            height: 28,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }

  Widget _flowSkeleton() {
    return SizedBox(
      height: 132,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _deviceSkeleton() {
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Container(
              height: 220,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 12),
              decoration: mgmtCardDeco(radius: 16),
              child: const ColoredBox(color: Color(0xFFF3FBF8)),
            ),
          ),
      ],
    );
  }

  String _flowTitle(RasFlowNodeLive n) => n.displayLabel.trim();

  String _deviceTitle(RasFlowNodeLive n) {
    final label = n.displayLabel.trim();
    if (!n.hasRelay) return label;
    final t = label.toLowerCase();
    final looksLikeTank = (t.contains('bể') || t.contains('be ')) &&
        !t.contains('sục') &&
        !t.contains('bơm') &&
        !t.contains('máy') &&
        !t.contains('filter') &&
        !t.contains('skimmer');
    if (looksLikeTank && (n.nodeCode == 'bio' || n.nodeCode == 'bio_2' || t.contains('vi sinh'))) {
      return 'Máy sục khí ${n.displayLabel}';
    }
    return label;
  }

  String _commandSource(RasFlowNodeLive n) {
    final e = _lastEvent(n);
    if (e != null) return _eventSource(e);
    return n.isAuto ? 'AUTO SYSTEM' : 'Thủ công';
  }

  String _sensorLabel(AreaEnvironmentMetric m) {
    final t = '${m.sensorType ?? ''} ${m.label}'.toLowerCase();
    if (t.contains('temp') || m.label.contains('Nhiệt')) return 'Nhiệt độ';
    if (t.contains('ph')) return 'pH';
    if (t.contains('do') || t.contains('oxy') || t.contains('oxygen')) return 'DO';
    if (t.contains('tds')) return 'TDS';
    return m.label;
  }

  String _eventSource(RasControlEvent e) {
    final k = e.kind.toLowerCase();
    final t = e.title.toLowerCase();
    if (k == 'auto' || t.contains('auto kích hoạt') || t.contains('auto system')) {
      return 'AUTO SYSTEM';
    }
    if (t.contains('chủ trại')) return 'Chủ trại';
    if (t.contains('controller')) return 'Controller';
    return 'Thủ công';
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.node,
    required this.title,
    required this.pending,
    required this.commandSource,
    required this.onAuto,
    required this.onManual,
    required this.onOn,
    required this.onOff,
    required this.onMenu,
    required this.onOpenController,
  });

  final RasFlowNodeLive node;
  final String title;
  final String? pending;
  final String commandSource;
  final VoidCallback onAuto;
  final VoidCallback onManual;
  final VoidCallback onOn;
  final VoidCallback onOff;
  final ValueChanged<String> onMenu;
  final VoidCallback onOpenController;

  @override
  Widget build(BuildContext context) {
    final offline = node.isOnline == false;
    final error = node.status.toLowerCase() == 'alarm' || node.status.toLowerCase() == 'error';
    final running = node.isOn == true && !offline && !error;
    final statusColor = error
        ? _kRed
        : offline
            ? const Color(0xFF94A3B8)
            : running
                ? DashboardColors.brand
                : DashboardColors.textMuted;
    final statusLabel = error
        ? 'Lỗi'
        : offline
            ? 'Mất kết nối'
            : running
                ? 'Đang chạy'
                : 'Đang tắt';
    final manualOk = !node.isAuto && !offline && pending == null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(node.icon, color: DashboardColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: bvText(fontWeight: FontWeight.w800)),
              ),
              _dot(statusLabel, statusColor),
              PopupMenuButton<String>(
                tooltip: 'Thao tác',
                onSelected: onMenu,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'history', child: Text('Xem lịch sử')),
                  const PopupMenuItem(value: 'controller', child: Text('Xem Controller')),
                  const PopupMenuItem(value: 'auto', child: Text('Cấu hình AUTO')),
                  const PopupMenuItem(value: 'schedule', child: Text('Lịch chạy')),
                  if (!node.isAuto && !offline) ...[
                    const PopupMenuItem(value: 'on', child: Text('Bật')),
                    const PopupMenuItem(value: 'off', child: Text('Tắt')),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _meta('Controller', _controllerCode(node)),
          _meta('Kết nối', offline ? 'Mất kết nối' : 'Online', color: offline ? _kRed : DashboardColors.brand),
          if (offline)
            _meta('Lần thấy', node.lastCommandAt == null ? '—' : fmtDateTimeVn(node.lastCommandAt)),
          _meta('Chế độ', node.isAuto ? 'AUTO' : 'MANUAL', color: node.isAuto ? DashboardColors.brand : _kAmber),
          _meta('Thời gian chạy', _runtime(node)),
          _meta('Lần thay đổi', node.lastCommandAt == null ? '—' : fmtDateTimeVn(node.lastCommandAt)),
          _meta('Nguồn lệnh', commandSource),
          if (offline) ...[
            const SizedBox(height: 8),
            Text('⚠ Không thể gửi lệnh điều khiển.', style: bvText(fontSize: 12, color: _kAmber)),
            TextButton(
              onPressed: onOpenController,
              child: Text('Xem Controller →', style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.brand)),
            ),
          ],
          if (pending != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Đang gửi lệnh...', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _modeBtn('AUTO', node.isAuto, pending == null && !offline ? onAuto : null, 'Chuyển $title sang AUTO'),
              const SizedBox(width: 6),
              _modeBtn('MANUAL', !node.isAuto, pending == null && !offline ? onManual : null, 'Chuyển $title sang MANUAL'),
              const Spacer(),
              _modeBtn('Bật', false, manualOk ? onOn : null, 'Bật $title'),
              const SizedBox(width: 6),
              _modeBtn('Tắt', false, manualOk ? onOff : null, 'Tắt $title'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(String k, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(width: 118, child: Text(k, style: bvText(fontSize: 12, color: DashboardColors.textMuted))),
          Expanded(
            child: Text(v, style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _dot(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: bvText(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, bool on, VoidCallback? tap, String semantic) {
    return Semantics(
      button: true,
      enabled: tap != null,
      label: semantic,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: tap == null ? 0.4 : 1,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? DashboardColors.brand : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? DashboardColors.brand : DashboardColors.cardBorder),
            ),
            child: Text(
              label,
              style: bvText(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: on ? Colors.white : DashboardColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleSheet extends StatelessWidget {
  const _RuleSheet({
    required this.title,
    required this.devices,
    required this.describe,
    required this.nameOf,
    this.focusId,
  });

  final String title;
  final List<RasFlowNodeLive> devices;
  final String Function(RasFlowNodeLive) describe;
  final String Function(RasFlowNodeLive) nameOf;
  final String? focusId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final n in devices)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: n.id == focusId ? DashboardColors.lightMint : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameOf(n), style: bvText(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(describe(n), style: bvText(color: DashboardColors.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RasAlert {
  const _RasAlert({
    required this.title,
    required this.device,
    this.at,
    this.value,
    this.threshold,
    this.unit,
  });
  final String title;
  final String device;
  final DateTime? at;
  final double? value;
  final double? threshold;
  final String? unit;
}

String _controllerCode(RasFlowNodeLive n) {
  final ch = (n.relayChannel ?? '').trim();
  if (ch.isNotEmpty && ch.toLowerCase() != 'online') return ch;
  final id = (n.relayDeviceId ?? '').trim();
  if (id.length >= 8) return 'CTRL-${id.substring(0, 8).toUpperCase()}';
  return n.connectionLabel.isEmpty ? '—' : n.connectionLabel;
}

String _runtime(RasFlowNodeLive n) {
  final from = n.runStartedAt;
  if (n.isOn != true || from == null) return '—';
  final d = DateTime.now().toUtc().difference(from.toUtc());
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return '$h giờ $m phút';
}

String _fmt(DateTime at) {
  final l = at.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

String _hhmm(DateTime at) {
  final l = at.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

class _RasMintFlow extends StatelessWidget {
  const _RasMintFlow({required this.nodes, required this.titleOf});

  final List<RasFlowNodeLive> nodes;
  final String Function(RasFlowNodeLive) titleOf;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < nodes.length; i++) ...[
            _node(nodes[i]),
            if (i < nodes.length - 1) _arrow(nodes[i + 1]),
          ],
        ],
      ),
    );
  }

  Widget _arrow(RasFlowNodeLive next) {
    final error = next.status.toLowerCase() == 'alarm' || next.status.toLowerCase() == 'error';
    final offline = next.isOnline == false;
    final color = error
        ? _kRed
        : offline
            ? const Color(0xFF94A3B8)
            : const Color(0xFF2495E8).withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        offline ? Icons.more_horiz : Icons.arrow_forward_rounded,
        size: 18,
        color: color,
      ),
    );
  }

  Widget _node(RasFlowNodeLive n) {
    final error = n.status.toLowerCase() == 'alarm' || n.status.toLowerCase() == 'error';
    final offline = n.isOnline == false;
    final running = n.hasRelay && n.isOn == true && !offline && !error;
    final Color color;
    final String status;
    if (error) {
      color = _kRed;
      status = 'Lỗi';
    } else if (offline) {
      color = const Color(0xFF94A3B8);
      status = 'Mất kết nối';
    } else if (n.hasRelay) {
      color = running ? DashboardColors.brand : DashboardColors.textMuted;
      status = running ? 'Đang chạy' : 'Đang tắt';
    } else {
      color = DashboardColors.brand;
      status = 'Bình thường';
    }
    final tag = n.hasRelay
        ? (n.isAuto ? 'AUTO' : 'MANUAL')
        : (offline ? 'Ngoại tuyến' : 'Trực tuyến');
    return Semantics(
      label: '${titleOf(n)}, $status, $tag',
      child: Container(
        width: 148,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(n.icon, size: 18, color: DashboardColors.brand),
            ),
            const SizedBox(height: 8),
            Text(
              titleOf(n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(status, style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: bvText(fontSize: 10.5, fontWeight: FontWeight.w800, color: DashboardColors.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
