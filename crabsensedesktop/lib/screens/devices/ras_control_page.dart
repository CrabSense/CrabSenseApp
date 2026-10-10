import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/area_environment_metric.dart';
import '../../models/ras_flow.dart';
import '../../models/tank_level.dart';
import '../../models/water_quality.dart';
import '../../navigation/app_route.dart';
import '../../services/area_environment_service.dart';
import '../../services/controller_provisioning_service.dart';
import '../../services/ras_flow_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';
import '../environment/realtime_monitor_page.dart';

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
  final _relayOn = <String, bool>{};
  final _controllerIp = <String, String>{};
  final _controllerCode = <String, String>{};
  var _systemBusy = false;
  Timer? _relayTimer;

  RasFlowService get _svc => widget.service;
  AreaEnvironmentService? get _env => widget.environment;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    _env?.addListener(_onUpdate);
    _svc.startLiveRefresh(widget.areaId);
    _env?.startLiveRefresh(widget.areaId);
    _relayTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollRelays());
    _pollRelays();
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
    _relayTimer?.cancel();
    _svc.removeListener(_onUpdate);
    _env?.removeListener(_onUpdate);
    super.dispose();
  }

  String _relayKey(String deviceId, int channel) => '$deviceId:$channel';

  bool? _liveOn(RasFlowNodeLive n) {
    final channel = int.tryParse(n.relayChannel ?? '');
    if (channel == null) return null;
    final deviceId = n.relayDeviceId ?? '';
    final exact = _relayOn[_relayKey(deviceId, channel)];
    if (exact != null) return exact;
    final sameChannel = [
      for (final entry in _relayOn.entries)
        if (entry.key.endsWith(':$channel')) entry.value,
    ];
    if (sameChannel.length == 1) return sameChannel.first;
    return null;
  }

  Future<void> _pollRelays() async {
    try {
      final controllers = await _svc.areaControllers(widget.areaId);
      if (!mounted) return;
      final next = <String, bool>{};
      for (final controller in controllers) {
        try {
          final ip = controller.ip.trim();
          if (controller.id.isEmpty || ip.isEmpty) continue;
          _controllerIp[controller.id] = ip;
          _controllerCode[controller.id] = controller.code;
          final info = await ControllerProvisioningService().discover(
            baseUrl: 'http://$ip',
          );
          for (final pin in info.outputs) {
            if (pin.on != null) {
              next[_relayKey(controller.id, pin.channel)] = pin.on!;
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _relayOn
          ..clear()
          ..addAll(next);
      });
    } catch (_) {}
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
  List<RasFlowNodeLive> get _managed =>
      _nodes.where((n) => n.nodeType != 'source').toList();

  bool get _systemAuto =>
      _devices.isNotEmpty && _devices.every((n) => n.isAuto);

  bool get _controllerOnline =>
      _devices.isEmpty
          ? _nodes.any((n) => n.isOnline != false)
          : _devices.any((n) => n.isOnline != false);

  bool _shownOn(RasFlowNodeLive n) => _liveOn(n) ?? n.isOn == true;

  int get _running => _devices
      .where((n) => _shownOn(n) && !_isError(n) && n.isOnline != false)
      .length;
  int get _off =>
      _devices.where((n) => !_shownOn(n) && !_isError(n)).length;
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
    final lowered = command.toLowerCase();
    if (lowered == 'on' || lowered == 'off' || lowered == 'start' || lowered == 'stop') {
      await _driveRelay(node, lowered == 'on' || lowered == 'start');
      return;
    }
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

  Future<void> _driveRelay(RasFlowNodeLive node, bool on) async {
    final channel = int.tryParse(node.relayChannel ?? '');
    final deviceId = node.relayDeviceId ?? '';
    if (channel == null || deviceId.isEmpty) {
      _toast('Chưa gán actuator cho ${_deviceTitle(node)}.');
      return;
    }
    final ip = _controllerIp[deviceId];
    if (ip == null || ip.isEmpty) {
      _toast('Controller đã gán chưa có IP, không bật tắt được.');
      return;
    }
    setState(() => _pending[node.id] = on ? 'on' : 'off');
    try {
      final state = await ControllerProvisioningService().commandEsp(
        ip: ip,
        command: on ? 'on' : 'off',
        channel: channel,
      );
      if (!mounted) return;
      if (state == null) {
        _toast('Không điều khiển được actuator trên Controller.');
        return;
      }
      final echoed = state[channel];
      if (echoed == null) {
        _toast('Không điều khiển được actuator trên Controller.');
        return;
      }
      setState(() => _relayOn[_relayKey(deviceId, channel)] = echoed);
      _toast('✓ ${_deviceTitle(node)} ${echoed ? 'đã bật' : 'đã tắt'}.');
      final code = _controllerCode[deviceId];
      if (code != null && echoed == on) {
        await _svc.reportRelay(deviceCode: code, channel: channel, on: on);
      }
    } catch (_) {
      if (mounted) _toast('Không nối được Controller.');
    } finally {
      if (mounted) setState(() => _pending.remove(node.id));
    }
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
    for (final n in _devices) {
      final channel = int.tryParse(n.relayChannel ?? '');
      if (channel == null) continue;
      await _driveRelay(n, false);
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
              _EspMonitor(
                power: _svc.power,
                loadHistory: (id, range) => _svc.powerHistory(id, range: range),
              ),
              const SizedBox(height: 16),
              _flowCard(loading),
              const SizedBox(height: 18),
              _deviceHeader(),
              const SizedBox(height: 12),
              if (loading)
                _deviceSkeleton()
              else if (_managed.isEmpty)
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
              Text('Sơ đồ RAS', style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
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
          else
            _RasCanvas(
              areaId: widget.areaId,
              nodes: _nodes,
              pipes: _topologyPipes(),
              titleOf: _flowTitle,
              onOpen: _openTopologyNode,
              onAdd: _addDevice,
              meterOf: _ratedLine,
              levelOf: _tankLevel,
              kindOf: (n) => _savedGroup(n, _paramMap(n.paramDefaultsJson)),
              liveOf: _liveOn,
              floatsOf: (n) {
                if (_savedGroup(n, _paramMap(n.paramDefaultsJson)) != 'tank') return null;
                return 'Dưới ${_floatLine(n, 'lowFloat', 'lowWhen')} · Trên ${_floatLine(n, 'highFloat', 'highWhen')}';
              },
            ),
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
              onTap: _addDevice,
              icon: Icons.add,
              label: 'Thêm thiết bị',
            ),
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
            for (final n in _managed)
              SizedBox(
                width: w,
                child: _DeviceCard(
                  node: n,
                  title: _deviceTitle(n),
                  pending: _pending[n.id],
                  commandSource: _commandSource(n),
                  level: _tankLevel(n),
                  lowFloat: _floatLine(n, 'lowFloat', 'lowWhen'),
                  highFloat: _floatLine(n, 'highFloat', 'highWhen'),
                  tank: _savedGroup(n, _paramMap(n.paramDefaultsJson)) == 'tank',
                  pump: _savedGroup(n, _paramMap(n.paramDefaultsJson)) == 'pump',
                  liveOn: _liveOn(n),
                  onAuto: () => _cmd(n, 'auto'),
                  onManual: () => _cmd(n, 'manual'),
                  onOn: () => _sendOn(n),
                  onOff: () => _cmd(n, 'off'),
                  onMenu: (a) => _onDeviceMenu(n, a),
                  onOpenController: () => widget.onNavigate?.call(AppRoute.controllers),
                  power: _isElectrical(n) ? _svc.power : null,
                  onPower: _isElectrical(n) ? () => _openPowerHistory() : null,
                  assignable: _isElectrical(n),
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
      case 'power':
        _openPowerHistory();
      case 'controller':
        widget.onNavigate?.call(AppRoute.controllers);
      case 'relay':
        _assignActuator(n);
      case 'delete':
        _deleteDevice(n);
      case 'edit':
        _editDevice(n);
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

  Future<void> _addDevice() async {
    final picked = await _pickDevice(title: 'Thêm thiết bị', submit: 'Thêm');
    if (picked == null || !mounted) return;
    final code = '${picked.icon}_${DateTime.now().millisecondsSinceEpoch}';
    final saved = await _svc.addNode(
      areaId: widget.areaId,
      nodeCode: code,
      displayLabel: picked.label,
      sortOrder: _nodes.length + 1,
      nodeType: picked.electrical ? 'equipment' : 'tank',
      type: picked.kind,
      paramDefaults: jsonEncode({
        'label': picked.label,
        'icon': picked.icon,
        'electrical': picked.electrical,
        'kind': picked.kind,
        'group': picked.group,
        ...picked.specs,
      }),
    );
    if (saved) await _dropAutoPipe(code);
    if (mounted) {
      _toast(saved ? 'Đã thêm ${picked.label}.' : (_svc.error ?? 'Không thêm được thiết bị.'));
    }
  }

  Future<void> _dropAutoPipe(String nodeCode) async {
    RasFlowNodeLive? created;
    for (final node in _nodes) {
      if (node.nodeCode == nodeCode) created = node;
    }
    if (created == null) return;
    final incoming = [
      for (final pipe in _svc.diagram?.flows ?? const <RasPipe>[])
        if (pipe.toId == created.id) pipe.id,
    ];
    if (incoming.isEmpty) return;
    final map = _paramMap(created.paramDefaultsJson);
    final cut = {
      for (final item in (map['cutPipes'] as List?) ?? const []) item.toString(),
      ...incoming,
    };
    map['cutPipes'] = cut.toList();
    await _writeParams(created, map);
  }

  Future<void> _editDevice(RasFlowNodeLive node) async {
    final current = _paramMap(node.paramDefaultsJson);
    final picked = await _pickDevice(
      title: 'Sửa thiết bị',
      submit: 'Cập nhật',
      initialName: _savedLabel(node),
      initialElectrical: _isElectrical(node),
      initialKind: current['kind']?.toString() ?? node.type,
      initialIcon: current['icon']?.toString() ?? node.iconKey ?? node.nodeCode,
      initialGroup: _savedGroup(node, current),
      initialSpecs: current,
    );
    if (picked == null || !mounted) return;
    current['label'] = picked.label;
    current['icon'] = picked.icon;
    current['electrical'] = picked.electrical;
    current['kind'] = picked.kind;
    current['group'] = picked.group;
    for (final key in ['length', 'width', 'volume', 'volts', 'amps', 'watts', 'flow', ...tankLevelKeys]) {
      current.remove(key);
    }
    current.addAll(picked.specs);
    final saved = await _writeParams(node, current);
    if (mounted) {
      _toast(saved ? 'Đã cập nhật ${picked.label}.' : (_svc.error ?? 'Không cập nhật được.'));
    }
  }

  Future<_PickedDevice?> _pickDevice({
    required String title,
    required String submit,
    String initialName = '',
    bool initialElectrical = false,
    String? initialKind,
    String? initialIcon,
    String? initialGroup,
    Map<String, dynamic>? initialSpecs,
  }) async {
    final known = _deviceKinds.where(
      (item) => item.type == initialKind || item.label == initialKind,
    );
    String textOf(String key) => initialSpecs?[key]?.toString() ?? '';
    final name = TextEditingController(text: initialName);
    final length = TextEditingController(text: textOf('length'));
    final width = TextEditingController(text: textOf('width'));
    final volume = TextEditingController(text: textOf('volume'));
    final volts = TextEditingController(text: textOf('volts'));
    final amps = TextEditingController(text: textOf('amps'));
    final watts = TextEditingController(text: textOf('watts'));
    final flow = TextEditingController(text: textOf('flow'));
    String savedFloat(String key) {
      const known = {'float_1', 'float_2', 'float_3', 'float_4'};
      final value = initialSpecs?[key]?.toString() ?? '';
      return known.contains(value) ? value : '';
    }

    String savedWhen(String key) => initialSpecs?[key]?.toString() == 'off' ? 'off' : 'on';
    var lowFloat = savedFloat('lowFloat');
    var lowWhen = savedWhen('lowWhen');
    var highFloat = savedFloat('highFloat');
    var highWhen = savedWhen('highWhen');
    var group = initialGroup ??
        (known.isEmpty
            ? (initialElectrical ? 'electric' : 'tank')
            : (known.first.type == 'PUMP'
                ? 'pump'
                : (known.first.electrical ? 'electric' : 'tank')));
    var icon = _deviceIcons.any((item) => item.key == initialIcon)
        ? initialIcon!
        : (known.isEmpty ? _deviceIcons.first.key : known.first.icon);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          Widget numberField(TextEditingController controller, String label) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: label),
              ),
            );
          }

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Tên thiết bị'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: group,
                    decoration: const InputDecoration(labelText: 'Nhóm'),
                    items: const [
                      DropdownMenuItem(value: 'tank', child: Text('Bể / thùng')),
                      DropdownMenuItem(value: 'electric', child: Text('Thiết bị điện')),
                      DropdownMenuItem(value: 'pump', child: Text('Máy bơm')),
                    ],
                    onChanged: (value) => setDialog(() => group = value ?? 'tank'),
                  ),
                  const SizedBox(height: 12),
                  Text('Icon', style: bvText(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in _deviceIcons)
                        InkWell(
                          onTap: () => setDialog(() => icon = item.key),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: icon == item.key
                                  ? DashboardColors.lightMint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: icon == item.key
                                    ? DashboardColors.brand
                                    : DashboardColors.cardBorder,
                              ),
                            ),
                            child: Icon(item.icon, size: 20, color: DashboardColors.brand),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (group == 'tank') ...[
                    numberField(length, 'Chiều dài (m)'),
                    numberField(width, 'Chiều rộng (m)'),
                    numberField(volume, 'Thể tích (m³)'),
                    const SizedBox(height: 4),
                    Text('Mực nước', style: bvText(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    _levelAssign(
                      'Cạn',
                      lowFloat,
                      lowWhen,
                      highFloat,
                      (sensor, when) => setDialog(() {
                        lowFloat = sensor;
                        lowWhen = when;
                        if (sensor.isNotEmpty && sensor == highFloat) highFloat = '';
                      }),
                    ),
                    _levelAssign(
                      'Tràn',
                      highFloat,
                      highWhen,
                      lowFloat,
                      (sensor, when) => setDialog(() {
                        highFloat = sensor;
                        highWhen = when;
                        if (sensor.isNotEmpty && sensor == lowFloat) lowFloat = '';
                      }),
                    ),
                    Text(
                      'Bình thường khi không cạn và không tràn.',
                      style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                    ),
                  ] else ...[
                    numberField(volts, 'Điện áp (V)'),
                    numberField(amps, 'Dòng điện (A)'),
                    numberField(watts, 'Công suất (W)'),
                    if (group == 'pump') numberField(flow, 'Lưu lượng (L/phút)'),
                  ],
                ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(submit)),
            ],
          );
        },
      ),
    );
    final label = name.text.trim();
    String read(TextEditingController controller) => controller.text.trim();
    final specs = <String, String>{};
    void keep(String key, String value) {
      if (value.isNotEmpty) specs[key] = value;
    }
    if (group == 'tank') {
      keep('length', read(length));
      keep('width', read(width));
      keep('volume', read(volume));
      void level(String floatKey, String whenKey, String sensor, String when) {
        if (sensor.isEmpty) return;
        specs[floatKey] = sensor;
        specs[whenKey] = when;
      }

      level('lowFloat', 'lowWhen', lowFloat, lowWhen);
      level('highFloat', 'highWhen', highFloat, highWhen);
    } else {
      keep('volts', read(volts));
      keep('amps', read(amps));
      keep('watts', read(watts));
      if (group == 'pump') keep('flow', read(flow));
    }
    name.dispose();
    length.dispose();
    width.dispose();
    volume.dispose();
    volts.dispose();
    amps.dispose();
    watts.dispose();
    flow.dispose();
    if (ok != true || label.isEmpty) return null;
    final matched = _deviceKinds.where(
      (item) => item.label.toLowerCase() == label.toLowerCase(),
    );
    final kindCode = group == 'pump'
        ? 'PUMP'
        : (matched.isEmpty ? label : matched.first.type);
    return _PickedDevice(label, group != 'tank', kindCode, icon, group, specs);
  }

  Future<void> _deleteDevice(RasFlowNodeLive node) async {
    final title = _deviceTitle(node);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thiết bị'),
        content: Text('Xóa $title khỏi sơ đồ RAS?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await _svc.deleteNode(areaId: widget.areaId, nodeId: node.id);
    if (mounted) {
      _toast(saved ? 'Đã xóa $title.' : (_svc.error ?? 'Không xóa được thiết bị.'));
    }
  }

  Future<void> _openTopologyNode(RasFlowNodeLive node) async {
    final pipes = _topologyPipes();
    final outgoing = pipes.where((p) => p.fromId == node.id).toList();
    final electrical = _isElectrical(node);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_deviceTitle(node)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              electrical
                  ? (node.hasRelay
                      ? 'Đã gán actuator kênh ${node.relayChannel}'
                      : 'Chưa gán actuator')
                  : 'Bể / thùng — không gán actuator',
              style: bvText(color: DashboardColors.textMuted),
            ),
            if (!electrical) ...[
              const SizedBox(height: 8),
              Text(
                _tankLevel(node) ?? 'Chưa gán',
                style: bvText(fontWeight: FontWeight.w800, color: _levelColor(_tankLevel(node)) ?? DashboardColors.textMuted),
              ),
              Text('Phao dưới  ${_floatLine(node, 'lowFloat', 'lowWhen')}', style: bvText(color: DashboardColors.textMuted)),
              Text('Phao trên  ${_floatLine(node, 'highFloat', 'highWhen')}', style: bvText(color: DashboardColors.textMuted)),
            ],
            if (_ratedLine(node) != null) ...[
              const SizedBox(height: 8),
              Text('Định mức  ${_ratedLine(node)}', style: bvText(color: DashboardColors.textMuted)),
            ],
            if (outgoing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Ống nước đi', style: bvText(fontWeight: FontWeight.w800)),
              for (final pipe in outgoing)
                Row(
                  children: [
                    Expanded(child: Text(_pipeTarget(pipe.toId))),
                    IconButton(
                      tooltip: 'Gỡ ống',
                      onPressed: () => Navigator.pop(ctx, 'cut:${pipe.id}'),
                      icon: const Icon(Icons.link_off, size: 18),
                    ),
                  ],
                ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Sửa thông tin')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'connect'), child: const Text('Nối tới')),
          if (electrical)
            TextButton(onPressed: () => Navigator.pop(ctx, 'assign'), child: const Text('Gán actuator')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'delete'), child: const Text('Xóa')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _editDevice(node);
    } else if (action == 'assign') {
      await _assignActuator(node);
    } else if (action == 'delete') {
      await _deleteDevice(node);
    } else if (action == 'connect') {
      await _connectNode(node);
    } else if (action.startsWith('cut:')) {
      await _dropPipe(node, action.substring(4));
    }
  }

  String _pipeTarget(String id) {
    for (final n in _nodes) {
      if (n.id == id) return _deviceTitle(n);
    }
    return id;
  }

  Future<void> _connectNode(RasFlowNodeLive node) async {
    final others = _nodes.where((n) => n.id != node.id).toList();
    if (others.isEmpty) return;
    var target = others.first.id;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Nối từ ${_deviceTitle(node)}'),
          content: DropdownButtonFormField<String>(
            value: target,
            decoration: const InputDecoration(labelText: 'Tới thiết bị'),
            items: [
              for (final n in others)
                DropdownMenuItem(value: n.id, child: Text(_deviceTitle(n))),
            ],
            onChanged: (value) => setDialog(() => target = value ?? target),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, target), child: const Text('Nối')),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final ok = await _svc.addFlow(areaId: widget.areaId, fromId: node.id, toId: picked);
    if (!ok && (_svc.error ?? '').contains('404')) {
      final saved = await _rememberPipe(node, picked);
      if (mounted) {
        _toast(saved ? 'Đã nối ống nước.' : (_svc.error ?? 'Không nối được.'));
      }
      return;
    }
    if (mounted) {
      _toast(ok ? 'Đã nối ống nước.' : (_svc.error ?? 'Không nối được.'));
    }
  }

  List<RasPipe> _topologyPipes() {
    final hidden = <String>{};
    final extra = <RasPipe>[];
    for (final node in _nodes) {
      final map = _paramMap(node.paramDefaultsJson);
      final cut = map['cutPipes'];
      if (cut is List) {
        hidden.addAll(cut.map((e) => e.toString()));
      }
      final links = map['pipes'];
      if (links is List) {
        for (final to in links) {
          final toId = to.toString();
          extra.add(RasPipe(id: 'extra:${node.id}:$toId', fromId: node.id, toId: toId));
        }
      }
    }
    final seen = <String>{};
    final pipes = <RasPipe>[];
    for (final pipe in [...?_svc.diagram?.flows, ...extra]) {
      if (hidden.contains(pipe.id)) continue;
      final key = '${pipe.fromId}>${pipe.toId}';
      if (!seen.add(key)) continue;
      pipes.add(pipe);
    }
    return pipes;
  }

  Map<String, dynamic> _paramMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'label': raw};
    } catch (_) {
      return {'label': raw};
    }
  }

  Future<bool> _writeParams(RasFlowNodeLive node, Map<String, dynamic> map) {
    return _svc.updateNodeRelay(
      areaId: widget.areaId,
      nodeId: node.id,
      relayDeviceId: node.hasRelay ? node.relayDeviceId : null,
      relayChannel: node.hasRelay ? node.relayChannel : null,
      paramDefaultsJson: jsonEncode(map),
    );
  }

  Future<bool> _rememberPipe(RasFlowNodeLive node, String toId) async {
    final map = _paramMap(node.paramDefaultsJson);
    final links = [
      for (final item in (map['pipes'] as List?) ?? const []) item.toString(),
    ];
    if (!links.contains(toId)) links.add(toId);
    map['pipes'] = links;
    return _writeParams(node, map);
  }

  Future<void> _dropPipe(RasFlowNodeLive node, String pipeId) async {
    if (pipeId.startsWith('extra:')) {
      final toId = pipeId.split(':').skip(2).join(':');
      final map = _paramMap(node.paramDefaultsJson);
      final links = [
        for (final item in (map['pipes'] as List?) ?? const []) item.toString(),
      ]..remove(toId);
      map['pipes'] = links;
      final ok = await _writeParams(node, map);
      if (mounted) _toast(ok ? 'Đã gỡ ống nước.' : (_svc.error ?? 'Không gỡ được ống.'));
      return;
    }
    final ok = await _svc.deleteFlow(areaId: widget.areaId, flowId: pipeId);
    if (!ok && (_svc.error ?? '').contains('404')) {
      final map = _paramMap(node.paramDefaultsJson);
      final cut = [
        for (final item in (map['cutPipes'] as List?) ?? const []) item.toString(),
      ];
      if (!cut.contains(pipeId)) cut.add(pipeId);
      map['cutPipes'] = cut;
      final saved = await _writeParams(node, map);
      if (mounted) _toast(saved ? 'Đã gỡ ống nước.' : (_svc.error ?? 'Không gỡ được ống.'));
      return;
    }
    if (mounted) _toast(ok ? 'Đã gỡ ống nước.' : (_svc.error ?? 'Không gỡ được ống.'));
  }

  Future<void> _assignActuator(RasFlowNodeLive node) async {
    final controllers = await _svc.areaControllers(widget.areaId);
    if (!mounted) return;
    if (controllers.isEmpty) {
      _toast('Khu này chưa có Controller.');
      return;
    }
    var picked = controllers.first;
    List<EspOutputPin> outputs = [];
    String? readError;
    var channel = node.relayChannel ?? '';
    var started = false;

    Future<void> loadOutputs(
      ({String id, String code, String name, String ip}) controller,
      void Function(void Function()) setDialog,
    ) async {
      setDialog(() {
        picked = controller;
        outputs = [];
        readError = null;
      });
      if (controller.ip.isEmpty) {
        setDialog(() => readError = 'Controller chưa có IP.');
        return;
      }
      try {
        final info = await ControllerProvisioningService()
            .discover(baseUrl: 'http://${controller.ip}');
        if (!mounted) return;
        setDialog(() {
          outputs = info.outputs;
          if (outputs.isEmpty) {
            readError = 'Controller chưa trả danh sách actuator.';
          } else if (!outputs.any((p) => '${p.channel}' == channel)) {
            channel = '${outputs.first.channel}';
          }
        });
      } catch (_) {
        if (!mounted) return;
        setDialog(() => readError = 'Không đọc được actuator từ Controller.');
      }
    }

    final result = await showDialog<({String code, String channel})?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (!started) {
            started = true;
            Future<void>.microtask(() => loadOutputs(picked, setDialog));
          }
          return AlertDialog(
            title: Text('Gán actuator cho ${_deviceTitle(node)}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: picked.code,
                    decoration: const InputDecoration(labelText: 'Controller'),
                    items: [
                      for (final c in controllers)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text(c.name.isEmpty ? c.code : c.name),
                        ),
                    ],
                    onChanged: (code) {
                      final next = controllers.firstWhere((c) => c.code == code);
                      loadOutputs(next, setDialog);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (readError != null)
                    Text(readError!, style: bvText(color: _kRed))
                  else if (outputs.isEmpty)
                    Text('Đang đọc actuator...', style: bvText(color: DashboardColors.textMuted))
                  else
                    DropdownButtonFormField<String>(
                      value: outputs.any((p) => '${p.channel}' == channel)
                          ? channel
                          : '${outputs.first.channel}',
                      decoration: const InputDecoration(labelText: 'Actuator'),
                      items: [
                        for (final pin in outputs)
                          DropdownMenuItem(
                            value: '${pin.channel}',
                            child: Text('Kênh ${pin.channel} · GPIO ${pin.gpio}'),
                          ),
                      ],
                      onChanged: (value) => setDialog(() => channel = value ?? channel),
                    ),
                ],
              ),
            ),
            actions: [
              if (node.hasRelay)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, (code: '', channel: '')),
                  child: const Text('Bỏ gán'),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              FilledButton(
                onPressed: outputs.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, (code: picked.code, channel: channel)),
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null || !mounted) return;
    final ok = await _svc.updateNodeRelay(
      areaId: widget.areaId,
      nodeId: node.id,
      relayDeviceCode: result.code.isEmpty ? null : result.code,
      relayChannel: result.channel.isEmpty ? null : result.channel,
    );
    if (mounted) {
      _toast(ok
          ? (result.code.isEmpty
              ? 'Đã bỏ gán actuator.'
              : 'Đã gán ${result.code} / kênh ${result.channel}.')
          : (_svc.error ?? 'Không gán được actuator.'));
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
          Text('Chưa có thiết bị điều khiển.', style: bvText(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          MgmtOutlineButton(
            onTap: _addDevice,
            icon: Icons.add,
            label: 'Thêm thiết bị',
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
    if (focus == null) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        builder: (_) => _RuleSheet(title: 'C?u h?nh AUTO RAS', devices: _devices, focusId: null, nameOf: _deviceTitle, describe: _autoRuleLabel),
      );
      return;
    }
    final current = _params(focus) ?? const <String, dynamic>{};
    final onSensor = TextEditingController(text: '${current['onSensor'] ?? ''}');
    final onValue = TextEditingController(text: '${current['onValue'] ?? 1}');
    final offSensor = TextEditingController(text: '${current['offSensor'] ?? ''}');
    final offValue = TextEditingController(text: '${current['offValue'] ?? 1}');
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text('C?u h?nh AUTO ${_deviceTitle(focus)}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: onSensor, decoration: const InputDecoration(labelText: 'Sensor b?t')),
        TextField(controller: onValue, decoration: const InputDecoration(labelText: 'Gi? tr? b?t')),
        TextField(controller: offSensor, decoration: const InputDecoration(labelText: 'Sensor t?t')),
        TextField(controller: offValue, decoration: const InputDecoration(labelText: 'Gi? tr? t?t')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('H?y')),
        FilledButton(onPressed: () async {
          final rule = jsonEncode({'onSensor': onSensor.text.trim(), 'onValue': double.tryParse(onValue.text) ?? 1, 'offSensor': offSensor.text.trim(), 'offValue': double.tryParse(offValue.text) ?? 1});
          final channel = (focus.relayChannel ?? '').trim();
          final ok = await _svc.updateNodeRelay(
            areaId: widget.areaId,
            nodeId: focus.id,
            relayDeviceId: focus.relayDeviceId,
            relayChannel: channel.isEmpty ? null : channel,
            paramDefaultsJson: rule,
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) _toast(ok ? '?? l?u logic AUTO.' : (_svc.error ?? 'Kh?ng l?u ???c logic AUTO.'));
        }, child: const Text('L?u')),
      ],
    ));
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

  Future<void> _openPowerHistory() async {
    final specs = [
      ('meter_v', 'Điện áp', 'V'),
      ('meter_a', 'Dòng', 'A'),
      ('meter_w', 'Công suất', 'W'),
      ('meter_kwh', 'Điện năng', 'kWh'),
    ];
    final sections = <({String title, List<Map<String, dynamic>> rows, String unit})>[];
    for (final spec in specs) {
      final point = _svc.power[spec.$1];
      if (point == null || point.id.isEmpty) continue;
      try {
        final rows = await _svc.powerHistory(point.id);
        sections.add((title: spec.$2, rows: rows, unit: point.unit ?? spec.$3));
      } catch (e) {
        if (mounted) _toast('$e');
        return;
      }
    }
    if (!mounted) return;
    if (sections.isEmpty) {
      _toast('Chưa có số đo điện.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lịch sử điện 24 giờ'),
        content: SizedBox(
          width: 460,
          height: 420,
          child: ListView(
            children: [
              for (final section in sections) ...[
                Text(section.title, style: bvText(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                if (section.rows.isEmpty)
                  Text('Chưa có điểm.', style: bvText(color: DashboardColors.textMuted))
                else
                  for (final row in section.rows.take(12))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_powerValue(row)} ${section.unit}   ${_powerWhen(row)}',
                        style: bvText(fontSize: 13),
                      ),
                    ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
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

  String _savedLabel(RasFlowNodeLive n) {
    final label = _paramMap(n.paramDefaultsJson)['label']?.toString().trim() ?? '';
    return label.isEmpty ? n.displayLabel.trim() : label;
  }

  String _flowTitle(RasFlowNodeLive n) => _savedLabel(n);

  bool _isElectrical(RasFlowNodeLive n) {
    final saved = _paramMap(n.paramDefaultsJson);
    final group = saved['group']?.toString();
    if (group == 'tank') return false;
    if (group == 'electric' || group == 'pump') return true;
    if (saved['electrical'] == false) return false;
    if (saved['electrical'] == true) return true;
    final text = _savedLabel(n).toLowerCase();
    const machine = [
      'drum', 'skimmer', 'pump', 'bơm', 'bom', 'ozone', 'oxy',
      'máy', 'may', 'filter', 'lọc', 'ssr', 'blower', 'uv', 'đèn',
    ];
    final tankWord = text.contains('bể') ||
        text.contains('hộp') ||
        text.contains('thùng') ||
        text.contains('tank') ||
        n.nodeType == 'source';
    final machineWord = machine.any(text.contains);
    if (tankWord && !machineWord) return false;
    return machineWord;
  }

  String? _tankLevel(RasFlowNodeLive n) {
    final map = _paramMap(n.paramDefaultsJson);
    if (_savedGroup(n, map) != 'tank') return null;
    return tankLevelLabel(map, (code) => _svc.power[code]?.value);
  }

  String _floatLine(RasFlowNodeLive n, String floatKey, String whenKey) {
    final map = _paramMap(n.paramDefaultsJson);
    final sensor = map[floatKey]?.toString().trim() ?? '';
    if (!sensor.startsWith('float_') || sensor.length < 7) return 'Chưa gán';
    final when = map[whenKey]?.toString() == 'off' ? 'Tắt' : 'Bật';
    final value = _svc.power[sensor]?.value;
    final now = value == null ? '' : (value >= 0.5 ? ', đang bật' : ', đang tắt');
    return 'Phao ${sensor.substring(sensor.length - 1)} khi $when$now';
  }

  String _savedGroup(RasFlowNodeLive node, Map<String, dynamic> current) {
    final saved = current['group']?.toString();
    if (saved == 'tank' || saved == 'electric' || saved == 'pump') return saved!;
    if (current['electrical'] == false) return 'tank';
    if (current['electrical'] == true) return 'electric';
    final text = _savedLabel(node).toLowerCase();
    if (text.contains('pump') || text.contains('bơm') || text.contains('bom')) return 'pump';
    return _isElectrical(node) ? 'electric' : 'tank';
  }

  String? _ratedLine(RasFlowNodeLive n) {
    final map = _paramMap(n.paramDefaultsJson);
    String one(String key, String unit) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isEmpty) return '';
      return '$value $unit';
    }

    final group = map['group']?.toString();
    if (group == 'tank') {
      final parts = [one('length', 'm'), one('width', 'm'), one('volume', 'm³')]
          .where((part) => part.isNotEmpty);
      final line = parts.join(' · ');
      return line.isEmpty ? null : line;
    }
    if (group == 'electric' || group == 'pump' || _isElectrical(n)) {
      final parts = [
        one('volts', 'V'),
        one('amps', 'A'),
        one('watts', 'W'),
        one('flow', 'L/phút'),
      ].where((part) => part.isNotEmpty);
      if (parts.isNotEmpty) return parts.join(' · ');
      return null;
    }
    return null;
  }

  String _deviceTitle(RasFlowNodeLive n) {
    final label = _savedLabel(n);
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

class _EspChannel {
  const _EspChannel(this.code, this.label, this.unit, this.icon, this.digits);

  final String code;
  final String label;
  final String unit;
  final IconData icon;
  final int digits;
}

const _espChannels = [
  _EspChannel('meter_v', 'Điện áp', 'V', Icons.bolt_outlined, 1),
  _EspChannel('meter_a', 'Dòng điện', 'A', Icons.electric_meter_outlined, 3),
  _EspChannel('meter_w', 'Công suất', 'W', Icons.power_outlined, 0),
  _EspChannel('meter_va', 'Công suất biểu kiến', 'VA', Icons.flash_on_outlined, 0),
  _EspChannel('meter_kwh', 'Điện năng', 'kWh', Icons.energy_savings_leaf_outlined, 3),
  _EspChannel('meter_hz', 'Tần số', 'Hz', Icons.waves_outlined, 1),
  _EspChannel('meter_pf', 'Hệ số công suất', '%', Icons.percent, 0),
  _EspChannel('meter_min', 'Thời gian chạy', 'phút', Icons.timer_outlined, 0),
  _EspChannel('meter_c', 'Nhiệt độ đồng hồ', '°C', Icons.thermostat_outlined, 0),
];

const _espRanges = [
  ('1H', Duration(hours: 1)),
  ('6H', Duration(hours: 6)),
  ('24H', Duration(hours: 24)),
  ('7 Ngày', Duration(days: 7)),
  ('30 Ngày', Duration(days: 30)),
];

class _EspMonitor extends StatefulWidget {
  const _EspMonitor({required this.power, required this.loadHistory});

  final PowerSnapshot power;
  final Future<List<Map<String, dynamic>>> Function(String sensorId, Duration range) loadHistory;

  @override
  State<_EspMonitor> createState() => _EspMonitorState();
}

class _EspMonitorState extends State<_EspMonitor> {
  String _code = 'meter_v';
  int _range = 2;
  bool _detail = false;
  bool _showThreshold = true;
  String _loadedFor = '';
  DateTime _loadedAt = DateTime.fromMillisecondsSinceEpoch(0);
  List<({DateTime at, double value})> _points = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _EspMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    if (!_detail) return;
    final point = widget.power[_code];
    final id = point?.id ?? '';
    if (id.isEmpty) return;
    final key = '$id:$_range';
    if (key == _loadedFor && DateTime.now().difference(_loadedAt) < const Duration(seconds: 30)) {
      return;
    }
    _loadedFor = key;
    _loadedAt = DateTime.now();
    final rows = await widget.loadHistory(id, _espRanges[_range].$2);
    final points = <({DateTime at, double value})>[];
    for (final row in rows) {
      final raw = row['value'] ?? row['Value'];
      final when = row['measuredAt'] ?? row['MeasuredAt'];
      final at = when == null ? null : DateTime.tryParse(when.toString());
      final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (at == null || value == null) continue;
      points.add((at: at.toLocal(), value: value));
    }
    points.sort((a, b) => a.at.compareTo(b.at));
    if (!mounted) return;
    setState(() => _points = points);
  }

  String _fmt(_EspChannel channel, double? value) {
    final shown = value ?? 0;
    final unit = channel.unit.isEmpty ? '' : ' ${channel.unit}';
    return '${shown.toStringAsFixed(channel.digits)}$unit';
  }

  String _ago(DateTime? at) {
    if (at == null) return 'Chưa nhận được dữ liệu từ đồng hồ.';
    final d = DateTime.now().difference(at.toLocal());
    final when = d.inSeconds < 15
        ? 'vừa xong'
        : d.inMinutes < 1
            ? '${d.inSeconds} giây trước'
            : d.inHours < 1
                ? '${d.inMinutes} phút trước'
                : '${d.inHours} giờ trước';
    return 'Cập nhật: $when';
  }

  @override
  Widget build(BuildContext context) {
    final channel = _espChannels.firstWhere((item) => item.code == _code);
    final live = widget.power[channel.code];
    final fallback = live?.value ?? 0;
    final values = [for (final point in _points) point.value];
    final minV = values.isEmpty ? fallback : values.reduce((a, b) => a < b ? a : b);
    final maxV = values.isEmpty ? fallback : values.reduce((a, b) => a > b ? a : b);
    final avg = values.isEmpty ? fallback : values.reduce((a, b) => a + b) / values.length;
    final lo = live?.min;
    final hi = live?.max;
    var over = 0;
    if (lo != null && hi != null) {
      for (final value in values) {
        if (value < lo || value > hi) over++;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: mgmtCardDeco(radius: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ssid_chart, color: DashboardColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giám sát điện', style: bvText(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(
                      'Điện áp, dòng, công suất và các thông số đồng hồ từ Controller.',
                      style: bvText(color: DashboardColors.textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              MgmtOutlineButton(icon: Icons.refresh_rounded, label: 'Làm mới', onTap: () {
                setState(() => _loadedFor = '');
                _load();
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 700 ? 3 : 2);
            final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in _espChannels)
                  SizedBox(width: width, child: _valueCard(item)),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () {
            setState(() {
              _detail = !_detail;
              if (_detail) _loadedFor = '';
            });
            if (_detail) _load();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: mgmtCardDeco(radius: 14),
            child: Row(
              children: [
                Text('Xem chi tiết', style: bvText(fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(
                  _detail ? Icons.expand_less : Icons.expand_more,
                  color: DashboardColors.brand,
                ),
              ],
            ),
          ),
        ),
        if (_detail) ...[
          const SizedBox(height: 14),
          Container(
          padding: const EdgeInsets.all(16),
          decoration: mgmtCardDeco(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Biểu đồ ${channel.label}', style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
              Text(
                'Diễn biến ${channel.label.toLowerCase()} theo thời gian.',
                style: bvText(color: DashboardColors.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _code,
                      decoration: const InputDecoration(labelText: 'Chỉ số'),
                      items: [
                        for (final item in _espChannels)
                          DropdownMenuItem(value: item.code, child: Text(item.label)),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _code = value;
                          _loadedFor = '';
                        });
                        _load();
                      },
                    ),
                  ),
                  for (var i = 0; i < _espRanges.length; i++)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _range = i;
                          _loadedFor = '';
                        });
                        _load();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: i == _range ? DashboardColors.brand : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == _range ? DashboardColors.brand : DashboardColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          _espRanges[i].$1,
                          style: bvText(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: i == _range ? Colors.white : DashboardColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  FilterChip(
                    selected: _showThreshold,
                    label: Text('Hiện ngưỡng', style: bvText(fontWeight: FontWeight.w700, fontSize: 12)),
                    selectedColor: DashboardColors.mint,
                    onSelected: (value) => setState(() => _showThreshold = value),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                children: [
                  _stat('THẤP NHẤT', _fmt(channel, minV)),
                  _stat('TRUNG BÌNH', _fmt(channel, avg)),
                  _stat('CAO NHẤT', _fmt(channel, maxV)),
                  _stat('NGOÀI NGƯỠNG', '$over lần'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: HistoryChart(
                  segments: _segments(),
                  rangeMinutes: _espRanges[_range].$2.inMinutes,
                  color: const Color(0xFFFF9800),
                  unit: channel.unit,
                  minTh: _showThreshold ? lo : null,
                  maxTh: _showThreshold ? hi : null,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                children: [
                  _legend(const Color(0xFFFF9800), channel.label),
                  if (_showThreshold) ...[
                    _legend(const Color(0xFF94A3B8), 'Ngưỡng thấp'),
                    _legend(_kRed, 'Ngưỡng cao'),
                  ],
                  _legend(const Color(0xFFCBD5E1), 'Mất dữ liệu'),
                ],
              ),
              const SizedBox(height: 12),
              Text('Lịch sử gần nhất', style: bvText(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              if (_points.isEmpty)
                Text('${_fmt(channel, widget.power[channel.code]?.value ?? 0)}    ${fmtDateTimeVn(DateTime.now())}', style: bvText(fontSize: 13))
              else
                for (final point in _points.reversed.take(8))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${_fmt(channel, point.value)}    ${fmtDateTimeVn(point.at)}',
                      style: bvText(fontSize: 13),
                    ),
                  ),
            ],
          ),
        ),
        ],
      ],
    );
  }

  Widget _valueCard(_EspChannel item) {
    final point = widget.power[item.code];
    final has = point?.value != null;
    final on = item.code == _code;
    return InkWell(
      onTap: () {
        setState(() {
          _code = item.code;
          _loadedFor = '';
        });
        _load();
      },
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? DashboardColors.brand : DashboardColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, size: 18, color: DashboardColors.brand),
                const SizedBox(width: 6),
                Expanded(child: Text(item.label, style: bvText(fontWeight: FontWeight.w800))),
                MgmtStatusBadge(
                  label: has ? 'Đang nhận' : 'Chưa có dữ liệu',
                  color: has ? DashboardColors.brand : const Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_fmt(item, point?.value), style: bvText(fontSize: 26, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(_ago(point?.at), style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: bvText(fontSize: 10.5, color: DashboardColors.textMuted, fontWeight: FontWeight.w700)),
        Text(value, style: bvText(fontWeight: FontWeight.w800)),
      ],
    );
  }

  List<List<RealtimeChartPoint>> _segments() {
    final minutes = _espRanges[_range].$2.inMinutes;
    final start = DateTime.now().subtract(Duration(minutes: minutes));
    final current = widget.power[_code]?.value ?? 0;
    final series = <RealtimeChartPoint>[
      if (_points.isEmpty) ...[
        RealtimeChartPoint(xMinutes: 0, label: '0p', timestamp: start, value: current),
        RealtimeChartPoint(
          xMinutes: minutes.toDouble(),
          label: '${minutes}p',
          timestamp: DateTime.now(),
          value: current,
        ),
      ] else
        for (final point in _points)
          if (!point.at.isBefore(start))
            RealtimeChartPoint(
              xMinutes: point.at.difference(start).inSeconds / 60,
              label: '',
              timestamp: point.at,
              value: point.value,
            ),
    ];
    if (series.isEmpty) {
      return [
        [
          RealtimeChartPoint(xMinutes: 0, label: '0p', timestamp: start, value: 0),
          RealtimeChartPoint(xMinutes: minutes.toDouble(), label: '${minutes}p', timestamp: DateTime.now(), value: 0),
        ],
      ];
    }
    if (_points.isEmpty) return [series];
    final gap = switch (minutes) {
      <= 60 => const Duration(seconds: 90),
      <= 360 => const Duration(minutes: 8),
      <= 1440 => const Duration(minutes: 20),
      _ => const Duration(hours: 3),
    };
    final segs = <List<RealtimeChartPoint>>[];
    var cur = <RealtimeChartPoint>[series.first];
    for (var i = 1; i < series.length; i++) {
      if (series[i].timestamp.difference(series[i - 1].timestamp) > gap) {
        segs.add(cur);
        cur = [series[i]];
      } else {
        cur.add(series[i]);
      }
    }
    segs.add(cur);
    return segs;
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
        ],
      );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.node,
    required this.title,
    required this.pending,
    required this.commandSource,
    required this.level,
    required this.lowFloat,
    required this.highFloat,
    required this.tank,
    required this.pump,
    this.liveOn,
    required this.onAuto,
    required this.onManual,
    required this.onOn,
    required this.onOff,
    required this.onMenu,
    required this.onOpenController,
    this.power,
    this.onPower,
    this.assignable = false,
  });

  final RasFlowNodeLive node;
  final String title;
  final String? pending;
  final String commandSource;
  final String? level;
  final String lowFloat;
  final String highFloat;
  final bool tank;
  final bool pump;
  final bool? liveOn;
  final VoidCallback onAuto;
  final VoidCallback onManual;
  final VoidCallback onOn;
  final VoidCallback onOff;
  final ValueChanged<String> onMenu;
  final VoidCallback onOpenController;
  final PowerSnapshot? power;
  final VoidCallback? onPower;
  final bool assignable;

  @override
  Widget build(BuildContext context) {
    final offline = node.isOnline == false;
    final error = node.status.toLowerCase() == 'alarm' || node.status.toLowerCase() == 'error';
    final on = liveOn ?? node.isOn;
    final running = on == true && !offline && !error;
    final statusLabel = tank
        ? (level ?? 'Chưa gán')
        : pump
            ? (on == true ? 'Mở' : 'Tắt')
            : (error
                ? 'Lỗi'
                : offline
                    ? 'Mất kết nối'
                    : running
                        ? 'Đang chạy'
                        : 'Đang tắt');
    final statusColor = tank
        ? (_levelColor(level) ?? const Color(0xFF94A3B8))
        : pump
            ? (on == true ? DashboardColors.brand : DashboardColors.textMuted)
            : (error
                ? _kRed
                : offline
                    ? const Color(0xFF94A3B8)
                    : running
                        ? DashboardColors.brand
                        : DashboardColors.textMuted);
    final canCmd = node.hasRelay && !offline && pending == null;
    final manualOk = canCmd && !node.isAuto;
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
                  if (tank) const PopupMenuItem(value: 'edit', child: Text('Gán phao')),
                  if (!tank) const PopupMenuItem(value: 'history', child: Text('Xem lịch sử')),
                  if (!tank && power != null)
                    const PopupMenuItem(value: 'power', child: Text('Lịch sử điện')),
                  if (!tank) const PopupMenuItem(value: 'controller', child: Text('Xem Controller')),
                  if (assignable)
                    const PopupMenuItem(value: 'relay', child: Text('Gán actuator')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa thiết bị')),
                  if (!tank) ...[
                    const PopupMenuItem(value: 'auto', child: Text('Cấu hình AUTO')),
                    const PopupMenuItem(value: 'schedule', child: Text('Lịch chạy')),
                  ],
                  if (!tank && node.hasRelay && !node.isAuto && !offline) ...[
                    const PopupMenuItem(value: 'on', child: Text('Bật')),
                    const PopupMenuItem(value: 'off', child: Text('Tắt')),
                  ],
                ],
              ),
            ],
          ),
          if (!tank && node.hasRelay) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _modeBtn(pump ? 'Mở' : 'Bật', on == true, manualOk ? onOn : null, 'Bật $title'),
                const SizedBox(width: 6),
                _modeBtn('Tắt', on != true, manualOk ? onOff : null, 'Tắt $title'),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (tank) ...[
            _meta('Trạng thái', statusLabel, color: statusColor),
            _meta('Phao dưới', lowFloat),
            _meta('Phao trên', highFloat),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onMenu('edit'),
                child: const Text('Gán phao'),
              ),
            ),
          ] else ...[
          _meta('Vị trí', '${node.sortOrder}'),
          _meta('Controller', node.relayDeviceId == null ? 'Chưa gán' : 'Đã gán'),
          _meta('Actuator', _controllerCode(node)),
          _meta('Kết nối', offline ? 'Mất kết nối' : 'Online', color: offline ? _kRed : DashboardColors.brand),
          if (offline)
            _meta('Lần thấy', node.lastCommandAt == null ? '—' : fmtDateTimeVn(node.lastCommandAt)),
          _meta('Chế độ', node.isAuto ? 'AUTO' : 'MANUAL', color: node.isAuto ? DashboardColors.brand : _kAmber),
          _meta('Thời gian chạy', on == true ? _runtime(node) : '—'),
          _meta('Lần thay đổi', node.lastCommandAt == null ? '—' : fmtDateTimeVn(node.lastCommandAt)),
          _meta('Nguồn lệnh', commandSource),
          if (power != null) _powerBlock(),
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
              _modeBtn('AUTO', node.isAuto, canCmd ? onAuto : null, 'Chuyển $title sang AUTO'),
              const SizedBox(width: 6),
              _modeBtn('MANUAL', !node.isAuto, canCmd ? onManual : null, 'Chuyển $title sang MANUAL'),
            ],
          ),
          ],
        ],
      ),
    );
  }

  Widget _powerBlock() {
    final snap = power!;
    String line(String code, String unit) {
      final point = snap[code];
      if (point?.value == null) return '';
      return '${point!.value!.toStringAsFixed(code == 'meter_kwh' ? 3 : 1)} $unit';
    }

    final rows = [
      ('Điện áp', line('meter_v', 'V')),
      ('Dòng', line('meter_a', 'A')),
      ('Công suất', line('meter_w', 'W')),
      ('Điện năng', line('meter_kwh', 'kWh')),
    ].where((row) => row.$2.isNotEmpty);

    return InkWell(
      onTap: onPower,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điện', style: bvText(fontSize: 12, fontWeight: FontWeight.w800, color: DashboardColors.brand)),
            for (final row in rows) _meta(row.$1, row.$2),
          ],
        ),
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

String _powerValue(Map<String, dynamic> row) {
  final raw = row['value'] ?? row['Value'];
  if (raw is num) return raw.toString();
  return raw?.toString() ?? '—';
}

String _powerWhen(Map<String, dynamic> row) {
  final raw = row['measuredAt'] ?? row['MeasuredAt'];
  final at = raw == null ? null : DateTime.tryParse(raw.toString());
  return at == null ? '' : fmtDateTimeVn(at);
}

String _controllerCode(RasFlowNodeLive n) {
  final ch = (n.relayChannel ?? '').trim();
  if (ch.isNotEmpty && ch.toLowerCase() != 'online') return 'Kênh $ch';
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

Color? _levelColor(String? level) => switch (level) {
      'Tràn' => _kRed,
      'Cạn' => _kAmber,
      'Bình thường' => DashboardColors.brand,
      null => null,
      _ => const Color(0xFF94A3B8),
    };

Widget _levelAssign(
  String title,
  String sensor,
  String when,
  String taken,
  void Function(String sensor, String when) onChanged,
) {
  const floats = ['float_1', 'float_2', 'float_3', 'float_4'];
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 96, child: Text(title, style: bvText(fontWeight: FontWeight.w700))),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: sensor,
            decoration: const InputDecoration(labelText: 'Phao'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Không gán')),
              for (final code in floats)
                if (code != taken || code == sensor)
                  DropdownMenuItem(value: code, child: Text('Phao ${code.substring(code.length - 1)}')),
            ],
            onChanged: (value) => onChanged(value ?? '', when),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: DropdownButtonFormField<String>(
            value: when,
            decoration: const InputDecoration(labelText: 'Khi phao'),
            items: const [
              DropdownMenuItem(value: 'on', child: Text('Bật')),
              DropdownMenuItem(value: 'off', child: Text('Tắt')),
            ],
            onChanged: sensor.isEmpty ? null : (value) => onChanged(sensor, value ?? 'on'),
          ),
        ),
      ],
    ),
  );
}

class _PickedDevice {
  const _PickedDevice(
    this.label,
    this.electrical,
    this.kind,
    this.icon,
    this.group,
    this.specs,
  );

  final String label;
  final bool electrical;
  final String kind;
  final String icon;
  final String group;
  final Map<String, String> specs;
}

class _KindChoice {
  const _KindChoice(this.label, this.type, this.icon, this.electrical);

  final String label;
  final String type;
  final String icon;
  final bool electrical;
}

class _IconChoice {
  const _IconChoice(this.key, this.icon);

  final String key;
  final IconData icon;
}

const _deviceKinds = [
  _KindChoice('Hộp nuôi', 'CULTURE', 'crab_boxes', false),
  _KindChoice('Bể xả', 'DRAIN_TANK', 'discharge_100', false),
  _KindChoice('Bể vi sinh', 'BIOFILTER', 'bio', false),
  _KindChoice('Bể san hô', 'CORAL_TANK', 'sand_coral_200', false),
  _KindChoice('Bể lắng', 'SETTLING_TANK', 'settling', false),
  _KindChoice('Drum Filter', 'FILTER', 'drum', true),
  _KindChoice('Skimmer', 'SKIMMER', 'skimmer', true),
  _KindChoice('Máy bơm', 'PUMP', 'pump', true),
  _KindChoice('Ozone', 'OZONE', 'ozone', true),
  _KindChoice('Máy oxy', 'OXY', 'oxy', true),
  _KindChoice('UV', 'UV', 'uv', true),
];

const _deviceIcons = [
  _IconChoice('crab_boxes', Icons.grid_view),
  _IconChoice('discharge_100', Icons.water_drop_outlined),
  _IconChoice('bio', Icons.biotech_outlined),
  _IconChoice('sand_coral_200', Icons.spa_outlined),
  _IconChoice('settling', Icons.layers_outlined),
  _IconChoice('drum', Icons.filter_alt_outlined),
  _IconChoice('skimmer', Icons.air_outlined),
  _IconChoice('pump', Icons.water),
  _IconChoice('ozone', Icons.bubble_chart_outlined),
  _IconChoice('oxy', Icons.air),
  _IconChoice('uv', Icons.wb_sunny_outlined),
  _IconChoice('heater', Icons.thermostat_outlined),
];

class _RasCanvas extends StatefulWidget {
  const _RasCanvas({
    required this.areaId,
    required this.nodes,
    required this.pipes,
    required this.titleOf,
    required this.onOpen,
    required this.onAdd,
    required this.meterOf,
    required this.levelOf,
    required this.kindOf,
    required this.liveOf,
    required this.floatsOf,
  });

  final String areaId;
  final List<RasFlowNodeLive> nodes;
  final List<RasPipe> pipes;
  final String Function(RasFlowNodeLive) titleOf;
  final ValueChanged<RasFlowNodeLive> onOpen;
  final VoidCallback onAdd;
  final String? Function(RasFlowNodeLive) meterOf;
  final String? Function(RasFlowNodeLive) levelOf;
  final String Function(RasFlowNodeLive) kindOf;
  final bool? Function(RasFlowNodeLive) liveOf;
  final String? Function(RasFlowNodeLive) floatsOf;

  @override
  State<_RasCanvas> createState() => _RasCanvasState();
}

class _RasCanvasState extends State<_RasCanvas> with SingleTickerProviderStateMixin {
  static const _cardW = 176.0;

  final _drag = <String, Offset>{};
  final _view = TransformationController();
  late final AnimationController _flow;
  late Map<String, Offset> _saved;
  Map<String, Offset> _base = {};

  @override
  void initState() {
    super.initState();
    _saved = RasLayoutStore.load(widget.areaId);
    _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    _view.dispose();
    super.dispose();
  }

  double _cardH(RasFlowNodeLive n) {
    var height = 96.0;
    if (widget.meterOf(n) != null) height += 28;
    if (widget.floatsOf(n) != null) height += 32;
    return height;
  }

  RasFlowNodeLive? _node(String id) {
    for (final n in widget.nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  double get _scale => _view.value.getMaxScaleOnAxis();

  void _setScale(double next) {
    final scale = next.clamp(0.4, 2.5);
    _view.value = Matrix4.identity()..scale(scale);
    setState(() {});
  }

  void _syncLayout() {
    final ids = widget.nodes.map((n) => n.id).toSet();
    _saved.removeWhere((id, _) => !ids.contains(id));
    _base.removeWhere((id, _) => !ids.contains(id));
    _drag.removeWhere((id, _) => !ids.contains(id));
    if (_saved.isEmpty && _base.isEmpty && widget.nodes.isNotEmpty) {
      _base = _place(widget.nodes, widget.pipes);
      _saved = Map<String, Offset>.from(_base);
      RasLayoutStore.save(widget.areaId, _saved);
      return;
    }
    final missing = <RasFlowNodeLive>[];
    for (final n in widget.nodes) {
      if (_drag.containsKey(n.id)) continue;
      final kept = _saved[n.id];
      if (kept != null) {
        _base[n.id] = kept;
      } else {
        missing.add(n);
      }
    }
    if (missing.isEmpty) return;
    var maxX = 20.0;
    for (final spot in _base.values) {
      if (spot.dx > maxX) maxX = spot.dx;
    }
    for (var i = 0; i < missing.length; i++) {
      final spot = Offset(maxX + 230, 16 + i * 150.0);
      _base[missing[i].id] = spot;
      _saved[missing[i].id] = spot;
    }
    RasLayoutStore.save(widget.areaId, _saved);
  }

  void _keep(String id) {
    final spot = _at(id);
    _base[id] = spot;
    _drag.remove(id);
    _saved[id] = spot;
    RasLayoutStore.save(widget.areaId, _saved);
  }

  Offset _at(String id) => (_base[id] ?? Offset.zero) + (_drag[id] ?? Offset.zero);

  @override
  Widget build(BuildContext context) {
    _syncLayout();
    var width = 1400.0;
    var height = 720.0;
    for (final n in widget.nodes) {
      final p = _at(n.id);
      if (p.dx + _cardW + 240 > width) width = p.dx + _cardW + 240;
      if (p.dy + _cardH(n) + 240 > height) height = p.dy + _cardH(n) + 240;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MgmtOutlineButton(onTap: widget.onAdd, icon: Icons.add, label: 'Thêm mới'),
            MgmtOutlineButton(
              onTap: () => _setScale(_scale / 1.2),
              icon: Icons.zoom_out,
              label: 'Thu nhỏ',
            ),
            Text('${(_scale * 100).round()}%', style: bvText(fontWeight: FontWeight.w800)),
            MgmtOutlineButton(
              onTap: () => _setScale(_scale * 1.2),
              icon: Icons.zoom_in,
              label: 'Phóng to',
            ),
            MgmtOutlineButton(
              onTap: () => _setScale(1),
              icon: Icons.fit_screen,
              label: 'Vừa khung',
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DashboardColors.cardBorder),
          ),
          child: SizedBox(
            height: 460,
            child: Listener(
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent) return;
                GestureBinding.instance.pointerSignalResolver.register(event, (signal) {
                  if (signal is! PointerScrollEvent || !mounted) return;
                  _setScale(_scale * (signal.scrollDelta.dy > 0 ? 0.9 : 1.1));
                });
              },
              child: InteractiveViewer(
                transformationController: _view,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(600),
                minScale: 0.4,
                maxScale: 2.5,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _flow,
                        builder: (context, _) => CustomPaint(
                          size: Size(width, height),
                          painter: _PipePainter(
                            phase: _flow.value,
                            cardWidth: _cardW,
                            segments: [
                              for (final pipe in widget.pipes)
                                if (_node(pipe.fromId) != null && _node(pipe.toId) != null)
                                  (
                                    _at(pipe.fromId),
                                    _cardH(_node(pipe.fromId)!),
                                    _at(pipe.toId),
                                    _cardH(_node(pipe.toId)!),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      for (final n in widget.nodes)
                        Positioned(
                          left: _at(n.id).dx,
                          top: _at(n.id).dy,
                          child: GestureDetector(
                            onTap: () => widget.onOpen(n),
                            onPanUpdate: (d) => setState(() {
                              final scale = _scale == 0 ? 1.0 : _scale;
                              _drag[n.id] = (_drag[n.id] ?? Offset.zero) + d.delta / scale;
                            }),
                            onPanEnd: (_) => setState(() => _keep(n.id)),
                            child: _canvasNode(n),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _canvasNode(RasFlowNodeLive n) {
    final error = n.status.toLowerCase() == 'alarm' || n.status.toLowerCase() == 'error';
    final offline = n.isOnline == false;
    final on = widget.liveOf(n) ?? n.isOn;
    final running = n.hasRelay && on == true && !offline && !error;
    final kind = widget.kindOf(n);
    final level = widget.levelOf(n);
    final open = n.hasRelay && on == true;
    final String status;
    final Color color;
    if (kind == 'tank') {
      status = level ?? 'Chưa gán';
      color = _levelColor(level) ?? const Color(0xFF94A3B8);
    } else if (kind == 'pump') {
      status = open ? 'Mở' : 'Tắt';
      color = open ? DashboardColors.brand : const Color(0xFF94A3B8);
    } else {
      color = error
          ? _kRed
          : offline
              ? const Color(0xFF94A3B8)
              : running
                  ? DashboardColors.brand
                  : const Color(0xFF2495E8);
      status = error
          ? 'Lỗi'
          : offline
              ? 'Mất kết nối'
              : running
                  ? 'Đang chạy'
                  : n.hasRelay
                      ? 'Tắt'
                      : 'Online';
    }
    return Container(
      width: _cardW,
      height: _cardH(n),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(n.icon, size: 16, color: DashboardColors.brand),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.titleOf(n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (widget.meterOf(n) != null)
            Text(
              widget.meterOf(n)!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontSize: 11, fontWeight: FontWeight.w800, color: DashboardColors.brand),
            ),
          if (widget.floatsOf(n) != null)
            Text(
              widget.floatsOf(n)!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bvText(fontSize: 10.5, color: DashboardColors.textMuted),
            ),
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(status, style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RasLayoutStore {
  static File _file() {
    final root = Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    final dir = Directory('$root\\CrabSense');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}\\ras-layout.json');
  }

  static Map<String, Offset> load(String areaId) {
    try {
      final raw = jsonDecode(_file().readAsStringSync());
      final area = raw is Map ? raw[areaId] : null;
      if (area is! Map) return {};
      final points = <String, Offset>{};
      for (final entry in area.entries) {
        final value = entry.value;
        if (value is! List || value.length < 2) continue;
        points[entry.key.toString()] = Offset(
          (value[0] as num).toDouble(),
          (value[1] as num).toDouble(),
        );
      }
      return points;
    } catch (_) {
      return {};
    }
  }

  static void save(String areaId, Map<String, Offset> points) {
    Map<String, dynamic> all = {};
    try {
      final raw = jsonDecode(_file().readAsStringSync());
      if (raw is Map<String, dynamic>) all = raw;
      if (raw is Map && raw is! Map<String, dynamic>) {
        all = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}
    all[areaId] = {
      for (final entry in points.entries) entry.key: [entry.value.dx, entry.value.dy],
    };
    _file().writeAsStringSync(jsonEncode(all));
  }
}

Map<String, Offset> _place(List<RasFlowNodeLive> nodes, List<RasPipe> pipes) {
  final ids = nodes.map((n) => n.id).toList();
  final out = <String, List<String>>{for (final id in ids) id: []};
  final incoming = <String, int>{for (final id in ids) id: 0};
  for (final pipe in pipes) {
    if (!out.containsKey(pipe.fromId) || !incoming.containsKey(pipe.toId)) continue;
    out[pipe.fromId]!.add(pipe.toId);
    incoming[pipe.toId] = incoming[pipe.toId]! + 1;
  }
  final depth = <String, int>{};
  final queue = <String>[];
  for (final id in ids) {
    if (incoming[id] == 0) {
      depth[id] = 0;
      queue.add(id);
    }
  }
  if (queue.isEmpty && ids.isNotEmpty) {
    depth[ids.first] = 0;
    queue.add(ids.first);
  }
  var guard = 0;
  while (queue.isNotEmpty && guard < 400) {
    guard++;
    final id = queue.removeAt(0);
    for (final next in out[id] ?? const <String>[]) {
      final d = (depth[id] ?? 0) + 1;
      if (d > 12) continue;
      if ((depth[next] ?? -1) >= d) continue;
      depth[next] = d;
      queue.add(next);
    }
  }
  final layers = <int, List<String>>{};
  for (final id in ids) {
    final d = depth[id] ?? 0;
    layers.putIfAbsent(d, () => []).add(id);
  }
  final pos = <String, Offset>{};
  const dx = 210.0;
  const dy = 150.0;
  for (final layer in layers.entries) {
    for (var i = 0; i < layer.value.length; i++) {
      pos[layer.value[i]] = Offset(20 + layer.key * dx, 16 + i * dy);
    }
  }
  return pos;
}

class _PipePainter extends CustomPainter {
  _PipePainter({
    required this.segments,
    required this.phase,
    required this.cardWidth,
  });

  final List<(Offset, double, Offset, double)> segments;
  final double phase;
  final double cardWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = const Color(0xFF2495E8).withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final moving = Paint()..color = const Color(0xFF1D4ED8);
    for (final segment in segments) {
      final fromBox = segment.$1;
      final fromH = segment.$2;
      final toBox = segment.$3;
      final toH = segment.$4;
      final fromCenter = fromBox + Offset(cardWidth / 2, fromH / 2);
      final toCenter = toBox + Offset(cardWidth / 2, toH / 2);
      final leave = _port(fromBox, fromH, _toward(fromCenter, toCenter));
      final arrive = _port(toBox, toH, _toward(toCenter, fromCenter));
      final out = _outward(_toward(fromCenter, toCenter));
      final inn = _outward(_toward(toCenter, fromCenter));
      final path = Path()
        ..moveTo(leave.dx, leave.dy)
        ..cubicTo(
          leave.dx + out.dx * 70,
          leave.dy + out.dy * 70,
          arrive.dx + inn.dx * 70,
          arrive.dy + inn.dy * 70,
          arrive.dx,
          arrive.dy,
        );
      canvas.drawPath(path, base);
      for (final metric in path.computeMetrics()) {
        if (metric.length < 8) continue;
        const gap = 14.0;
        final shift = (phase % 1) * gap;
        for (var distance = shift; distance < metric.length - 2; distance += gap) {
          final spot = metric.getTangentForOffset(distance);
          if (spot == null) continue;
          canvas.drawCircle(spot.position, 3.4, moving);
        }
      }
    }
  }

  Offset _port(Offset topLeft, double height, Offset dir) {
    if (dir.dx.abs() >= dir.dy.abs()) {
      return dir.dx >= 0
          ? Offset(topLeft.dx + cardWidth, topLeft.dy + height / 2)
          : Offset(topLeft.dx, topLeft.dy + height / 2);
    }
    return dir.dy >= 0
        ? Offset(topLeft.dx + cardWidth / 2, topLeft.dy + height)
        : Offset(topLeft.dx + cardWidth / 2, topLeft.dy);
  }

  Offset _toward(Offset from, Offset to) => to - from;

  Offset _outward(Offset dir) {
    if (dir.dx.abs() >= dir.dy.abs()) {
      return Offset(dir.dx >= 0 ? 1 : -1, 0);
    }
    return Offset(0, dir.dy >= 0 ? 1 : -1);
  }

  @override
  bool shouldRepaint(covariant _PipePainter oldDelegate) => true;
}
