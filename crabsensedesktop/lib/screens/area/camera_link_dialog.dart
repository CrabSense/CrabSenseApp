import 'package:flutter/material.dart';

import '../../services/cloud_api_client.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

/// Thêm hoặc sửa camera trên khu. Điền IP, cổng, đường dẫn, tài khoản
/// và mật khẩu; URL RTSP được ghép từ các ô đó.
Future<bool> showCameraLinkDialog(
  BuildContext context, {
  required CloudApiClient api,
  required String token,
  required String areaId,
  String? deviceId,
  String? code,
  String? name,
  String? ipAddress,
  String? streamUrl,
  String? resolution,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CameraLinkDialog(
      api: api,
      token: token,
      areaId: areaId,
      deviceId: deviceId,
      code: code,
      name: name,
      ipAddress: ipAddress,
      streamUrl: streamUrl,
      resolution: resolution,
    ),
  );
  return saved == true;
}

class _ParsedStream {
  const _ParsedStream({
    this.user = '',
    this.password = '',
    this.host = '',
    this.port = '554',
    this.path = '/live0',
  });

  final String user;
  final String password;
  final String host;
  final String port;
  final String path;

  static _ParsedStream fromUrl(String? raw) {
    final text = (raw ?? '').trim();
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) {
      return const _ParsedStream();
    }
    final info = uri.userInfo;
    final colon = info.indexOf(':');
    final user = colon < 0 ? info : info.substring(0, colon);
    final password = colon < 0 ? '' : info.substring(colon + 1);
    final path = uri.path.isEmpty ? '/live0' : uri.path;
    return _ParsedStream(
      user: Uri.decodeComponent(user),
      password: Uri.decodeComponent(password),
      host: uri.host,
      port: uri.hasPort ? '${uri.port}' : '554',
      path: path,
    );
  }
}

class _CameraLinkDialog extends StatefulWidget {
  const _CameraLinkDialog({
    required this.api,
    required this.token,
    required this.areaId,
    this.deviceId,
    this.code,
    this.name,
    this.ipAddress,
    this.streamUrl,
    this.resolution,
  });

  final CloudApiClient api;
  final String token;
  final String areaId;
  final String? deviceId;
  final String? code;
  final String? name;
  final String? ipAddress;
  final String? streamUrl;
  final String? resolution;

  @override
  State<_CameraLinkDialog> createState() => _CameraLinkDialogState();
}

class _CameraLinkDialogState extends State<_CameraLinkDialog> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late final TextEditingController _path;
  late final TextEditingController _user;
  late final TextEditingController _password;
  late final List<String> _resolutions;
  late String _resolution;
  var _showPassword = false;
  var _saving = false;
  String? _error;

  bool get _editing => widget.deviceId != null && widget.deviceId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final parsed = _ParsedStream.fromUrl(widget.streamUrl);
    _name = TextEditingController(text: widget.name ?? '');
    _code = TextEditingController(
      text: widget.code ?? 'CAM-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    _ip = TextEditingController(
      text: (widget.ipAddress ?? '').trim().isNotEmpty ? widget.ipAddress!.trim() : parsed.host,
    );
    _port = TextEditingController(text: parsed.port);
    _path = TextEditingController(text: parsed.path);
    _user = TextEditingController(text: parsed.user);
    _password = TextEditingController(text: parsed.password);
    const choices = ['2K', '1080p', '720p', '480p'];
    final saved = (widget.resolution ?? '').trim();
    _resolutions = [
      if (saved.isNotEmpty && !choices.contains(saved)) saved,
      ...choices,
    ];
    _resolution = saved.isEmpty ? '2K' : saved;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _ip.dispose();
    _port.dispose();
    _path.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _streamUrl() {
    final ip = _ip.text.trim();
    if (ip.isEmpty) return null;
    final port = int.tryParse(_port.text.trim()) ?? 554;
    var path = _path.text.trim();
    if (path.isEmpty) path = '/';
    if (!path.startsWith('/')) path = '/$path';
    final user = _user.text.trim();
    final pass = _password.text;
    final auth = user.isEmpty
        ? ''
        : '${Uri.encodeComponent(user)}:${Uri.encodeComponent(pass)}@';
    return 'rtsp://$auth$ip:$port$path';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final code = _code.text.trim();
    final url = _streamUrl();
    if (name.isEmpty) {
      setState(() => _error = 'Nhập tên camera.');
      return;
    }
    if (url == null) {
      setState(() => _error = 'Nhập địa chỉ IP của camera.');
      return;
    }
    if (!_editing && code.isEmpty) {
      setState(() => _error = 'Nhập mã camera.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_editing) {
        await widget.api.updateController(
          widget.token,
          widget.deviceId!,
          name: name,
          ipAddress: _ip.text.trim(),
          streamUrl: url,
          resolution: _resolution,
          status: 'Online',
        );
      } else {
        final created = await widget.api.createController(
          widget.token,
          deviceCode: code,
          name: name,
          deviceType: 'camera',
          ipAddress: _ip.text.trim(),
          farmingAreaId: widget.areaId,
          streamUrl: url,
          resolution: _resolution,
        );
        final id = (created['id'] ?? created['Id'] ?? '').toString();
        if (id.isNotEmpty) {
          await widget.api.updateController(
            widget.token,
            id,
            status: 'Online',
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label, String hint) => InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        );
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _editing ? 'Sửa camera' : 'Thêm camera',
        style: bvText(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: deco('Tên', 'Camera khu A')),
              const SizedBox(height: 10),
              TextField(
                controller: _code,
                enabled: !_editing && !_saving,
                decoration: deco('Mã', 'CAM-0001'),
              ),
              const SizedBox(height: 10),
              TextField(controller: _ip, decoration: deco('Địa chỉ IP', '192.168.1.140')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: _port, decoration: deco('Cổng', '554')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(controller: _path, decoration: deco('Đường dẫn', '/live0')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: _user, decoration: deco('Tài khoản', 'admin')),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: !_showPassword,
                decoration: deco('Mật khẩu', 'Mật khẩu ONVIF').copyWith(
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _resolution,
                decoration: deco('Độ phân giải', ''),
                items: [
                  for (final item in _resolutions)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _resolution = value);
                      },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: bvText(fontSize: 12, color: DashboardColors.risk)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
