import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_route.dart';
import '../../theme/dashboard_theme.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
    this.onUpgradeSensorKit,
    this.onOpenDeviceSetup,
  });

  final AppRoute selected;
  final ValueChanged<AppRoute> onSelect;
  final VoidCallback onLogout;
  final VoidCallback? onUpgradeSensorKit;
  final VoidCallback? onOpenDeviceSetup;

  static const farmMapIcon = 'assets/icon_tab/tab_camp_map.png';
  static const dashboardIcon = 'assets/icon_tab/tab_dashboard.png';
  static const crabManagementIcon = 'assets/icon_tab/tab_crab_management.png';

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const _expandedWidth = 280.0;
  static const _collapsedWidth = 80.0;

  static const _routes = [
    AppRoute.dashboard,
    AppRoute.farmAreas,
    AppRoute.farmManagement,
    AppRoute.rowManagement,
    AppRoute.boxManagement,
    AppRoute.inboundLots,
    AppRoute.productionCrabManagement,
    AppRoute.devices,
    AppRoute.environment,
    AppRoute.alerts,
    AppRoute.farmLogs,
    AppRoute.harvestSales,
    AppRoute.aiInsight,
  ];

  bool _collapsed = false;

  static IconData _icon(AppRoute r) => switch (r) {
        AppRoute.dashboard => Icons.dashboard_outlined,
        AppRoute.cameraAi => Icons.videocam_outlined,
        AppRoute.batches => Icons.layers_outlined,
        AppRoute.batchDetail => Icons.layers_outlined,
        AppRoute.individualDetail => Icons.pets_outlined,
        AppRoute.individualHealth => Icons.monitor_heart_outlined,
        AppRoute.farmAreas => Icons.map_outlined,
        AppRoute.farmManagement => Icons.agriculture_outlined,
        AppRoute.areaManagement => Icons.landscape_outlined,
        AppRoute.areaDetail => Icons.landscape_outlined,
        AppRoute.rowManagement => Icons.view_week_outlined,
        AppRoute.boxManagement => Icons.inventory_2_outlined,
        AppRoute.boxDetail => Icons.inventory_2_outlined,
        AppRoute.farmingBatchManagement => Icons.eco_outlined,
        AppRoute.farmingBatchDetail => Icons.eco_outlined,
        AppRoute.inboundLots => Icons.local_shipping_outlined,
        AppRoute.inboundLotDetail => Icons.local_shipping_outlined,
        AppRoute.productionCrabManagement => Icons.set_meal_outlined,
        AppRoute.crabManagementDetail => Icons.set_meal_outlined,
        AppRoute.individuals => Icons.pets_outlined,
        AppRoute.feed => Icons.restaurant_outlined,
        AppRoute.devices => Icons.sensors_outlined,
        AppRoute.environment => Icons.water_outlined,
        AppRoute.alerts => Icons.notifications_active_outlined,
        AppRoute.farmLogs => Icons.history_outlined,
        AppRoute.harvestSales => Icons.shopping_bag_outlined,
        AppRoute.reports => Icons.assessment_outlined,
        AppRoute.aiInsight => Icons.auto_awesome_outlined,
        AppRoute.sensorUpgrade => Icons.upgrade,
        AppRoute.deviceSetup => Icons.tune,
      };

  static String? _imageAsset(AppRoute r) => switch (r) {
        AppRoute.dashboard => AppSidebar.dashboardIcon,
        AppRoute.farmAreas => AppSidebar.farmMapIcon,
        AppRoute.productionCrabManagement ||
        AppRoute.crabManagementDetail =>
          AppSidebar.crabManagementIcon,
        _ => null,
      };

  bool _isActive(AppRoute r) =>
      r == widget.selected ||
      (r == AppRoute.batches && widget.selected == AppRoute.batchDetail) ||
      (r == AppRoute.individuals &&
          (widget.selected == AppRoute.individualDetail ||
              widget.selected == AppRoute.individualHealth)) ||
      (r == AppRoute.areaManagement && widget.selected == AppRoute.areaDetail) ||
      (r == AppRoute.boxManagement && widget.selected == AppRoute.boxDetail) ||
      (r == AppRoute.farmingBatchManagement &&
          widget.selected == AppRoute.farmingBatchDetail) ||
      (r == AppRoute.inboundLots && widget.selected == AppRoute.inboundLotDetail) ||
      (r == AppRoute.productionCrabManagement &&
          widget.selected == AppRoute.crabManagementDetail);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: _collapsed ? _collapsedWidth : _expandedWidth,
      decoration: BoxDecoration(
        color: DashboardColors.sidebarBg.withValues(alpha: 0.95),
        border: Border(
          right: BorderSide(
            color: DashboardColors.cardBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _collapsed ? 10 : 16,
              20,
              _collapsed ? 10 : 12,
              12,
            ),
            child: _collapsed ? _collapsedHeader() : _expandedHeader(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: _collapsed ? 8 : 12),
              children: [
                for (final route in _routes)
                  _SidebarTile(
                    icon: _icon(route),
                    imageAsset: _imageAsset(route),
                    label: route.label,
                    active: _isActive(route),
                    collapsed: _collapsed,
                    onTap: () {
                      if (route.isImplemented) {
                        widget.onSelect(route);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${route.label} — đang phát triển'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
          Divider(color: DashboardColors.cardBorder, height: 1),
          if (!_collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'CÀI ĐẶT',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          _SidebarTile(
            icon: Icons.logout,
            label: 'Logout',
            active: false,
            collapsed: _collapsed,
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _expandedHeader() {
    return Row(
      children: [
        Image.asset('assets/images/logo.png', height: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CrabSense',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PRECISION MONITORING',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 8,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thu gọn menu',
          onPressed: () => setState(() => _collapsed = true),
          icon: Icon(
            Icons.menu_open_rounded,
            color: DashboardColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _collapsedHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 36),
        const SizedBox(height: 8),
        IconButton(
          tooltip: 'Mở rộng menu',
          onPressed: () => setState(() => _collapsed = false),
          icon: Icon(
            Icons.menu_rounded,
            color: DashboardColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.imageAsset,
    this.collapsed = false,
  });

  final IconData icon;
  final String? imageAsset;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active
            ? DashboardColors.purple.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                if (active)
                  Container(width: 3, color: DashboardColors.purple),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 8 : 14,
                      vertical: collapsed ? 10 : 12,
                    ),
                    child: collapsed ? _collapsedContent() : _expandedContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!collapsed) return tile;
    return Tooltip(message: label, waitDuration: const Duration(milliseconds: 400), child: tile);
  }

  Widget _collapsedContent() {
    return Center(child: _leading(size: imageAsset != null ? 40 : 22));
  }

  Widget _expandedContent() {
    return Row(
      children: [
        _leading(size: imageAsset != null ? 28 : 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? DashboardColors.textPrimary
                  : DashboardColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _leading({required double size}) {
    if (imageAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          imageAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      );
    }
    return Icon(
      icon,
      size: size,
      color: active ? DashboardColors.purple : DashboardColors.textMuted,
    );
  }
}
