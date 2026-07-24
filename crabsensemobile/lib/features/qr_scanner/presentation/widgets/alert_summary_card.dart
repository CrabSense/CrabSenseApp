import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/scan_quick_result.dart';

class AlertSummaryCard extends StatelessWidget {
  const AlertSummaryCard({required this.alerts, super.key});

  final List<ScanAlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cảnh báo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: alerts.map((a) {
            final color = _color(a.severity);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.45)),
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      a.title,
                      style: TextStyle(
                        color: CrabSenseColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _color(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return CrabSenseColors.danger;
      case 'medium':
      case 'warning':
        return CrabSenseColors.warning;
      default:
        return CrabSenseColors.info;
    }
  }
}
