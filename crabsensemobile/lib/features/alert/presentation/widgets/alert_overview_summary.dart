import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/alerts_models.dart';

class AlertOverviewSummary extends StatelessWidget {
  const AlertOverviewSummary({
    required this.summary,
    this.onTapSeverity,
    super.key,
  });

  final AlertSeveritySummary summary;
  final ValueChanged<AlertQuickFilter>? onTapSeverity;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Critical',
        value: summary.critical,
        color: CrabSenseColors.danger,
        filter: AlertQuickFilter.critical,
      ),
      _SummaryItem(
        label: 'High',
        value: summary.high,
        color: CrabSenseColors.warning,
        filter: AlertQuickFilter.high,
      ),
      _SummaryItem(
        label: 'Medium',
        value: summary.medium,
        color: CrabSenseColors.info,
        filter: null,
      ),
      _SummaryItem(
        label: 'Low',
        value: summary.low,
        color: CrabSenseColors.hintText,
        filter: null,
      ),
      _SummaryItem(
        label: 'Ack',
        value: summary.acknowledged,
        color: CrabSenseColors.primary,
        filter: null,
      ),
      _SummaryItem(
        label: 'Resolved',
        value: summary.resolvedToday,
        color: CrabSenseColors.success,
        filter: AlertQuickFilter.resolved,
      ),
    ];

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return Semantics(
            button: item.filter != null,
            label: '${item.label}: ${item.value}',
            child: InkWell(
              onTap: item.filter != null && onTapSeverity != null
                  ? () => onTapSeverity!(item.filter!)
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 86,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CrabSenseColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CrabSenseColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.value}',
                      style: TextStyle(
                        color: item.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: CrabSenseColors.hintText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.filter,
  });

  final String label;
  final int value;
  final Color color;
  final AlertQuickFilter? filter;
}
