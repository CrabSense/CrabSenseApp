import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_list_item.dart';
import '../../navigation/app_route.dart';
import '../../services/box_management_service.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_list_toolbar.dart';
import '../../widgets/box/box_cards.dart';
import '../../widgets/box/box_list_toolbar.dart';
import '../../widgets/production/production_dialogs.dart';

class BoxManagementPage extends StatefulWidget {
  const BoxManagementPage({
    super.key,
    required this.service,
    required this.productionService,
    this.onNavigate,
    this.onBoxTap,
  });

  final BoxManagementService service;
  final ProductionManagementService productionService;
  final void Function(AppRoute route)? onNavigate;
  final void Function(BoxListItem item)? onBoxTap;

  @override
  State<BoxManagementPage> createState() => _BoxManagementPageState();
}

class _BoxManagementPageState extends State<BoxManagementPage> {
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
    if (svc.rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có dãy — thêm dãy trước')),
      );
      return;
    }

    var areaId = svc.areaFilterId;
    var rowId = svc.rowFilterId;
    if (rowId == null) {
      final picked = await _pickRow(svc);
      if (picked == null || !mounted) return;
      areaId = picked.$1;
      rowId = picked.$2;
    } else {
      areaId ??= svc.rows
          .where((r) => r.id == rowId)
          .map((r) => r.areaId)
          .firstOrNull;
    }

    final prod = widget.productionService;
    prod.selectArea(areaId);
    prod.selectRow(rowId);
    await showBoxFormDialog(context, prod);
    if (mounted) await svc.load();
  }

  Future<(String, String)?> _pickRow(BoxManagementService svc) async {
    var areaId = svc.areaFilterId ??
        (svc.areas.length == 1 ? svc.areas.first.id : svc.areas.first.id);
    var rows = svc.rows.where((r) => r.areaId == areaId).toList();
    if (rows.isEmpty) rows = List.of(svc.rows);
    String? rowId = rows.isNotEmpty ? rows.first.id : null;

    return showDialog<(String, String)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final areaRows = svc.rows.where((r) => r.areaId == areaId).toList();
          return AlertDialog(
            backgroundColor: DashboardColors.card,
            title: Text(
              'Chọn dãy để thêm hộp',
              style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: areaId,
                  dropdownColor: DashboardColors.card,
                  decoration: const InputDecoration(labelText: 'Khu'),
                  items: [
                    for (final a in svc.areas)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.areaCode} — ${a.areaName}'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() {
                      areaId = v;
                      final next = svc.rows.where((r) => r.areaId == v).toList();
                      rowId = next.isNotEmpty ? next.first.id : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: rowId != null && areaRows.any((r) => r.id == rowId)
                      ? rowId
                      : (areaRows.isNotEmpty ? areaRows.first.id : null),
                  dropdownColor: DashboardColors.card,
                  decoration: const InputDecoration(labelText: 'Dãy'),
                  items: [
                    for (final r in areaRows)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text('${r.rowCode} — ${r.rowName}'),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => rowId = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: rowId == null
                    ? null
                    : () => Navigator.pop(ctx, (areaId, rowId!)),
                child: const Text('Tiếp tục'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onAction(BoxListItem item, _BoxAction type) async {
    final svc = widget.service;
    switch (type) {
      case _BoxAction.edit:
        final prod = widget.productionService;
        prod.selectArea(item.areaId);
        prod.selectRow(item.rowId);
        await showBoxFormDialog(context, prod, existing: item.box);
        if (mounted) await svc.load();
      case _BoxAction.delete:
        if (!await confirmDelete(
          context,
          title: 'Xóa hộp?',
          message: '${item.displayName} (${item.box.boxCode})?',
        )) {
          return;
        }
        try {
          await svc.deleteBox(item);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa hộp')),
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

  void _openBox(BoxListItem item) {
    widget.onBoxTap?.call(item);
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
          _Breadcrumb(onNavigate: widget.onNavigate),
          const SizedBox(height: 12),
          Text(
            'Quản lý Hộp',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          BoxListToolbar(
            searchController: _searchCtrl,
            areas: svc.areas,
            rows: svc.rowsForFilter,
            areaFilterId: svc.areaFilterId,
            rowFilterId: svc.rowFilterId,
            occupancyFilter: svc.occupancyFilter,
            crabFilter: svc.crabFilter,
            loading: svc.loading,
            onSearchChanged: svc.setSearch,
            onAreaChanged: svc.setAreaFilter,
            onRowChanged: svc.setRowFilter,
            onOccupancyChanged: svc.setOccupancyFilter,
            onCrabChanged: svc.setCrabFilter,
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
                'Chưa có hộp phù hợp bộ lọc.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
              ),
            )
          else ...[
            _BoxCardGrid(
              items: paged,
              onOpen: _openBox,
              onAction: _onAction,
            ),
            const SizedBox(height: 16),
            AreaListPagination(
              page: svc.page,
              pageSize: BoxManagementService.pageSize,
              itemCount: paged.length,
              totalItems: filtered.length,
              totalPages: svc.totalPages,
              onPageChanged: svc.setPage,
              itemLabel: 'hộp',
            ),
          ],
        ],
      ),
    );
  }
}

enum _BoxAction { edit, delete }

class _BoxCardGrid extends StatelessWidget {
  const _BoxCardGrid({
    required this.items,
    required this.onOpen,
    required this.onAction,
  });

  final List<BoxListItem> items;
  final ValueChanged<BoxListItem> onOpen;
  final void Function(BoxListItem item, _BoxAction type) onAction;

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
              child: BoxOverviewCard(
                item: item,
                onOpen: () => onOpen(item),
                onEdit: () => onAction(item, _BoxAction.edit),
                onDelete: () => onAction(item, _BoxAction.delete),
                onAddCrab: () => onOpen(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onNavigate});

  final void Function(AppRoute route)? onNavigate;

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
        InkWell(
          onTap: () => onNavigate?.call(AppRoute.dashboard),
          child: Text('Dashboard', style: link),
        ),
        Text('  >  ', style: muted),
        InkWell(
          onTap: () => onNavigate?.call(AppRoute.farmManagement),
          child: Text('Quản lý Khu', style: link),
        ),
        Text('  >  ', style: muted),
        InkWell(
          onTap: () => onNavigate?.call(AppRoute.rowManagement),
          child: Text('Quản lý Dãy', style: link),
        ),
        Text('  >  ', style: muted),
        Text(
          'Quản lý Hộp',
          style: muted.copyWith(color: DashboardColors.textPrimary),
        ),
      ],
    );
  }
}
