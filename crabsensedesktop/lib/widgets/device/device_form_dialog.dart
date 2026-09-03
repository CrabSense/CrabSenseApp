import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/iot_device.dart';
import '../../services/iot_device_service.dart';
import '../../theme/dashboard_theme.dart';

Future<IoTDevice?> showDeviceFormDialog(
  BuildContext context,
  IoTDeviceService service, {
  IoTDevice? existing,
  String? defaultBoxId,
}) async {
  return showDialog<IoTDevice>(
    context: context,
    builder: (context) => _DeviceFormDialog(
      service: service,
      existing: existing,
      defaultBoxId: defaultBoxId,
    ),
  );
}

class _DeviceFormDialog extends StatefulWidget {
  const _DeviceFormDialog({
    required this.service,
    this.existing,
    this.defaultBoxId,
  });

  final IoTDeviceService service;
  final IoTDevice? existing;
  final String? defaultBoxId;

  @override
  State<_DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends State<_DeviceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _firmwareCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  
  String? _boxId;
  String _status = 'offline';
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _codeCtrl.text = existing.deviceCode;
      _nameCtrl.text = existing.deviceName ?? '';
      _macCtrl.text = existing.macAddress ?? '';
      _firmwareCtrl.text = existing.firmwareVersion ?? '';
      _ipCtrl.text = existing.ipLan ?? '';
      _boxId = existing.boxId;
      _status = existing.status;
    } else {
      _boxId = widget.defaultBoxId;
      _loadNextCode();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _macCtrl.dispose();
    _firmwareCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNextCode() async {
    final code = await widget.service.getNextDeviceCode();
    if (code != null && mounted) {
      _codeCtrl.text = code;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final request = UpsertDeviceRequest(
        deviceCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
        deviceName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        boxId: _boxId,
        macAddress: _macCtrl.text.trim().isEmpty ? null : _macCtrl.text.trim(),
        firmwareVersion:
            _firmwareCtrl.text.trim().isEmpty ? null : _firmwareCtrl.text.trim(),
        ipLan: _ipCtrl.text.trim().isEmpty ? null : _ipCtrl.text.trim(),
        status: _status,
      );

      IoTDevice? device;
      if (widget.existing != null) {
        device = await widget.service.updateDevice(widget.existing!.id, request);
      } else {
        device = await widget.service.createDevice(request);
      }

      if (device != null && mounted) {
        Navigator.pop(context, device);
      } else {
        setState(() {
          _error = 'Không thể lưu thiết bị';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        isEdit ? 'Sửa thiết bị IoT' : 'Thêm thiết bị IoT',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.risk,
                        fontSize: 12,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: _inputDec('Mã thiết bị', Icons.qr_code),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDec('Tên thiết bị (tùy chọn)', Icons.label),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _macCtrl,
                  decoration: _inputDec('Địa chỉ MAC', Icons.fingerprint),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      // Basic MAC validation
                      final mac = v.trim().toUpperCase();
                      if (!RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(mac)) {
                        return 'Định dạng MAC không hợp lệ (VD: AA:BB:CC:DD:EE:FF)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ipCtrl,
                  decoration: _inputDec('IP LAN', Icons.lan),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      // Basic IP validation
                      final parts = v.trim().split('.');
                      if (parts.length != 4 ||
                          parts.any((p) {
                            final n = int.tryParse(p);
                            return n == null || n < 0 || n > 255;
                          })) {
                        return 'Định dạng IP không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firmwareCtrl,
                  decoration: _inputDec('Firmware Version', Icons.info_outline),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _inputDec('Trạng thái', Icons.power_settings_new),
                  dropdownColor: DashboardColors.darkNavy,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'online',
                      child: Text('Hoạt động'),
                    ),
                    DropdownMenuItem(
                      value: 'offline',
                      child: Text('Ngoại tuyến'),
                    ),
                    DropdownMenuItem(
                      value: 'error',
                      child: Text('Lỗi'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'offline'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: DashboardColors.cyan,
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DashboardColors.cyan),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DashboardColors.risk),
        ),
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
      );
}
