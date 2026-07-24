import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';

// Palette đồng bộ với header: xanh dương (azure) trên nền navy đậm.
const Color _kBlue = Color(0xFF2F80FF);
const Color _kBlueLight = Color(0xFF6FB0FF);
const Color _kCyan = Color(0xFF3DDCFF);
const Color _kNavyDeep = Color(0xFF081A36);
const Color _kNavy = Color(0xFF0C2348);
const Color _kNavyLift = Color(0xFF123061);
const Color _kBorderBlue = Color(0xFF3E6FB8);

class FarmOverviewHeroCard extends StatelessWidget {
  const FarmOverviewHeroCard({required this.summary, super.key});

  final FarmSummary summary;

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    return '${diff.inHours} giờ trước';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNavyLift, _kNavy, _kNavyDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _kBorderBlue.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Họa tiết lưới khay nuôi + cua (giống bộ chọn khu) làm nền
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: _kBlueLight.withValues(alpha: 0.1),
                  trayExtent: 26,
                ),
              ),
            ),
          ),
          // Vệt sáng nhẹ ở cạnh trên
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            height: 1,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kBlueLight.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TỔNG QUAN VẬN HÀNH',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _kBlueLight,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 13,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Cập nhật: ${_formatTime(summary.lastUpdated)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CrabSenseColors.hintText,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: 6),
                    // Cua mini (họa tiết thương hiệu)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(
                        painter: _CrabSketchPainter(
                          color: _kCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatTile(
                      iconColor: _kBlue,
                      iconBuilder: (color) => Icon(
                        Icons.grid_view_rounded,
                        size: 22,
                        color: color,
                      ),
                      label: 'Tổng Hộp\nNuôi',
                      value: '${summary.totalBoxes}',
                    ),
                    _vDivider(),
                    _StatTile(
                      iconColor: _kCyan,
                      // Icon cua vẽ tay cho "Số Cua Đang Nuôi"
                      iconBuilder: (color) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: CustomPaint(
                          painter: _CrabSketchPainter(color: color),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      label: 'Số Cua Đang\nNuôi',
                      value: '${summary.totalCrabs}',
                    ),
                    _vDivider(),
                    _StatTile(
                      iconColor: summary.openAlerts > 0
                          ? CrabSenseColors.warning
                          : CrabSenseColors.success,
                      iconBuilder: (color) => Icon(
                        Icons.warning_amber_rounded,
                        size: 22,
                        color: color,
                      ),
                      label: 'Cảnh Báo\nMở',
                      value: '${summary.openAlerts}',
                    ),
                    _vDivider(),
                    _StatTile(
                      iconColor: summary.iotOnlinePercentage >= 90
                          ? CrabSenseColors.success
                          : const Color(0xFF35E08A),
                      iconBuilder: (color) => Icon(
                        Icons.wifi_tethering_rounded,
                        size: 22,
                        color: color,
                      ),
                      label: 'IoT\nOnline',
                      value:
                          '${summary.iotOnlinePercentage.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      height: 76,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _kBorderBlue.withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.iconColor,
    required this.iconBuilder,
    required this.label,
    required this.value,
  });

  final Color iconColor;
  final Widget Function(Color color) iconBuilder;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: Center(child: iconBuilder(iconColor)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.05,
              fontSize: 24,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: CrabSenseColors.textSecondary,
              fontSize: 10,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Cua wireframe nhìn từ trên xuống (mai + càng + chân), tự co giãn theo
/// vùng vẽ. Dùng làm watermark nền lẫn icon mini.
class _CrabSketchPainter extends CustomPainter {
  const _CrabSketchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide * 0.52;
    final c = Offset(size.width * 0.5, size.height * 0.52);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.045).clamp(0.8, 1.4).toDouble()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final glow = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.1).clamp(1.6, 3.0).toDouble()
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..isAntiAlias = true;

    final r = (s * 0.05).clamp(0.5, 1.6).toDouble();

    // Mai cua (bát giác)
    final shell = <Offset>[
      Offset(c.dx, c.dy - s * 0.32),
      Offset(c.dx + s * 0.28, c.dy - s * 0.18),
      Offset(c.dx + s * 0.42, c.dy),
      Offset(c.dx + s * 0.28, c.dy + s * 0.22),
      Offset(c.dx, c.dy + s * 0.35),
      Offset(c.dx - s * 0.28, c.dy + s * 0.22),
      Offset(c.dx - s * 0.42, c.dy),
      Offset(c.dx - s * 0.28, c.dy - s * 0.18),
    ];
    final shellPath = Path()..moveTo(shell[0].dx, shell[0].dy);
    for (var i = 1; i < shell.length; i++) {
      shellPath.lineTo(shell[i].dx, shell[i].dy);
    }
    shellPath.close();
    canvas.drawPath(shellPath, glow);
    canvas.drawPath(shellPath, stroke);
    canvas.drawLine(
      Offset(c.dx, c.dy - s * 0.28),
      Offset(c.dx, c.dy + s * 0.32),
      stroke,
    );
    canvas.drawLine(
      Offset(c.dx - s * 0.35, c.dy),
      Offset(c.dx + s * 0.35, c.dy),
      stroke,
    );

    // Mắt
    for (final side in [-1.0, 1.0]) {
      final tip = Offset(c.dx + side * s * 0.16, c.dy - s * 0.42);
      canvas.drawLine(
        Offset(c.dx + side * s * 0.12, c.dy - s * 0.22),
        tip,
        stroke,
      );
      _dot(canvas, tip, stroke, r);
    }

    // Càng
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(c.dx + side * s * 0.4, c.dy - s * 0.05);
      final elbow = Offset(c.dx + side * s * 0.72, c.dy - s * 0.28);
      final tipA = Offset(c.dx + side * s * 0.95, c.dy - s * 0.48);
      final tipB = Offset(c.dx + side * s * 0.88, c.dy - s * 0.18);
      canvas.drawLine(shoulder, elbow, glow);
      canvas.drawLine(shoulder, elbow, stroke);
      canvas.drawLine(elbow, tipA, stroke);
      canvas.drawLine(elbow, tipB, stroke);
      _dot(canvas, shoulder, stroke, r);
      _dot(canvas, elbow, stroke, r);
      _dot(canvas, tipA, stroke, r);
      _dot(canvas, tipB, stroke, r);
    }

    // Chân
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final base = Offset(
          c.dx + side * s * 0.38,
          c.dy + s * (-0.02 + i * 0.16),
        );
        final mid = Offset(
          c.dx + side * s * (0.7 + i * 0.04),
          c.dy + s * (0.12 + i * 0.14),
        );
        final tip = Offset(
          c.dx + side * s * (0.95 + i * 0.06),
          c.dy + s * (0.28 + i * 0.1),
        );
        canvas.drawLine(base, mid, stroke);
        canvas.drawLine(mid, tip, stroke);
        _dot(canvas, mid, stroke, r);
        _dot(canvas, tip, stroke, r);
      }
    }

    for (final p in shell) {
      _dot(canvas, p, stroke, r);
    }
    _dot(canvas, c, stroke, r);
  }

  void _dot(Canvas canvas, Offset p, Paint stroke, double r) {
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CrabSketchPainter oldDelegate) =>
      oldDelegate.color != color;
}
