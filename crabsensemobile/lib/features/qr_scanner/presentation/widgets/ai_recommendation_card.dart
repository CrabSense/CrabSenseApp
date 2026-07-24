import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
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
      decoration: homeCardDecoration(accent: kHomePurple, radius: 16, glowAlpha: 0.14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HomeCrabWatermark(alpha: 0.05, trayExtent: 22),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: kHomePurple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GỢI Ý AI',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: kHomeBlueLight,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                    if (conf != null)
                      Text(
                        '${conf.round()}%',
                        style: const TextStyle(
                          color: kHomeCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result.aiRecommendation!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onViewAnalysis,
                  style: TextButton.styleFrom(
                    foregroundColor: kHomeCyan,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Xem phân tích'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
