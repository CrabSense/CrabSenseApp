import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_route.dart';
import '../../theme/dashboard_theme.dart';

class AppSidebar extends StatelessWidget {
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

  static const _routes = [
    AppRoute.dashboard,
    AppRoute.farmAreas,
    AppRoute.farmManagement,
    AppRoute.areaManagement,
    AppRoute.rowManagement,
    AppRoute.boxManagement,
    AppRoute.productionCrabManagement,
    AppRoute.devices,
    AppRoute.environment,
    AppRoute.alerts,
    AppRoute.farmLogs,
    AppRoute.harvestSales,
    AppRoute.aiInsight,
  ];

  static IconData _icon(AppRoute r) => switch (r) {
        AppRoute.dashboard => Icons.dashboard_outlined,
        AppRoute.cameraAi => Icons.videocam_outlined,
        AppRoute.batches => Icons.layers_outlined,
        AppRoute.batchDetail => Icons.layers_outlined,
        AppRoute.individualDetail => Icons.pets_outlined,
        AppRoute.individualHealth => Icons.monitor_heart_outlined,
        AppRoute.farmAreas => Icons.grid_view_outlined,
        AppRoute.farmManagement => Icons.agriculture_outlined,
        AppRoute.areaManagement => Icons.landscape_outlined,
        AppRoute.areaDetail => Icons.landscape_outlined,
        AppRoute.rowManagement => Icons.view_week_outlined,
        AppRoute.boxManagement => Icons.inventory_2_outlined,
        AppRoute.boxDetail => Icons.inventory_2_outlined,
        AppRoute.farmingBatchManagement => Icons.eco_outlined,
        AppRoute.farmingBatchDetail => Icons.eco_outlined,
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

  bool _isActive(AppRoute r) =>
      r == selected ||
      (r == AppRoute.batches && selected == AppRoute.batchDetail) ||
      (r == AppRoute.individuals &&
          (selected == AppRoute.individualDetail ||
              selected == AppRoute.individualHealth)) ||
      (r == AppRoute.areaManagement && selected == AppRoute.areaDetail) ||
      (r == AppRoute.boxManagement && selected == AppRoute.boxDetail) ||
      (r == AppRoute.farmingBatchManagement &&
          selected == AppRoute.farmingBatchDetail) ||
      (r == AppRoute.productionCrabManagement &&
          selected == AppRoute.crabManagementDetail);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CrabFarm',
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
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final route in _routes)
                  _SidebarTile(
                    icon: _icon(route),
                    label: route.label,
                    active: _isActive(route),
                    onTap: () {
                      if (route.isImplemented) {
                        onSelect(route);
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
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: active
                              ? DashboardColors.purple
                              : DashboardColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            color: active
                                ? DashboardColors.textPrimary
                                : DashboardColors.textMuted,
                          ),
                        ),
                      ],
                    ),
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
