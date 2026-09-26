import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/auth_models.dart';
import '../../models/iot_device.dart';
import '../../models/row_list_item.dart';
import '../../services/controller_provisioning_service.dart';
import '../../services/controller_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';
import 'add_controller_dialog.dart';

const _kOverlay = Color.fromRGBO(15, 35, 30, 0.45);
const _kAmber = Color(0xFFF5B700);
const _kRed = Color(0xFFEF4444);
const _kSlate = Color(0xFF94A3B8);
const _kNoteMax = 500;
const _kUnlinkRow = '00000000-0000-0000-0000-000000000000';
const _kOnline = Duration(seconds: 30);
const _kDegraded = Duration(seconds: 90);

class _EscIntent extends Intent {
  const _EscIntent();
}

enum _Link { online, degraded, offline, disabled }

enum EditControllerOutcome { saved, disabled }

Future<EditControllerOutcome?> showEditControllerDialog(
  BuildContext context, {
  required ControllerService service,
  required IoTDevice device,
  RowManagementService? rowService,
}) {
  return showDialog<EditControllerOutcome>(
    context: context,
    barrierDismissible: false,
    barrierColor: _kOverlay,
    builder: (_) => EditControllerModal(
      service: service,
      device: device,
      rowService: rowService,
    ),
  );
}

String _normalizeType(String raw) {
  switch (controllerTypeFilterKey(raw)) {
    case 'water':
      return controllerTypeWaterAnalysis;
    case 'ras':
      return controllerTypeRas;
    case 'camera':
      return controllerTypeCamera;
    case 'mixed':
      return controllerTypeMixed;
    case 'realtime':
      return controllerTypeRealtime;
    default:
      return controllerTypeOther;
  }
}

bool _typeLockedByFirmware(String raw) {
  final t = raw.trim().toLowerCase();
  return t.contains('camera') || t.contains('ai');
}

String _areaLabelOf(FarmSummary f) {
  if (f.code.isEmpty || f.code == f.name) return f.name;
  return '${f.name} (${f.code})';
}

String _deviceAreaLabel(IoTDevice d) {
  final name = d.areaName ?? '';
  final code = d.areaCode ?? '';
  if (name.isEmpty && code.isEmpty) return '—';
  if (code.isEmpty) return name;
  if (name.isEmpty) return code;
  return '$name ($code)';
}

_Link _linkOf(IoTDevice d) {
  final s = d.status.toLowerCase();
  if (s == 'maintenance' || s == 'disabled') return _Link.disabled;
  final seen = d.lastSeenAt ?? d.lastTelemetryAt;
  final age = seen == null ? null : DateTime.now().difference(seen.toLocal());
  if (s == 'offline' || s == 'error' || !d.isOnline) {
    if (age != null && age <= _kOnline) return _Link.online;
    return _Link.offline;
  }
  if (age != null) {
    if (age > _kDegraded) return _Link.offline;
    if (age > _kOnline) return _Link.degraded;
  }
  return _Link.online;
}

({String label, Color color}) _linkStyle(_Link link) {
  return switch (link) {
    _Link.online => (label: 'Online', color: DashboardColors.brand),
    _Link.degraded => (label: 'Kết nối không ổn định', color: _kAmber),
    _Link.offline => (label: 'Mất kết nối', color: _kRed),
    _Link.disabled => (label: 'Đã vô hiệu hóa', color: _kSlate),
  };
}

String _rel(DateTime? at) {
  if (at == null) return 'Chưa từng';
  final d = DateTime.now().difference(at.toLocal());
  if (d.inSeconds < 15) return 'vừa xong';
  if (d.inMinutes < 1) return '${d.inSeconds} giây trước';
  if (d.inHours < 1) return '${d.inMinutes} phút trước';
  if (d.inDays < 2) return '${d.inHours} giờ ${d.inMinutes % 60} phút trước';
  return '${d.inDays} ngày trước';
}

String _rssiLabel(double? rssi, bool online) {
  if (!online || rssi == null) return '—';
  final n = rssi.round();
  final quality = n >= -60
      ? 'Tốt'
      : n >= -75
          ? 'Trung bình'
          : 'Yếu';
  return '$n dBm · $quality';
}

String _uptime(EspProvisionInfo? live) {
  final sec = live?.lastHeartbeatSeconds;
  if (sec == null || sec <= 0) return '—';
  final d0 = Duration(seconds: sec);
  if (d0.inDays >= 1) return '${d0.inDays} ngày ${d0.inHours % 24} giờ';
  if (d0.inHours >= 1) return '${d0.inHours} giờ ${d0.inMinutes % 60} phút';
  return '${d0.inMinutes} phút';
}

String _boardOf(EspProvisionInfo? live, IoTDevice d) {
  final board = live?.board.trim() ?? '';
  if (board.isNotEmpty) return board;
  final t = (d.deviceType ?? '').toLowerCase();
  if (t.contains('s3')) return 'ESP32-S3';
  if (t.contains('camera')) return 'ESP32-CAM';
  return 'ESP32';
}

class EditControllerModal extends StatefulWidget {
  const EditControllerModal({
    super.key,
    required this.service,
    required this.device,
    this.rowService,
  });

  final ControllerService service;
  final IoTDevice device;
  final RowManagementService? rowService;

  @override
  State<EditControllerModal> createState() => _EditControllerModalState();
}

class _EditControllerModalState extends State<EditControllerModal> {
  late IoTDevice _device;
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _note;
  late String _type;
  late String _areaId;
  String? _rowId;
  late final String _initialAreaId;

  EspProvisionInfo? _live;
  var _booting = true;
  var _saving = false;
  var _refreshingHw = false;
  var _conflict = false;
  String? _error;
  String? _nameError;

  ControllerService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _name = TextEditingController(text: widget.device.deviceName ?? widget.device.deviceCode);
    _location = TextEditingController(text: widget.device.installationLocation ?? '');
    _note = TextEditingController(text: widget.device.note ?? '');
    _type = _normalizeType(widget.device.deviceType ?? controllerTypeRealtime);
    _areaId = (widget.device.areaId ?? widget.device.farmId).trim();
    final rawRow = (widget.device.rowId ?? '').trim();
    _rowId = rawRow.isEmpty || rawRow == _kUnlinkRow ? null : rawRow;
    _initialAreaId = _areaId;
    _name.addListener(() => setState(() {}));
    _note.addListener(() => setState(() {}));
    _svc.addListener(_onSvc);
    widget.rowService?.addListener(_onRows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _svc.removeListener(_onSvc);
    widget.rowService?.removeListener(_onRows);
    _name.dispose();
    _location.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSvc() {
    final latest = _svc.items.cast<IoTDevice?>().firstWhere(
          (e) => e?.id == _device.id,
          orElse: () => null,
        ) ??
        (_svc.detail?.controller.id == _device.id ? _svc.detail!.controller : null);
    if (latest == null || !mounted) return;
    setState(() => _device = latest);
  }

  void _onRows() {
    if (mounted) setState(() {});
  }

  Future<void> _boot() async {
    setState(() => _booting = true);
    if (_svc.selectedId != _device.id) {
      await _svc.select(_device.id, force: true);
    } else if (_svc.detail == null) {
      await _svc.select(_device.id, force: true);
    }
    if (_areaId.isNotEmpty) widget.rowService?.setAreaFilter(_areaId);
    widget.rowService?.load();
    final live = await _svc.refreshHardware(_device);
    if (!mounted) return;
    setState(() {
      _live = live;
      _booting = false;
      if (_svc.detail?.controller.id == _device.id) {
        _device = _svc.detail!.controller;
      }
      _location.text = _device.installationLocation ?? '';
      _note.text = _device.note ?? '';
    });
  }

  Future<void> _refreshHw() async {
    setState(() => _refreshingHw = true);
    final live = await _svc.refreshHardware(_device);
    if (!mounted) return;
    setState(() {
      _live = live;
      _refreshingHw = false;
      if (_svc.detail?.controller.id == _device.id) {
        _device = _svc.detail!.controller;
      }
    });
  }

  List<FarmSummary> get _areas {
    final seen = <String>{};
    final out = <FarmSummary>[];
    void add(FarmSummary f) {
      if (f.id.isEmpty || seen.contains(f.id)) return;
      seen.add(f.id);
      out.add(f);
    }

    for (final f in _svc.session.farms) {
      add(f);
    }
    for (final a in widget.rowService?.areas ?? const []) {
      add(FarmSummary(id: a.id, code: a.areaCode, name: a.areaName));
    }
    if (_areaId.isNotEmpty && !seen.contains(_areaId)) {
      add(FarmSummary(
        id: _areaId,
        code: _device.areaCode ?? '',
        name: _device.areaName ?? _device.areaCode ?? 'Khu hiện tại',
      ));
    }
    return out;
  }

  List<RowListItem> get _rows {
    final rows = widget.rowService?.items ?? const <RowListItem>[];
    return rows.where((r) => r.areaId == _areaId || r.areaId.isEmpty).toList();
  }

  _Link get _link => _linkOf(_device);
  bool get _online => _link == _Link.online || _link == _Link.degraded;
  bool get _typeLocked => _typeLockedByFirmware(_device.deviceType ?? '');

  String? _validateName() {
    final v = _name.text.trim();
    if (v.isEmpty) return 'Tên Controller là bắt buộc.';
    if (v.length < 2) return 'Tên Controller tối thiểu 2 ký tự.';
    if (v.length > 80) return 'Tên Controller tối đa 80 ký tự.';
    return null;
  }

  bool get _canSave =>
      !_saving &&
      _validateName() == null &&
      _areaId.isNotEmpty &&
      _type.trim().isNotEmpty;

  Future<void> _copy(String value, String label) async {
    if (value.isEmpty || value == '—') return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label')),
    );
  }

  Future<bool> _confirmAreaChange() async {
    final oldArea = _areas.cast<FarmSummary?>().firstWhere(
          (f) => f?.id == _initialAreaId,
          orElse: () => null,
        );
    final newArea = _areas.cast<FarmSummary?>().firstWhere(
          (f) => f?.id == _areaId,
          orElse: () => null,
        );
    final sensors = _svc.detail?.sensors.length ?? _device.sensorCount;
    final outputs = _svc.detail?.actuators.length ?? _device.actuatorCount;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: _kOverlay,
      builder: (ctx) => _ConfirmDialog(
        title: 'Chuyển Controller sang khu vực khác?',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _kvLine('Khu hiện tại', oldArea == null ? _deviceAreaLabel(_device) : _areaLabelOf(oldArea)),
            _kvLine('Khu mới', newArea == null ? _areaId : _areaLabelOf(newArea)),
            const SizedBox(height: 8),
            Text(
              'Controller đang có: $sensors sensors · $outputs outputs',
              style: bvText(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Các liên kết sensor/output có thể bị ảnh hưởng bởi phạm vi khu vực.',
              style: bvText(color: DashboardColors.textMuted, height: 1.45),
            ),
          ],
        ),
        cancel: 'Hủy',
        confirm: 'Xác nhận chuyển',
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    final nameErr = _validateName();
    if (nameErr != null) {
      setState(() => _nameError = nameErr);
      return;
    }
    if (_areaId.isEmpty) {
      setState(() => _error = '⚠ Khu vực là bắt buộc.');
      return;
    }
    if (_areaId != _initialAreaId) {
      final go = await _confirmAreaChange();
      if (!go || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _conflict = false;
      _nameError = null;
    });
    final result = await _svc.updateMeta(
      id: _device.id,
      name: _name.text.trim(),
      deviceType: _typeLocked ? null : _type,
      farmingAreaId: _areaId,
      farmingRowId: _rowId ?? _kUnlinkRow,
      installationLocation: _location.text.trim(),
      note: _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case ControllerMetaSaveResult.ok:
        Navigator.pop(context, EditControllerOutcome.saved);
      case ControllerMetaSaveResult.conflict:
        setState(() {
          _conflict = true;
          _error = '⚠ Controller vừa được cập nhật ở phiên khác.';
        });
      case ControllerMetaSaveResult.failed:
        setState(() {
          _error = '⚠ Không thể cập nhật Controller.\n${_svc.detailError ?? ''}'.trim();
        });
    }
  }

  Future<void> _disable() async {
    final outcome = await showDisableControllerDialog(
      context,
      service: _svc,
      device: _device,
      sensorCount: _svc.detail?.sensors.length ?? _device.sensorCount,
      outputCount: _svc.detail?.actuators.length ?? _device.actuatorCount,
    );
    if (outcome == true && mounted) {
      Navigator.pop(context, EditControllerOutcome.disabled);
    }
  }

  Future<void> _openNetwork() async {
    await showControllerNetworkDialog(
      context,
      service: _svc,
      device: _device,
      live: _live,
      online: _online,
    );
    if (mounted) await _refreshHw();
  }

  Future<void> _openFirmware() async {
    await showControllerFirmwareDialog(
      context,
      device: _device,
      live: _live,
      online: _online,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 860;
    final width = size.width < 1100 ? size.width - 24 : 1000.0;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 20,
        vertical: compact ? 8 : 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.light,
          canvasColor: Colors.white,
          colorScheme: ColorScheme.light(
            primary: DashboardColors.brand,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: DashboardColors.textPrimary,
          ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: DashboardColors.textPrimary,
                displayColor: DashboardColors.textPrimary,
              ),
        ),
        child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width.clamp(320, 1050),
          maxHeight: size.height * 0.90,
        ),
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.escape): _EscIntent(),
          },
          child: Actions(
            actions: {
              _EscIntent: CallbackAction<_EscIntent>(onInvoke: (_) {
                if (!_saving) Navigator.pop(context);
                return null;
              }),
            },
            child: Focus(
              autofocus: true,
              child: Column(
                children: [
                  _header(),
                  const Divider(height: 1, color: DashboardColors.mint),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 22,
                        16,
                        compact ? 14 : 22,
                        18,
                      ),
                      child: _booting ? _skeleton(compact) : _body(compact),
                    ),
                  ),
                  const Divider(height: 1, color: DashboardColors.mint),
                  _footer(compact),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỉnh sửa Controller',
                  style: bvText(fontSize: 18, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cập nhật thông tin quản lý, khu vực và vị trí của Controller.',
                  style: bvText(color: DashboardColors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _body(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          _banner(_error!, _conflict ? _kAmber : _kRed, action: _conflict
              ? TextButton(
                  onPressed: _boot,
                  child: Text(
                    'Tải dữ liệu mới',
                    style: bvText(fontWeight: FontWeight.w800, color: DashboardColors.brand),
                  ),
                )
              : null),
          const SizedBox(height: 12),
        ],
        _summary(),
        const SizedBox(height: 16),
        if (compact) ...[
          _managementCard(),
          const SizedBox(height: 14),
          _deviceCard(),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 52, child: _managementCard()),
              const SizedBox(width: 14),
              Expanded(flex: 48, child: _deviceCard()),
            ],
          ),
      ],
    );
  }

  Widget _skeleton(bool compact) {
    Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(14),
          ),
        );
    return Column(
      children: [
        box(88),
        const SizedBox(height: 14),
        if (compact) ...[
          box(280),
          const SizedBox(height: 14),
          box(280),
        ] else
          Row(
            children: [
              Expanded(child: box(320)),
              const SizedBox(width: 14),
              Expanded(child: box(320)),
            ],
          ),
      ],
    );
  }

  Widget _summary() {
    final link = _linkStyle(_link);
    final title = _name.text.trim().isEmpty
        ? (_device.deviceName ?? _device.deviceCode)
        : _name.text.trim();
    final sensors = _svc.detail?.sensors.length ?? _device.sensorCount;
    final outputs = _svc.detail?.actuators.length ?? _device.actuatorCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DashboardColors.lightMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.memory_rounded, color: DashboardColors.brand, size: 28),
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
                    Text(title, style: bvText(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
                    MgmtStatusBadge(label: link.label, color: link.color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  controllerTypeLabel(_type),
                  style: bvText(color: DashboardColors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _metaChip(Icons.place_outlined, _deviceAreaLabel(_device)),
                    _metaChip(Icons.sensors, '$sensors sensors'),
                    _metaChip(Icons.tune, '$outputs outputs'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DashboardColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
      ],
    );
  }

  Widget _managementCard() {
    final farms = _areas;
    final areaValue = farms.any((f) => f.id == _areaId) ? _areaId : null;
    final rows = _rows;
    final rowValue = _rowId != null && rows.any((r) => r.rowId == _rowId) ? _rowId : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thông tin quản lý', style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 80,
            enabled: !_saving,
            style: _ink,
            decoration: _input('Tên Controller *').copyWith(
              counterText: '',
              errorText: _nameError,
            ),
            onChanged: (_) => setState(() => _nameError = _validateName()),
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: _input('Loại Controller *'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                style: _ink,
                dropdownColor: Colors.white,
                iconEnabledColor: DashboardColors.textPrimary,
                items: [
                  DropdownMenuItem(value: controllerTypeRealtime, child: _item('Realtime Sensor Controller')),
                  DropdownMenuItem(value: controllerTypeRas, child: _item('RAS Controller')),
                  DropdownMenuItem(value: controllerTypeMixed, child: _item('Sensor + Actuator Controller')),
                  DropdownMenuItem(value: controllerTypeCamera, child: _item('Camera / AI Controller')),
                  DropdownMenuItem(value: controllerTypeOther, child: _item('Khác')),
                  if (_type == controllerTypeWaterAnalysis)
                    DropdownMenuItem(
                      value: controllerTypeWaterAnalysis,
                      child: _item('Water Analysis (NO₂ Analyzer)'),
                    ),
                ],
                onChanged: _typeLocked || _saving
                    ? null
                    : (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ),
          if (_typeLocked) ...[
            const SizedBox(height: 4),
            Text(
              'Loại được firmware cố định — chỉ đọc.',
              style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          InputDecorator(
            decoration: _input('Khu vực *'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: areaValue,
                isExpanded: true,
                hint: Text('Chọn khu vực', style: bvText(color: DashboardColors.textMuted)),
                style: _ink,
                dropdownColor: Colors.white,
                iconEnabledColor: DashboardColors.textPrimary,
                items: [
                  for (final f in farms)
                    DropdownMenuItem(value: f.id, child: _item(_areaLabelOf(f))),
                ],
                onChanged: _saving
                    ? null
                    : (id) {
                        if (id == null) return;
                        setState(() {
                          _areaId = id;
                          if (_rowId != null && !_rows.any((r) => r.rowId == _rowId && r.areaId == id)) {
                            _rowId = null;
                          }
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
                value: rowValue,
                isExpanded: true,
                hint: Text('Không gán dãy', style: bvText(color: DashboardColors.textMuted)),
                style: _ink,
                dropdownColor: Colors.white,
                iconEnabledColor: DashboardColors.textPrimary,
                items: [
                  DropdownMenuItem<String>(value: null, child: _item('Không gán dãy')),
                  for (final r in rows)
                    DropdownMenuItem(
                      value: r.rowId,
                      child: _item(r.rowName.isEmpty ? r.rowCode : '${r.rowCode} — ${r.rowName}'),
                    ),
                ],
                onChanged: _saving ? null : (v) => setState(() => _rowId = v),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _location,
            enabled: !_saving,
            maxLength: 200,
            style: _ink,
            decoration: _input('Vị trí lắp đặt').copyWith(
              counterText: '',
              hintText: _areaId.isEmpty
                  ? 'Tủ điều khiển khu…'
                  : 'Tủ điều khiển khu ${_areas.cast<FarmSummary?>().firstWhere((f) => f?.id == _areaId, orElse: () => null)?.code ?? _device.areaCode ?? ''}',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            enabled: !_saving,
            maxLength: _kNoteMax,
            maxLines: 4,
            style: _ink.copyWith(height: 1.45),
            decoration: _input('Ghi chú').copyWith(
              hintText: 'Controller đo pH, TDS và nhiệt độ.\nĐặt tại tủ điều khiển khu ${_device.areaCode ?? ''}.',
              counterText: '${_note.text.length} / $_kNoteMax',
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard() {
    final d = _device;
    final fw = (_live?.firmware.isNotEmpty == true ? _live!.firmware : d.firmwareVersion ?? '').trim();
    final fwLabel = fw.isEmpty ? '—' : (fw.toLowerCase().startsWith('v') ? fw : 'v$fw');
    final mac = (d.macAddress ?? _live?.mac ?? '').trim();
    final ip = (d.ipLan ?? _live?.staIp ?? '').trim();
    final wifi = (_live?.wifiSsid ?? '').trim();
    final rssi = _live?.rssi ?? d.rssiDbm;
    final seen = d.lastSeenAt ?? d.lastTelemetryAt;
    final deviceId = d.deviceCode.isEmpty ? (d.id) : d.deviceCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Thông tin thiết bị', style: bvText(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardColors.lightMint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Text('🔒 Chỉ đọc', style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: DashboardColors.textMuted)),
              ),
              IconButton(
                tooltip: 'Làm mới thông tin thiết bị',
                onPressed: _refreshingHw ? null : _refreshHw,
                icon: _refreshingHw
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ro('Device ID', deviceId, onCopy: () => _copy(deviceId, 'Device ID')),
          _ro('Board', _boardOf(_live, d)),
          _ro(
            'Firmware',
            fwLabel,
            trailing: Tooltip(
              message: _online
                  ? 'Firmware không sửa bằng cách nhập version. Cập nhật qua luồng OTA riêng.'
                  : 'Controller cần online để cập nhật firmware từ xa.',
              child: TextButton(
                onPressed: _openFirmware,
                child: Text(
                  'Cập nhật FW',
                  style: bvText(
                    fontWeight: FontWeight.w800,
                    color: _online ? DashboardColors.brand : _kSlate,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ),
          _ro('MAC', mac.isEmpty ? '—' : mac, onCopy: mac.isEmpty ? null : () => _copy(mac, 'MAC')),
          _ro('IP', ip.isEmpty ? '—' : ip),
          _ro('Wi-Fi', wifi.isEmpty ? '—' : wifi, leading: Icons.wifi_rounded),
          _ro('RSSI', _rssiLabel(rssi, _online)),
          _ro(
            'Heartbeat cuối',
            seen == null ? '—' : '${fmtDateTimeVn(seen)}\n(${_rel(seen)})',
          ),
          _ro('Thời gian hoạt động', _online ? _uptime(_live) : '—'),
          const SizedBox(height: 10),
          _healthBanner(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: _online
                  ? 'Mở cấu hình mạng — gửi lệnh tới thiết bị, không sửa IP/Wi-Fi trong database.'
                  : 'Controller cần online để cấu hình mạng từ xa.',
              child: MgmtOutlineButton(
                icon: Icons.settings_outlined,
                label: 'Cấu hình mạng',
                onTap: _online ? _openNetwork : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthBanner() {
    if (_link == _Link.disabled) {
      return _banner('○ Controller đã vô hiệu hóa. Có thể sửa thông tin quản lý.', _kSlate);
    }
    if (_online && _link != _Link.degraded) {
      return _banner('✓ Controller đang hoạt động bình thường.', DashboardColors.brand);
    }
    if (_link == _Link.degraded) {
      return _banner('⚠ Kết nối không ổn định — heartbeat chậm.', _kAmber);
    }
    return _banner(
      '⚠ Controller đang mất kết nối.\nKhông thể gửi cấu hình mạng hoặc cập nhật firmware từ xa.',
      _kAmber,
    );
  }

  Widget _footer(bool compact) {
    final disableBtn = MgmtOutlineButton(
      icon: Icons.block_outlined,
      label: 'Vô hiệu hóa Controller',
      color: _kRed,
      onTap: _saving ? null : _disable,
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MgmtOutlineButton(
          label: 'Hủy',
          onTap: _saving ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        MgmtPrimaryButton(
          icon: Icons.save_outlined,
          label: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
          onTap: _canSave ? _save : null,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                disableBtn,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            )
          : Row(
              children: [
                disableBtn,
                const Spacer(),
                actions,
              ],
            ),
    );
  }

  Widget _ro(
    String label,
    String value, {
    VoidCallback? onCopy,
    Widget? trailing,
    IconData? leading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: bvText(color: DashboardColors.textMuted, fontSize: 12.5)),
          ),
          if (leading != null) ...[
            Icon(leading, size: 15, color: DashboardColors.brand),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: bvText(fontWeight: FontWeight.w700, height: 1.35, color: DashboardColors.textPrimary),
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Sao chép $label',
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 16),
            ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _banner(String msg, Color color, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(msg, style: bvText(color: color, fontWeight: FontWeight.w600, height: 1.4)),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  TextStyle get _ink => bvText(
        fontWeight: FontWeight.w600,
        color: DashboardColors.textPrimary,
      );

  Widget _item(String label) => Text(
        label,
        style: bvText(
          fontWeight: FontWeight.w600,
          color: DashboardColors.textPrimary,
        ),
      );

  InputDecoration _input(String label) => InputDecoration(
        labelText: label,
        labelStyle: bvText(color: DashboardColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardColors.brand, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      );
}

Widget _kvLine(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text(k, style: bvText(color: DashboardColors.textMuted))),
        Expanded(child: Text(v, style: bvText(fontWeight: FontWeight.w800))),
      ],
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.cancel,
    required this.confirm,
  });

  final String title;
  final Widget body;
  final String cancel;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              body,
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MgmtOutlineButton(label: cancel, onTap: () => Navigator.pop(context, false)),
                  const SizedBox(width: 8),
                  MgmtPrimaryButton(
                    label: confirm,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showDisableControllerDialog(
  BuildContext context, {
  required ControllerService service,
  required IoTDevice device,
  int sensorCount = 0,
  int outputCount = 0,
}) {
  final reason = TextEditingController();
  return showDialog<bool>(
    context: context,
    barrierColor: _kOverlay,
    builder: (ctx) {
      var busy = false;
      String? err;
      return StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vô hiệu hóa ${device.deviceName ?? device.deviceCode}?',
                    style: bvText(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Controller sẽ không còn được sử dụng trong các luồng vận hành mới. Dữ liệu lịch sử vẫn được giữ lại.',
                    style: bvText(color: DashboardColors.textMuted, height: 1.45),
                  ),
                  if (sensorCount > 0 || outputCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Không xóa vật lý — đang có $sensorCount sensors / $outputCount outputs.',
                      style: bvText(fontWeight: FontWeight.w700, color: _kAmber),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: reason,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Lý do vô hiệu hóa',
                      labelStyle: bvText(color: DashboardColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!, style: bvText(color: _kRed, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MgmtOutlineButton(
                        label: 'Hủy',
                        onTap: busy ? null : () => Navigator.pop(ctx, false),
                      ),
                      const SizedBox(width: 8),
                      MgmtOutlineButton(
                        label: busy ? 'Đang xử lý...' : 'Vô hiệu hóa',
                        color: _kRed,
                        onTap: busy
                            ? null
                            : () async {
                                setLocal(() => busy = true);
                                final ok = await service.deactivate(device.id);
                                if (!ctx.mounted) return;
                                if (ok) {
                                  Navigator.pop(ctx, true);
                                } else {
                                  setLocal(() {
                                    busy = false;
                                    err = service.detailError ?? 'Không vô hiệu hóa được.';
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ).whenComplete(reason.dispose);
}

Future<void> showControllerNetworkDialog(
  BuildContext context, {
  required ControllerService service,
  required IoTDevice device,
  EspProvisionInfo? live,
  required bool online,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: _kOverlay,
    builder: (_) => _NetworkDialog(
      service: service,
      device: device,
      live: live,
      online: online,
    ),
  );
}

class _NetworkDialog extends StatefulWidget {
  const _NetworkDialog({
    required this.service,
    required this.device,
    required this.live,
    required this.online,
  });

  final ControllerService service;
  final IoTDevice device;
  final EspProvisionInfo? live;
  final bool online;

  @override
  State<_NetworkDialog> createState() => _NetworkDialogState();
}

class _NetworkDialogState extends State<_NetworkDialog> {
  var _mode = _NetMode.overview;
  var _dhcp = true;
  var _obscure = true;
  var _sending = false;
  String? _error;
  String? _phase;
  late final TextEditingController _ssid;
  late final TextEditingController _password;
  late final TextEditingController _ip;
  late final TextEditingController _subnet;
  late final TextEditingController _gateway;
  late final TextEditingController _dns;

  @override
  void initState() {
    super.initState();
    _ssid = TextEditingController();
    _password = TextEditingController();
    _ip = TextEditingController();
    _subnet = TextEditingController(text: '255.255.255.0');
    _gateway = TextEditingController();
    _dns = TextEditingController();
  }

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    _ip.dispose();
    _subnet.dispose();
    _gateway.dispose();
    _dns.dispose();
    super.dispose();
  }

  Future<void> _sendWifi() async {
    if (_ssid.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = '⚠ Nhập SSID và mật khẩu Wi-Fi mới.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _phase = 'Đang gửi cấu hình tới Controller...';
    });
    final ok = await widget.service.sendWifi(
      device: widget.device,
      ssid: _ssid.text,
      password: _password.text,
      liveIp: widget.live?.staIp ?? widget.live?.ip,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _phase =
            '✓ Đã gửi cấu hình. Controller đang khởi động lại.\nMáy tính phải cùng Wi-Fi mới. Nếu mất máy, nối hotspot CrabSense-XXXX.';
        _password.clear();
      } else {
        _error = '⚠ ${widget.service.detailError ?? 'Không gửi được cấu hình Wi-Fi.'}';
        _phase = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wifi = (widget.live?.wifiSsid ?? '').trim();
    final ip = (widget.device.ipLan ?? widget.live?.staIp ?? '').trim();
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Cấu hình mạng Controller', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!widget.online)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '⚠ Controller đang offline — không gửi được lệnh mạng.',
                    style: bvText(color: _kAmber, fontWeight: FontWeight.w600),
                  ),
                ),
              _kvLine('Wi-Fi hiện tại', wifi.isEmpty ? '—' : wifi),
              _kvLine('IP', ip.isEmpty ? '—' : ip),
              _kvLine('Mode', 'DHCP'),
              const SizedBox(height: 12),
              if (_mode == _NetMode.overview) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MgmtPrimaryButton(
                      label: 'Đổi Wi-Fi',
                      onTap: widget.online ? () => setState(() => _mode = _NetMode.wifi) : null,
                    ),
                    MgmtOutlineButton(
                      label: 'Cấu hình IP tĩnh',
                      onTap: widget.online ? () => setState(() => _mode = _NetMode.ip) : null,
                    ),
                  ],
                ),
              ] else if (_mode == _NetMode.wifi) ...[
                TextField(
                  controller: _ssid,
                  enabled: !_sending,
                  decoration: _netInput('SSID *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  enabled: !_sending,
                  obscureText: _obscure,
                  decoration: _netInput('Password mới *').copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Không điền sẵn mật khẩu cũ. Mật khẩu không gửi lên CrabSenseBE.',
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
                if (_phase != null) ...[
                  const SizedBox(height: 8),
                  Text(_phase!, style: bvText(fontWeight: FontWeight.w700, color: DashboardColors.brand)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: bvText(color: _kAmber, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    MgmtOutlineButton(
                      label: 'Quay lại',
                      onTap: _sending ? null : () => setState(() => _mode = _NetMode.overview),
                    ),
                    const Spacer(),
                    MgmtPrimaryButton(
                      label: _sending ? 'Đang gửi...' : 'Gửi tới Controller',
                      onTap: _sending || !widget.online ? null : _sendWifi,
                    ),
                  ],
                ),
              ] else ...[
                RadioGroup<bool>(
                  groupValue: _dhcp,
                  onChanged: (v) => setState(() => _dhcp = v ?? true),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        value: true,
                        title: Text('DHCP', style: bvText(fontWeight: FontWeight.w700)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        value: false,
                        title: Text('Static IP', style: bvText(fontWeight: FontWeight.w700)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                if (!_dhcp) ...[
                  TextField(controller: _ip, decoration: _netInput('IP')),
                  const SizedBox(height: 8),
                  TextField(controller: _subnet, decoration: _netInput('Subnet')),
                  const SizedBox(height: 8),
                  TextField(controller: _gateway, decoration: _netInput('Gateway')),
                  const SizedBox(height: 8),
                  TextField(controller: _dns, decoration: _netInput('DNS')),
                ],
                const SizedBox(height: 8),
                Text(
                  'Firmware hiện tại chưa có API IP tĩnh. CrabSense không ghi IP vào database thay cho thiết bị.',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: MgmtOutlineButton(
                    label: 'Quay lại',
                    onTap: () => setState(() => _mode = _NetMode.overview),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _netInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: bvText(color: DashboardColors.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}

enum _NetMode { overview, wifi, ip }

Future<void> showControllerFirmwareDialog(
  BuildContext context, {
  required IoTDevice device,
  EspProvisionInfo? live,
  required bool online,
}) {
  final fw = (live?.firmware.isNotEmpty == true ? live!.firmware : device.firmwareVersion ?? '').trim();
  final current = fw.isEmpty ? '—' : (fw.toLowerCase().startsWith('v') ? fw : 'v$fw');
  return showDialog<void>(
    context: context,
    barrierColor: _kOverlay,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cập nhật Firmware', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _kvLine('Current', current),
              _kvLine('Available', 'Chưa có bản mới từ backend'),
              const SizedBox(height: 8),
              Text(
                'Không sửa firmware bằng cách đổi text version. OTA phải đi qua kênh riêng và chờ device ACK.',
                style: bvText(color: DashboardColors.textMuted, height: 1.45),
              ),
              if (!online) ...[
                const SizedBox(height: 8),
                Text(
                  'Controller cần online để cập nhật firmware từ xa.',
                  style: bvText(color: _kAmber, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MgmtOutlineButton(label: 'Đóng', onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: online
                        ? 'Backend chưa hỗ trợ OTA firmware.'
                        : 'Controller cần online để cập nhật firmware từ xa.',
                    child: const MgmtPrimaryButton(label: 'Cập nhật Firmware', onTap: null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
