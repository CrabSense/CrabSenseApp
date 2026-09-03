import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/camera_ai.dart';
import '../../services/camera_ai_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';
import 'camera_ai_dialogs.dart';
import 'camera_stream_player.dart';

class CameraLiveFeed extends StatelessWidget {
  const CameraLiveFeed({
    super.key,
    required this.camera,
    this.compact = false,
    this.onTap,
  });

  final CameraFeed camera;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, size) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (!compact &&
                      camera.streamUrl != null &&
                      camera.streamUrl!.isNotEmpty)
                    CameraStreamPlayer(
                      key: ValueKey('live-${camera.id}'),
                      streamUrl: camera.streamUrl!,
                      ipAddress: camera.ipAddress,
                      snapshotFallbackUrl: camera.snapshotFallbackUrl,
                      streamUrlCandidates: camera.streamUrlCandidates,
                      maxFps: camera.maxFps,
                      snapshotOnly: camera.snapshotOnly,
                      htmlPageMode: camera.htmlPageMode,
                      pollMinMs: camera.pollMinMs,
                    )
                  else
                    _FeedBackground(
                      compact: compact,
                      ipAddress: camera.ipAddress,
                    ),
                  for (final box in camera.overlays)
                    Positioned(
                      left: size.maxWidth * box.left,
                      top: size.maxHeight * box.top,
                      width: size.maxWidth * box.width,
                      height: size.maxHeight * box.height,
                      child: _BoundingBoxContent(box: box),
                    ),
                  Positioned(
                top: 10,
                left: 10,
                child: _LiveBadge(camera: camera),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Text(
                  'FPS: ${camera.fps} | Res: ${camera.resolution}',
                  style: GoogleFonts.notoSans(
                    color: Colors.white70,
                    fontSize: compact ? 9 : 10,
                  ),
                ),
              ),
                  if (!compact)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _feedIcon(Icons.fullscreen),
                          const SizedBox(width: 8),
                          _feedIcon(Icons.videocam_outlined),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _feedIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _FeedBackground extends StatelessWidget {
  const _FeedBackground({required this.compact, this.ipAddress});

  final bool compact;
  final String? ipAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D1B4E),
            Color(0xFF1A1035),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _RackPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                compact ? Icons.videocam_outlined : Icons.grid_view,
                size: compact ? 28 : 48,
                color: DashboardColors.purple.withValues(alpha: 0.35),
              ),
              if (compact) ...[
                const SizedBox(height: 6),
                Text(
                  'Chạm để xem live',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 9,
                  ),
                ),
                if (ipAddress != null)
                  Text(
                    ipAddress!,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.cyan.withValues(alpha: 0.8),
                      fontSize: 8,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DashboardColors.purple.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var j = 1; j < 4; j++) {
      final y = size.height * j / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.camera});

  final CameraFeed camera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: camera.status == CameraStatus.online
                  ? DashboardColors.risk
                  : camera.status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            camera.status == CameraStatus.online ? 'LIVE' : camera.status.label,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${camera.name} - ${camera.area}',
            style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _BoundingBoxContent extends StatelessWidget {
  const _BoundingBoxContent({required this.box});

  final AiBoundingBox box;

  /// Khung nhỏ (feed compact / overlay % thấp) không đủ chỗ cho nhãn + viền dạng Column.
  static const _minLabelHeight = 36.0;
  static const _minLabelWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final showLabel = h >= _minLabelHeight && w >= _minLabelWidth;
        final borderWidth = h < 28 ? 1.0 : 2.0;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: box.color, width: borderWidth),
              ),
            ),
            if (showLabel)
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: w,
                    maxHeight: (h * 0.45).clamp(12.0, 22.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  color: box.color.withValues(alpha: 0.85),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${box.label} ${(box.confidence * 100).round()}%',
                      style: GoogleFonts.notoSans(
                        color: box.color == Colors.white
                            ? Colors.black
                            : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AiDetectionPanel extends StatelessWidget {
  const AiDetectionPanel({super.key, required this.counts});

  final List<AiDetectionCount> counts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PHÂN TÍCH AI THỜI GIAN THỰC',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 260 ? 2 : 1;
              final w = (c.maxWidth - 10 * (cols - 1)) / cols;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: counts.map((item) {
                  final highlight = item.type == AiDetectionType.escaped ||
                      item.type == AiDetectionType.abnormal;
                  final borderColor = item.type == AiDetectionType.abnormal
                      ? DashboardColors.risk
                      : item.type == AiDetectionType.escaped
                          ? DashboardColors.molting
                          : DashboardColors.cardBorder;
                  return SizedBox(
                    width: w,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DashboardColors.darkNavy,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: highlight ? borderColor : DashboardColors.cardBorder,
                          width: highlight ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(item.type.icon, size: 16, color: item.type.accentColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.type.label,
                                  style: GoogleFonts.notoSans(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.count}',
                            style: GoogleFonts.notoSans(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CrabAssistantCameraCard extends StatelessWidget {
  const CrabAssistantCameraCard({
    super.key,
    required this.insight,
    required this.recommendation,
  });

  final String insight;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAssistantAvatar(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crab Assistant',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khuyến nghị:',
                  style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  recommendation,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiEventsTable extends StatelessWidget {
  const AiEventsTable({
    super.key,
    required this.events,
    required this.service,
  });

  final List<AiCameraEvent> events;
  final CameraAiService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'DANH SÁCH SỰ KIỆN AI GẦN ĐÂY',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Xem tất cả →',
                  style: GoogleFonts.notoSans(color: DashboardColors.purple, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Không có sự kiện phù hợp bộ lọc',
                  style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                columnSpacing: 20,
                headingTextStyle: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                columns: const [
                  DataColumn(label: Text('THỜI GIAN')),
                  DataColumn(label: Text('CAMERA')),
                  DataColumn(label: Text('HỘP')),
                  DataColumn(label: Text('PHÁT HIỆN')),
                  DataColumn(label: Text('TIN CẬY')),
                  DataColumn(label: Text('MỨC ĐỘ')),
                  DataColumn(label: Text('TRẠNG THÁI')),
                  DataColumn(label: Text('')),
                ],
                rows: events.map((e) => _row(context, e)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _row(BuildContext context, AiCameraEvent e) {
    final confColor = e.level == AiEventLevel.critical
        ? DashboardColors.risk
        : e.level == AiEventLevel.warning
            ? DashboardColors.molting
            : DashboardColors.purple;

    return DataRow(
      cells: [
        DataCell(Text(e.time)),
        DataCell(Text(e.cameraLabel)),
        DataCell(Text(e.boxId, style: GoogleFonts.notoSans(color: DashboardColors.cyan))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(e.detectionType.icon, size: 16, color: e.detectionType.accentColor),
              const SizedBox(width: 6),
              Text(e.detectionType.label, style: GoogleFonts.notoSans(fontSize: 12)),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.confidence,
                    minHeight: 6,
                    backgroundColor: DashboardColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation(confColor),
                  ),
                ),
                Text(
                  '${(e.confidence * 100).round()}%',
                  style: GoogleFonts.notoSans(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        DataCell(_LevelBadge(level: e.level)),
        DataCell(_StatusCell(status: e.status)),
        DataCell(
          IconButton(
            onPressed: () => showAiEventDetailDialog(context, service, e),
            icon: const Icon(Icons.more_horiz, size: 18),
            color: DashboardColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final AiEventLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.label,
        style: GoogleFonts.notoSans(
          color: level.color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.status});

  final AiEventStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AiEventStatus.pending => DashboardColors.monitoring,
      AiEventStatus.viewed => DashboardColors.cyan,
      AiEventStatus.confirmed => DashboardColors.healthy,
      AiEventStatus.falsePositive => DashboardColors.textMuted,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status == AiEventStatus.viewed || status == AiEventStatus.confirmed
              ? Icons.check_circle_outline
              : Icons.circle,
          size: 10,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: GoogleFonts.notoSans(color: color, fontSize: 11),
        ),
      ],
    );
  }
}

class CameraThumbnailStrip extends StatelessWidget {
  const CameraThumbnailStrip({
    super.key,
    required this.cameras,
    required this.onSelect,
  });

  final List<CameraFeed> cameras;
  final ValueChanged<CameraFeed> onSelect;

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < cameras.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${cameras[i].name} - ${cameras[i].area}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                CameraLiveFeed(
                  camera: cameras[i],
                  compact: true,
                  onTap: () => onSelect(cameras[i]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
