import 'package:flutter/material.dart';

import '../../models/farm_record.dart';
import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../models/row_status.dart';
import '../../navigation/app_route.dart';
import '../../services/production_management_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/production/production_dialogs.dart' show confirmDelete;
import '../../widgets/row/row_cards.dart' show showRowDetailDialog;
import '../../widgets/row/row_dialogs.dart';
import '../../widgets/shared/mgmt_ui.dart';

const _kBoxOrange = Color(0xFFF59E0B);

enum _RowSort { newest, oldest, nameAz, mostBoxes, mostAlerts }

extension on _RowSort {
  String get label => switch (this) {
        _RowSort.newest => 'Mới nhất',
        _RowSort.oldest => 'Cũ nhất',
        _RowSort.nameAz => 'Tên A → Z',
        _RowSort.mostBoxes => 'Nhiều hộp nhất',
        _RowSort.mostAlerts => 'Nhiều cảnh báo',
      };
}

enum _ViewMode { grid, list }

/// Quản lý dãy — danh sách dãy nuôi thuộc khu (Khu → Dãy → Hộp → Cua).
/// Dữ liệu thật từ `GET /api/farming-rows` qua [RowManagementService].
class RowManagementPage extends StatefulWidget {
  const RowManagementPage({
    super.key,
    required this.service,
    required this.productionService,
    this.onNavigate,
    this.onViewBoxes,
  });

  final RowManagementService service;
  final ProductionManagementService productionService;
  final void Function(AppRoute route)? onNavigate;

  /// "Xem hộp →": mở Quản lý hộp đã lọc theo dãy này.
  final void Function(RowListItem row)? onViewBoxes;

  @override
  State<RowManagementPage> createState() => _RowManagementPageState();
}

class _RowManagementPageState extends State<RowManagementPage> {
  final _searchCtrl = TextEditingController();
  _RowSort _sort = _RowSort.newest;
  _ViewMode _view = _ViewMode.grid;

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

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _onAdd() async {
    final svc = widget.service;
    if (svc.areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có khu — thêm khu trước')),
      );
      return;
    }
    var areaId = svc.areaFilterId;
    if (areaId == null && svc.areas.length == 1) areaId = svc.areas.first.id;
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Chọn khu để thêm dãy',
            style: bvText(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            dropdownColor: Colors.white,
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
            MgmtPrimaryButton(
              label: 'Tiếp tục',
              height: 38,
              onTap:
                  selected == null ? null : () => Navigator.pop(ctx, selected),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEdit(RowListItem item) async {
    await showEditRowDialog(context, widget.service, item);
    if (mounted) await widget.service.load();
  }

  Future<void> _onDelete(RowListItem item) async {
    final ok = await confirmDelete(
      context,
      title: 'Xóa dãy?',
      message: '${item.rowName} (${item.rowCode})?',
    );
    if (!ok || !mounted) return;
    try {
      await widget.service.deleteRow(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa dãy')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _onDetail(RowListItem item) => showRowDetailDialog(
        context,
        item: item,
        onEdit: () => _onEdit(item),
        onDelete: () => _onDelete(item),
      );

  void _onViewBoxes(RowListItem item) {
    if (widget.onViewBoxes != null) {
      widget.onViewBoxes!(item);
    } else {
      widget.onNavigate?.call(AppRoute.boxManagement);
    }
  }

  // ── Data helpers ─────────────────────────────────────────────────────────

  List<RowListItem> _sorted(List<RowListItem> list) {
    final out = [...list];
    int byName(RowListItem a, RowListItem b) =>
        a.rowName.toLowerCase().compareTo(b.rowName.toLowerCase());
    DateTime ts(RowListItem r) =>
        r.row.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (_sort) {
      case _RowSort.newest:
        out.sort((a, b) {
          final c = ts(b).compareTo(ts(a));
          return c != 0 ? c : byName(a, b);
        });
      case _RowSort.oldest:
        out.sort((a, b) {
          final c = ts(a).compareTo(ts(b));
          return c != 0 ? c : byName(a, b);
        });
      case _RowSort.nameAz:
        out.sort(byName);
      case _RowSort.mostBoxes:
        out.sort((a, b) {
          final c = b.boxCount.compareTo(a.boxCount);
          return c != 0 ? c : byName(a, b);
        });
      case _RowSort.mostAlerts:
        out.sort((a, b) {
          final c = b.row.alertBoxCount.compareTo(a.row.alertBoxCount);
          return c != 0 ? c : byName(a, b);
        });
    }
    return out;
  }

  String? _placeOf(RowListItem item) {
    final svc = widget.service;
    final area = svc.areas.where((a) => a.id == item.areaId).firstOrNull;
    final areaName = (area?.areaName ?? item.areaName).trim();
    final place = area?.placeName?.trim() ?? '';
    final parts = <String>[
      if (areaName.isNotEmpty) areaName,
      if (place.isNotEmpty && place != areaName) place,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final all = svc.items;
    final filtered = _sorted(svc.filteredItems);
    final pageSize = RowManagementService.pageSize;
    final totalPages = filtered.isEmpty ? 1 : (filtered.length + pageSize - 1) ~/ pageSize;
    final page = svc.page.clamp(0, totalPages - 1);
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final paged = filtered.isEmpty ? const <RowListItem>[] : filtered.sublist(start, end);

    final totalRows = all.length;
    final activeRows = all.where((r) => r.status == FarmStatus.active).length;
    final totalBoxes = all.fold<int>(0, (s, r) => s + r.boxCount);
    final occupied = all.fold<int>(0, (s, r) => s + r.row.occupiedBoxes);
    String pct(int v, int of) => of == 0 ? '0%' : '${(v * 100 / of).round()}%';

    final areaLabel = svc.areaFilterId == null
        ? 'Tất cả khu'
        : svc.areas
                .where((a) => a.id == svc.areaFilterId)
                .map((a) => a.areaName)
                .firstOrNull ??
            'Khu';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(
            onDashboard: () => widget.onNavigate?.call(AppRoute.dashboard),
            onArea: () => widget.onNavigate?.call(AppRoute.farmManagement),
          ),
          const SizedBox(height: 14),

          // KPI
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 1100 ? 4 : 2;
              const gap = 16.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              final cards = [
                MgmtKpiCard(
                  icon: Icons.view_week_outlined,
                  label: 'Tổng dãy',
                  value: '$totalRows',
                  color: DashboardColors.brand,
                ),
                MgmtKpiCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Đang hoạt động',
                  value: '$activeRows',
                  suffix: '(${pct(activeRows, totalRows)})',
                  color: DashboardColors.brandGreen,
                ),
                MgmtKpiCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Tổng hộp',
                  value: '$totalBoxes',
                  color: kMgmtBlue,
                ),
                MgmtKpiCard(
                  icon: Icons.set_meal_outlined,
                  label: 'Đang nuôi',
                  value: '$occupied',
                  suffix: '(${pct(occupied, totalBoxes)})',
                  color: kMgmtBlue,
                ),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final k in cards) SizedBox(width: w, child: k)],
              );
            },
          ),
          const SizedBox(height: 16),

          // Filters
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 980;
              // PopupMenu bỏ qua value null → dùng '' làm "Tất cả khu".
              final areaDd = MgmtDropdown<String>(
                width: narrow ? null : 240,
                leading: Icons.home_outlined,
                valueLabel: areaLabel,
                items: [
                  ('', 'Tất cả khu'),
                  for (final a in svc.areas) (a.id, a.areaName),
                ],
                onSelected: (v) => svc.setAreaFilter(v.isEmpty ? null : v),
              );
              final statusDd = MgmtDropdown<RowStatusFilter>(
                width: narrow ? null : 200,
                valueLabel: svc.statusFilter.label.replaceAll(RegExp(r'^[^\p{L}]+', unicode: true), ''),
                items: [
                  for (final f in RowStatusFilter.values)
                    (f, f.label.replaceAll(RegExp(r'^[^\p{L}]+', unicode: true), '')),
                ],
                onSelected: svc.setStatusFilter,
              );
              final search = MgmtSearchField(
                controller: _searchCtrl,
                onChanged: svc.setSearch,
                hint: 'Tìm kiếm dãy theo tên, mã hoặc vị trí...',
              );
              final add = MgmtPrimaryButton(
                icon: Icons.add_rounded,
                label: 'Thêm dãy',
                onTap: svc.loading ? null : _onAdd,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: areaDd),
                        const SizedBox(width: 10),
                        Expanded(child: statusDd),
                        const SizedBox(width: 10),
                        add,
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  areaDd,
                  const SizedBox(width: 12),
                  statusDd,
                  const SizedBox(width: 12),
                  Expanded(child: search),
                  const SizedBox(width: 12),
                  add,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // List header
          Row(
            children: [
              Text(
                'Danh sách dãy (${filtered.length})',
                style: bvText(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
              ),
              if (svc.loading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const Spacer(),
              MgmtInlineSort<_RowSort>(
                value: _sort,
                items: [for (final s in _RowSort.values) (s, s.label)],
                onChanged: (s) => setState(() => _sort = s),
              ),
              const SizedBox(width: 14),
              MgmtIconToggle(
                icon: Icons.grid_view_rounded,
                active: _view == _ViewMode.grid,
                tooltip: 'Dạng lưới',
                onTap: () => setState(() => _view = _ViewMode.grid),
              ),
              const SizedBox(width: 6),
              MgmtIconToggle(
                icon: Icons.view_list_rounded,
                active: _view == _ViewMode.list,
                tooltip: 'Dạng danh sách',
                onTap: () => setState(() => _view = _ViewMode.list),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                svc.error!,
                style: bvText(fontSize: 12.5, color: DashboardColors.risk),
              ),
            ),

          if (svc.loading && all.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (paged.isEmpty)
            MgmtEmptyState(
              icon: Icons.view_week_outlined,
              title: 'Chưa có dãy phù hợp bộ lọc',
              message: 'Thử đổi khu / trạng thái / từ khóa, hoặc tạo dãy mới.',
              action: MgmtPrimaryButton(
                icon: Icons.add_rounded,
                label: 'Thêm dãy',
                onTap: _onAdd,
              ),
            )
          else if (_view == _ViewMode.grid)
            _RowGrid(
              items: paged,
              placeOf: _placeOf,
              onDetail: _onDetail,
              onViewBoxes: _onViewBoxes,
              onEdit: _onEdit,
              onDelete: _onDelete,
            )
          else
            Column(
              children: [
                for (var i = 0; i < paged.length; i++) ...[
                  _RowListTile(
                    item: paged[i],
                    place: _placeOf(paged[i]),
                    onDetail: () => _onDetail(paged[i]),
                    onViewBoxes: () => _onViewBoxes(paged[i]),
                    onEdit: () => _onEdit(paged[i]),
                    onDelete: () => _onDelete(paged[i]),
                  ),
                  if (i != paged.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),

          const SizedBox(height: 16),
          MgmtPagination(
            page: page,
            totalPages: totalPages,
            start: filtered.isEmpty ? 0 : start + 1,
            end: end,
            total: filtered.length,
            onPage: svc.setPage,
            itemLabel: 'dãy',
          ),
        ],
      ),
    );
  }
}

// ── Breadcrumb ─────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onDashboard, this.onArea});

  final VoidCallback? onDashboard;
  final VoidCallback? onArea;

  @override
  Widget build(BuildContext context) {
    final link = bvText(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: DashboardColors.brand,
    );
    final muted = bvText(fontSize: 12.5, color: DashboardColors.textMuted);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(onTap: onDashboard, child: Text('Dashboard', style: link)),
        Text('  ›  ', style: muted),
        InkWell(onTap: onArea, child: Text('Quản lý khu', style: link)),
        Text('  ›  ', style: muted),
        Text(
          'Quản lý dãy',
          style: muted.copyWith(
            color: DashboardColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Grid ───────────────────────────────────────────────────────────────────

class _RowGrid extends StatelessWidget {
  const _RowGrid({
    required this.items,
    required this.placeOf,
    required this.onDetail,
    required this.onViewBoxes,
    required this.onEdit,
    required this.onDelete,
  });

  final List<RowListItem> items;
  final String? Function(RowListItem) placeOf;
  final void Function(RowListItem) onDetail;
  final void Function(RowListItem) onViewBoxes;
  final void Function(RowListItem) onEdit;
  final void Function(RowListItem) onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1180
            ? 3
            : c.maxWidth >= 760
                ? 2
                : 1;
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += cols) {
          final slice = items.sublist(i, (i + cols).clamp(0, items.length));
          final missing = cols - slice.length;
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < slice.length; j++) ...[
                    SizedBox(
                      width: w,
                      child: _RowCard(
                        item: slice[j],
                        place: placeOf(slice[j]),
                        onDetail: () => onDetail(slice[j]),
                        onViewBoxes: () => onViewBoxes(slice[j]),
                        onEdit: () => onEdit(slice[j]),
                        onDelete: () => onDelete(slice[j]),
                      ),
                    ),
                    if (j != cols - 1) const SizedBox(width: gap),
                  ],
                  // Ô trống cuối hàng: trang trí cực nhạt (không để trắng trơn).
                  if (missing > 0)
                    SizedBox(
                      width: w * missing + gap * (missing - 1),
                      child: const _EmptySlotDecor(),
                    ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }
}

class _EmptySlotDecor extends StatelessWidget {
  const _EmptySlotDecor();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -30,
            bottom: -40,
            child: Opacity(
              opacity: 0.045,
              child: Image.asset(
                'assets/images/logo.png',
                width: 260,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.set_meal_outlined, size: 200,
                  color: DashboardColors.brand,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 36,
            child: Icon(Icons.bubble_chart_outlined, size: 60,
                color: DashboardColors.brand.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }
}

// ── Card dãy (grid) ────────────────────────────────────────────────────────

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.item,
    required this.place,
    required this.onDetail,
    required this.onViewBoxes,
    required this.onEdit,
    required this.onDelete,
  });

  final RowListItem item;
  final String? place;
  final VoidCallback onDetail;
  final VoidCallback onViewBoxes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = item.row;
    final total = r.boxCount;
    final occupied = r.occupiedBoxes;
    final empty = r.emptyBoxes;
    final usage = total == 0 ? 0.0 : occupied / total;
    final usagePct = (usage * 100).round();
    final hasAlert = r.alertBoxCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DashboardColors.mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.view_week_outlined, size: 18, color: DashboardColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.rowName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bvText(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: DashboardColors.textPrimary,
                            ),
                          ),
                        ),
                        if (hasAlert) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: '${r.alertBoxCount} hộp cảnh báo',
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
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.rowCode,
                      style: bvText(
                        fontSize: 11.5,
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MgmtStatusBadge(
                label: r.status.label,
                color: _statusColor(r.status),
              ),
            ],
          ),
          if (place != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 13, color: DashboardColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    place!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bvText(
                        fontSize: 11.5, color: DashboardColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // 3 mini stat
          Row(
            children: [
              Expanded(
                child: MgmtMiniStat(
                  height: 48,
                  data: MgmtMiniStatData(Icons.inventory_2_outlined,
                      'Tổng hộp', '$total', null, _kBoxOrange),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MgmtMiniStat(
                  height: 48,
                  data: MgmtMiniStatData(Icons.set_meal_outlined, 'Đang nuôi',
                      '$occupied', null, kMgmtBlue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MgmtMiniStat(
                  height: 48,
                  data: MgmtMiniStatData(Icons.crop_square_outlined,
                      'Hộp trống', '$empty', null, kMgmtSlate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3 trạng thái
          Row(
            children: [
              Expanded(
                child: MgmtDotStat(
                  label: 'Bình thường',
                  value: '${r.healthyBoxCount}',
                  color: DashboardColors.brandGreen,
                ),
              ),
              Expanded(
                child: MgmtDotStat(
                  label: 'Theo dõi',
                  value: '${r.watchBoxCount}',
                  color: kMgmtAmber,
                ),
              ),
              Expanded(
                child: MgmtDotStat(
                  label: 'Cảnh báo',
                  value: '${r.alertBoxCount}',
                  color: DashboardColors.risk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          MgmtUsageBar(usage: usage, trailing: '$usagePct%', height: 7),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 13, color: DashboardColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Cập nhật: ${fmtDateTimeVn(r.updatedAt)}',
                style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 12),

          // Actions
          _RowActions(
            onDetail: onDetail,
            onViewBoxes: onViewBoxes,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onDetail,
    required this.onViewBoxes,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  final VoidCallback onDetail;
  final VoidCallback onViewBoxes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 36.0 : 38.0;
    return Row(
      children: [
        MgmtOutlineButton(
          icon: Icons.visibility_outlined,
          label: 'Chi tiết',
          height: h,
          onTap: onDetail,
        ),
        const SizedBox(width: 8),
        MgmtPrimaryButton(
          label: 'Xem hộp',
          trailing: Icons.arrow_forward_rounded,
          height: h,
          onTap: onViewBoxes,
        ),
        const Spacer(),
        MgmtOutlineButton(
          icon: Icons.edit_outlined,
          color: DashboardColors.textPrimary,
          borderColor: DashboardColors.cardBorder,
          tooltip: 'Chỉnh sửa',
          height: h,
          onTap: onEdit,
        ),
        const SizedBox(width: 8),
        MgmtOutlineButton(
          icon: Icons.delete_outline_rounded,
          color: DashboardColors.risk,
          borderColor: DashboardColors.risk.withValues(alpha: 0.35),
          tooltip: 'Xóa dãy',
          height: h,
          onTap: onDelete,
        ),
      ],
    );
  }
}

// ── List view ──────────────────────────────────────────────────────────────

class _RowListTile extends StatelessWidget {
  const _RowListTile({
    required this.item,
    required this.place,
    required this.onDetail,
    required this.onViewBoxes,
    required this.onEdit,
    required this.onDelete,
  });

  final RowListItem item;
  final String? place;
  final VoidCallback onDetail;
  final VoidCallback onViewBoxes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = item.row;
    final total = r.boxCount;
    final occupied = r.occupiedBoxes;
    final usage = total == 0 ? 0.0 : occupied / total;

    Widget stat(String label, String value, Color color) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: bvText(fontSize: 10.5, color: DashboardColors.textMuted)),
              Text(value,
                  style: bvText(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: mgmtCardDeco(radius: 14),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          final head = Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DashboardColors.mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.view_week_outlined, size: 18, color: DashboardColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.rowName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bvText(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: DashboardColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MgmtStatusBadge(
                          label: r.status.label,
                          color: _statusColor(r.status),
                        ),
                      ],
                    ),
                    Text(
                      [item.rowCode, if (place != null) place!].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bvText(
                          fontSize: 11.5, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
          final stats = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              stat('Tổng hộp', '$total', DashboardColors.textPrimary),
              stat('Đang nuôi', '$occupied', kMgmtBlue),
              stat('Trống', '${r.emptyBoxes}', kMgmtSlate),
              stat('Bình thường', '${r.healthyBoxCount}', DashboardColors.brandGreen),
              stat('Theo dõi', '${r.watchBoxCount}', kMgmtAmber),
              stat('Cảnh báo', '${r.alertBoxCount}', DashboardColors.risk),
              SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: MgmtUsageBar(
                    usage: usage,
                    trailing: '${(usage * 100).round()}%',
                    label: 'Sử dụng',
                    height: 6,
                  ),
                ),
              ),
            ],
          );
          final actions = _RowActions(
            compact: true,
            onDetail: onDetail,
            onViewBoxes: onViewBoxes,
            onEdit: onEdit,
            onDelete: onDelete,
          );
          if (wide) {
            return Row(
              children: [
                SizedBox(width: 300, child: head),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: stats,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 340, child: actions),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: stats,
              ),
              const SizedBox(height: 10),
              actions,
            ],
          );
        },
      ),
    );
  }
}

Color _statusColor(FarmStatus s) => switch (s) {
      FarmStatus.active => DashboardColors.brandGreen,
      FarmStatus.suspended => kMgmtAmber,
      FarmStatus.closed => kMgmtSlate,
    };
