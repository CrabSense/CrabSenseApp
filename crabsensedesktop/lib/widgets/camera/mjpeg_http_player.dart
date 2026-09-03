import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/dashboard_theme.dart';
import 'camera_jpeg_fetch.dart';
import 'mjpeg_stream_client.dart';

/// Phát HTTP MJPEG — tương thích [ESP32-CAM_WebServer]:
/// `multipart/x-mixed-replace; boundary=frame` + `Content-Length` từng JPEG.
/// Fallback: marker FFD8/FFD9 hoặc poll `/capture`.
class MjpegHttpPlayer extends StatefulWidget {
  const MjpegHttpPlayer({
    super.key,
    required this.streamUrl,
    this.ipAddress,
    this.snapshotFallbackUrl,
    this.streamUrlCandidates,
    this.maxFps = 10,
    this.snapshotOnly = false,
  });

  final String streamUrl;
  final String? ipAddress;
  final String? snapshotFallbackUrl;
  final List<String>? streamUrlCandidates;

  /// Giới hạn repaint để giảm lag UI (ESP32 thường gửi >15 fps).
  final int maxFps;

  /// Bỏ thử MJPEG, chỉ GET /capture (mượt hơn khi stream không ổn định).
  final bool snapshotOnly;

  @override
  State<MjpegHttpPlayer> createState() => _MjpegHttpPlayerState();
}

class _MjpegHttpPlayerState extends State<MjpegHttpPlayer> {
  static const _maxBufferBytes = 2 * 1024 * 1024;

  var _streamActive = false;
  var _snapshotBusy = false;
  StreamSubscription<List<int>>? _sub;
  final _buffer = <int>[];
  final _frameNotifier = ValueNotifier<Uint8List?>(null);
  Uint8List? _pendingFrame;
  String? _error;
  var _connecting = true;
  Timer? _snapshotTimer;
  Timer? _frameThrottleTimer;
  var _snapshotMode = false;
  late List<String> _urls;
  var _urlIndex = 0;
  String? _activeUrl;
  DateTime? _lastUiFrameAt;
  Timer? _firstFrameWatchdog;
  var _snapshotFailCount = 0;
  void Function()? _closeStream;

  Duration get _minFrameInterval =>
      Duration(milliseconds: (1000 / widget.maxFps.clamp(4, 30)).round());

  @override
  void initState() {
    super.initState();
    _urls = _buildUrlList();
    if (widget.snapshotOnly) {
      _snapshotMode = true;
      unawaited(_startSnapshotOnly());
    } else {
      unawaited(_startStream());
    }
  }

  Future<void> _startSnapshotOnly() async {
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    _startSnapshotPolling(widget.snapshotFallbackUrl ?? widget.streamUrl);
  }

  List<String> _buildUrlList() {
    final seen = <String>{};
    final out = <String>[];
    void add(String u) {
      final t = u.trim();
      if (t.isEmpty || seen.contains(t)) return;
      seen.add(t);
      out.add(t);
    }

    add(widget.streamUrl);
    for (final u in widget.streamUrlCandidates ?? const []) {
      add(u);
    }
    return out;
  }

  @override
  void dispose() {
    _frameNotifier.dispose();
    _teardown();
    super.dispose();
  }

  void _teardownStream() {
    _cancelFirstFrameWatchdog();
    _frameThrottleTimer?.cancel();
    _frameThrottleTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _closeStream?.call();
    _closeStream = null;
    _streamActive = false;
  }

  void _teardown() {
    _teardownStream();
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
  }

  Future<void> _startStream() async {
    _teardownStream();
    _buffer.clear();
    _pendingFrame = null;
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _error = null;
      _snapshotMode = false;
    });

    if (_snapshotMode) {
      _startSnapshotPolling();
      return;
    }

    if (_urlIndex >= _urls.length) {
      _fail('Đã thử ${_urls.length} URL, không có MJPEG');
      return;
    }

    final url = _urls[_urlIndex];
    _activeUrl = url;

    try {
      final handle = await openMjpegStream(url);
      _closeStream = handle.close;

      if (!mounted) return;
      if (handle.statusCode != 200) {
        _fail('HTTP ${handle.statusCode}');
        return;
      }

      final contentType = handle.contentType;
      if (contentType.contains('image/jpeg') &&
          !contentType.contains('multipart')) {
        unawaited(_switchToSnapshotAfterStream(url));
        return;
      }

      _streamActive = true;
      _sub = handle.byteStream.listen(
        _onChunk,
        onError: (e) => _fail('$e'),
        onDone: () {
          if (mounted && _frameNotifier.value == null) _fail('Stream đã ngắt');
        },
        cancelOnError: true,
      );

      _armFirstFrameWatchdog(url);
      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      _fail('$e');
    }
  }

  void _onChunk(List<int> chunk) {
    _buffer.addAll(chunk);
    if (_buffer.length > _maxBufferBytes) {
      _buffer.removeRange(0, _buffer.length - (_maxBufferBytes ~/ 2));
    }

    while (_tryExtractMultipartJpegFrame()) {}

    while (true) {
      final start = _indexOfMarker(_buffer, 0xFF, 0xD8);
      if (start < 0) {
        if (_buffer.length > 1) {
          _buffer.removeRange(0, _buffer.length - 1);
        }
        break;
      }
      if (start > 0) _buffer.removeRange(0, start);

      final end = _indexOfMarker(_buffer, 0xFF, 0xD9, 1);
      if (end >= 0) {
        _pendingFrame = Uint8List.fromList(_buffer.sublist(0, end + 2));
        _buffer.removeRange(0, end + 2);
        _scheduleFrameFlush();
        continue;
      }

      // ESP32-CAM: frame kế tiếp bắt đầu bằng FFD8 trước khi có FFD9.
      final nextStart = _indexOfMarker(_buffer, 0xFF, 0xD8, 2);
      if (nextStart > 0) {
        _pendingFrame = Uint8List.fromList(_buffer.sublist(0, nextStart));
        _buffer.removeRange(0, nextStart);
        _scheduleFrameFlush();
        continue;
      }

      break;
    }
  }

  void _scheduleFrameFlush() {
    final now = DateTime.now();
    final last = _lastUiFrameAt;
    if (last == null || now.difference(last) >= _minFrameInterval) {
      _flushPendingFrame();
      return;
    }
    _frameThrottleTimer ??= Timer(
      _minFrameInterval - now.difference(last),
      () {
        _frameThrottleTimer = null;
        _flushPendingFrame();
      },
    );
  }

  void _flushPendingFrame() {
    final pending = _pendingFrame;
    if (pending == null || !mounted) return;
    _pendingFrame = null;
    _cancelFirstFrameWatchdog();
    _lastUiFrameAt = DateTime.now();
    _frameNotifier.value = pending;
    if (_snapshotMode) {
      _snapshotFailCount = 0;
    }
    if (mounted && (_error != null || _connecting)) {
      setState(() {
        _error = null;
        _connecting = false;
      });
    }
  }

  int _indexOfMarker(List<int> data, int b0, int b1, [int from = 0]) {
    for (var i = from; i < data.length - 1; i++) {
      if (data[i] == b0 && data[i + 1] == b1) return i;
    }
    return -1;
  }

  int _indexOfSubsequence(List<int> data, List<int> pattern, [int from = 0]) {
    if (pattern.isEmpty || data.length < pattern.length) return -1;
    final limit = data.length - pattern.length;
    for (var i = from; i <= limit; i++) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return i;
    }
    return -1;
  }

  /// ESP32-CAM_WebServer.ino: `--frame` + headers + JPEG theo Content-Length.
  bool _tryExtractMultipartJpegFrame() {
    const crlf2 = [13, 10, 13, 10];
    const boundaryMarkers = [
      [45, 45, 102, 114, 97, 109, 101], // --frame
      [13, 10, 45, 45, 102, 114, 97, 109, 101], // \r\n--frame
    ];

    for (final marker in boundaryMarkers) {
      final boundaryAt = _indexOfSubsequence(_buffer, marker);
      if (boundaryAt < 0) continue;

      final headerEnd = _indexOfSubsequence(_buffer, crlf2, boundaryAt);
      if (headerEnd < 0) return false;

      final headerText = String.fromCharCodes(
        _buffer.sublist(boundaryAt, headerEnd),
      );
      final lenMatch = RegExp(
        r'Content-Length:\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(headerText);
      if (lenMatch == null) continue;

      final contentLen = int.tryParse(lenMatch.group(1)!);
      if (contentLen == null || contentLen <= 0) continue;

      final bodyStart = headerEnd + 4;
      if (_buffer.length < bodyStart + contentLen) return false;

      final frame = Uint8List.fromList(
        _buffer.sublist(bodyStart, bodyStart + contentLen),
      );
      var consumed = bodyStart + contentLen;
      if (consumed + 1 < _buffer.length &&
          _buffer[consumed] == 13 &&
          _buffer[consumed + 1] == 10) {
        consumed += 2;
      }
      _buffer.removeRange(0, consumed);

      if (frame.length >= 2 && frame[0] == 0xFF && frame[1] == 0xD8) {
        _pendingFrame = frame;
        _scheduleFrameFlush();
        return true;
      }
    }

    return false;
  }

  void _armFirstFrameWatchdog(String streamUrl) {
    _cancelFirstFrameWatchdog();
    _firstFrameWatchdog = Timer(const Duration(seconds: 4), () {
      unawaited(_switchToSnapshotAfterStream(streamUrl));
    });
  }

  /// ESP32 WebServer: chỉ 1 HTTP client — phải đóng /stream trước khi poll /capture.
  Future<void> _switchToSnapshotAfterStream(String streamUrl) async {
    if (!mounted || _frameNotifier.value != null || _snapshotMode) return;
    final snapUrl = widget.snapshotFallbackUrl?.trim().isNotEmpty == true
        ? widget.snapshotFallbackUrl!.trim()
        : _resolveSnapshotUrl(streamUrl);
    debugPrint('MjpegHttpPlayer: chuyển sang $snapUrl (đóng stream trước)');
    _snapshotMode = true;
    _urlIndex = _urls.length;
    _teardownStream();
    _buffer.clear();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _snapshotFailCount = 0;
    if (mounted) {
      setState(() {
        _error = null;
        _connecting = true;
      });
    }
    _startSnapshotPolling(snapUrl);
  }

  void _cancelFirstFrameWatchdog() {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
  }

  String _resolveSnapshotUrl([String? streamUrl]) {
    final explicit = widget.snapshotFallbackUrl;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }

    final raw = (streamUrl ?? widget.streamUrl).trim();
    if (raw.isEmpty) return raw;

    final uri = Uri.parse(raw);
    if (uri.path.endsWith('/stream')) {
      final path = uri.path.substring(0, uri.path.length - '/stream'.length);
      return uri.replace(path: '$path/capture').toString();
    }
    if (uri.path == '/' || uri.path.isEmpty) {
      return uri.replace(path: '/capture').toString();
    }
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/capture';
  }

  void _fail(String message) {
    if (!mounted) return;
    if (!_snapshotMode && _urlIndex + 1 < _urls.length) {
      _urlIndex++;
      _teardownStream();
      unawaited(_startStream());
      return;
    }
    final fallback = widget.snapshotFallbackUrl;
    if (fallback != null && fallback.isNotEmpty && !_snapshotMode) {
      unawaited(_switchToSnapshotAfterStream(
        _activeUrl ?? widget.streamUrl,
      ));
      return;
    }
    setState(() {
      _error = message;
      _connecting = false;
    });
  }

  void _startSnapshotPolling([String? url]) {
    final target = url ?? widget.snapshotFallbackUrl ?? widget.streamUrl;
    final intervalMs =
        (1000 / widget.maxFps.clamp(2, 6)).round().clamp(500, 800);
    _snapshotTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => unawaited(_fetchSnapshot(target)),
    );
    unawaited(_fetchSnapshot(target));
    if (mounted) setState(() => _connecting = false);
  }

  Future<void> _fetchSnapshot(String baseUrl) async {
    if (!mounted || !_snapshotMode || _streamActive) return;
    if (_snapshotBusy) return;
    _snapshotBusy = true;
    try {
      final base = Uri.parse(baseUrl);
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          '_': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      final bytes = await fetchJpegUrl(uri.toString());
      if (!mounted || !_snapshotMode) return;
      if (bytes != null) {
        _pendingFrame = bytes;
        _scheduleFrameFlush();
        _snapshotFailCount = 0;
        return;
      }
      _snapshotFailCount++;
      if (_snapshotFailCount >= 6 && _frameNotifier.value == null) {
        setState(() {
          _error =
              'Không lấy được ảnh từ $baseUrl — kiểm tra ESP32 (một client/lần)';
          _connecting = false;
        });
      }
    } finally {
      _snapshotBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
                isAntiAlias: false,
                errorBuilder: (_, error, __) {
                  debugPrint('MjpegHttpPlayer decode error: $error');
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
        if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_outlined,
                    color: DashboardColors.risk,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không kết nối được stream',
                    style: GoogleFonts.notoSans(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeUrl ?? widget.streamUrl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (_urls.length > 1)
                    Text(
                      'Đã thử ${_urlIndex + 1}/${_urls.length} URL',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  if (widget.ipAddress != null)
                    Text(
                      'IP: ${widget.ipAddress}',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.cyan,
                        fontSize: 12,
                      ),
                    ),
                ],
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
              widget.ipAddress ?? widget.streamUrl,
              style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
