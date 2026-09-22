import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_env.dart';
import '../../models/auth_models.dart';
import '../../services/controller_provisioning_service.dart';
import '../../services/controller_service.dart';
import '../../services/wifi_ssid_scanner.dart';
import '../../theme/dashboard_theme.dart';

const controllerTypeRealtime = 'realtime_sensor';
const controllerTypeWaterAnalysis = 'water_analysis';

String controllerTypeLabel(String type) {
  switch (type) {
    case controllerTypeWaterAnalysis:
      return 'Water Analysis (NO₂ Analyzer)';
    case controllerTypeRealtime:
    default:
      return 'Realtime Sensor Controller';
  }
}

Future<bool> showAddControllerDialog(
  BuildContext context, {
  required ControllerService service,
  required AuthSession session,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AddControllerDialog(
      service: service,
      session: session,
    ),
  );
  return ok == true;
}

class _AddControllerDialog extends StatefulWidget {
  const _AddControllerDialog({
    required this.service,
    required this.session,
  });

  final ControllerService service;
  final AuthSession session;

  @override
  State<_AddControllerDialog> createState() => _AddControllerDialogState();
}

class _AddControllerDialogState extends State<_AddControllerDialog> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  final _deviceCode = TextEditingController(text: 'CrabSense-C114');
  final _provisioning = ControllerProvisioningService();

  EspProvisionInfo? _esp;
  String _type = controllerTypeRealtime;
  late FarmSummary _area;
  List<String> _ssids = const [];
  bool _busy = false;
  bool _obscure = true;
  bool _wifiSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _area = widget.session.selectedFarm;
    _loadSsids();
  }

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    _deviceCode.dispose();
    super.dispose();
  }

  Future<void> _loadSsids() async {
    final names = await WifiSsidScanner.scan();
    if (!mounted) return;
    setState(() => _ssids = names);
  }

  Future<void> _discover() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await _provisioning.discoverNearby();
      if (!mounted) return;
      setState(() {
        _esp = info;
        if (info.controllerType.isNotEmpty) {
          _type = info.controllerType;
        }
        if (info.deviceCode.isNotEmpty) {
          _deviceCode.text = info.deviceCode;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Không thấy ESP32. PC cùng Wi-Fi trại thì bấm Tìm lại (ESP đang ở 192.168.110.240). '
            'Hoặc điền mã CrabSense-C114 rồi Đăng ký lên CrabMonitor.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendWifiToEsp() async {
    final esp = _esp;
    if (esp == null) {
      setState(() => _error = 'Hãy tìm Controller trước.');
      return;
    }
    if (_ssid.text.trim().isEmpty) {
      setState(() => _error = 'Nhập Wi-Fi của trại.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _provisioning.provision(
        ssid: _ssid.text,
        password: _password.text,
        backendUrl: await ControllerProvisioningService.backendUrlForEsp(
          AppEnv.cloudApiUrl,
        ),
        baseUrl: esp.baseUrl,
      );
      if (!mounted) return;
      setState(() => _wifiSent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerOnBackend() async {
    final code = _deviceCode.text.trim().isNotEmpty
        ? _deviceCode.text.trim()
        : (_esp?.deviceCode.isNotEmpty == true
            ? _esp!.deviceCode
            : (_esp?.apName ?? ''));
    if (code.isEmpty) {
      setState(() => _error = 'Nhập mã controller (ví dụ CrabSense-C114).');
      return;
    }
    if (_area.isUnassigned) {
      setState(() => _error = 'Chọn khu vực trước.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final saved = await widget.service.add(
        deviceCode: code,
        name: _esp?.displayName ?? code,
        deviceType: _type,
        macAddress: _esp?.mac,
        firmwareVersion: _esp?.firmware.isEmpty == false
            ? _esp!.firmware
            : '1.0.0',
        farmingAreaId: _area.id,
        registerRealtimeSensors: _type == controllerTypeRealtime,
      );

      if (!mounted) return;
      if (saved) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _error = widget.service.error ??
            'Chưa đăng ký được backend. Hãy chắc PC đã về Wi-Fi có internet, CrabSenseBE đang chạy.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farms = widget.session.farms;
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Thêm Controller',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ESP đã vào Wi-Fi trại thì AP CrabSense-C114 có thể không còn trong danh sách Wi-Fi. '
              'Để PC cùng mạng trại, bấm Tìm Controller (quét LAN), hoặc điền mã rồi đăng ký.',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _esp == null
                        ? 'Chưa tìm thấy controller'
                        : _esp!.displayName,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _discover,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Tìm Controller'),
                ),
              ],
            ),
            if (_esp != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (_esp!.mac.isNotEmpty) 'MAC ${_esp!.mac}',
                  if (_esp!.firmware.isNotEmpty) 'FW ${_esp!.firmware}',
                  if (_esp!.staIp.isNotEmpty) 'LAN ${_esp!.staIp}',
                ].join(' · '),
                style: GoogleFonts.robotoMono(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _deviceCode,
              enabled: !_busy,
              style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
              decoration: _deco('Mã controller'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_type),
              initialValue: _type,
              dropdownColor: DashboardColors.card,
              decoration: _deco('Loại'),
              items: const [
                DropdownMenuItem(
                  value: controllerTypeRealtime,
                  child: Text('Realtime Sensor Controller'),
                ),
                DropdownMenuItem(
                  value: controllerTypeWaterAnalysis,
                  child: Text('Water Analysis (NO₂ Analyzer)'),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ssid,
              enabled: !_busy,
              style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
              decoration: _deco('Wi-Fi'),
            ),
            if (_ssids.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final name in _ssids.take(8))
                    ActionChip(
                      label: Text(name, style: GoogleFonts.notoSans(fontSize: 11)),
                      onPressed: _busy
                          ? null
                          : () {
                              _ssid.text = name;
                              setState(() {});
                            },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
              decoration: _deco('Mật khẩu').copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: farms.any((f) => f.id == _area.id)
                  ? _area.id
                  : (farms.isEmpty ? null : farms.first.id),
              dropdownColor: DashboardColors.card,
              decoration: _deco('Khu vực'),
              items: [
                for (final farm in farms)
                  DropdownMenuItem(value: farm.id, child: Text(farm.name)),
              ],
              onChanged: _busy
                  ? null
                  : (id) {
                      if (id == null) return;
                      setState(() {
                        _area = farms.firstWhere(
                          (f) => f.id == id,
                          orElse: () => _area,
                        );
                      });
                    },
            ),
            if (_wifiSent) ...[
              const SizedBox(height: 12),
              Text(
                'ESP32 đã nhận Wi-Fi và đang restart. '
                'Đổi máy tính về Wi-Fi trại (có internet), đợi CrabSenseBE kết nối được database, '
                'rồi bấm Đăng ký lên CrabMonitor.',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.brand,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.risk,
                  fontSize: 12,
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : (_wifiSent || _esp == null ? _registerOnBackend : _sendWifiToEsp),
          child: Text(
            _wifiSent || _esp == null
                ? 'Đăng ký lên CrabMonitor'
                : 'Gửi Wi-Fi cho ESP32',
          ),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
    );
  }
}
