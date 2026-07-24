import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/boxes_models.dart';

class FarmOverviewSummary extends StatelessWidget {
  const FarmOverviewSummary({
    required this.overview,
    this.onStatusTap,
    super.key,
  });

  final FarmBoxesOverview overview;
  final ValueChanged<BoxQuickFilter>? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final total = overview.total == 0 ? 1 : overview.total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.border),
        gradient: CrabSenseColors.glassGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Stat(
                label: 'Total',
                value: overview.total,
                color: CrabSenseColors.primary,
                onTap: () => onStatusTap?.call(BoxQuickFilter.all),
              ),
              _Stat(
                label: 'Healthy',
                value: overview.healthy,
                color: CrabSenseColors.success,
                onTap: () => onStatusTap?.call(BoxQuickFilter.healthy),
              ),
              _Stat(
                label: 'Warning',
                value: overview.warning,
                color: CrabSenseColors.warning,
                onTap: () => onStatusTap?.call(BoxQuickFilter.warning),
              ),
              _Stat(
                label: 'Critical',
                value: overview.critical,
                color: CrabSenseColors.danger,
                onTap: () => onStatusTap?.call(BoxQuickFilter.critical),
              ),
              _Stat(
                label: 'Offline',
                value: overview.offline,
                color: CrabSenseColors.hintText,
                onTap: () => onStatusTap?.call(BoxQuickFilter.offline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: overview.healthy,
                    child: Container(color: CrabSenseColors.success),
                  ),
                  Expanded(
                    flex: overview.warning,
                    child: Container(color: CrabSenseColors.warning),
                  ),
                  Expanded(
                    flex: overview.critical,
                    child: Container(color: CrabSenseColors.danger),
                  ),
                  Expanded(
                    flex: overview.offline,
                    child: Container(color: CrabSenseColors.hintText),
                  ),
                  if (overview.total == 0)
                    const Expanded(
                      child: ColoredBox(color: CrabSenseColors.container),
                    ),
                ],
              ),
            ),
          ),
          if (overview.withAiRecommendation > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: CrabSenseColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  '${overview.withAiRecommendation} Box có đề xuất AI',
                  style: const TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${((overview.healthy / total) * 100).round()}% healthy',
                  style: const TextStyle(
                    color: CrabSenseColors.hintText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: CrabSenseColors.hintText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
