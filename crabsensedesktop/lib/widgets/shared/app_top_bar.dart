import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/auth_models.dart';
import '../../services/connectivity_link_service.dart';
import '../../theme/dashboard_theme.dart';
import 'cloud_edge_header_badges.dart';
import 'farm_header_selector.dart';
import 'theme_mode_toggle.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.searchHint = 'Tìm kiếm...',
    this.onSearchChanged,
    this.displayName = 'Admin',
    this.alertCount = 5,
    this.leading,
    this.centerTitle,
    this.onSettingsTap,
    this.connectivity,
    this.onOpenDeviceSetup,
    this.onLogout,
    this.farms,
    this.selectedFarm,
    this.onFarmChanged,
  });

  final String? title;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final String displayName;
  final int alertCount;
  final Widget? leading;
  final Widget? centerTitle;
  final VoidCallback? onSettingsTap;
  final ConnectivityLinkService? connectivity;
  final VoidCallback? onOpenDeviceSetup;
  final VoidCallback? onLogout;
  final List<FarmSummary>? farms;
  final FarmSummary? selectedFarm;
  final ValueChanged<FarmSummary>? onFarmChanged;

  @override
  Widget build(BuildContext context) {
    final searchKey = ValueKey('search-$searchHint');
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
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          if (title != null)
            Text(
              title!,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (title != null) const SizedBox(width: 24),
          Expanded(
            child: centerTitle ??
                Container(
                  height: 40,
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: DashboardColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DashboardColors.cardBorder),
                  ),
                  child: TextField(
                    key: searchKey,
                    onChanged: onSearchChanged,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: DashboardColors.textMuted,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
          ),
          const Spacer(),
          if (selectedFarm != null && farms != null && farms!.isNotEmpty) ...[
            FarmHeaderSelector(
              farms: farms!,
              selected: selectedFarm!,
              onChanged: onFarmChanged ?? (_) {},
            ),
            const SizedBox(width: 12),
          ],
          if (connectivity != null) ...[
            CloudEdgeHeaderBadges(
              service: connectivity!,
              onTapCloud: onOpenDeviceSetup,
              onTapEdge: onOpenDeviceSetup,
            ),
            const SizedBox(width: 12),
          ],
          const ThemeModeToggle(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined,
                    color: DashboardColors.textMuted, size: 22),
                if (alertCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
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
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            tooltip: 'Cài đặt — Device Setup',
            icon: Icon(Icons.settings_outlined,
                color: DashboardColors.textMuted, size: 22),
          ),
          const SizedBox(width: 8),
          _UserChip(name: displayName, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, this.onLogout});

  final String name;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Admin Panel',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          if (onLogout != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: DashboardColors.textMuted,
            ),
          ],
        ],
      ),
    );

    if (onLogout == null) return chip;

    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      offset: const Offset(0, 48),
      color: DashboardColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardColors.cardBorder),
      ),
      onSelected: (value) {
        if (value == 'logout') onLogout!();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: DashboardColors.risk),
              const SizedBox(width: 10),
              Text(
                'Đăng xuất',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      child: chip,
    );
  }
}
