import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/dashboard_theme.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, 'Dashboard', true),
    _NavItem(Icons.grid_view_outlined, 'Khu nuôi', false),
    _NavItem(Icons.sensors_outlined, 'Thiết bị', false),
    _NavItem(Icons.water_outlined, 'Môi trường', false),
    _NavItem(Icons.notifications_active_outlined, 'Cảnh báo', false),
    _NavItem(Icons.assessment_outlined, 'Báo cáo', false),
    _NavItem(Icons.auto_awesome_outlined, 'AI Insight', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: DashboardColors.sidebarBg.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(color: DashboardColors.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CrabFarm\nManagement Portal',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final item in _navItems)
                  _SidebarTile(item: item),
              ],
            ),
          ),
          Divider(color: DashboardColors.cardBorder, height: 1),
          _SidebarTile(
            item: const _NavItem(Icons.help_outline, 'Support', false),
            onTap: () {},
          ),
          _SidebarTile(
            item: const _NavItem(Icons.logout, 'Logout', false),
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.active);

  final IconData icon;
  final String label;
  final bool active;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, this.onTap});

  final _NavItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: item.active
            ? DashboardColors.purple.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: item.active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: DashboardColors.purple, width: 3),
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: item.active
                      ? DashboardColors.purple
                      : DashboardColors.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight:
                        item.active ? FontWeight.w600 : FontWeight.w400,
                    color: item.active
                        ? DashboardColors.textPrimary
                        : DashboardColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
