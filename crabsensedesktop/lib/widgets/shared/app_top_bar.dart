import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/auth_models.dart';
import '../../services/connectivity_link_service.dart';
import '../../theme/dashboard_theme.dart';
import 'cloud_edge_header_badges.dart';
import 'farm_header_selector.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
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
    this.hideSearch = false,
  });

  final String? title;
  final String? subtitle;
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
  final bool hideSearch;

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.beVietnamPro;
    final searchKey = ValueKey('search-$searchHint');

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedFarm != null && farms != null && farms!.isNotEmpty) ...[
          FarmHeaderSelector(
            farms: farms!,
            selected: selectedFarm!,
            onChanged: onFarmChanged ?? (_) {},
          ),
          const SizedBox(width: 10),
        ],
        if (connectivity != null) ...[
          CloudEdgeHeaderBadges(
            service: connectivity!,
            onTapCloud: onOpenDeviceSetup,
            onTapEdge: onOpenDeviceSetup,
          ),
          const SizedBox(width: 10),
        ],
        _NotificationPill(alertCount: alertCount),
        const SizedBox(width: 10),
        _UserChip(name: displayName, onLogout: onLogout),
      ],
    );

    return Container(
      height: subtitle != null ? 88 : 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint.withValues(alpha: 0.65),
        border: Border(
          bottom: BorderSide(
            color: DashboardColors.cardBorder.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          if (title != null)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text(
                      color: DashboardColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text(
                        color: DashboardColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!hideSearch || centerTitle != null) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: centerTitle ??
                  (hideSearch
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 40,
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: _pillDecoration(),
                            child: TextField(
                              key: searchKey,
                              onChanged: onSearchChanged,
                              style: text(
                                color: DashboardColors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: searchHint,
                                hintStyle: text(
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
                        )),
            ),
          ],
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BoxDecoration _pillDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7EBE3)),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.brand.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

class _NotificationPill extends StatelessWidget {
  const _NotificationPill({required this.alertCount});

  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: AppTopBar._pillDecoration(),
      child: IconButton(
        onPressed: () {},
        tooltip: 'Cảnh báo',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: DashboardColors.textMuted,
              size: 22,
            ),
                if (alertCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: DashboardColors.risk,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    alertCount > 99 ? '99+' : '$alertCount',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final text = GoogleFonts.beVietnamPro;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppTopBar._pillDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DashboardColors.mintActive,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'C',
              style: text(
                color: DashboardColors.brand,
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
                name.isEmpty ? 'Chủ trại' : name,
                style: text(
                  color: DashboardColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Admin Panel',
                style: text(
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
                style: text(
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
