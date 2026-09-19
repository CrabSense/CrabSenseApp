import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_status.dart';
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
      _Kpi('BÌNH THƯỜNG', '${summary.normal}', DashboardColors.healthy),
      _Kpi('LỘT XÁC', '${summary.molting}', DashboardColors.moltPurple),
      _Kpi('CÓ VẤN ĐỀ', '${summary.alert}', DashboardColors.monitoring),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 1100 ? 6 : c.maxWidth > 700 ? 3 : 2;
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
        ),
        const SizedBox(height: 12),
        const _StatusLegend(),
      ],
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  static const _items = <BoxStatus>[
    BoxStatus.normal,
    BoxStatus.molting,
    BoxStatus.alert,
    BoxStatus.empty,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final status in _items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                status.iconAsset,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: GoogleFonts.notoSans(
                  color: status.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
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
