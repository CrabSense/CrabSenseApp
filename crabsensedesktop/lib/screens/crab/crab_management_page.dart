import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/crab_individual.dart';
import '../../models/crab_status.dart';
import '../../navigation/app_route.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/app_formatters.dart';
import '../../widgets/crab/crab_action_modals.dart';
import '../../widgets/crab/crab_bulk_add_dialog.dart';
import '../../widgets/crab/crab_management_dialogs.dart';
import '../../widgets/crab/crab_management_table.dart';
import '../../widgets/crab/crab_quick_detail.dart';
import '../../widgets/shared/mgmt_ui.dart';

class CrabManagementPage extends StatefulWidget {
  const CrabManagementPage({
    super.key,
    required this.service,
    this.onNavigate,
    this.onOpenDetail,
    this.onOpenArea,
    this.onOpenBoxes,
  });

  final CrabService service;
  final void Function(AppRoute route)? onNavigate;
  final void Function(CrabIndividual crab)? onOpenDetail;
  final void Function(String areaId)? onOpenArea;
  final void Function({required String areaId, String? rowId})? onOpenBoxes;

  @override
  State<CrabManagementPage> createState() => _CrabManagementPageState();
}

class _CrabManagementPageState extends State<CrabManagementPage> {
  final _searchCtrl = TextEditingController();
  final _checked = <String>{};
  Timer? _debounce;
  String? _selectedId;
  var _hidePanel = false;
  var _detailLoading = false;

  CrabService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_svc.crabs.isEmpty && !_svc.loading) _svc.load();
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  List<CrabIndividual> get _paged => _svc.paginatedCrabs;

  CrabIndividual? get _selected {
    if (_hidePanel) return null;
    final id = _selectedId;
    if (id != null) {
      for (final c in _svc.crabs) {
        if (c.id == id) return c;
      }
    }
    final page = _paged;
    return page.isEmpty ? null : page.first;
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _svc.setSearch(q);
    });
  }

  Future<void> _select(CrabIndividual crab) async {
    setState(() {
      _selectedId = crab.id;
      _hidePanel = false;
      _detailLoading = true;
    });
    await _svc.loadDetail(crab.id);
    if (mounted) setState(() => _detailLoading = false);
  }

  Future<void> _onAction(CrabIndividual crab, CrabManagementAction action) async {
    switch (action) {
      case CrabManagementAction.view:
        widget.onOpenDetail?.call(crab);
      case CrabManagementAction.edit:
        await showCrabManagementFormDialog(context, _svc, existing: crab);
      case CrabManagementAction.history:
        widget.onOpenDetail?.call(crab);
      case CrabManagementAction.viewBox:
        _openBoxes(crab);
      case CrabManagementAction.move:
        await showMoveCrabModal(context, _svc, crab);
      case CrabManagementAction.molt:
        await showMarkMoltingModal(context, _svc, crab);
      case CrabManagementAction.readyHarvest:
        final ok = await _svc.markReadyHarvest(crab.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Đã đánh dấu ${crab.code} sắp thu hoạch' : (_svc.error ?? 'Lỗi'),
              ),
            ),
          );
        }
      case CrabManagementAction.dead:
        await showMarkDeadModal(context, _svc, crab);
    }
  }

  void _openBoxes(CrabIndividual crab) {
    if (crab.areaId.isEmpty) return;
    widget.onOpenBoxes?.call(areaId: crab.areaId, rowId: crab.rowId);
  }

  Future<void> _export(List<CrabIndividual> crabs) async {
    if (crabs.isEmpty) return;
    final sb = StringBuffer()
      ..writeln(
        'Ma cua,Lo cua,Day,Hop,Gioi tinh,Can nang (g),Kich thuoc,Suc khoe,Trang thai,Cap nhat',
      );
    String csv(String v) =>
        v.contains(',') || v.contains('"') || v.contains('\n')
            ? '"${v.replaceAll('"', '""')}"'
            : v;
    for (final c in crabs) {
      sb.writeln([
        csv(c.code),
        csv(c.batchId),
        csv(c.rowLabel),
        csv(c.boxLabel),
        csv(c.gender.label),
        c.weightGram.round(),
        csv(c.sizeLabel),
        csv(c.displayHealth.label),
        csv(c.lifecycleStatus.label),
        csv(fmtDateTimeVn(c.lastUpdated)),
      ].join(','));
    }
    final now = DateTime.now();
    final name =
        'crabsense_cua_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất dữ liệu cua',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null || !mounted) return;
    try {
      await File(path).writeAsString('\uFEFF$sb');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất ${crabs.length} cua: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không ghi được file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final wide = MediaQuery.sizeOf(context).width >= 1180;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 12),
          _kpis(),
          const SizedBox(height: 12),
          _filters(),
          const SizedBox(height: 10),
          _chips(),
          const SizedBox(height: 12),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 72, child: _listCard()),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 28,
                        child: selected == null
                            ? _emptyDetail()
                            : CrabQuickDetail(
                                crab: selected,
                                loading: _detailLoading,
                                onClose: () => setState(() {
                                  _hidePanel = true;
                                  _selectedId = null;
                                }),
                                onOpenArea: selected.areaId.isEmpty
                                    ? null
                                    : () => widget.onOpenArea?.call(selected.areaId),
                                onOpenRow: selected.areaId.isEmpty
                                    ? null
                                    : () => _openBoxes(selected),
                                onOpenBox: selected.areaId.isEmpty
                                    ? null
                                    : () => _openBoxes(selected),
                                onHistory: () => widget.onOpenDetail?.call(selected),
                                onOpenFull: () => widget.onOpenDetail?.call(selected),
                              ),
                      ),
                    ],
                  )
                : _listCard(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => widget.onNavigate?.call(AppRoute.dashboard),
                    child: Text(
                      'Dashboard',
                      style: bvText(fontSize: 12.5, color: DashboardColors.brand),
                    ),
                  ),
                  Text(
                    '  >  ',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                  ),
                  Text(
                    'Quản lý Cua',
                    style: bvText(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Quản lý Cua',
                style: bvText(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Giám sát và quản lý từng cá thể cua trong hệ thống.',
                style: bvText(fontSize: 13, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            MgmtOutlineButton(
              icon: Icons.inventory_2_outlined,
              label: 'Nhập lô',
              onTap: () => widget.onNavigate?.call(AppRoute.inboundLots),
              height: 42,
            ),
            MgmtOutlineButton(
              icon: Icons.playlist_add_rounded,
              label: 'Thêm nhiều',
              onTap: () => showCrabBulkAddDialog(
                context,
                _svc,
                onManageLots: () => widget.onNavigate?.call(AppRoute.inboundLots),
              ),
              height: 42,
            ),
            MgmtPrimaryButton(
              icon: Icons.add_rounded,
              label: 'Thêm Cua',
              onTap: () => showCrabManagementFormDialog(
                context,
                _svc,
                onManageLots: () => widget.onNavigate?.call(AppRoute.inboundLots),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpis() {
    final s = _svc.summary;
    if (_svc.loading && _svc.crabs.isEmpty) {
      return LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 1180 ? 6 : c.maxWidth >= 780 ? 3 : 2;
          final gap = 10.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < 6; i++)
                SizedBox(
                  width: w,
                  height: 76,
                  child: Container(decoration: mgmtCardDeco(radius: 14)),
                ),
            ],
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1180
            ? 6
            : c.maxWidth >= 780
                ? 3
                : 2;
        final gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        final items = [
          _Kpi(
            icon: Icons.set_meal_outlined,
            label: 'TỔNG SỐ CUA',
            value: formatInt(s.total),
            hint: 'Tất cả cá thể trong hệ thống',
            color: const Color(0xFF2495E8),
          ),
          _Kpi(
            icon: Icons.eco_outlined,
            label: 'ĐANG NUÔI',
            value: formatInt(s.alive),
            hint: '${s.pct(s.alive).toStringAsFixed(1)}%',
            color: DashboardColors.brandGreen,
          ),
          _Kpi(
            icon: Icons.warning_amber_rounded,
            label: 'THEO DÕI',
            value: formatInt(s.monitoring),
            hint: '${s.pct(s.monitoring).toStringAsFixed(1)}%',
            color: const Color(0xFFF5B700),
          ),
          _Kpi(
            icon: Icons.sync_outlined,
            label: 'ĐANG LỘT XÁC',
            value: formatInt(s.molting),
            hint: '${s.pct(s.molting).toStringAsFixed(1)}%',
            color: const Color(0xFF7C3AED),
          ),
          _Kpi(
            icon: Icons.shopping_basket_outlined,
            label: 'SẮP THU HOẠCH',
            value: formatInt(s.readyHarvest),
            hint: '${s.pct(s.readyHarvest).toStringAsFixed(1)}%',
            color: DashboardColors.seaGreen,
          ),
          _Kpi(
            icon: Icons.heart_broken_outlined,
            label: 'CUA CHẾT',
            value: formatInt(s.dead),
            hint: '${s.pct(s.dead).toStringAsFixed(1)}%',
            color: DashboardColors.risk,
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items) SizedBox(width: w, child: item),
          ],
        );
      },
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: MgmtSearchField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  hint: 'Tìm mã cua, mã hộp hoặc mã lô...',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _areaValueLabel,
                  items: [
                    (kAllFilter, 'Tất cả'),
                    ..._svc.areaFilterItems,
                  ],
                  onSelected: _svc.setAreaFilter,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _rowValueLabel,
                  items: [
                    (kAllFilter, 'Tất cả'),
                    ..._svc.rowFilterItems,
                  ],
                  onSelected: _svc.setRowFilter,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _boxValueLabel,
                  items: [
                    (kAllFilter, 'Tất cả'),
                    ..._svc.boxFilterItems,
                  ],
                  onSelected: _svc.setBoxFilter,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _svc.batchFilter == kAllFilter
                      ? 'Tất cả'
                      : _svc.batchFilter,
                  items: [
                    for (final b in _svc.batchOptions) (b, b == kAllFilter ? 'Tất cả' : b),
                  ],
                  onSelected: _svc.setBatchFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MgmtDropdown<CrabGender?>(
                  valueLabel: _svc.genderFilter?.label ?? 'Tất cả',
                  items: [
                    (null, 'Tất cả'),
                    for (final g in CrabGender.values) (g, g.label),
                  ],
                  onSelected: _svc.setGenderFilter,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<CrabLifecycleStatus?>(
                  valueLabel: _svc.lifecycleFilter?.label ?? 'Tất cả',
                  items: [
                    (null, 'Tất cả'),
                    for (final s in CrabLifecycleStatus.values) (s, s.label),
                  ],
                  onSelected: _svc.setLifecycleFilter,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<CrabDisplayHealth?>(
                  valueLabel: _svc.healthFilter?.label ?? 'Tất cả',
                  items: [
                    (null, 'Tất cả'),
                    for (final h in CrabDisplayHealth.values) (h, h.label),
                  ],
                  onSelected: _svc.setHealthFilter,
                ),
              ),
              const Spacer(),
              MgmtOutlineButton(
                icon: Icons.filter_alt_off_outlined,
                label: 'Xóa bộ lọc',
                onTap: () {
                  _searchCtrl.clear();
                  _svc.clearFilters();
                },
                color: DashboardColors.textMuted,
                height: 42,
              ),
              const SizedBox(width: 8),
              MgmtPrimaryButton(
                icon: Icons.search_rounded,
                label: 'Tìm kiếm',
                onTap: () => _svc.setSearch(_searchCtrl.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _areaValueLabel {
    if (_svc.areaFilter == kAllFilter) return 'Tất cả';
    for (final e in _svc.areaFilterItems) {
      if (e.$1 == _svc.areaFilter) return e.$2;
    }
    return 'Tất cả';
  }

  String get _rowValueLabel {
    if (_svc.rowFilter == kAllFilter) return 'Tất cả';
    for (final e in _svc.rowFilterItems) {
      if (e.$1 == _svc.rowFilter) return e.$2;
    }
    return 'Tất cả';
  }

  String get _boxValueLabel {
    if (_svc.boxFilter == kAllFilter) return 'Tất cả';
    for (final e in _svc.boxFilterItems) {
      if (e.$1 == _svc.boxFilter) return e.$2;
    }
    return 'Tất cả';
  }

  Widget _chips() {
    final s = _svc.summary;
    final items = <(CrabManagementStatusFilter, String, int, IconData)>[
      (CrabManagementStatusFilter.all, 'Tất cả', s.total, Icons.circle),
      (CrabManagementStatusFilter.growing, 'Đang nuôi', s.alive, Icons.eco_outlined),
      (
        CrabManagementStatusFilter.monitoring,
        'Theo dõi',
        s.monitoring,
        Icons.warning_amber_rounded,
      ),
      (CrabManagementStatusFilter.molting, 'Đang lột xác', s.molting, Icons.sync_outlined),
      (
        CrabManagementStatusFilter.readyHarvest,
        'Sắp thu hoạch',
        s.readyHarvest,
        Icons.shopping_basket_outlined,
      ),
      (CrabManagementStatusFilter.dead, 'Chết', s.dead, Icons.favorite_border),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          _Chip(
            label: '${item.$2} (${item.$3})',
            icon: item.$4,
            selected: _svc.statusFilter == item.$1,
            onTap: () => _svc.setStatusFilter(item.$1),
          ),
      ],
    );
  }

  Widget _listCard() {
    final filtered = _svc.filteredCrabs;
    final page = _paged;
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  'Danh sách cua (${filtered.length})',
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const Spacer(),
                MgmtInlineSort<CrabListSort>(
                  value: _svc.sort,
                  items: [
                    for (final s in CrabListSort.values) (s, s.label),
                  ],
                  onChanged: _svc.setSort,
                ),
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: _svc.loading ? null : _svc.load,
                  iconSize: 18,
                  splashRadius: 16,
                  icon: Icon(Icons.refresh_rounded, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DashboardColors.mint),
          Expanded(child: _body(page, filtered)),
          _bottomBar(filtered),
        ],
      ),
    );
  }

  Widget _body(List<CrabIndividual> page, List<CrabIndividual> filtered) {
    if (_svc.loading && _svc.crabs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var i = 0; i < 8; i++)
            Container(
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: DashboardColors.lightMint,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      );
    }
    if (_svc.error != null && _svc.crabs.isEmpty) {
      return MgmtEmptyState(
        icon: Icons.warning_amber_rounded,
        title: 'Không thể tải danh sách cua.',
        message: 'Vui lòng thử lại.',
        action: MgmtPrimaryButton(label: 'Thử lại', onTap: _svc.load),
      );
    }
    if (filtered.isEmpty) {
      if (_svc.crabs.isEmpty) {
        return MgmtEmptyState(
          icon: Icons.set_meal_outlined,
          title: 'Chưa có cua trong hệ thống',
          message:
              'Các cá thể cua sau khi nhập lô hoặc thêm thủ công sẽ xuất hiện tại đây.',
          action: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              MgmtOutlineButton(
                label: 'Nhập lô',
                onTap: () => widget.onNavigate?.call(AppRoute.inboundLots),
              ),
              MgmtPrimaryButton(
                icon: Icons.add_rounded,
                label: 'Thêm cua',
                onTap: () => showCrabManagementFormDialog(
                  context,
                  _svc,
                  onManageLots: () => widget.onNavigate?.call(AppRoute.inboundLots),
                ),
              ),
            ],
          ),
        );
      }
      return MgmtEmptyState(
        icon: Icons.search_rounded,
        title: 'Không tìm thấy cua',
        message: 'Không có cá thể nào phù hợp với bộ lọc hiện tại.',
        action: MgmtOutlineButton(
          label: 'Xóa bộ lọc',
          onTap: () {
            _searchCtrl.clear();
            _svc.clearFilters();
          },
        ),
      );
    }
    return CrabManagementDataTable(
      crabs: page,
      selectedId: _selected?.id,
      checkedIds: _checked,
      onToggle: (c) {
        setState(() {
          if (_checked.contains(c.id)) {
            _checked.remove(c.id);
          } else {
            _checked.add(c.id);
          }
        });
      },
      onToggleAll: () {
        setState(() {
          if (page.every((c) => _checked.contains(c.id))) {
            for (final c in page) {
              _checked.remove(c.id);
            }
          } else {
            for (final c in page) {
              _checked.add(c.id);
            }
          }
        });
      },
      onSelectRow: _select,
      onOpenCode: widget.onOpenDetail,
      onAction: _onAction,
      onSort: (col, asc) {
        _svc.setSort(switch (col) {
          1 => CrabListSort.code,
          5 => CrabListSort.weight,
          7 => CrabListSort.health,
          8 => CrabListSort.status,
          9 => CrabListSort.updatedDesc,
          _ => CrabListSort.updatedDesc,
        });
      },
    );
  }

  Widget _bottomBar(List<CrabIndividual> filtered) {
    final selected = _svc.crabs.where((c) => _checked.contains(c.id)).toList();
    final n = selected.length;
    final totalPages = filtered.isEmpty
        ? 1
        : (filtered.length / _svc.pageSize).ceil().clamp(1, 999);
    final start = filtered.isEmpty ? 0 : (_svc.currentPage - 1) * _svc.pageSize + 1;
    final end = (_svc.currentPage * _svc.pageSize).clamp(0, filtered.length);
    const window = 7;
    var from = (_svc.currentPage - 3).clamp(1, totalPages);
    var to = (from + window - 1).clamp(1, totalPages);
    from = (to - window + 1).clamp(1, totalPages);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DashboardColors.mint)),
      ),
      child: Row(
        children: [
          Text(
            filtered.isEmpty
                ? 'Không có cá thể'
                : 'Hiển thị $start – $end của ${filtered.length} cá thể',
            style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
          ),
          if (n > 0) ...[
            const SizedBox(width: 12),
            Text(
              'Đã chọn $n cua',
              style: bvText(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: DashboardColors.brand,
              ),
            ),
            const SizedBox(width: 8),
            MgmtOutlineButton(
              label: 'Chuyển hộp',
              onTap: () {
                if (n != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chọn 1 cua để chuyển hộp (1 hộp = 1 cua).'),
                    ),
                  );
                  return;
                }
                showMoveCrabModal(context, _svc, selected.first);
              },
              height: 34,
            ),
            const SizedBox(width: 6),
            MgmtOutlineButton(
              label: 'Cập nhật sức khỏe',
              onTap: () => showBulkHealthModal(context, _svc, selected),
              height: 34,
            ),
            const SizedBox(width: 6),
            MgmtOutlineButton(
              icon: Icons.download_outlined,
              label: 'Xuất dữ liệu',
              onTap: () => _export(selected),
              height: 34,
            ),
          ],
          const Spacer(),
          MgmtPageBtn(
            icon: Icons.chevron_left_rounded,
            onTap: _svc.currentPage > 1
                ? () => _svc.goToPage(_svc.currentPage - 1)
                : null,
          ),
          for (var i = from; i <= to; i++) ...[
            const SizedBox(width: 6),
            MgmtPageBtn(
              label: '$i',
              active: i == _svc.currentPage,
              onTap: () => _svc.goToPage(i),
            ),
          ],
          const SizedBox(width: 6),
          MgmtPageBtn(
            icon: Icons.chevron_right_rounded,
            onTap: _svc.currentPage < totalPages
                ? () => _svc.goToPage(_svc.currentPage + 1)
                : null,
          ),
          const SizedBox(width: 16),
          Text('Hiển thị', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          const SizedBox(width: 8),
          MgmtDropdown<int>(
            width: 110,
            valueLabel: '${_svc.pageSize}',
            items: const [
              (10, '10'),
              (20, '20'),
              (50, '50'),
              (100, '100'),
            ],
            onSelected: _svc.setPageSize,
          ),
        ],
      ),
    );
  }

  Widget _emptyDetail() {
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        'Chọn một cua để xem chi tiết',
        style: bvText(fontSize: 13, color: DashboardColors.textMuted),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DashboardColors.mintActive : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? DashboardColors.brand : DashboardColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? DashboardColors.brand : DashboardColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: bvText(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? DashboardColors.brand
                      : DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: mgmtCardDeco(radius: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: DashboardColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: bvText(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
