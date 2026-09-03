import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/camera_device.dart';
import '../../services/camera_device_service.dart';
import '../../theme/dashboard_theme.dart';
import 'camera_connect_test_dialog.dart';

Future<bool?> showCameraFormDialog(
  BuildContext context,
  CameraDeviceService service, {
  required String gatewayId,
  CameraDevice? existing,
  String? defaultBoxId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _CameraFormDialog(
      service: service,
      gatewayId: gatewayId,
      existing: existing,
      defaultBoxId: defaultBoxId,
    ),
  );
}

class _CameraFormDialog extends StatefulWidget {
  const _CameraFormDialog({
    required this.service,
    required this.gatewayId,
    this.existing,
    this.defaultBoxId,
  });

  final CameraDeviceService service;
  final String gatewayId;
  final CameraDevice? existing;
  final String? defaultBoxId;

  @override
  State<_CameraFormDialog> createState() => _CameraFormDialogState();
}

class _CameraFormDialogState extends State<_CameraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _streamUrlCtrl;
  late final TextEditingController _ipCtrl;
  late final TextEditingController _boxIdCtrl;
  late String _status;
  var _loading = false;
  var _testing = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _codeCtrl = TextEditingController(text: ex?.cameraCode);
    _nameCtrl = TextEditingController(text: ex?.name);
    _streamUrlCtrl = TextEditingController(text: ex?.streamUrl);
    _ipCtrl = TextEditingController(text: ex?.ipAddress);
    _boxIdCtrl = TextEditingController(
        text: ex?.boxId ?? widget.defaultBoxId ?? '');
    _status = ex?.status ?? 'offline';

    if (ex == null) {
      _loadNextCode();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _streamUrlCtrl.dispose();
    _ipCtrl.dispose();
    _boxIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNextCode() async {
    final code = await widget.service.getNextCameraCode(gatewayId: widget.gatewayId);
    if (code != null && mounted) {
      _codeCtrl.text = code;
    }
  }

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split('.');
    if (parts.length != 4) return 'Định dạng IP không hợp lệ';
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'Mỗi octet phải từ 0-255';
      }
    }
    return null;
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      await showCameraConnectTestDialog(
        context,
        streamUrl: _streamUrlCtrl.text.trim().isNotEmpty
            ? _streamUrlCtrl.text.trim()
            : null,
        ipAddress:
            _ipCtrl.text.trim().isNotEmpty ? _ipCtrl.text.trim() : null,
        title: _nameCtrl.text.trim().isNotEmpty
            ? 'Test — ${_nameCtrl.text.trim()}'
            : 'Test kết nối',
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final boxId = _boxIdCtrl.text.trim();
    final request = UpsertCameraRequest(
      cameraCode: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      boxId: boxId.isNotEmpty ? boxId : null,
      streamUrl: _streamUrlCtrl.text.trim().isNotEmpty ? _streamUrlCtrl.text.trim() : null,
      ipAddress: _ipCtrl.text.trim().isNotEmpty ? _ipCtrl.text.trim() : null,
      status: _status,
    );

    try {
      final result = widget.existing == null
          ? await widget.service.createCamera(request, gatewayId: widget.gatewayId)
          : await widget.service.updateCamera(widget.existing!.id, request);

      if (mounted) {
        if (result != null) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.service.error ?? 'Có lỗi xảy ra'),
              backgroundColor: DashboardColors.risk,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        isEdit ? 'Chỉnh sửa camera' : 'Thêm camera',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeCtrl,
                  decoration: _inputDec('Mã camera', Icons.videocam),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nhập mã camera' : null,
                  style: _textStyle(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDec('Tên camera', Icons.label),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nhập tên camera' : null,
                  style: _textStyle(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _streamUrlCtrl,
                  decoration: _inputDec('Stream URL (tùy chọn)', Icons.link),
                  style: _textStyle(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ipCtrl,
                  decoration: _inputDec('IP Address (tùy chọn)', Icons.wifi),
                  validator: _validateIp,
                  style: _textStyle(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _boxIdCtrl,
                  decoration: _inputDec('Box ID (tùy chọn)', Icons.inventory_2),
                  readOnly: widget.defaultBoxId != null,
                  style: _textStyle(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _inputDec('Trạng thái', Icons.circle),
                  dropdownColor: DashboardColors.darkNavy,
                  style: _textStyle(),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'offline', child: Text('Ngoại tuyến')),
                    DropdownMenuItem(value: 'error', child: Text('Lỗi')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'offline'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: (_loading || _testing) ? null : _testConnection,
          icon: _testing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lan_outlined, size: 18),
          label: const Text('Test kết nối'),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: (_loading || _testing) ? null : _submit,
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      );

  TextStyle _textStyle() =>
      GoogleFonts.notoSans(color: DashboardColors.textPrimary);
}
