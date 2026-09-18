import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';

class BoxStatusBadge extends StatelessWidget {
  const BoxStatusBadge({required this.status, this.compact = false, super.key});

  final BoxStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Semantics(
      label: 'Trạng thái ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji 🟢🟡🟣🔴 giống hệt app desktop.
            Text(status.emoji, style: TextStyle(fontSize: compact ? 10 : 11)),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AIHealthBadge extends StatelessWidget {
  const AIHealthBadge({
    required this.healthScore,
    this.compact = false,
    this.onExplain,
    super.key,
  });

  final BoxHealthScore healthScore;
  final bool compact;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final color = healthScore.scoreColor;
    return Semantics(
      label:
          'Health Score ${healthScore.score}, AI ${healthScore.aiConfidence.round()} phần trăm, xu hướng ${healthScore.trend.label}',
      button: onExplain != null,
      child: InkWell(
        onTap: onExplain,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: kHomeBg.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.85),
                      color.withValues(alpha: 0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '${healthScore.score}',
                  style: TextStyle(
                    color: kHomeTextMain,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: TextStyle(
                        color: const Color(0xFF5A7184),
                        fontSize: compact ? 9 : 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'AI ${healthScore.aiConfidence.round()}%',
                          style: TextStyle(
                            color: const Color(0xFF5A7184),
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          healthScore.trend.icon,
                          size: 14,
                          color: healthScore.trend.color,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            healthScore.trend.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: healthScore.trend.color,
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onExplain != null)
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: const Color(0xFF5A7184),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
