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
  static const rasControlIcon = 'assets/icon_tab/tab_RAS_control.png';
  static const controllerIcon = 'assets/icon_tab/tab_manage_controll.png';
  static const realtimeIcon = 'assets/icon_tab/tab_real-time_monitoring.png';
  static const waterAnalysisIcon = 'assets/icon_tab/tab_water_analysis.png';
  static const warningSystemIcon = 'assets/icon_tab/tab_warning_system.png';

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const _expandedWidth = 286.0;
  static const _collapsedWidth = 80.0;

  /// Menu khớp mockup Dashboard Tổng Quan.
  static const _routes = [
    AppRoute.dashboard,
    AppRoute.farmAreas,
    AppRoute.farmManagement,
    AppRoute.rowManagement,
    AppRoute.boxManagement,
    AppRoute.inboundLots,
    AppRoute.productionCrabManagement,
    AppRoute.devices,
    AppRoute.controllers,
    AppRoute.environment,
    AppRoute.waterAnalysis,
    AppRoute.alerts,
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
        AppRoute.farmManagement => Icons.grid_view_outlined,
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
        AppRoute.devices => Icons.settings_input_component_outlined,
        AppRoute.controllers => Icons.developer_board_outlined,
        AppRoute.environment => Icons.ssid_chart,
        AppRoute.waterAnalysis => Icons.science_outlined,
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
        AppRoute.devices => AppSidebar.rasControlIcon,
        AppRoute.controllers => AppSidebar.controllerIcon,
        AppRoute.environment => AppSidebar.realtimeIcon,
        AppRoute.waterAnalysis => AppSidebar.waterAnalysisIcon,
        AppRoute.alerts => AppSidebar.warningSystemIcon,
        _ => null,
      };

  bool _isActive(AppRoute r) =>
      r == widget.selected ||
      (r == AppRoute.batches && widget.selected == AppRoute.batchDetail) ||
      (r == AppRoute.individuals &&
          (widget.selected == AppRoute.individualDetail ||
              widget.selected == AppRoute.individualHealth)) ||
      (r == AppRoute.areaManagement && widget.selected == AppRoute.areaDetail) ||
      (r == AppRoute.farmManagement &&
          (widget.selected == AppRoute.areaManagement ||
              widget.selected == AppRoute.areaDetail)) ||
      (r == AppRoute.boxManagement && widget.selected == AppRoute.boxDetail) ||
      (r == AppRoute.farmingBatchManagement &&
          widget.selected == AppRoute.farmingBatchDetail) ||
      (r == AppRoute.inboundLots &&
          widget.selected == AppRoute.inboundLotDetail) ||
      (r == AppRoute.productionCrabManagement &&
          widget.selected == AppRoute.crabManagementDetail);

  @override
  Widget build(BuildContext context) {
    final width = _collapsed ? _collapsedWidth : _expandedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FFFC), Color(0xFFEAF8F3)],
          ),
          border: Border(
            right: BorderSide(color: Color(0xFFD7EBE3)),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Trong lúc animate, dùng layout hẹp theo width thực tế.
            final narrow = constraints.maxWidth < 140;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (!narrow)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/background_tabslidebar.png',
                        width: constraints.maxWidth,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        narrow ? 10 : 16,
                        18,
                        narrow ? 10 : 12,
                        8,
                      ),
                      child: narrow ? _collapsedHeader() : _expandedHeader(),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          narrow ? 8 : 12,
                          4,
                          narrow ? 8 : 12,
                          narrow ? 12 : 180,
                        ),
                        children: [
                          for (final route in _routes)
                            _SidebarTile(
                              icon: _icon(route),
                              imageAsset: _imageAsset(route),
                              label: route.label,
                              active: _isActive(route),
                              collapsed: narrow,
                              onTap: () {
                                if (route.isImplemented) {
                                  widget.onSelect(route);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${route.label} — đang phát triển',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            color: DashboardColors.cardBorder
                                .withValues(alpha: 0.9),
                          ),
                          if (!narrow)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                              child: Text(
                                'CÀI ĐẶT',
                                style: GoogleFonts.beVietnamPro(
                                  color: DashboardColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          _SidebarTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Hồ sơ',
                            active: false,
                            collapsed: narrow,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hồ sơ — đang phát triển'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _SidebarTile(
                            icon: Icons.settings_outlined,
                            label: 'Cài đặt',
                            active: widget.selected == AppRoute.deviceSetup ||
                                widget.selected == AppRoute.devices,
                            collapsed: narrow,
                            onTap: () {
                              if (widget.onOpenDeviceSetup != null) {
                                widget.onOpenDeviceSetup!();
                              } else {
                                widget.onSelect(AppRoute.devices);
                              }
                            },
                          ),
                          _SidebarTile(
                            icon: Icons.logout_rounded,
                            label: 'Đăng xuất',
                            active: false,
                            collapsed: narrow,
                            danger: true,
                            onTap: widget.onLogout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _expandedHeader() {
    final text = GoogleFonts.beVietnamPro;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 48,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, __, ___) => Text(
                  'CrabSense',
                  style: text(
                    color: DashboardColors.brand,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Smart Farming for a Cleaner Ocean',
                style: text(
                  color: DashboardColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
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
    this.danger = false,
  });

  final IconData icon;
  final String? imageAsset;
  final String label;
  final bool active;
  final bool collapsed;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = danger
        ? const Color(0xFFDC2626)
        : active
            ? DashboardColors.brand
            : const Color(0xFF3D6B5F);

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: active ? DashboardColors.mintActive : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 8 : 12,
              vertical: 10,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Khi đang animate mở rộng, width còn hẹp nhưng collapsed=false
                // → phải vẫn render icon-only để tránh overflow.
                final narrow = collapsed || constraints.maxWidth < 56;
                if (narrow) {
                  return Center(
                    child: _leading(
                      size: imageAsset != null ? 28 : 22,
                      color: accent,
                    ),
                  );
                }
                return Row(
                  children: [
                    _leading(
                      size: imageAsset != null ? 26 : 20,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    if (!collapsed) return tile;
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: tile,
    );
  }

  Widget _leading({required double size, required Color color}) {
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
    return Icon(icon, size: size, color: color);
  }
}
