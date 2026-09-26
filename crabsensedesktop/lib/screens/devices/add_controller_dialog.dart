import 'package:flutter/material.dart';

import '../../config/app_env.dart';
import '../../models/auth_models.dart';
import '../../models/iot_device.dart';
import '../../models/row_list_item.dart';
import '../../services/controller_provisioning_service.dart';
import '../../services/controller_service.dart';
import '../../services/row_management_service.dart';
import '../../services/wifi_ssid_scanner.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

const controllerTypeRealtime = 'realtime_sensor';
const controllerTypeWaterAnalysis = 'water_analysis';
const controllerTypeRas = 'ras';
const controllerTypeMixed = 'mixed';
const controllerTypeCamera = 'camera';
const controllerTypeOther = 'other';

const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kSlate = Color(0xFF94A3B8);

String controllerTypeLabel(String type) {
  switch (type.trim().toLowerCase()) {
    case controllerTypeWaterAnalysis:
      return 'Water Analysis (NO₂ Analyzer)';
    case controllerTypeRas:
    case 'ras_controller':
    case 'esp32':
    case 'esp32-s3':
      return 'RAS Controller';
    case controllerTypeCamera:
    case 'camera_controller':
      return 'Camera / AI Controller';
    case controllerTypeMixed:
    case 'mixed_controller':
      return 'Sensor + Actuator Controller';
    case controllerTypeRealtime:
    case 'sensor':
      return 'Realtime Sensor Controller';
    default:
      return type.trim().isEmpty ? 'Khác' : type;
  }
}

String controllerTypeFilterKey(String type) {
  switch (type.trim().toLowerCase()) {
    case controllerTypeWaterAnalysis:
      return 'water';
    case controllerTypeRas:
    case 'ras_controller':
    case 'esp32':
    case 'esp32-s3':
      return 'ras';
    case controllerTypeCamera:
    case 'camera_controller':
      return 'camera';
    case controllerTypeMixed:
    case 'mixed_controller':
      return 'mixed';
    case controllerTypeRealtime:
    case 'sensor':
      return 'realtime';
    default:
      return 'other';
  }
}

String _typeFromFirmware(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.contains('ras') ||
      t.contains('actuator') ||
      t == 'esp32' ||
      t == 'esp32-s3') {
    return t.contains('sensor') ? controllerTypeMixed : controllerTypeRas;
  }
  if (t.contains('camera') || t.contains('ai')) return controllerTypeCamera;
  if (t.contains('water')) return controllerTypeWaterAnalysis;
  if (t.contains('mix')) return controllerTypeMixed;
  if (t.isEmpty || t.contains('sensor') || t.contains('realtime')) {
    return controllerTypeRealtime;
  }
  return controllerTypeOther;
}

class AddControllerWizardResult {
  const AddControllerWizardResult({
    required this.deviceId,
    this.openSensors = false,
  });

  final String deviceId;
  final bool openSensors;
}

Future<AddControllerWizardResult?> showAddControllerDialog(
  BuildContext context, {
  required ControllerService service,
  required AuthSession session,
  RowManagementService? rowService,
}) {
  return showDialog<AddControllerWizardResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color.fromRGBO(15, 35, 30, 0.45),
    builder: (ctx) => _AddControllerWizard(
      service: service,
      session: session,
      rowService: rowService,
    ),
  );
}

enum _Step { discover, config, verify, success }

enum _FindTab { lan, wifi }

enum _Check { pending, ok, fail }

class _AddControllerWizard extends StatefulWidget {
  const _AddControllerWizard({
    required this.service,
    required this.session,
    this.rowService,
  });

  final ControllerService service;
  final AuthSession session;
  final RowManagementService? rowService;

  @override
  State<_AddControllerWizard> createState() => _AddControllerWizardState();
}

class _AddControllerWizardState extends State<_AddControllerWizard> {
  final _provisioning = ControllerProvisioningService();
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _location = TextEditingController();
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  final _kioskUrl = TextEditingController(text: AppEnv.kioskUrl);
  final _staticIp = TextEditingController();
  final _subnet = TextEditingController();
  final _gateway = TextEditingController();
  final _dns = TextEditingController();
  final _manualId = TextEditingController();
  final _manualName = TextEditingController();

  _Step _step = _Step.discover;
  _FindTab _findTab = _FindTab.lan;
  var _scanning = false;
  var _registering = false;
  var _wifiSending = false;
  var _obscure = true;
  var _dhcp = true;
  var _advanced = false;
  var _manual = false;
  String? _error;
  String? _wifiError;
  String? _wifiPhase;
  List<EspProvisionInfo> _found = const [];
  EspProvisionInfo? _selected;
  late FarmSummary _area;
  String? _rowId;
  String _type = controllerTypeRealtime;
  List<String> _ssids = const [];
  IoTDevice? _duplicate;
  Map<String, dynamic>? _created;
  _Check _chkBoard = _Check.pending;
  _Check _chkWifi = _Check.pending;
  _Check _chkApi = _Check.pending;
  _Check _chkFw = _Check.pending;
  _Check _chkId = _Check.pending;
  String? _chkBoardDetail;
  String? _chkWifiDetail;
  String? _chkApiDetail;

  @override
  void initState() {
    super.initState();
    _area = widget.session.selectedFarm;
    _location.text = _area.isUnassigned
        ? ''
        : 'Tủ điều khiển khu ${_area.code.isEmpty ? _area.name : _area.code}';
    _loadSsids();
    widget.rowService?.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _location.dispose();
    _ssid.dispose();
    _password.dispose();
    _kioskUrl.dispose();
    _staticIp.dispose();
    _subnet.dispose();
    _gateway.dispose();
    _dns.dispose();
    _manualId.dispose();
    _manualName.dispose();
    super.dispose();
  }

  Future<void> _loadSsids() async {
    final names = await WifiSsidScanner.scan();
    if (!mounted) return;
    setState(() => _ssids = names);
  }

  List<RowListItem> get _rows {
    final rows = widget.rowService?.items ?? const <RowListItem>[];
    return rows.where((r) => r.areaId == _area.id || r.areaId.isEmpty).toList();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _found = const [];
      _selected = null;
    });
    try {
      final list = await _provisioning.discoverAllNearby();
      if (!mounted) return;
      setState(() => _found = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '⚠ Không thể quét mạng. $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  IoTDevice? _findDuplicate(EspProvisionInfo info) {
    for (final d in widget.service.items) {
      final mac = (d.macAddress ?? '').toLowerCase();
      if (info.mac.isNotEmpty && mac == info.mac.toLowerCase()) return d;
      if (info.deviceCode.isNotEmpty &&
          d.deviceCode.toLowerCase() == info.deviceCode.toLowerCase()) {
        return d;
      }
      if (info.deviceId.isNotEmpty &&
          d.deviceCode.toLowerCase() == info.deviceId.toLowerCase()) {
        return d;
      }
    }
    return null;
  }

  void _pick(EspProvisionInfo info) {
    final dup = _findDuplicate(info);
    setState(() {
      _selected = info;
      _duplicate = dup;
      _name.text = info.displayName;
      _type = _typeFromFirmware(info.controllerType);
      _error = null;
      if (dup == null) _step = _Step.config;
    });
  }

  Future<void> _runChecks() async {
    final sel = _selected;
    setState(() {
      _chkBoard = _Check.pending;
      _chkWifi = _Check.pending;
      _chkApi = _Check.pending;
      _chkFw = _Check.pending;
      _chkId = _Check.pending;
      _chkBoardDetail = 'Đang kiểm tra...';
      _chkWifiDetail = 'Đang kiểm tra...';
      _chkApiDetail = 'Đang kiểm tra...';
    });
    if (sel == null) return;

    try {
      final live = await _provisioning.discover(baseUrl: sel.baseUrl);
      if (!mounted) return;
      setState(() {
        _selected = live;
        _chkBoard = _Check.ok;
        _chkBoardDetail = 'Đã nhận heartbeat từ thiết bị';
        _chkWifi = live.staIp.isNotEmpty ||
                live.wifiSsid.isNotEmpty ||
                live.provisioned
            ? _Check.ok
            : _Check.fail;
        _chkWifiDetail = live.wifiSsid.isNotEmpty
            ? 'Đang kết nối với ${live.wifiSsid}'
            : (live.staIp.isNotEmpty
                ? 'Đã có IP LAN ${live.staIp}'
                : 'Chưa thấy Wi-Fi trại');
        _chkFw = live.firmware.isNotEmpty ? _Check.ok : _Check.fail;
        _chkId = live.hardwareId.isNotEmpty ? _Check.ok : _Check.fail;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chkBoard = _Check.fail;
        _chkBoardDetail = 'Không nhận được heartbeat trong thời gian chờ.';
        _chkWifi = _Check.fail;
        _chkWifiDetail = 'Không xác nhận được Wi-Fi';
        _chkFw = (sel.firmware.isNotEmpty) ? _Check.ok : _Check.fail;
        _chkId = sel.hardwareId.isNotEmpty ? _Check.ok : _Check.fail;
      });
    }

    try {
      await widget.service.load(silent: true);
      if (!mounted) return;
      setState(() {
        _chkApi = _Check.ok;
        _chkApiDetail = 'Có thể gửi/nhận dữ liệu';
        _duplicate = _findDuplicate(_selected ?? sel);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chkApi = _Check.fail;
        _chkApiDetail = 'Không gọi được CrabSense API';
      });
    }
  }

  bool get _canRegister =>
      _selected != null &&
      _name.text.trim().isNotEmpty &&
      !_area.isUnassigned &&
      _duplicate == null &&
      _chkBoard == _Check.ok &&
      _chkId != _Check.fail &&
      !_registering;

  Future<void> _register() async {
    final sel = _selected;
    if (sel == null || !_canRegister) return;
    setState(() => _registering = true);
    final created = await widget.service.add(
      deviceCode: sel.deviceCode.isNotEmpty ? sel.deviceCode : sel.hardwareId,
      name: _name.text.trim(),
      deviceType: _type,
      macAddress: sel.mac,
      ipAddress: sel.ip,
      firmwareVersion: sel.firmware,
      farmingAreaId: _area.id,
      farmingRowId: _rowId,
      installationLocation:
          _location.text.trim().isEmpty ? null : _location.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      registerRealtimeSensors: false,
    );
    if (!mounted) return;
    if (created == null) {
      final err = widget.service.error ?? '';
      final isDup = err.toLowerCase().contains('already') ||
          err.toLowerCase().contains('exists') ||
          err.toLowerCase().contains('tồn tại');
      setState(() {
        _registering = false;
        if (isDup) {
          _duplicate = _findDuplicate(sel) ??
              widget.service.items.cast<IoTDevice?>().firstWhere(
                    (d) => d != null && d.deviceCode == sel.deviceCode,
                    orElse: () => null,
                  );
        } else {
          _error = '⚠ Không thể đăng ký Controller. $err';
        }
      });
      return;
    }
    setState(() {
      _registering = false;
      _created = created;
      _step = _Step.success;
    });
  }

  Future<void> _sendWifi() async {
    if (_ssid.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _wifiError = '⚠ Nhập SSID và mật khẩu Wi-Fi mới.');
      return;
    }
    setState(() {
      _wifiSending = true;
      _wifiError = null;
      _wifiPhase = 'Đang gửi cấu hình...';
    });
    try {
      setState(() => _wifiPhase = 'Đã gửi SSID/password');
      await _provisioning.provision(
        ssid: _ssid.text,
        password: _password.text,
        kioskUrl: _kioskUrl.text,
      );
      if (!mounted) return;
      setState(() => _wifiPhase = 'ESP32 đang khởi động lại');
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() => _wifiPhase = 'Đang kết nối ${_ssid.text.trim()}');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _wifiSending = false;
        _wifiPhase = '✓ Đã gửi cấu hình. Quét LAN để tìm Controller.';
        _findTab = _FindTab.lan;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _wifiSending = false;
        _wifiError = '⚠ ${_wifiReason('$e')}';
        _wifiPhase = null;
      });
    }
  }

  String _wifiReason(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('auth')) return 'Sai mật khẩu Wi-Fi';
    if (t.contains('ssid') || t.contains('not found'))
      return 'Không tìm thấy Wi-Fi';
    if (t.contains('timeout')) return 'Kết nối quá thời gian';
    if (t.contains('unreachable') || t.contains('network')) {
      return 'Không thể truy cập mạng';
    }
    return 'Không thể gửi cấu hình Wi-Fi. $raw';
  }

  void _close({AddControllerWizardResult? result}) {
    if (_registering) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width;
    final width = wide < 760 ? wide * 0.94 : 840.0;
    return PopScope(
      canPop: !_registering,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          child: Column(
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _stepper(),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: switch (_step) {
                    _Step.discover => _discoverBody(),
                    _Step.config => _configBody(),
                    _Step.verify => _verifyBody(),
                    _Step.success => _successBody(),
                  },
                ),
              ),
              if (_step != _Step.success) ...[
                const Divider(height: 1),
                _footer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thêm Controller',
                    style: bvText(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Kết nối Controller ESP32 với CrabSense. Có thể tìm thiết bị trong mạng LAN hoặc cấu hình Wi-Fi nếu thiết bị chưa kết nối.',
                  style: bvText(color: DashboardColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _registering ? null : () => _close(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _stepper() {
    Widget node(int i, String label, _Step step) {
      final idx = _Step.values.indexOf(_step);
      final done = idx > i;
      final active = _step == step;
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done || active
                    ? DashboardColors.brand
                    : DashboardColors.lightMint,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${i + 1}',
                      style: bvText(
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : _kSlate,
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: active || done ? DashboardColors.brand : _kSlate,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        node(0, 'Tìm thiết bị', _Step.discover),
        _line(),
        node(1, 'Cấu hình', _Step.config),
        _line(),
        node(2, 'Xác nhận', _Step.verify),
      ],
    );
  }

  Widget _line() => Expanded(
        child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: DashboardColors.cardBorder),
      );

  Widget _discoverBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _tab('Tìm trong mạng LAN', _FindTab.lan),
            const SizedBox(width: 8),
            _tab('Cấu hình Wi-Fi (thiết bị mới)', _FindTab.wifi),
          ],
        ),
        const SizedBox(height: 16),
        if (_findTab == _FindTab.lan) _lanPane() else _wifiPane(),
      ],
    );
  }

  Widget _tab(String label, _FindTab tab) {
    final on = _findTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _findTab = tab),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? DashboardColors.brand : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: on ? DashboardColors.brand : DashboardColors.cardBorder),
          ),
          child: Text(
            label,
            style: bvText(
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : DashboardColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _lanPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tìm Controller trong mạng LAN',
            style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Tìm Controller ESP32 đang kết nối cùng mạng với máy tính hiện tại.',
          style: bvText(color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: MgmtPrimaryButton(
            label: _scanning ? 'Đang quét...' : 'Quét mạng LAN',
            icon: Icons.search,
            onTap: _scanning ? null : _scan,
          ),
        ),
        if (_scanning) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(height: 10),
          Text(
            'Đang tìm Controller trong mạng Wi-Fi...',
            textAlign: TextAlign.center,
            style: bvText(fontWeight: FontWeight.w700),
          ),
          Text(
            'Vui lòng đảm bảo Controller đang bật và cùng mạng LAN.',
            textAlign: TextAlign.center,
            style: bvText(color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 12),
          _skelCards(),
        ] else if (_error != null) ...[
          const SizedBox(height: 12),
          _banner(_error!, _kRed),
        ],
        if (!_scanning && _found.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Thiết bị tìm thấy (${_found.length})',
              style: bvText(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          for (final d in _found) _deviceCard(d),
        ],
        if (!_scanning && _found.isEmpty && _error == null && !_manual) ...[
          const SizedBox(height: 20),
          _emptyLan(),
        ],
        if (_duplicate != null) ...[
          const SizedBox(height: 12),
          _duplicateBanner(),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            MgmtOutlineButton(
                onTap: _scanning ? null : _scan,
                icon: Icons.refresh,
                label: 'Quét lại'),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => setState(() => _findTab = _FindTab.wifi),
              child: Text('Không tìm thấy thiết bị? Cấu hình Wi-Fi →',
                  style: bvText(
                      color: DashboardColors.brand,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _manual = !_manual),
          child: Text(
              _manual
                  ? 'Ẩn nhập Device ID thủ công'
                  : 'Nhập Device ID thủ công',
              style: bvText(color: DashboardColors.textMuted)),
        ),
        if (_manual) _manualBox(),
      ],
    );
  }

  Widget _emptyLan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        children: [
          const Icon(Icons.wifi_tethering,
              size: 36, color: DashboardColors.brand),
          const SizedBox(height: 8),
          Text('Không tìm thấy Controller',
              style: bvText(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '• Controller chưa bật\n• Controller chưa kết nối Wi-Fi\n• Controller đang ở chế độ cấu hình AP\n• Controller đang ở mạng khác',
            textAlign: TextAlign.center,
            style: bvText(color: DashboardColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              MgmtOutlineButton(
                  onTap: _scan, icon: Icons.refresh, label: 'Quét lại'),
              MgmtPrimaryButton(
                label: 'Cấu hình Wi-Fi',
                icon: Icons.wifi,
                onTap: () => setState(() => _findTab = _FindTab.wifi),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(EspProvisionInfo d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.memory, color: DashboardColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(d.displayName,
                            style: bvText(fontWeight: FontWeight.w800))),
                    const MgmtStatusBadge(
                        label: 'Online', color: DashboardColors.brand),
                  ],
                ),
                Text(
                  [
                    if (d.board.isNotEmpty) d.board else 'ESP32',
                    if (d.firmware.isNotEmpty) 'v${d.firmware}',
                  ].join(' • '),
                  style:
                      bvText(color: DashboardColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (d.ip.isNotEmpty) _mini('IP', d.ip),
                    if (d.mac.isNotEmpty) _mini('MAC', d.mac),
                    if (d.hardwareId.isNotEmpty)
                      _mini('Device ID', d.hardwareId),
                    if (d.wifiSsid.isNotEmpty) _mini('Wi-Fi', d.wifiSsid),
                    if (d.rssi != null) _mini('RSSI', '${d.rssi!.round()} dBm'),
                    if (d.lastHeartbeatSeconds != null)
                      _mini(
                          'Heartbeat', '${d.lastHeartbeatSeconds} giây trước'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          MgmtPrimaryButton(label: 'Chọn thiết bị', onTap: () => _pick(d)),
        ],
      ),
    );
  }

  Widget _mini(String k, String v) {
    return Text.rich(TextSpan(children: [
      TextSpan(
          text: '$k: ',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
      TextSpan(
          text: v, style: bvText(fontSize: 12, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _wifiPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ⓘ Thiết bị sẽ tạo Wi-Fi tạm thời CrabSense-Setup để cấu hình mạng.',
            style: bvText(height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        _field(_ssid, 'SSID Wi-Fi *', suggestions: _ssids),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: _input('Mật khẩu Wi-Fi *').copyWith(
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _kioskUrl,
          keyboardType: TextInputType.url,
          decoration: _input('Kiosk URL (PC trong LAN)'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _advanced = !_advanced),
          child: Text(_advanced ? 'Ẩn tùy chọn nâng cao' : 'Tùy chọn nâng cao',
              style: bvText(
                  color: DashboardColors.brand, fontWeight: FontWeight.w700)),
        ),
        if (_advanced) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('DHCP', style: bvText(fontWeight: FontWeight.w700)),
            value: _dhcp,
            onChanged: (v) => setState(() => _dhcp = v),
          ),
          if (!_dhcp) ...[
            _field(_staticIp, 'Static IP'),
            _field(_subnet, 'Subnet mask'),
            _field(_gateway, 'Gateway'),
            _field(_dns, 'DNS'),
          ],
        ],
        const SizedBox(height: 8),
        Text(
          '1. Kết nối vào Wi-Fi tạm thời: CrabSense-Setup\n'
          '2. Nhập thông tin Wi-Fi của trại\n'
          '3. Gửi cấu hình tới ESP32\n'
          '4. Chờ ESP32 kết nối Wi-Fi\n'
          '5. Quay lại quét mạng LAN',
          style: bvText(color: DashboardColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        if (_wifiPhase != null)
          Text(_wifiPhase!,
              style: bvText(
                  fontWeight: FontWeight.w700, color: DashboardColors.brand)),
        if (_wifiError != null) _banner(_wifiError!, _kAmber),
        const SizedBox(height: 8),
        MgmtPrimaryButton(
          label: _wifiSending ? 'Đang gửi cấu hình...' : 'Gửi cấu hình Wi-Fi',
          onTap: _wifiSending ? null : _sendWifi,
        ),
        if (_wifiPhase != null && _wifiPhase!.startsWith('✓')) ...[
          const SizedBox(height: 8),
          MgmtOutlineButton(
            onTap: () {
              setState(() => _findTab = _FindTab.lan);
              _scan();
            },
            label: 'Quét Controller trong LAN →',
          ),
        ],
      ],
    );
  }

  Widget _manualBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: mgmtCardDeco(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'Chỉ dùng khi discovery không hoạt động. Device ID vẫn phải khớp firmware nếu kiểm tra được.',
              style: bvText(color: DashboardColors.textMuted)),
          _field(_manualId, 'Device ID *'),
          _field(_manualName, 'Tên Controller *'),
          const SizedBox(height: 8),
          MgmtOutlineButton(
            onTap: () {
              final id = _manualId.text.trim();
              if (id.isEmpty) return;
              _pick(EspProvisionInfo(
                deviceId: id,
                deviceCode: id,
                apName: _manualName.text.trim().isEmpty
                    ? id
                    : _manualName.text.trim(),
                controllerType: controllerTypeRealtime,
                firmware: '',
                mac: '',
              ));
            },
            label: 'Dùng Device ID này',
          ),
        ],
      ),
    );
  }

  Widget _configBody() {
    final sel = _selected;
    if (sel == null) return const SizedBox.shrink();
    final farms = widget.session.farms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Thiết bị đã chọn',
            style: bvText(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: DashboardColors.lightMint,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.memory, color: DashboardColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sel.displayName,
                        style: bvText(fontWeight: FontWeight.w800)),
                    Text(
                      '${sel.board.isEmpty ? 'ESP32' : sel.board} • ${sel.firmware.isEmpty ? '—' : 'v${sel.firmware}'}',
                      style: bvText(
                          color: DashboardColors.textMuted, fontSize: 12.5),
                    ),
                    Wrap(spacing: 12, children: [
                      if (sel.ip.isNotEmpty) _mini('IP', sel.ip),
                      if (sel.mac.isNotEmpty) _mini('MAC', sel.mac),
                      _mini('Device ID', sel.hardwareId),
                    ]),
                  ],
                ),
              ),
              MgmtOutlineButton(
                onTap: () => setState(() => _step = _Step.discover),
                label: 'Thay đổi',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Thông tin đăng ký',
            style: bvText(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        _field(_name, 'Tên Controller *'),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _input('Device ID'),
          child: Row(
            children: [
              Expanded(
                  child: Text(sel.hardwareId,
                      style: bvText(fontWeight: FontWeight.w700))),
              const Icon(Icons.lock_outline, size: 16, color: _kSlate),
            ],
          ),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _input('Loại Controller *'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _type,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: controllerTypeRealtime,
                    child: Text('Realtime Sensor Controller')),
                DropdownMenuItem(
                    value: controllerTypeRas, child: Text('RAS Controller')),
                DropdownMenuItem(
                    value: controllerTypeMixed,
                    child: Text('Sensor + Actuator Controller')),
                DropdownMenuItem(
                    value: controllerTypeCamera,
                    child: Text('Camera / AI Controller')),
                DropdownMenuItem(
                    value: controllerTypeOther, child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _input('Khu vực *'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: farms.any((f) => f.id == _area.id)
                  ? _area.id
                  : (farms.isEmpty ? null : farms.first.id),
              isExpanded: true,
              items: [
                for (final f in farms)
                  DropdownMenuItem(
                      value: f.id,
                      child: Text(
                          '${f.code.isEmpty ? f.name : f.code} — ${f.name}')),
              ],
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  _area =
                      farms.firstWhere((f) => f.id == id, orElse: () => _area);
                  _rowId = null;
                });
                widget.rowService?.setAreaFilter(id);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: _input('Dãy'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _rowId,
              isExpanded: true,
              hint: Text('Không gán dãy',
                  style: bvText(color: DashboardColors.textMuted)),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('Không gán dãy')),
                for (final r in _rows)
                  DropdownMenuItem(
                      value: r.rowId,
                      child: Text(r.rowName.isEmpty
                          ? r.rowCode
                          : '${r.rowCode} — ${r.rowName}')),
              ],
              onChanged: (v) => setState(() => _rowId = v),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _field(_location, 'Vị trí lắp đặt'),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          maxLength: 400,
          maxLines: 3,
          decoration: _input('Ghi chú').copyWith(
              hintText: 'Nhập mô tả vị trí hoặc mục đích Controller...'),
        ),
      ],
    );
  }

  Widget _verifyBody() {
    final sel = _selected;
    if (sel == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kiểm tra kết nối',
            style: bvText(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: mgmtCardDeco(radius: 14),
          child: Row(
            children: [
              Expanded(
                  child: Text(sel.displayName,
                      style: bvText(fontWeight: FontWeight.w800))),
              MgmtStatusBadge(
                label: _canRegister ? 'Sẵn sàng' : 'Đang kiểm tra',
                color: _canRegister ? DashboardColors.brand : _kAmber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _checkRow('Controller phản hồi', _chkBoard, _chkBoardDetail ?? ''),
        _checkRow('Kết nối Wi-Fi', _chkWifi, _chkWifiDetail ?? ''),
        _checkRow('Truy cập API', _chkApi, _chkApiDetail ?? ''),
        _checkRow(
            'Phiên bản firmware',
            _chkFw,
            sel.firmware.isEmpty
                ? 'Chưa đọc được firmware'
                : 'v${sel.firmware}'),
        _checkRow('Device ID hợp lệ', _chkId, sel.hardwareId),
        if (_chkBoard == _Check.fail) ...[
          const SizedBox(height: 8),
          MgmtOutlineButton(onTap: _runChecks, label: 'Thử lại'),
        ],
        if (_duplicate != null) ...[
          const SizedBox(height: 12),
          _duplicateBanner(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          _banner(_error!, _kRed),
        ],
        const SizedBox(height: 14),
        _card('Thông tin đăng ký', [
          _kv('Tên Controller', _name.text.trim()),
          _kv('Loại', controllerTypeLabel(_type)),
          _kv('Khu vực',
              '${_area.name}${_area.code.isEmpty ? '' : ' (${_area.code})'}'),
          _kv(
              'Dãy',
              _rowId == null
                  ? '—'
                  : (_rows
                          .where((r) => r.rowId == _rowId)
                          .map((r) => r.rowCode)
                          .firstOrNull ??
                      '—')),
          _kv('Vị trí',
              _location.text.trim().isEmpty ? '—' : _location.text.trim()),
        ]),
      ],
    );
  }

  Widget _successBody() {
    final sel = _selected!;
    final id = (_created?['id'] ?? _created?['Id'] ?? '').toString();
    final code =
        (_created?['deviceCode'] ?? _created?['DeviceCode'] ?? sel.deviceCode)
            .toString();
    final sensors = (_created?['sensorCount'] ??
        _created?['SensorCount'] ??
        sel.sensorCount ??
        0) as num;
    final outputs = (_created?['actuatorCount'] ??
        _created?['ActuatorCount'] ??
        sel.outputCount ??
        0) as num;
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 56, color: DashboardColors.brand),
        const SizedBox(height: 8),
        Text('Đã thêm Controller thành công!',
            style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(
          '${_name.text.trim()} đã được đăng ký vào hệ thống CrabSense.',
          textAlign: TextAlign.center,
          style: bvText(color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: mgmtCardDeco(radius: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(_name.text.trim(),
                          style: bvText(
                              fontWeight: FontWeight.w800, fontSize: 16))),
                  const MgmtStatusBadge(
                      label: 'Online', color: DashboardColors.brand),
                ],
              ),
              _kv('Controller ID', code.isEmpty ? id : code),
              _kv('Board', sel.board.isEmpty ? 'ESP32' : sel.board),
              if (sel.firmware.isNotEmpty) _kv('Firmware', 'v${sel.firmware}'),
              if (sel.ip.isNotEmpty) _kv('IP', sel.ip),
              if (sel.mac.isNotEmpty) _kv('MAC', sel.mac),
              _kv('Khu',
                  '${_area.name}${_area.code.isEmpty ? '' : ' (${_area.code})'}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _stat('${sensors.toInt()}', 'Sensor được phát hiện')),
            const SizedBox(width: 10),
            Expanded(
                child: _stat('${outputs.toInt()}', 'Output được phát hiện')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Bạn có thể cấu hình chi tiết Sensor và liên kết thiết bị đầu ra sau.',
          textAlign: TextAlign.center,
          style: bvText(color: DashboardColors.textMuted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            MgmtOutlineButton(onTap: () => _close(), label: 'Đóng'),
            MgmtOutlineButton(
              onTap: () => _close(
                  result: AddControllerWizardResult(
                      deviceId: id, openSensors: true)),
              label: 'Cấu hình Sensor',
            ),
            MgmtPrimaryButton(
              label: 'Xem Controller →',
              onTap: () =>
                  _close(result: AddControllerWizardResult(deviceId: id)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(String n, String l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        children: [
          Text(n,
              style: bvText(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.brand)),
          Text(l, style: bvText(color: DashboardColors.textMuted)),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          if (_step != _Step.discover)
            MgmtOutlineButton(
              onTap: _registering
                  ? null
                  : () => setState(() {
                        _step = _step == _Step.verify
                            ? _Step.config
                            : _Step.discover;
                      }),
              label: 'Quay lại',
            ),
          const Spacer(),
          if (_step == _Step.discover)
            MgmtPrimaryButton(
              label: 'Tiếp tục →',
              onTap: _selected == null
                  ? null
                  : () {
                      if (_duplicate != null) return;
                      setState(() => _step = _Step.config);
                    },
            ),
          if (_step == _Step.config)
            MgmtPrimaryButton(
              label: 'Tiếp tục →',
              onTap: _name.text.trim().isEmpty || _area.isUnassigned
                  ? null
                  : () {
                      setState(() => _step = _Step.verify);
                      _runChecks();
                    },
            ),
          if (_step == _Step.verify)
            MgmtPrimaryButton(
              label: _registering ? 'Đang đăng ký...' : 'Đăng ký Controller',
              onTap: _canRegister ? _register : null,
            ),
        ],
      ),
    );
  }

  Widget _duplicateBanner() {
    final d = _duplicate!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠ Controller này đã được đăng ký.',
              style: bvText(fontWeight: FontWeight.w800, color: _kAmber)),
          Text('${d.deviceName ?? d.deviceCode}  •  ${d.deviceCode}',
              style: bvText()),
          Text('Khu vực: ${d.areaName ?? d.areaCode ?? '—'}',
              style: bvText(color: DashboardColors.textMuted)),
          TextButton(
            onPressed: () =>
                _close(result: AddControllerWizardResult(deviceId: d.id)),
            child: Text('Xem Controller',
                style: bvText(
                    color: DashboardColors.brand, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String title, _Check state, String detail) {
    final icon = switch (state) {
      _Check.pending => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2)),
      _Check.ok =>
        const Icon(Icons.check_circle, size: 18, color: DashboardColors.brand),
      _Check.fail => const Icon(Icons.cancel, size: 18, color: _kRed),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: icon),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: bvText(fontWeight: FontWeight.w700)),
                Text(detail,
                    style: bvText(
                        fontSize: 12.5, color: DashboardColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: bvText(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(k, style: bvText(color: DashboardColors.textMuted))),
          Expanded(child: Text(v, style: bvText(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _banner(String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          Text(msg, style: bvText(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _skelCards() {
    return Column(
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(14)),
          ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {List<String> suggestions = const []}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: c, decoration: _input(label)),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: [
                for (final s in suggestions.take(8))
                  ActionChip(
                    label: Text(s, style: bvText(fontSize: 11)),
                    onPressed: () => setState(() => c.text = s),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        labelStyle: bvText(color: DashboardColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DashboardColors.cardBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DashboardColors.cardBorder)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: DashboardColors.brand, width: 1.4),
        ),
      );
}
