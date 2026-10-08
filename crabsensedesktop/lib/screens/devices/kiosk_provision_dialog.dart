import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_env.dart';
import '../../services/cloud_api_client.dart';
import '../../services/cloud_auth_service.dart';
import '../../services/controller_provisioning_service.dart';
import '../../services/controller_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

class KioskSection extends StatefulWidget {
  const KioskSection({super.key, required this.service});

  final ControllerService service;

  @override
  State<KioskSection> createState() => KioskSectionState();
}

class KioskSectionState extends State<KioskSection> {
  final _api = CloudApiClient();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _controllers = [];
  bool _loading = true;
  String? _error;
  Timer? _tick;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);
  String? _espKioskUrl;
  List<EspProvisionInfo> _espBoards = const [];

  @override
  void initState() {
    super.initState();
    _seenArea = widget.service.session.selectedFarm.id;
    widget.service.addListener(_onService);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (DateTime.now().difference(_lastFetch).inSeconds >= 5) _load(silent: true);
    });
    _load();
    _loadEspUrl();
    _loadEspWifi();
  }

  Future<void> _loadEspUrl() async {
    String? farm;
    String? lan;
    String? other;
    for (final iface in await NetworkInterface.list()) {
      for (final addr in iface.addresses) {
        if (addr.type != InternetAddressType.IPv4) continue;
        final ip = addr.address;
        if (ip.startsWith('127.') || ip.startsWith('169.254.')) continue;
        if (ip.startsWith('192.168.1.')) {
          farm ??= ip;
        } else if (ip.startsWith('192.168.')) {
          lan ??= ip;
        } else {
          other ??= ip;
        }
      }
    }
    final ip = farm ?? lan ?? other;
    if (!mounted || ip == null) return;
    setState(() => _espKioskUrl = 'http://$ip:8090');
  }

  Future<void> _loadEspWifi() async {
    try {
      final boards = await ControllerProvisioningService().discoverAllNearby();
      if (!mounted) return;
      setState(() => _espBoards = boards);
    } catch (_) {}
  }

  void _onService() {
    final id = widget.service.session.selectedFarm.id;
    if (id == _seenArea) return;
    _seenArea = id;
    _load();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onService);
    _tick?.cancel();
    super.dispose();
  }

  String? _seenArea;

  String get _token => LiveSession.tokenOf(widget.service.session);
  String get _areaId => widget.service.session.selectedFarm.id;

  Future<void> create() => _create();

  Future<void> _load({bool silent = false}) async {
    _lastFetch = DateTime.now();
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      var token = _token;
      List<Map<String, dynamic>> items;
      List<Map<String, dynamic>> controllers;
      try {
        items = await _api.listKiosks(token, _areaId);
        controllers = await _api.listEdgeControllers(token, _areaId);
      } on CloudApiException catch (e) {
        if (e.statusCode != 401) rethrow;
        final renewed = await widget.service.renewToken();
        if (renewed == null) rethrow;
        token = renewed;
        items = await _api.listKiosks(token, _areaId);
        controllers = await _api.listEdgeControllers(token, _areaId);
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _controllers = controllers;
        _loading = false;
        _error = null;
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
    return DecoratedBox(
      decoration: mgmtCardDeco(radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kiosk', style: bvText(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Site ${farm.code}. Máy trại nhập mã vào start-kiosk.bat. Mã hết hạn sau 10 phút và chỉ dùng một lần.',
              style: bvText(fontSize: 13, color: DashboardColors.textMuted, height: 1.4),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              )
            else ...[
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
                const SizedBox(height: 4),
                Text('Controller đang gắn Kiosk', style: bvText(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ..._controllers.map(_controllerTile),
              ],
            ],
          ],
        ),
      ),
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
              const SizedBox(height: 8),
              _info('BE', AppEnv.cloudApiUrl, copy: true),
              if (_espKioskUrl != null) _info('Cho ESP', _espKioskUrl!, copy: true),
              for (final board in _espBoards)
                if (board.wifiSsid.isNotEmpty)
                  _info('Wi-Fi ${board.displayName}', board.wifiSsid, copy: true),
              _info('Kết nối', _when(item['lastSeenAt'])),
              _info('IP máy trại', _text(item['lanIp'])),
              if (_text(item['name']) != '—') _info('Tên', _text(item['name'])),
              if (provision != null && alive) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    SelectableText(provision, style: bvText(fontSize: 22, fontWeight: FontWeight.w800)),
                    _copyIcon(provision),
                  ],
                ),
                Text(
                  'Còn ${_fmt(left)}',
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
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

  String _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? '—' : text;
  }

  String _when(Object? value) {
    final at = DateTime.tryParse('${value ?? ''}');
    return at == null ? '—' : fmtDateTimeVn(at.toLocal());
  }

  Widget _copyIcon(String value) {
    return IconButton(
      tooltip: 'Copy',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: const Icon(Icons.copy_outlined, size: 16),
      onPressed: () => Clipboard.setData(ClipboardData(text: value)),
    );
  }

  Widget _info(String label, String value, {bool copy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: $value', style: bvText(fontSize: 13, color: DashboardColors.textMuted)),
          if (copy) _copyIcon(value),
        ],
      ),
    );
  }
}
