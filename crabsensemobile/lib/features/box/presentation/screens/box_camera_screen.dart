import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/home_palette.dart';
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
      const SnackBar(content: Text('Đã sao chép URL stream')),
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
      backgroundColor: kHomeNavyDeep,
      appBar: AppBar(
        title: const Text(
          'CAMERA TRỰC TIẾP',
          style: TextStyle(
            color: kHomeBlueLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: kHomeNavy,
        foregroundColor: kHomeBlueLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kHomeCyan))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(
                            backgroundColor: kHomeBlue,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
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
                        border: Border.all(
                          color: kHomeBorderBlue.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kHomeBlue.withValues(alpha: 0.18),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildPreview(online, snapshot, stream),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: homeCardDecoration(radius: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _metaRow('Thiết bị', device),
                          const SizedBox(height: 8),
                          _metaRow('Trạng thái', status),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                          if (stream.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SelectableText(
                              stream,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 46,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF5BA0FF),
                              kHomeBlue,
                              Color(0xFF1A5FD0),
                            ],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: stream.isNotEmpty ? _copyStream : null,
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sao chép URL stream',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _load,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kHomeCyan,
                        side: BorderSide(
                          color: kHomeCyan.withValues(alpha: 0.55),
                        ),
                      ),
                      child: const Text('Làm mới'),
                    ),
                  ],
                ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: online
                      ? kHomeGreen.withValues(alpha: 0.6)
                      : Colors.white24,
                ),
              ),
              child: Text(
                online ? 'Trực tiếp / Xem trước' : 'Xem trước',
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
              color: online ? kHomeGreen : Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              online ? 'Camera trực tuyến' : 'Camera ngoại tuyến',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
}
