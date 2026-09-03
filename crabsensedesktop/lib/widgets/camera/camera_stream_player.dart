import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../theme/dashboard_theme.dart';
import 'http_page_camera_player.dart';
import 'mjpeg_http_player.dart';

/// Phát stream camera: HTTP MJPEG → [MjpegHttpPlayer], RTSP → media_kit.
class CameraStreamPlayer extends StatelessWidget {
  const CameraStreamPlayer({
    super.key,
    required this.streamUrl,
    this.ipAddress,
    this.snapshotFallbackUrl,
    this.streamUrlCandidates,
    this.maxFps = 10,
    this.snapshotOnly = false,
    this.htmlPageMode = false,
    this.pollMinMs = 3500,
  });

  final String streamUrl;
  final String? ipAddress;
  final String? snapshotFallbackUrl;
  final List<String>? streamUrlCandidates;
  final int maxFps;
  final bool snapshotOnly;
  final bool htmlPageMode;
  final int pollMinMs;

  bool get _useMediaKit {
    final lower = streamUrl.toLowerCase();
    return lower.startsWith('rtsp://') ||
        lower.startsWith('rtmp://') ||
        lower.startsWith('udp://');
  }

  @override
  Widget build(BuildContext context) {
    if (_useMediaKit) {
      return _MediaKitStreamPlayer(
        streamUrl: streamUrl,
        ipAddress: ipAddress,
      );
    }
    if (htmlPageMode) {
      return HttpPageCameraPlayer(
        pageUrl: streamUrl,
        ipAddress: ipAddress,
        maxFps: maxFps,
        pollMinMs: pollMinMs,
      );
    }
    return MjpegHttpPlayer(
      streamUrl: streamUrl,
      ipAddress: ipAddress,
      snapshotFallbackUrl: snapshotFallbackUrl,
      streamUrlCandidates: streamUrlCandidates,
      maxFps: maxFps,
      snapshotOnly: snapshotOnly,
    );
  }
}

class _MediaKitStreamPlayer extends StatefulWidget {
  const _MediaKitStreamPlayer({
    required this.streamUrl,
    this.ipAddress,
  });

  final String streamUrl;
  final String? ipAddress;

  @override
  State<_MediaKitStreamPlayer> createState() => _MediaKitStreamPlayerState();
}

class _MediaKitStreamPlayerState extends State<_MediaKitStreamPlayer> {
  late final Player _player;
  late final VideoController _controller;
  var _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.stream.error.listen((e) {
      if (!mounted || e == null) return;
      setState(() => _error = e.toString());
    });
    _player.stream.buffering.listen((buffering) {
      if (!mounted || buffering) return;
      if (!_ready) setState(() => _ready = true);
    });
    _open();
  }

  Future<void> _open() async {
    try {
      await _player.open(Media(widget.streamUrl), play: true);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_error == null)
          Video(
            controller: _controller,
            fit: BoxFit.cover,
            controls: NoVideoControls,
          )
        else
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
                    widget.streamUrl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
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
        if (!_ready && _error == null)
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
