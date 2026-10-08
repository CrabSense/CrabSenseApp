import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/cloud_api_client.dart';
import '../../services/controller_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

Future<void> showKioskProvisionDialog(
  BuildContext context,
  ControllerService service,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _KioskProvisionDialog(service: service),
  );
}

class _KioskProvisionDialog extends StatefulWidget {
  const _KioskProvisionDialog({required this.service});

  final ControllerService service;

  @override
  State<_KioskProvisionDialog> createState() => _KioskProvisionDialogState();
}

class _KioskProvisionDialogState extends State<_KioskProvisionDialog> {
  final _api = CloudApiClient();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _controllers = [];
  bool _loading = true;
  String? _error;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _token => widget.service.session.token;
  String get _areaId => widget.service.session.selectedFarm.id;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listKiosks(_token, _areaId);
      final controllers = await _api.listEdgeControllers(_token, _areaId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _controllers = controllers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    setState(() => _error = null);
    try {
      await _api.createKiosk(
        _token,
        _areaId,
        name: widget.service.session.selectedFarm.name,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _reissue(String id) async {
    setState(() => _error = null);
    try {
      await _api.issueKioskCode(_token, id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _decide(String id, bool approve) async {
    setState(() => _error = null);
    try {
      if (approve) {
        await _api.approveController(_token, id);
      } else {
        await _api.rejectController(_token, id);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _revoke(String id) async {
    setState(() => _error = null);
    try {
      await _api.revokeKiosk(_token, id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _deleteKiosk(String id, String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa $code?'),
        content: const Text('Kiosk và mã cấp phát bị xóa. Controller gắn kiosk này trở lại chưa nối.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _error = null);
    try {
      await _api.deleteKiosk(_token, id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm = widget.service.session.selectedFarm;
    return AlertDialog(
      title: Text('Kiosk — ${farm.name}', style: bvText(fontSize: 18, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 520,
        height: _loading ? 80 : 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Site ${farm.code}. Nhập mã vào setup-kiosk.bat trên máy trại. Mã hết hạn sau 10 phút và chỉ dùng một lần.',
                    style: bvText(fontSize: 13, color: DashboardColors.textMuted, height: 1.4),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: bvText(fontSize: 13, color: const Color(0xFFEF4444))),
                  ],
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    Text('Chưa có Kiosk trong khu này.', style: bvText(fontSize: 13))
                  else
                    ..._items.map(_tile),
                  if (_controllers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Controller', style: bvText(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ..._controllers.map(_controllerTile),
                  ],
                ],
              ),
            ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        MgmtPrimaryButton(label: 'Tạo Kiosk', icon: Icons.add, onTap: _loading ? null : _create),
      ],
    );
  }

  Widget _controllerTile(Map<String, dynamic> item) {
    final id = '${item['id']}';
    final code = '${item['deviceCode']}';
    final state = '${item['linkStatus'] ?? item['edgeState']}';
    final ip = item['ipAddress']?.toString();
    final pending = state == 'Pending';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text('$code  ·  $state${ip == null ? '' : '  ·  $ip'}', style: bvText(fontSize: 13))),
          if (pending) ...[
            TextButton(onPressed: () => _decide(id, true), child: const Text('Duyệt')),
            TextButton(onPressed: () => _decide(id, false), child: const Text('Từ chối')),
          ],
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> item) {
    final id = '${item['id']}';
    final code = '${item['code']}';
    final status = '${item['status']}';
    final provision = item['provisioningCode']?.toString();
    final expires = DateTime.tryParse('${item['provisioningExpiresAt']}')?.toLocal();
    final left = expires?.difference(DateTime.now());
    final alive = left != null && !left.isNegative;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: mgmtCardDeco(radius: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$code  ·  $status', style: bvText(fontSize: 14, fontWeight: FontWeight.w700)),
              if (provision != null && alive) ...[
                const SizedBox(height: 6),
                SelectableText(provision, style: bvText(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(
                  'Còn ${_fmt(left)}',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (provision != null && alive)
                    TextButton(
                      onPressed: () => Clipboard.setData(ClipboardData(text: provision)),
                      child: const Text('Chép mã'),
                    ),
                  TextButton(onPressed: () => _reissue(id), child: const Text('Cấp mã mới')),
                  TextButton(onPressed: () => _revoke(id), child: const Text('Thu hồi')),
                  TextButton(onPressed: () => _deleteKiosk(id, code), child: const Text('Xóa')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
