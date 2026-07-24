import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/alerts_models.dart';

class AIRecommendedActionCard extends StatelessWidget {
  const AIRecommendedActionCard({
    required this.recommendation,
    this.compact = false,
    this.onExecute,
    this.onGuide,
    this.onAssign,
    this.onSkip,
    this.onSnooze,
    super.key,
  });

  final AIRecommendedAction recommendation;
  final bool compact;
  final VoidCallback? onExecute;
  final VoidCallback? onGuide;
  final VoidCallback? onAssign;
  final VoidCallback? onSkip;
  final VoidCallback? onSnooze;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: CrabSenseColors.glassGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CrabSenseColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: CrabSenseColors.accent,
              ),
              const SizedBox(width: 6),
              const Text(
                'AI Recommendation',
                style: TextStyle(
                  color: CrabSenseColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${recommendation.confidence}%',
                style: const TextStyle(
                  color: CrabSenseColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.action,
            style: TextStyle(
              color: CrabSenseColors.textPrimary,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            _line('Lý do', recommendation.reason),
            _line('Thời hạn', recommendation.deadline),
            _line('Tác động', recommendation.expectedImpact),
            _line('Kiểm tra lại', recommendation.recheckCondition),
            if (onExecute != null || onGuide != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onExecute != null)
                    FilledButton(
                      onPressed: onExecute,
                      style: FilledButton.styleFrom(
                        backgroundColor: CrabSenseColors.primary,
                        foregroundColor: CrabSenseColors.background,
                        minimumSize: const Size(48, 40),
                      ),
                      child: const Text('Thực hiện ngay'),
                    ),
                  if (onGuide != null)
                    OutlinedButton(
                      onPressed: onGuide,
                      child: const Text('Xem hướng dẫn'),
                    ),
                  if (onAssign != null)
                    OutlinedButton(
                      onPressed: onAssign,
                      child: const Text('Giao nhân viên'),
                    ),
                  if (onSkip != null)
                    TextButton(onPressed: onSkip, child: const Text('Bỏ qua')),
                  if (onSnooze != null)
                    TextButton(
                      onPressed: onSnooze,
                      child: const Text('Nhắc lại sau'),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: CrabSenseColors.hintText,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
