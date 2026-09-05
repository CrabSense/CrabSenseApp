import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../navigation/app_route.dart';
import '../../services/production_management_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/production/production_dialogs.dart';
import '../../widgets/row/row_cards.dart';
import '../../widgets/row/row_dialogs.dart';
import '../../widgets/row/row_list_toolbar.dart';

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

  Future<void> _onAdd() async {
    final svc = widget.service;
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

    await showCreateRowDialog(context, svc, areaId: areaId);
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

  Future<void> _onAction(RowListItem item, _RowAction type) async {
    final svc = widget.service;
    switch (type) {
      case _RowAction.edit:
        await showEditRowDialog(context, svc, item);
        if (mounted) await svc.load();
      case _RowAction.delete:
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
            onArea: () => widget.onNavigate?.call(AppRoute.farmManagement),
          ),
          const SizedBox(height: 12),
          Text(
            'Quản lý Dãy',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
            onAdd: _onAdd,
          ),
          const SizedBox(height: 20),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                svc.error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          if (svc.loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (paged.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Chưa có dãy phù hợp bộ lọc.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            )
          else ...[
            _RowCardGrid(
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
        ],
      ),
    );
  }
}

enum _RowAction { edit, delete }

class _RowCardGrid extends StatelessWidget {
  const _RowCardGrid({required this.items, required this.onAction});

  final List<RowListItem> items;
  final void Function(RowListItem item, _RowAction type) onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 960 ? 3 : width >= 640 ? 2 : 1;
        final cardWidth = (width - 16 * (columns - 1)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: RowOverviewCard(
                item: item,
                onOpen: () => showRowDetailDialog(
                  context,
                  item: item,
                  onEdit: () => onAction(item, _RowAction.edit),
                  onDelete: () => onAction(item, _RowAction.delete),
                ),
                onEdit: () => onAction(item, _RowAction.edit),
                onDelete: () => onAction(item, _RowAction.delete),
              ),
            );
          }).toList(),
        );
      },
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

