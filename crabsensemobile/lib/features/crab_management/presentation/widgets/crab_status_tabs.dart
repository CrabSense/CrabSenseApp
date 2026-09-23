import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import 'crab_management_palette.dart';

/// Quick status filter chips row
class CrabStatusTabs extends StatelessWidget {
  const CrabStatusTabs({
    required this.kpi,
    required this.activeStatus,
    required this.onSelected,
    super.key,
  });

  final CrabKpiSummary kpi;
  final CrabLifecycleStatus? activeStatus; // null = Tất cả
  final void Function(CrabLifecycleStatus?) onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _ChipData(
        label: 'Tất cả',
        count: kpi.total,
        status: null,
        color: kCmPrimaryDark,
        activeColor: kCmPrimaryLight,
      ),
      _ChipData(
        label: 'Đang nuôi',
        count: kpi.growing,
        status: CrabLifecycleStatus.growing,
        color: kCmGreen,
        activeColor: kCmGreenLight,
        icon: '🌿',
      ),
      _ChipData(
        label: 'Theo dõi',
        count: kpi.monitoring,
        status: null, // Theo dõi is health-based — keep as separate chip
        color: kCmAmber,
        activeColor: kCmAmberLight,
        icon: '⚠',
        isHealthWatch: true,
      ),
      _ChipData(
        label: 'Đang lột',
        count: kpi.molting,
        status: CrabLifecycleStatus.molting,
        color: kCmPurple,
        activeColor: kCmPurpleLight,
        icon: '↻',
      ),
      _ChipData(
        label: 'Thu hoạch',
        count: kpi.readyToHarvest,
        status: CrabLifecycleStatus.readyToHarvest,
        color: kCmTeal,
        activeColor: kCmTealLight,
        icon: '🧺',
      ),
      _ChipData(
        label: 'Chết',
        count: kpi.dead,
        status: CrabLifecycleStatus.dead,
        color: kCmRed,
        activeColor: kCmRedLight,
        icon: '❤',
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _StatusChip(
              data: chips[i],
              isActive:
                  chips[i].status == activeStatus && !chips[i].isHealthWatch,
              onTap: () => onSelected(chips[i].status),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipData {
  const _ChipData({
    required this.label,
    required this.count,
    required this.status,
    required this.color,
    required this.activeColor,
    this.icon,
    this.isHealthWatch = false,
  });
  final String label;
  final int count;
  final CrabLifecycleStatus? status;
  final Color color;
  final Color activeColor;
  final String? icon;
  final bool isHealthWatch;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.data,
    required this.isActive,
    required this.onTap,
  });
  final _ChipData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? data.activeColor : kCmSurface;
    final borderColor = isActive ? data.color : kCmBorder;
    final textColor = isActive ? data.color : kCmTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
            if (!isActive && data.icon != null) ...[
              Text(data.icon!, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
            ],
            Text(
              '${data.label} (${data.count})',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
