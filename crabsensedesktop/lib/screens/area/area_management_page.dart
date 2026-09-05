import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_form_dialog.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/area/area_table.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/production/production_dialogs.dart' show confirmDelete;

class AreaManagementPage extends StatefulWidget {
  const AreaManagementPage({
    super.key,
    required this.service,
    this.onNavigate,
    this.onOpenDetail,
  });

  final AreaManagementService service;
  final void Function(AppRoute route)? onNavigate;
  final void Function(AreaRecord area)? onOpenDetail;

  @override
  State<AreaManagementPage> createState() => _AreaManagementPageState();
}

class _AreaManagementPageState extends State<AreaManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.areas.isEmpty) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> _onTableAction(AreaRecord a, AreaTableAction action) async {
    final svc = widget.service;
    switch (action) {
      case AreaTableAction.view:
        widget.onOpenDetail?.call(a);
      case AreaTableAction.edit:
        await showAreaFormDialog(context, svc, existing: a);
      case AreaTableAction.delete:
        if (!await confirmDelete(
          context,
          title: 'Xóa khu?',
          message: '${a.areaName} (${a.areaCode})?',
        )) {
          return;
        }
        try {
          await svc.deleteArea(a);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final items = svc.pagedAreas;
    final filtered = svc.filteredAreas;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(
            onDashboard: () => widget.onNavigate?.call(AppRoute.dashboard),
            onFarm: () => widget.onNavigate?.call(AppRoute.farmManagement),
          ),
          const SizedBox(height: 12),
          Text(
            'Quản lý Khu',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 700
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.8 : 2.2,
                children: [
                  _StatCard(
                    title: 'TỔNG SỐ KHU',
                    value: '${svc.summary.total}',
                    subtitle: '${svc.summary.total} khu trên trại',
                    accent: DashboardColors.purple,
                    icon: Icons.grid_view_rounded,
                  ),
                  _StatCard(
                    title: 'ĐANG HOẠT ĐỘNG',
                    value: '${svc.summary.active}',
                    subtitle: svc.summary.total > 0
                        ? 'Hiệu suất: ${((svc.summary.active / svc.summary.total) * 100).round()}%'
                        : '—',
                    accent: DashboardColors.seaGreen,
                    icon: Icons.bolt_rounded,
                  ),
                  _StatCard(
                    title: 'KHU BẢO TRÌ',
                    value: '${svc.summary.maintenance}',
                    subtitle: 'Theo dõi bảo trì định kỳ',
                    accent: DashboardColors.oceanBlue,
                    icon: Icons.build_circle_outlined,
                  ),
                  _StatCard(
                    title: 'TỔNG SỐ HỘP NUÔI',
                    value: '${svc.summary.totalBoxes}',
                    subtitle: svc.summary.total > 0
                        ? 'TB ${(svc.summary.totalBoxes / svc.summary.total).round()} hộp/khu'
                        : '—',
                    accent: const Color(0xFFE879F9),
                    icon: Icons.inventory_2_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                svc.error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AreaListToolbar(
                  searchController: _searchCtrl,
                  statusFilter: svc.statusFilter,
                  loading: svc.loading,
                  onSearchChanged: svc.setSearch,
                  onFilterChanged: svc.setStatusFilter,
                  onAdd: () => showAreaFormDialog(context, svc),
                  onRefresh: svc.load,
                ),
                const SizedBox(height: 20),
                if (svc.loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'Chưa có khu phù hợp bộ lọc.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  AreaDataTable(
                    areas: items,
                    onAction: _onTableAction,
                  ),
                const SizedBox(height: 16),
                AreaListPagination(
                  page: svc.page,
                  pageSize: AreaManagementService.pageSize,
                  itemCount: items.length,
                  totalItems: filtered.length,
                  totalPages: svc.totalPages,
                  onPageChanged: svc.setPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onDashboard, this.onFarm});

  final VoidCallback? onDashboard;
  final VoidCallback? onFarm;

  @override
  Widget build(BuildContext context) {
    TextStyle link = GoogleFonts.notoSans(
      color: DashboardColors.oceanBlue,
      fontSize: 13,
    );
    TextStyle current = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 13,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: onDashboard,
          child: Text('Dashboard', style: link),
        ),
        Text('  >  ', style: current),
        InkWell(
          onTap: onFarm,
          child: Text('Quản lý khu', style: link),
        ),
        Text('  >  ', style: current),
        Text(
          'Quản lý Khu',
          style: current.copyWith(color: DashboardColors.textPrimary),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: accent.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: accent.withValues(alpha: 0.85), size: 32),
        ],
      ),
    );
  }
}
