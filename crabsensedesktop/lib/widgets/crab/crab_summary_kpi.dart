import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_individual.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class CrabSummaryKpiRow extends StatelessWidget {
  const CrabSummaryKpiRow({super.key, required this.items});

  final List<CrabSummaryKpi> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = items.length;
        final cols = c.maxWidth > 1200
            ? (n >= 5 ? 5 : n.clamp(1, 4))
            : c.maxWidth > 800
                ? 3
                : c.maxWidth > 500
                    ? 2
                    : 1;
        final spacing = 16.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((k) => SizedBox(width: w, child: _KpiCard(kpi: k))).toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final CrabSummaryKpi kpi;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kpi.label,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kpi.value,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kpi.subtext,
                  style: GoogleFonts.notoSans(
                    color: kpi.subtext.contains('+') || kpi.subtext.contains('↗')
                        ? DashboardColors.healthy
                        : kpi.subtext.contains('!')
                            ? DashboardColors.monitoring
                            : DashboardColors.textMuted,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                if (kpi.showProgress && kpi.progress != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: kpi.progress,
                      minHeight: 4,
                      backgroundColor: DashboardColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation(kpi.accentColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            kpi.icon,
            color: kpi.accentColor.withValues(alpha: 0.45),
            size: 32,
          ),
        ],
      ),
    );
  }
}
