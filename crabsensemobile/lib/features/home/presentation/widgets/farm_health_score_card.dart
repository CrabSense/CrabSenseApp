import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

/// Farm Health Score Card — Light theme rebuild.
class FarmHealthScoreCard extends StatelessWidget {
  const FarmHealthScoreCard({
    required this.healthScore,
    required this.onAnalysisPressed,
    super.key,
  });

  final FarmHealthScore healthScore;
  final VoidCallback onAnalysisPressed;

  Color _statusColor(HealthStatusLevel level) {
    switch (level) {
      case HealthStatusLevel.excellent:
        return kHomePrimary;
      case HealthStatusLevel.good:
        return kHomeSecondary;
      case HealthStatusLevel.warning:
        return kHomeWarning;
      case HealthStatusLevel.danger:
        return kHomeDanger;
    }
  }

  String _statusBadgeLabel(HealthStatusLevel level) {
    switch (level) {
      case HealthStatusLevel.excellent:
      case HealthStatusLevel.good:
        return 'Tốt';
      case HealthStatusLevel.warning:
        return 'Cần chú ý';
      case HealthStatusLevel.danger:
        return 'Nguy hiểm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(healthScore.statusLevel);
    final delta = healthScore.deltaVsYesterday;
    final deltaPositive = delta >= 0;
    final deltaColor = deltaPositive ? kHomePrimary : kHomeDanger;

    return Container(
      decoration: homeCardDecoration(),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kHomePrimaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: kHomePrimary, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Điểm sức khỏe trang trại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kHomeTextMain,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onAnalysisPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: kHomePrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Xem phân tích',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: kHomeBorder),
          ),
          const SizedBox(height: 16),

          // Score gauge + explanation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular score gauge
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: _GaugePainter(
                          progress: (healthScore.score / 100.0).clamp(0.0, 1.0),
                          color: statusColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${healthScore.score}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              height: 1,
                            ),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kHomeTextSub,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              _statusBadgeLabel(healthScore.statusLevel),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Explanation + delta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        healthScore.explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kHomeTextSub,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // AI recommendations
                      const Text(
                        'AI gợi ý hôm nay:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kHomeTextMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _AiSuggestion(
                        text: 'Kiểm tra độ pH ao nuôi',
                        icon: Icons.science_rounded,
                        color: kHomeSecondary,
                      ),
                      const SizedBox(height: 3),
                      _AiSuggestion(
                        text: 'Theo dõi cua chuẩn bị lột',
                        icon: Icons.notifications_active_rounded,
                        color: kHomeWarning,
                      ),
                      const SizedBox(height: 8),
                      // Delta
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
                            '${deltaPositive ? '+' : ''}${delta.toStringAsFixed(0)}% so với hôm qua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: deltaColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Sub-score cards
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                _FactorCard(
                  icon: Icons.water_drop_rounded,
                  title: 'Chất lượng nước',
                  score: healthScore.waterQualityScore,
                  color: kHomeSecondary,
                ),
                const SizedBox(width: 8),
                _FactorCard(
                  icon: Icons.favorite_rounded,
                  title: 'Sức khỏe cua',
                  score: healthScore.crabHealthScore,
                  color: kHomePrimary,
                ),
                const SizedBox(width: 8),
                _FactorCard(
                  icon: Icons.memory_rounded,
                  title: 'Thiết bị',
                  score: healthScore.deviceStatusScore,
                  color: kHomePurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestion extends StatelessWidget {
  const _AiSuggestion({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: kHomeTextSub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: kHomeTextSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: kHomeBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = 3 * math.pi / 4;
    const totalSweep = 3 * math.pi / 2;

    // Track
    canvas.drawArc(
      rect,
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = kHomeBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    canvas.drawArc(
      rect,
      startAngle,
      totalSweep * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}
