import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
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
        label: 'Nghiêm trọng',
        value: summary.critical,
        color: Colors.redAccent,
        filter: AlertQuickFilter.critical,
      ),
      _SummaryItem(
        label: 'Cao',
        value: summary.high,
        color: kHomeOrange,
        filter: AlertQuickFilter.high,
      ),
      _SummaryItem(
        label: 'Trung bình',
        value: summary.medium,
        color: kHomeBlueLight,
        filter: null,
      ),
      _SummaryItem(
        label: 'Thấp',
        value: summary.low,
        color: Colors.white54,
        filter: null,
      ),
      _SummaryItem(
        label: 'Đã xem',
        value: summary.acknowledged,
        color: kHomeCyan,
        filter: null,
      ),
      _SummaryItem(
        label: 'Đã xử lý',
        value: summary.resolvedToday,
        color: kHomeGreen,
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
                width: 96,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: homeTileDecoration(radius: 14),
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
                        color: Colors.white54,
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
