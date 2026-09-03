import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../theme/dashboard_theme.dart';

/// ESP32 "DHCP Test" — trang HTML + 1 ảnh JPEG (Reload), không MJPEG.
/// ESP32 yếu: 1 GET/lần, poll chậm, Connection: close.
class HttpPageCameraPlayer extends StatefulWidget {
  const HttpPageCameraPlayer({
    super.key,
    required this.pageUrl,
    this.ipAddress,
    this.maxFps = 1,
    this.pollMinMs = 3500,
  });

  final String pageUrl;
  final String? ipAddress;
  final int maxFps;
  final int pollMinMs;

  @override
  State<HttpPageCameraPlayer> createState() => _HttpPageCameraPlayerState();
}

class _HttpPageCameraPlayerState extends State<HttpPageCameraPlayer> {
  static const _headers = {
    'Connection': 'close',
    'Accept':
        'text/html,application/xhtml+xml,image/avif,image/webp,image/apng,*/*',
    'Accept-Encoding': 'identity',
    'Cache-Control': 'no-cache',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  final _frameNotifier = ValueNotifier<Uint8List?>(null);
  var _stopped = false;
  var _busy = false;
  var _connecting = true;
  String? _error;
  var _failStreak = 0;

  Duration get _pollInterval {
    final fps = widget.maxFps.clamp(1, 2);
    final fromFps = Duration(milliseconds: (1000 / fps).round());
    final minMs = widget.pollMinMs.clamp(2500, 15000);
    final min = Duration(milliseconds: minMs);
    return fromFps > min ? fromFps : min;
  }

  Duration get _backoff =>
      Duration(milliseconds: (_failStreak * 1500).clamp(0, 8000));

  @override
  void initState() {
    super.initState();
    unawaited(_pollLoop());
  }

  @override
  void dispose() {
    _stopped = true;
    _frameNotifier.dispose();
    super.dispose();
  }

  Future<void> _pollLoop() async {
    while (!_stopped) {
      final t0 = DateTime.now();
      if (!_busy) {
        await _refreshOnce();
      }
      var wait = _pollInterval + _backoff - DateTime.now().difference(t0);
      if (wait < const Duration(milliseconds: 500)) {
        wait = const Duration(milliseconds: 500);
      }
      await Future.delayed(wait);
    }
  }

  Future<void> _refreshOnce() async {
    if (_busy || _stopped) return;
    _busy = true;
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        if (_stopped) return;
        try {
          final jpeg = await _fetchFrame();
          if (jpeg != null) {
            _frameNotifier.value = jpeg;
            _failStreak = 0;
            if (mounted && (_error != null || _connecting)) {
              setState(() {
                _error = null;
                _connecting = false;
              });
            }
          }
          return;
        } catch (e) {
          _failStreak++;
          if (attempt < 1) {
            await Future.delayed(Duration(milliseconds: 800 * (attempt + 1)));
            continue;
          }
          if (mounted && _frameNotifier.value == null) {
            setState(() {
              _error = _shortError(e);
              _connecting = false;
            });
          }
        }
      }
    } finally {
      _busy = false;
    }
  }

  String _shortError(Object e) {
    final s = e.toString();
    if (s.contains('Connection closed')) {
      return 'ESP32 đóng kết nối — đang thử lại chậm hơn…';
    }
    if (s.length > 120) return '${s.substring(0, 120)}…';
    return s;
  }

  Future<Uint8List?> _fetchFrame() async {
    final pageUri = Uri.parse(widget.pageUrl);
    final cacheBust = pageUri.replace(
      queryParameters: {
        ...pageUri.queryParameters,
        't': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );

    final response = await _get(cacheBust);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final ct = (response.headers['content-type'] ?? '').toLowerCase();
    final bytes = response.bodyBytes;

    if (ct.contains('image/jpeg') || ct.contains('image/jpg')) {
      return _jpegFromBytes(bytes);
    }

    final embedded = _extractJpeg(bytes);
    if (embedded != null) return embedded;

    final html = utf8.decode(bytes, allowMalformed: true);
    final src = _parseImgSrc(html);
    if (src == null) {
      throw Exception('Không tìm thấy ảnh trong HTML');
    }

    final imgUri = pageUri.resolve(src);
    if (imgUri.toString() == pageUri.toString()) {
      throw Exception('Ảnh trùng URL trang — thử Reload');
    }

    final img = await _get(imgUri.replace(
      queryParameters: {
        ...imgUri.queryParameters,
        't': '${DateTime.now().millisecondsSinceEpoch}',
      },
    ));
    if (img.statusCode != 200) {
      throw Exception('Ảnh HTTP ${img.statusCode}');
    }
    return _jpegFromBytes(img.bodyBytes);
  }

  Future<http.Response> _get(Uri uri) async {
    final client = http.Client();
    try {
      return await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
    } finally {
      client.close();
    }
  }

  Future<void> _openBrowser() async {
    final uri = Uri.parse(widget.pageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Uint8List? _jpegFromBytes(List<int> data) {
    if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xD8) {
      return Uint8List.fromList(data);
    }
    return _extractJpeg(data);
  }

  static Uint8List? _extractJpeg(List<int> data) {
    var start = -1;
    for (var i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD8) {
        start = i;
        break;
      }
    }
    if (start < 0) return null;
    for (var i = data.length - 2; i > start; i--) {
      if (data[i] == 0xFF && data[i + 1] == 0xD9) {
        return Uint8List.fromList(data.sublist(start, i + 2));
      }
    }
    return null;
  }

  static String? _parseImgSrc(String html) {
    final patterns = [
      RegExp(r'''<img[^>]+src\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(
        r'''src\s*=\s*["']([^"']+\.(?:jpg|jpeg))["']''',
        caseSensitive: false,
      ),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(html);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final labelSec = (_pollInterval.inMilliseconds / 1000).toStringAsFixed(1);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        ValueListenableBuilder<Uint8List?>(
          valueListenable: _frameNotifier,
          builder: (context, frame, _) {
            if (frame == null) return const SizedBox.shrink();
            return RepaintBoundary(
              child: Image.memory(
                frame,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
                isAntiAlias: false,
              ),
            );
          },
        ),
        if (_error != null && _frameNotifier.value == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.risk,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_connecting && _frameNotifier.value == null)
          const Center(
            child: CircularProgressIndicator(color: DashboardColors.cyan),
          ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.ipAddress ?? widget.pageUrl} · HTML ~${labelSec}s',
              style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 10),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.refresh, () => unawaited(_refreshOnce())),
              const SizedBox(width: 6),
              _iconBtn(Icons.open_in_new, _openBrowser),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}
