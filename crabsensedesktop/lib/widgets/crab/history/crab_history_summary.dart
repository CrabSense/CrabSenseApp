import 'package:flutter/material.dart';

import '../../../models/crab_lifecycle_event.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

class CrabHistorySummary extends StatelessWidget {
  const CrabHistorySummary({
    super.key,
    required this.summary,
    required this.active,
    required this.onTap,
    this.loading = false,
  });

  final CrabLifecycleSummary summary;
  final CrabHistoryEventFilter active;
  final ValueChanged<CrabHistoryEventFilter> onTap;
  final bool loading;

  static const _chips = [
    (CrabHistoryEventFilter.all, 'Tổng sự kiện', Icons.layers_outlined, DashboardColors.brand),
    (CrabHistoryEventFilter.feeding, 'Cho ăn', Icons.restaurant_rounded, DashboardColors.brand),
    (CrabHistoryEventFilter.growth, 'Sinh trưởng', Icons.monitor_weight_outlined, kHistBlue),
    (CrabHistoryEventFilter.molt, 'Lột xác', Icons.autorenew_rounded, kHistPurple),
    (CrabHistoryEventFilter.health, 'Sức khỏe', Icons.favorite_rounded, DashboardColors.brandGreen),
    (CrabHistoryEventFilter.transfer, 'Chuyển hộp', Icons.swap_horiz_rounded, kHistCyan),
    (CrabHistoryEventFilter.ai, 'AI phát hiện', Icons.smart_toy_outlined, kHistBlue),
    (CrabHistoryEventFilter.alert, 'Cảnh báo', Icons.warning_amber_rounded, kHistAmber),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 900;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _chip(_chips[i], compact),
            ],
          ],
        ),
      );
    });
  }

  Widget _chip((CrabHistoryEventFilter, String, IconData, Color) spec, bool compact) {
    final (filter, label, icon, color) = spec;
    final selected = active == filter;
    final value = summary.of(filter);
    return Material(
      color: selected ? DashboardColors.lightMint : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : () => onTap(filter),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: compact ? 118 : 128,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? DashboardColors.brand.withValues(alpha: 0.45) : DashboardColors.cardBorder,
            ),
          ),
          child: loading
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 8, width: 56, color: DashboardColors.mint),
                    const SizedBox(height: 8),
                    Container(height: 18, width: 28, color: DashboardColors.mint),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 13, color: color),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bvText(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: DashboardColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$value',
                      style: bvText(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
