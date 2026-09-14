import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_batch.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class BatchSummaryKpiRow extends StatelessWidget {
  const BatchSummaryKpiRow({super.key, required this.items});

  final List<BatchSummaryKpi> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1000 ? 4 : c.maxWidth > 600 ? 2 : 1;
        final spacing = 16.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((item) => SizedBox(width: w, child: _KpiCard(item: item)))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final BatchSummaryKpi item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: item.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label.toUpperCase(),
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: GoogleFonts.notoSans(
                    color: item.label == 'Tỷ lệ sống'
                        ? DashboardColors.cyan
                        : DashboardColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtext,
                  style: GoogleFonts.notoSans(
                    color: item.subtext.contains('+')
                        ? DashboardColors.healthy
                        : item.subtext == 'Live Metrics'
                            ? DashboardColors.cyan
                            : DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            ),
          ),
          Icon(item.icon, color: item.accentColor.withValues(alpha: 0.5), size: 32),
        ],
      ),
    );
  }
}
