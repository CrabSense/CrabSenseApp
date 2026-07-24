import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/scan_quick_result.dart';

class AIRecommendationCard extends StatelessWidget {
  const AIRecommendationCard({
    required this.result,
    required this.onViewAnalysis,
    super.key,
  });

  final ScanQuickResult result;
  final VoidCallback onViewAnalysis;

  @override
  Widget build(BuildContext context) {
    if (!result.hasAiRecommendation) return const SizedBox.shrink();

    final conf = result.aiConfidence;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: CrabSenseColors.glassGradient,
        border: Border.all(color: CrabSenseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: CrabSenseColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Recommendation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (conf != null)
                Text(
                  '${conf.round()}%',
                  style: const TextStyle(
                    color: CrabSenseColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.aiRecommendation!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CrabSenseColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onViewAnalysis,
            style: TextButton.styleFrom(
              foregroundColor: CrabSenseColors.primary,
              padding: EdgeInsets.zero,
            ),
            child: const Text('Xem phân tích'),
          ),
        ],
      ),
    );
  }
}
