import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/dashboard_summary.dart';

/// Displays the [AlertSummary] on the dashboard with colour-coded severity
/// chips and a "View All" button that navigates to `/alerts`.
///
/// Each severity chip shows the count and a colour indicator:
/// - Critical → red   ([CrabSenseColors.error])
/// - Warning  → amber ([CrabSenseColors.warning])
/// - Info     → blue  ([CrabSenseColors.info])
///
/// Requirements: 2.2
class AlertSummaryWidget extends StatelessWidget {
  const AlertSummaryWidget({required this.alertSummary, required this.onViewAll, super.key});

  /// The alert counts to display.
  final AlertSummary alertSummary;

  /// Callback invoked when "View All" is tapped.
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: CrabSenseColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Alerts',
                  style: theme.textTheme.titleMedium?.copyWith(color: CrabSenseColors.textPrimary),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View All'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Total count ───────────────────────────────────────────────
        if (alertSummary.totalActive == 0)
          Text(
            'No active alerts',
            style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
          )
        else ...[
          Text(
            '${alertSummary.totalActive} active alert'
            '${alertSummary.totalActive > 1 ? 's' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
          ),
          const SizedBox(height: 8),

          // ── Severity chips ─────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (alertSummary.criticalCount > 0)
                _SeverityChip(
                  label: '${alertSummary.criticalCount} Critical',
                  color: CrabSenseColors.error,
                  icon: Icons.error_outline,
                ),
              if (alertSummary.warningCount > 0)
                _SeverityChip(
                  label: '${alertSummary.warningCount} Warning',
                  color: CrabSenseColors.warning,
                  icon: Icons.warning_amber_outlined,
                ),
              if (alertSummary.infoCount > 0)
                _SeverityChip(
                  label: '${alertSummary.infoCount} Info',
                  color: CrabSenseColors.info,
                  icon: Icons.info_outline,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Internal chip widget for a single severity level.
class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
