import 'package:flutter/material.dart';

import '../../models/crab_status.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

class CrabHealthBadge extends StatelessWidget {
  const CrabHealthBadge({super.key, required this.status});

  final CrabDisplayHealth status;

  @override
  Widget build(BuildContext context) {
    return MgmtStatusBadge(label: status.label, color: status.color);
  }
}

class CrabLifecycleBadge extends StatelessWidget {
  const CrabLifecycleBadge({super.key, required this.status});

  final CrabLifecycleStatus status;

  @override
  Widget build(BuildContext context) {
    return MgmtStatusBadge(label: status.label, color: status.color);
  }
}

class CrabOperationalBadge extends StatelessWidget {
  const CrabOperationalBadge({super.key, required this.status});

  final CrabOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    final mapped = switch (status) {
      CrabOperationalStatus.alive => CrabLifecycleStatus.growing,
      CrabOperationalStatus.molting => CrabLifecycleStatus.molting,
      CrabOperationalStatus.readyHarvest => CrabLifecycleStatus.readyHarvest,
      CrabOperationalStatus.harvested ||
      CrabOperationalStatus.sold =>
        CrabLifecycleStatus.harvested,
      CrabOperationalStatus.dead => CrabLifecycleStatus.dead,
      CrabOperationalStatus.warning => CrabLifecycleStatus.growing,
    };
    return CrabLifecycleBadge(status: mapped);
  }
}

class CrabLifeBadge extends StatelessWidget {
  const CrabLifeBadge({super.key, required this.status});

  final CrabLifeStatus status;

  @override
  Widget build(BuildContext context) {
    final mapped = switch (status) {
      CrabLifeStatus.raising => CrabLifecycleStatus.growing,
      CrabLifeStatus.readyForSale ||
      CrabLifeStatus.sold =>
        CrabLifecycleStatus.harvested,
      CrabLifeStatus.dead => CrabLifecycleStatus.dead,
    };
    return CrabLifecycleBadge(status: mapped);
  }
}

class CrabGenderBadge extends StatelessWidget {
  const CrabGenderBadge({super.key, required this.gender});

  final CrabGender gender;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (gender) {
      CrabGender.female => (const Color(0xFFFCE7F3), const Color(0xFFBE185D)),
      CrabGender.male => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      CrabGender.unknown => (
          const Color(0xFFF1F5F9),
          const Color(0xFF64748B),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        gender.label,
        style: bvText(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class CrabCodeCell extends StatelessWidget {
  const CrabCodeCell({
    super.key,
    required this.code,
    this.onTap,
  });

  final String code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: DashboardColors.mint,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.set_meal_rounded,
            size: 16,
            color: DashboardColors.brand,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            code,
            overflow: TextOverflow.ellipsis,
            style: bvText(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: DashboardColors.brand,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}
