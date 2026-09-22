import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/harvest.dart';
import '../../domain/entities/harvest_summary.dart';

/// Widget displaying weekly/monthly harvest summary statistics and weekly cumulative weight per farm.
///
/// Requirements: 11.9, 11.10
class HarvestSummaryCard extends StatelessWidget {
  const HarvestSummaryCard({
    required this.summary,
    required this.weeklyCumulativeWeights,
    super.key,
  });

  final HarvestSummary summary;
  final Map<String, double> weeklyCumulativeWeights;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final periodText =
        '${dateFormat.format(summary.startDate)} - ${dateFormat.format(summary.endDate)}';

    return Container(
      decoration: BoxDecoration(
        color: CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CrabSenseColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Period Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: CrabSenseColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    summary.farmName ?? summary.farmId,
                    style: const TextStyle(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CrabSenseColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CrabSenseColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  periodText,
                  style: const TextStyle(
                    color: CrabSenseColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // KPI Grid (2x2)
          Row(
            children: [
              Expanded(
                child: _buildKpiTile(
                  label: 'Total Weight',
                  value: '${summary.totalWeight.toStringAsFixed(1)} kg',
                  icon: Icons.scale_rounded,
                  color: CrabSenseColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  label: 'Total Crabs',
                  value: '${summary.totalCrabCount}',
                  icon: Icons.pest_control_rounded,
                  color: CrabSenseColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiTile(
                  label: 'Harvest Operations',
                  value: '${summary.totalHarvestsCount}',
                  icon: Icons.inventory_2_rounded,
                  color: CrabSenseColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  label: 'Avg Crab Weight',
                  value: '${summary.averageWeightPerCrab.toStringAsFixed(2)} kg',
                  icon: Icons.line_weight_rounded,
                  color: CrabSenseColors.warning,
                ),
              ),
            ],
          ),

          // Weekly Cumulative Harvest Weight Section (Requirement 11.10)
          if (weeklyCumulativeWeights.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: CrabSenseColors.border),
            const SizedBox(height: 12),
            const Text(
              'Weekly Cumulative Weight (Requirement 11.10)',
              style: TextStyle(
                color: CrabSenseColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: weeklyCumulativeWeights.entries.map((entry) {
                final maxWeight = weeklyCumulativeWeights.values.fold(0.1, (prev, curr) => curr > prev ? curr : prev);
                final ratio = (entry.value / maxWeight).clamp(0.05, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: CrabSenseColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: CrabSenseColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: CrabSenseColors.background,
                          valueColor: const AlwaysStoppedAnimation<Color>(CrabSenseColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Quality Grade Breakdown Section
          if (summary.gradeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: CrabSenseColors.border),
            const SizedBox(height: 12),
            const Text(
              'Quality Grade Breakdown',
              style: TextStyle(
                color: CrabSenseColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.gradeBreakdown.entries.map((entry) {
                final color = _getGradeColor(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key.displayName}: ${entry.value.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(QualityGrade grade) {
    switch (grade) {
      case QualityGrade.gradeA:
        return CrabSenseColors.success;
      case QualityGrade.gradeB:
        return CrabSenseColors.primary;
      case QualityGrade.gradeC:
        return CrabSenseColors.warning;
    }
  }
}
