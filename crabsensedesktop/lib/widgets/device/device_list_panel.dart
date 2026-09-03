import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/iot_device.dart';
import '../../services/iot_device_service.dart';
import '../../theme/dashboard_theme.dart';
import 'device_form_dialog.dart';

class DeviceListPanel extends StatefulWidget {
  const DeviceListPanel({
    super.key,
    required this.service,
    this.boxIds,
  });

  final IoTDeviceService service;

  /// ID các hộp trên dãy đang chọn; `null` = chưa chọn dãy.
  final List<String>? boxIds;

  @override
  State<DeviceListPanel> createState() => _DeviceListPanelState();
}

class _DeviceListPanelState extends State<DeviceListPanel> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    if (widget.boxIds != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDevices();
      });
    }
  }

  @override
  void didUpdateWidget(DeviceListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameBoxIds(oldWidget.boxIds, widget.boxIds)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDevices();
      });
    }
  }

  bool _sameBoxIds(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDevices() async {
    final ids = widget.boxIds;
    if (ids == null) return;
    await widget.service.loadDevicesForBoxes(ids);
  }

  String? get _defaultBoxIdForNew {
    final ids = widget.boxIds;
    if (ids == null || ids.isEmpty) return null;
    if (ids.length == 1) return ids.first;
    return null;
  }

  Future<void> _addDevice() async {
    final device = await showDeviceFormDialog(
      context,
      widget.service,
      defaultBoxId: _defaultBoxIdForNew,
    );
    if (device != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm thiết bị ${device.deviceCode}')),
      );
      await _loadDevices();
    }
  }

  Future<void> _editDevice(IoTDevice device) async {
    final updated = await showDeviceFormDialog(
      context,
      widget.service,
      existing: device,
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${updated.deviceCode}')),
      );
      await _loadDevices();
    }
  }

  Future<void> _deleteDevice(IoTDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thiết bị?'),
        content: Text(
          'Xác nhận xóa thiết bị ${device.deviceCode}?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.risk,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await widget.service.deleteDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã xóa ${device.deviceCode}'
                  : 'Lỗi khi xóa thiết bị',
            ),
          ),
        );
        if (success) await _loadDevices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;

    if (widget.boxIds == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other,
              size: 48,
              color: DashboardColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Chọn khu và dãy để xem thiết bị IoT',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (widget.boxIds!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other,
              size: 48,
              color: DashboardColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Dãy này chưa có hộp nuôi',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          ],
        ),
      );
    }

    final devices = svc.devices;

    if (svc.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (svc.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: DashboardColors.risk,
            ),
            const SizedBox(height: 12),
            Text(
              svc.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDevices,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other,
              size: 48,
              color: DashboardColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có thiết bị IoT trên dãy này',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _addDevice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm thiết bị'),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.cyan,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text(
                '${devices.length} thiết bị',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _addDevice,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.cyan,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final device = devices[index];
              return _DeviceTile(
                device: device,
                onEdit: () => _editDevice(device),
                onDelete: () => _deleteDevice(device),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.onEdit,
    required this.onDelete,
  });

  final IoTDevice device;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DashboardColors.card,
      child: ListTile(
        leading: Icon(
          Icons.sensors,
          color: DashboardColors.cyan,
        ),
        title: Text(
          device.deviceCode,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (device.deviceName != null && device.deviceName!.isNotEmpty)
              device.deviceName!,
            device.statusLabel,
            if (device.boxCode != null) device.boxCode!,
          ].join(' · '),
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: DashboardColors.risk,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
