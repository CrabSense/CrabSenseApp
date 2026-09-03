import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/dashboard_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.displayName,
    required this.alertCount,
  });

  final String displayName;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DashboardColors.cardBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Dashboard Tổng Quan',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: DashboardColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: TextField(
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khu vực, ID cua...',
                  hintStyle: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: DashboardColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            badge: alertCount,
          ),
          const SizedBox(width: 8),
          const _HeaderIconButton(icon: Icons.settings_outlined),
          const SizedBox(width: 12),
          _UserChip(name: displayName),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.badge});

  final IconData icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(icon, color: DashboardColors.textMuted, size: 22),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: DashboardColors.risk,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DashboardColors.purple.withValues(alpha: 0.3),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: GoogleFonts.notoSans(
                color: DashboardColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
