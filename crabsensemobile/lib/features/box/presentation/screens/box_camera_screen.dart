import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

/// Shows camera metadata / stream placeholder for a box.
class BoxCameraScreen extends StatefulWidget {
  const BoxCameraScreen({required this.boxId, super.key});

  final String boxId;

  @override
  State<BoxCameraScreen> createState() => _BoxCameraScreenState();
}

class _BoxCameraScreenState extends State<BoxCameraScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<ApiClient>().safeGet<Map<String, dynamic>>(
      ApiConstants.boxCamera(widget.boxId),
    );
    if (!mounted) return;
    if (result.failure != null) {
      setState(() {
        _loading = false;
        _error = result.failure!.message;
      });
      return;
    }
    final body = result.data.data;
    Map<String, dynamic> data = {};
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        data = body['data'] as Map<String, dynamic>;
      } else {
        data = body;
      }
    }
    setState(() {
      _loading = false;
      _data = data;
    });
  }

  Future<void> _copyStream() async {
    final url = _data['streamUrl']?.toString();
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã copy stream URL')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (_data['status'] ?? 'unknown').toString();
    final message = (_data['message'] ?? '').toString();
    final device = (_data['deviceCode'] ?? '—').toString();
    final stream = _data['streamUrl']?.toString() ?? '';
    final snapshot = _data['snapshotUrl']?.toString() ?? '';
    final online = status.toLowerCase() == 'online' ||
        status.toLowerCase() == 'preview';

    return Scaffold(
      backgroundColor: CrabSenseColors.background,
      appBar: AppBar(
        title: const Text('Camera hộp'),
        backgroundColor: CrabSenseColors.surface,
        foregroundColor: CrabSenseColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
              : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildPreview(online, snapshot, stream),
                ),
                const SizedBox(height: 16),
                Text('Thiết bị: $device'),
                Text('Trạng thái: $status'),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(color: CrabSenseColors.textSecondary),
                  ),
                ],
                if (stream.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SelectableText(stream, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: stream.isNotEmpty ? _copyStream : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy stream / preview URL'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('Làm mới')),
              ],
            ),
    );
  }

  Widget _buildPreview(bool online, String snapshot, String stream) {
    final imageUrl = snapshot.isNotEmpty
        ? snapshot
        : (stream.startsWith('http') &&
                !stream.contains('stream.crabsense.local') &&
                !stream.contains('.m3u8')
            ? stream
            : '');

    if (imageUrl.startsWith('http')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _statusIcon(online),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Text(
                online ? 'Live / Preview' : 'Preview',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }
    return _statusIcon(online);
  }

  Widget _statusIcon(bool online) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              online ? Icons.videocam : Icons.videocam_off,
              color: online ? CrabSenseColors.success : Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              online ? 'Camera online' : 'Camera offline',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
}
