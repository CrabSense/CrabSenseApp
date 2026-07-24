import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';

// Palette đồng bộ với header + tổng quan vận hành.
const Color _kBlue = Color(0xFF2F80FF);
const Color _kBlueLight = Color(0xFF6FB0FF);
const Color _kNavyDeep = Color(0xFF081A36);
const Color _kNavy = Color(0xFF0C2348);
const Color _kNavyLift = Color(0xFF123061);
const Color _kBorderBlue = Color(0xFF3E6FB8);
const Color _kGreen = Color(0xFF2ECC71);
const Color _kPurple = Color(0xFF8B5CF6);

class FarmHealthScoreCard extends StatelessWidget {
  const FarmHealthScoreCard({
    required this.healthScore,
    required this.onAnalysisPressed,
    super.key,
  });

  final FarmHealthScore healthScore;
  final VoidCallback onAnalysisPressed;

  Color _getStatusColor(HealthStatusLevel level) {
    switch (level) {
      case HealthStatusLevel.excellent:
        return CrabSenseColors.success;
      case HealthStatusLevel.good:
        return CrabSenseColors.info;
      case HealthStatusLevel.warning:
        return CrabSenseColors.warning;
      case HealthStatusLevel.danger:
        return CrabSenseColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(healthScore.statusLevel);
    final delta = healthScore.deltaVsYesterday;
    final deltaPositive = delta >= 0;
    final deltaColor =
        deltaPositive ? _kGreen : CrabSenseColors.danger;

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
          // Vệt sáng nhẹ cạnh trên
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
          // Họa tiết lưới khay nuôi + cua (giống header và tổng quan)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: _kBlueLight.withValues(alpha: 0.09),
                  trayExtent: 26,
                ),
              ),
            ),
          ),
          // Cua chibi lớn mờ trang trí góc phải dưới
          Positioned(
            right: -8,
            bottom: -12,
            width: 130,
            height: 130,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.16,
                child: Transform.rotate(
                  angle: -0.22,
                  child: const CustomPaint(
                    painter: _ChibiCrabPainter(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'FARM HEALTH SCORE',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                      fontSize: 15,
                                    ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Cua chibi nhỏ cạnh tiêu đề
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CustomPaint(
                              painter: _ChibiCrabPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onAnalysisPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: _kBlueLight,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_rounded, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Xem phân tích',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nhịp tim ECG bên trái gauge
                    SizedBox(
                      width: 24,
                      height: 44,
                      child: CustomPaint(
                        painter: _EcgPainter(
                          color: statusColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    // Gauge tròn với điểm số ở giữa
                    SizedBox(
                      width: 152,
                      height: 152,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(152, 152),
                            painter: _RoundGaugePainter(
                              progress: (healthScore.score / 100.0)
                                  .clamp(0.0, 1.0),
                              color: statusColor,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${healthScore.score}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  height: 1,
                                  fontSize: 40,
                                  shadows: [
                                    Shadow(
                                      color: statusColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '/100',
                                style: TextStyle(
                                  color: CrabSenseColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withValues(alpha: 0.14),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor
                                        .withValues(alpha: 0.85),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  healthScore.statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Panel giải thích + delta
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kNavyDeep.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _kBorderBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              healthScore.explanation,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.4,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  deltaPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  size: 16,
                                  color: deltaColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${deltaPositive ? '+' : ''}${delta.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: deltaColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _FactorCard(
                      icon: Icons.water_drop_rounded,
                      title: 'Chất lượng nước',
                      score: healthScore.waterQualityScore,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 10),
                    _FactorCard(
                      icon: Icons.favorite_rounded,
                      title: 'Sức khỏe cua',
                      score: healthScore.crabHealthScore,
                      color: _kGreen,
                    ),
                    const SizedBox(width: 10),
                    _FactorCard(
                      icon: Icons.settings_rounded,
                      title: 'Thiết bị',
                      score: healthScore.deviceStatusScore,
                      color: _kPurple,
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
}

/// Thẻ chỉ số con: icon tròn màu riêng + số trắng lớn + progress bar màu.
class _FactorCard extends StatelessWidget {
  const _FactorCard({
    required this.icon,
    required this.title,
    required this.score,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          color: _kNavyDeep.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _kBorderBlue.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Co chữ khi hẹp thay vì cắt bớt bằng "..."
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  color: CrabSenseColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: _kNavyLift,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gauge tròn hở đáy (~270°) với gradient màu trạng thái → cam và glow.
class _RoundGaugePainter extends CustomPainter {
  _RoundGaugePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 13.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Hở ở đáy: bắt đầu 135°, quét 270°
    const startAngle = 3 * math.pi / 4;
    const totalSweep = 3 * math.pi / 2;

    final trackPaint = Paint()
      ..color = _kNavyLift
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweep, false, trackPaint);

    if (progress <= 0) {
      return;
    }

    final sweep = totalSweep * progress;
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + totalSweep,
      colors: [
        color.withValues(alpha: 0.75),
        color,
        const Color(0xFFFFA53E),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(0),
    ).createShader(rect);

    // Glow phía sau vòng tiến trình
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RoundGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Cua chibi dễ thương: thân tròn cam đỏ, mắt to, má hồng, miệng cười,
/// hai càng giơ lên và chân ngắn. Tự co giãn theo vùng vẽ.
class _ChibiCrabPainter extends CustomPainter {
  const _ChibiCrabPainter();

  static const Color _body = Color(0xFFFF5E62);
  static const Color _bodyLight = Color(0xFFFF9A76);
  static const Color _outline = Color(0xFFB03A48);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height * 0.56;

    final outline = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.035).clamp(0.8, 3.0).toDouble()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final bodyFill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        colors: [_bodyLight, _body],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: s * 0.34),
      )
      ..isAntiAlias = true;

    final solidFill = Paint()
      ..color = _body
      ..isAntiAlias = true;

    // Chân ngắn hai bên (vẽ trước để nằm sau thân)
    final legPaint = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.045).clamp(1.0, 4.0).toDouble()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final start = Offset(
          cx + side * s * 0.26,
          cy + s * (0.04 + i * 0.09),
        );
        final end = Offset(
          cx + side * s * (0.40 + i * 0.015),
          cy + s * (0.13 + i * 0.10),
        );
        canvas.drawLine(start, end, legPaint);
      }
    }

    // Càng: cánh tay + kẹp tròn giơ lên hai bên
    for (final side in [-1.0, 1.0]) {
      final armStart = Offset(cx + side * s * 0.24, cy - s * 0.06);
      final armEnd = Offset(cx + side * s * 0.40, cy - s * 0.26);
      canvas.drawLine(armStart, armEnd, legPaint);

      final clawCenter = Offset(cx + side * s * 0.42, cy - s * 0.30);
      final clawR = s * 0.115;
      canvas.drawCircle(clawCenter, clawR, solidFill);
      canvas.drawCircle(clawCenter, clawR, outline);
      // Khe kẹp chữ V
      final notch = Path()
        ..moveTo(
          clawCenter.dx + side * clawR * 0.2,
          clawCenter.dy - clawR * 1.05,
        )
        ..lineTo(clawCenter.dx, clawCenter.dy - clawR * 0.15)
        ..lineTo(
          clawCenter.dx + side * clawR * 1.05,
          clawCenter.dy - clawR * 0.25,
        );
      canvas.drawPath(notch, outline);
    }

    // Thân tròn bầu bĩnh
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: s * 0.62,
      height: s * 0.5,
    );
    canvas.drawOval(bodyRect, bodyFill);
    canvas.drawOval(bodyRect, outline);

    // Mắt to chibi
    final eyeR = s * 0.085;
    for (final side in [-1.0, 1.0]) {
      final eyeC = Offset(cx + side * s * 0.11, cy - s * 0.07);
      canvas.drawCircle(eyeC, eyeR, Paint()..color = Colors.white);
      canvas.drawCircle(
        eyeC,
        eyeR * 0.55,
        Paint()..color = const Color(0xFF1B2A4A),
      );
      canvas.drawCircle(
        Offset(eyeC.dx - eyeR * 0.25, eyeC.dy - eyeR * 0.28),
        eyeR * 0.2,
        Paint()..color = Colors.white,
      );
    }

    // Má hồng
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + side * s * 0.20, cy + s * 0.02),
        s * 0.045,
        Paint()..color = const Color(0xFFFFB3C1).withValues(alpha: 0.85),
      );
    }

    // Miệng cười nhỏ
    final smile = Path()
      ..moveTo(cx - s * 0.05, cy + s * 0.06)
      ..quadraticBezierTo(
        cx,
        cy + s * 0.11,
        cx + s * 0.05,
        cy + s * 0.06,
      );
    canvas.drawPath(smile, outline);
  }

  @override
  bool shouldRepaint(covariant _ChibiCrabPainter oldDelegate) => false;
}

/// Đường nhịp tim ECG nhỏ cạnh gauge.
class _EcgPainter extends CustomPainter {
  const _EcgPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final path = Path()
      ..moveTo(0, midY)
      ..lineTo(size.width * 0.2, midY)
      ..lineTo(size.width * 0.35, midY - size.height * 0.32)
      ..lineTo(size.width * 0.55, midY + size.height * 0.42)
      ..lineTo(size.width * 0.7, midY - size.height * 0.12)
      ..lineTo(size.width * 0.8, midY)
      ..lineTo(size.width, midY);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: color.a * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) =>
      oldDelegate.color != color;
}
