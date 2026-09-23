import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import 'crab_management_palette.dart';

/// 6 KPI cards in a 2x3 grid (or scrollable row on wider screens).
class CrabKpiCards extends StatelessWidget {
  const CrabKpiCards({
    required this.kpi,
    super.key,
    this.onQuickFilter,
    this.activeStatus,
  });

  final CrabKpiSummary kpi;
  final void Function(CrabLifecycleStatus?)? onQuickFilter;
  final CrabLifecycleStatus? activeStatus;

  @override
  Widget build(BuildContext context) {
    final pct = (double v) => '${v.toStringAsFixed(1)}%';
    final cards = [
      _KpiCardData(
        icon: '🦀',
        label: 'Tổng số cua',
        value: '${kpi.total}',
        sub: 'Tất cả cá thể trong hệ thống',
        color: kCmBlue,
        bgColor: kCmBlueLight,
        status: null,
      ),
      _KpiCardData(
        icon: '🌿',
        label: 'Đang nuôi',
        value: '${kpi.growing}',
        sub: pct(kpi.growingPct),
        color: kCmGreen,
        bgColor: kCmGreenLight,
        status: CrabLifecycleStatus.growing,
      ),
      _KpiCardData(
        icon: '⚠',
        label: 'Theo dõi',
        value: '${kpi.monitoring}',
        sub: pct(kpi.monitoringPct),
        color: kCmAmber,
        bgColor: kCmAmberLight,
        status: null, // health-based, no direct lifecycle filter
      ),
      _KpiCardData(
        icon: '↻',
        label: 'Đang lột xác',
        value: '${kpi.molting}',
        sub: pct(kpi.moltingPct),
        color: kCmPurple,
        bgColor: kCmPurpleLight,
        status: CrabLifecycleStatus.molting,
      ),
      _KpiCardData(
        icon: '🧺',
        label: 'Sắp thu hoạch',
        value: '${kpi.readyToHarvest}',
        sub: pct(kpi.harvestPct),
        color: kCmTeal,
        bgColor: kCmTealLight,
        status: CrabLifecycleStatus.readyToHarvest,
      ),
      _KpiCardData(
        icon: '💔',
        label: 'Cua chết',
        value: '${kpi.dead}',
        sub: pct(kpi.deadPct),
        color: kCmRed,
        bgColor: kCmRedLight,
        status: CrabLifecycleStatus.dead,
      ),
    ];

    // Responsive: 2 rows of 3 on narrow, single scroll row on wide
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Wide: single row
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  SizedBox(
                    width: (constraints.maxWidth - 50) / 6,
                    child: _KpiCard(
                      data: cards[i],
                      isActive:
                          activeStatus == cards[i].status &&
                          cards[i].status != null,
                      onTap: onQuickFilter == null
                          ? null
                          : () => onQuickFilter!(cards[i].status),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        // Mobile: 2×3 grid
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: cards
              .map(
                (d) => _KpiCard(
                  data: d,
                  isActive: activeStatus == d.status && d.status != null,
                  onTap: onQuickFilter == null
                      ? null
                      : () => onQuickFilter!(d.status),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bgColor,
    required this.status,
  });
  final String icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color bgColor;
  final CrabLifecycleStatus? status;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data, this.isActive = false, this.onTap});

  final _KpiCardData data;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? data.bgColor : kCmSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? data.color : kCmBorder,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: kCmShadow, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(data.icon, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text(
                  data.sub,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: data.color,
                  ),
                ),
              ],
            ),
            Text(
              data.value,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: data.color,
                height: 1.1,
              ),
            ),
            Text(
              data.label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kCmTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI Skeleton ──────────────────────────────────────────────────────────────

class CrabKpiSkeleton extends StatelessWidget {
  const CrabKpiSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.15,
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: kCmSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kCmBorder),
          ),
        ),
      ),
    );
  }
}
