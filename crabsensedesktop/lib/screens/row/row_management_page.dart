import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../models/row_status.dart';
import '../../navigation/app_route.dart';
import '../../services/production_management_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/production/production_dialogs.dart';
import '../../widgets/row/row_list_toolbar.dart';
import '../../widgets/row/row_table.dart';

class RowManagementPage extends StatefulWidget {
  const RowManagementPage({
    super.key,
    required this.service,
    required this.productionService,
    this.onNavigate,
  });

  final RowManagementService service;
  final ProductionManagementService productionService;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<RowManagementPage> createState() => _RowManagementPageState();
}

class _RowManagementPageState extends State<RowManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.items.isEmpty) {
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

  String _formatCount(int n) {
    if (n < 1000) return '$n';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _onAdd() async {
    final svc = widget.service;
    final prod = widget.productionService;
    if (svc.areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có khu — thêm khu trước')),
      );
      return;
    }
    var areaId = svc.areaFilterId;
    if (areaId == null && svc.areas.length == 1) {
      areaId = svc.areas.first.id;
    }
    if (areaId == null) {
      final picked = await _pickArea(svc.areas);
      if (picked == null || !mounted) return;
      areaId = picked;
    }

    prod.selectArea(areaId);
    await showRowFormDialog(context, prod);
    if (mounted) await svc.load();
  }

  Future<String?> _pickArea(List<AreaRecord> areas) async {
    String? selected = areas.isNotEmpty ? areas.first.id : null;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: DashboardColors.card,
          title: Text(
            'Chọn khu để thêm dãy',
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
          ),
          content: DropdownButtonFormField<String>(
            value: selected,
            dropdownColor: DashboardColors.card,
            decoration: const InputDecoration(labelText: 'Khu'),
            items: [
              for (final a in areas)
                DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.areaCode} — ${a.areaName}'),
                ),
            ],
            onChanged: (v) => setLocal(() => selected = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(ctx, selected),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(RowListItem item, RowTableActionType type) async {
    final svc = widget.service;
    final prod = widget.productionService;
    switch (type) {
      case RowTableActionType.edit:
        prod.selectArea(item.areaId);
        await showRowFormDialog(context, prod, existing: item.row);
        if (mounted) await svc.load();
      case RowTableActionType.delete:
        if (!await confirmDelete(
          context,
          title: 'Xóa dãy?',
          message: '${item.rowName} (${item.rowCode})?',
        )) {
          return;
        }
        try {
          await svc.deleteRow(item);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa dãy')),
            );
          }
        } catch (e) {
          if (mounted) {
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
    final paged = svc.pagedItems;
    final filtered = svc.filteredItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(
            onDashboard: () => widget.onNavigate?.call(AppRoute.dashboard),
            onArea: () => widget.onNavigate?.call(AppRoute.areaManagement),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Quản lý Dãy',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: svc.loading ? null : _onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm Dãy Mới'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.4 : 1.85,
                children: [
                  _StatCard(
                    title: 'TỔNG SỐ DÃY',
                    value: '${svc.summary.total}',
                    tag: 'HỆ THỐNG',
                    accent: DashboardColors.purple,
                    icon: Icons.grid_view_rounded,
                  ),
                  _StatCard(
                    title: 'DÃY ĐANG HOẠT ĐỘNG',
                    value: '${svc.summary.active}',
                    tag: 'LIVE',
                    accent: DashboardColors.seaGreen,
                    icon: Icons.check_circle_outline,
                  ),
                  _StatCard(
                    title: 'DÃY BẢO TRÌ',
                    value: '${svc.summary.maintenance}',
                    tag: 'MAINTENANCE',
                    accent: DashboardColors.oceanBlue,
                    icon: Icons.build_circle_outlined,
                  ),
                  _StatCard(
                    title: 'TỔNG SỐ HỘP NUÔI',
                    value: _formatCount(svc.summary.totalBoxes),
                    tag: 'CAPACITY',
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
                RowListToolbar(
                  searchController: _searchCtrl,
                  areas: svc.areas,
                  areaFilterId: svc.areaFilterId,
                  statusFilter: svc.statusFilter,
                  loading: svc.loading,
                  onSearchChanged: svc.setSearch,
                  onAreaChanged: svc.setAreaFilter,
                  onStatusChanged: (f) {
                    if (f != null) svc.setStatusFilter(f);
                  },
                  onRefresh: svc.load,
                ),
                const SizedBox(height: 20),
                if (svc.loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  RowDataTable(
                    items: paged,
                    onAction: _onAction,
                  ),
                const SizedBox(height: 16),
                AreaListPagination(
                  page: svc.page,
                  pageSize: RowManagementService.pageSize,
                  itemCount: paged.length,
                  totalItems: filtered.length,
                  totalPages: svc.totalPages,
                  onPageChanged: svc.setPage,
                  itemLabel: 'dãy',
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
  const _Breadcrumb({this.onDashboard, this.onArea});

  final VoidCallback? onDashboard;
  final VoidCallback? onArea;

  @override
  Widget build(BuildContext context) {
    final link = GoogleFonts.notoSans(
      color: DashboardColors.oceanBlue,
      fontSize: 13,
    );
    final muted = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 13,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(onTap: onDashboard, child: Text('Dashboard', style: link)),
        Text('  >  ', style: muted),
        InkWell(onTap: onArea, child: Text('Quản lý Khu', style: link)),
        Text('  >  ', style: muted),
        Text(
          'Quản lý Dãy',
          style: muted.copyWith(color: DashboardColors.textPrimary),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.tag,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String tag;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: accent.withValues(alpha: 0.35),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.notoSans(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          Icon(icon, color: accent.withValues(alpha: 0.85), size: 32),
        ],
      ),
    );
  }
}
