import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/crab_management_models.dart';
import 'crab_management_palette.dart';

// ── Health Status Badge ───────────────────────────────────────────────────────

class CrabHealthBadge extends StatelessWidget {
  const CrabHealthBadge(this.status, {super.key, this.compact = false});
  final CrabHealthStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      CrabHealthStatus.healthy => (kCmGreenLight, kCmPrimaryDark),
      CrabHealthStatus.monitoring => (kCmAmberLight, Color(0xFFB45309)),
      CrabHealthStatus.weak => (kCmRedLight, kCmRed),
      CrabHealthStatus.alert => (kCmRedLight, kCmRed),
      CrabHealthStatus.unknown => (kCmSlateBg, kCmSlate),
    };
    final dot = switch (status) {
      CrabHealthStatus.healthy => kCmGreen,
      CrabHealthStatus.monitoring => kCmAmber,
      CrabHealthStatus.weak => kCmRed,
      CrabHealthStatus.alert => kCmRed,
      CrabHealthStatus.unknown => kCmSlate,
    };
    return _StatusChip(
      label: status.label,
      bg: bg,
      fg: fg,
      dot: dot,
      compact: compact,
    );
  }
}

// ── Lifecycle Status Badge ────────────────────────────────────────────────────

class CrabLifecycleBadge extends StatelessWidget {
  const CrabLifecycleBadge(this.status, {super.key, this.compact = false});
  final CrabLifecycleStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      CrabLifecycleStatus.growing => (kCmGreenLight, kCmPrimaryDark),
      CrabLifecycleStatus.molting => (kCmPurpleLight, kCmPurple),
      CrabLifecycleStatus.readyToHarvest => (kCmTealLight, kCmTeal),
      CrabLifecycleStatus.harvested => (kCmSlateBg, kCmSlate),
      CrabLifecycleStatus.dead => (kCmRedLight, kCmRed),
      CrabLifecycleStatus.unknown => (kCmSlateBg, kCmSlate),
    };
    final dot = switch (status) {
      CrabLifecycleStatus.growing => kCmGreen,
      CrabLifecycleStatus.molting => kCmPurple,
      CrabLifecycleStatus.readyToHarvest => kCmTeal,
      CrabLifecycleStatus.harvested => kCmSlate,
      CrabLifecycleStatus.dead => kCmRed,
      CrabLifecycleStatus.unknown => kCmSlate,
    };
    return _StatusChip(
      label: status.label,
      bg: bg,
      fg: fg,
      dot: dot,
      compact: compact,
    );
  }
}

// ── Gender Badge ──────────────────────────────────────────────────────────────

class CrabGenderBadge extends StatelessWidget {
  const CrabGenderBadge(this.gender, {super.key});
  final CrabGender gender;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (gender) {
      CrabGender.female => (const Color(0xFFFFF0F3), const Color(0xFFE11D48)),
      CrabGender.male => (const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      CrabGender.unknown => (kCmSlateBg, kCmSlate),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        gender.label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ── Private shared chip ───────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.dot,
    this.compact = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color dot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
