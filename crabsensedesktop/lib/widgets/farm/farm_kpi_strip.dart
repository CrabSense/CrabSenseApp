import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_layout.dart';
import '../../theme/dashboard_theme.dart';

class FarmKpiStrip extends StatelessWidget {
  const FarmKpiStrip({super.key, required this.summary});

  final FarmLayoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Kpi('TỔNG HỘP', '${summary.total}', DashboardColors.textPrimary),
      _Kpi('ĐANG NUÔI', '${summary.occupied}', DashboardColors.blue),
      _Kpi('HỘP TRỐNG', '${summary.empty}', DashboardColors.textMuted),
      _Kpi('BÌNH THƯỜNG', '${summary.normal}', DashboardColors.cyan),
      _Kpi('THEO DÕI', '${summary.watch}', DashboardColors.monitoring),
      _Kpi('SẮP / LỘT XÁC', '${summary.molting}', const Color(0xFFA78BFA)),
      _Kpi('CẢNH BÁO', '${summary.alert}', const Color(0xFFFF6B8A)),
      _Kpi('SỰ CỐ', '${summary.deceased}', DashboardColors.dead),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1100 ? 8 : c.maxWidth > 700 ? 4 : 2;
        final spacing = 10.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((k) => SizedBox(width: w, child: _KpiCard(kpi: k)))
              .toList(),
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kpi.color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: kpi.color.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: kpi.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
