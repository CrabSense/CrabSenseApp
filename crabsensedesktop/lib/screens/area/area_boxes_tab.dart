import 'package:flutter/material.dart';

import '../../models/crab_condition.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/shared/mgmt_ui.dart';

/// Màu tím chỉ dùng cho trạng thái "Lột xác".
const kMoltPurple = Color(0xFF7C3AED);

enum _BoxFilter { all, occupied, empty }

enum _CrabFilter { all, normal, watch, alert, molting }

enum _BoxSort { codeAsc, codeDesc, newest, alertFirst }

/// Trạng thái cua trong hộp (đã gộp cho bảng): null = hộp trống.
enum _CrabState { normal, watch, alert, molting }

extension on _CrabState {
  String get label => switch (this) {
        _CrabState.normal => 'Bình thường',
        _CrabState.watch => 'Theo dõi',
        _CrabState.alert => 'Cảnh báo',
        _CrabState.molting => 'Lột xác',
      };
  Color get color => switch (this) {
        _CrabState.normal => DashboardColors.brandGreen,
        _CrabState.watch => kMgmtAmber,
        _CrabState.alert => DashboardColors.risk,
        _CrabState.molting => kMoltPurple,
      };
}

_CrabState? _crabStateOf(BoxRecord b) {
  if (!b.hasCrab) return null;
  final cond = CrabConditionX.parse(
    condition: b.crabCondition,
    moltingStage: b.crabMoltingStage,
    crabStatus: b.crabStatus,
    hasCrab: true,
  );
  if (b.alertCount > 0) return _CrabState.alert;
  return switch (cond) {
    CrabCondition.premolt ||
    CrabCondition.molting ||
    CrabCondition.softshell =>
      _CrabState.molting,
    CrabCondition.problem || CrabCondition.weak => _CrabState.watch,
    _ => _CrabState.normal,
  };
}

bool _aiAbnormal(BoxRecord b) {
  if (b.alertCount > 0) return true;
  final s = (b.aiSummary ?? '').toLowerCase();
  return s.contains('bất thường') ||
      s.contains('abnormal') ||
      s.contains('anomal') ||
      s.contains('cảnh báo');
}

String _crabSubtitle(BoxRecord b) {
  final cond = CrabConditionX.parse(
    condition: b.crabCondition,
    moltingStage: b.crabMoltingStage,
    crabStatus: b.crabStatus,
    hasCrab: b.hasCrab,
  );
  return switch (cond) {
    CrabCondition.normal => 'Khỏe mạnh',
    CrabCondition.empty => 'Chưa có cua',
    _ => cond.label,
  };
}

DateTime? _updatedAt(BoxRecord b) =>
    b.aiUpdatedAt ?? b.crabInBoxSince ?? b.emptySince;

/// Tab "Danh sách hộp" trong Chi tiết khu: bảng hộp thuộc khu, lọc theo dãy /
/// trạng thái hộp / trạng thái cua, chọn nhiều để xoá, phân trang.
class AreaBoxesTab extends StatefulWidget {
  const AreaBoxesTab({
    super.key,
    required this.boxes,
    required this.rows,
    this.initialRowId,
    this.onOpenBox,
    this.onOpenCrab,
    this.onEditBox,
    this.onDeleteBoxes,
    this.onAddBox,
    this.onRefresh,
  });

  final List<BoxRecord> boxes;
  final List<RowRecord> rows;
  final String? initialRowId;
  final void Function(BoxRecord box)? onOpenBox;
  final void Function(BoxRecord box)? onOpenCrab;
  final void Function(BoxRecord box)? onEditBox;

  /// Xoá 1 hoặc nhiều hộp; trả về true nếu đã xoá (để bỏ chọn).
  final Future<bool> Function(List<BoxRecord> boxes)? onDeleteBoxes;
  final void Function(RowRecord? row)? onAddBox;
  final Future<void> Function()? onRefresh;

  @override
  State<AreaBoxesTab> createState() => _AreaBoxesTabState();
}

class _AreaBoxesTabState extends State<AreaBoxesTab> {
  final _search = TextEditingController();
  String? _rowId;
  _BoxFilter _boxFilter = _BoxFilter.all;
  _CrabFilter _crabFilter = _CrabFilter.all;
  _BoxSort _sort = _BoxSort.codeAsc;
  int _page = 0;
  int _pageSize = 10;
  final _selected = <String>{};
  bool _deleting = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _rowId = widget.initialRowId;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BoxRecord> get _filtered {
    var list = widget.boxes;
    if (_rowId != null) list = list.where((b) => b.rowId == _rowId).toList();
    list = switch (_boxFilter) {
      _BoxFilter.occupied => list.where((b) => b.hasCrab).toList(),
      _BoxFilter.empty => list.where((b) => !b.hasCrab).toList(),
      _BoxFilter.all => list,
    };
    if (_crabFilter != _CrabFilter.all) {
      final want = switch (_crabFilter) {
        _CrabFilter.normal => _CrabState.normal,
        _CrabFilter.watch => _CrabState.watch,
        _CrabFilter.alert => _CrabState.alert,
        _CrabFilter.molting => _CrabState.molting,
        _CrabFilter.all => null,
      };
      list = list.where((b) => _crabStateOf(b) == want).toList();
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        return b.boxCode.toLowerCase().contains(q) ||
            b.title.toLowerCase().contains(q) ||
            (b.crabTag ?? '').toLowerCase().contains(q) ||
            (b.crabId ?? '').toLowerCase().contains(q) ||
            (b.rowName ?? '').toLowerCase().contains(q);
      }).toList();
    }
    list = [...list];
    switch (_sort) {
      case _BoxSort.codeAsc:
        list.sort((a, b) => a.boxCode.compareTo(b.boxCode));
      case _BoxSort.codeDesc:
        list.sort((a, b) => b.boxCode.compareTo(a.boxCode));
      case _BoxSort.newest:
        list.sort((a, b) {
          final x = _updatedAt(a), y = _updatedAt(b);
          if (x == null && y == null) return a.boxCode.compareTo(b.boxCode);
          if (x == null) return 1;
          if (y == null) return -1;
          return y.compareTo(x);
        });
      case _BoxSort.alertFirst:
        int rank(BoxRecord b) => switch (_crabStateOf(b)) {
              _CrabState.alert => 0,
              _CrabState.watch => 1,
              _CrabState.molting => 2,
              _CrabState.normal => 3,
              null => 4,
            };
        list.sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          return r != 0 ? r : a.boxCode.compareTo(b.boxCode);
        });
    }
    return list;
  }

  void _resetPage() => _page = 0;

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty || widget.onDeleteBoxes == null) return;
    final targets =
        widget.boxes.where((b) => _selected.contains(b.id)).toList();
    setState(() => _deleting = true);
    final ok = await widget.onDeleteBoxes!(targets);
    if (!mounted) return;
    setState(() {
      _deleting = false;
      if (ok) _selected.clear();
    });
  }

  Future<void> _refresh() async {
    if (widget.onRefresh == null) return;
    setState(() => _refreshing = true);
    await widget.onRefresh!();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final rowById = {for (final r in widget.rows) r.id: r};
    final all = _filtered;
    final totalPages = all.isEmpty ? 1 : (all.length + _pageSize - 1) ~/ _pageSize;
    final page = _page.clamp(0, totalPages - 1);
    final start = page * _pageSize;
    final shown = all.isEmpty
        ? const <BoxRecord>[]
        : all.sublist(start, (start + _pageSize).clamp(0, all.length));
    final pageIds = shown.map((b) => b.id).toSet();
    final allOnPageSelected =
        pageIds.isNotEmpty && pageIds.every(_selected.contains);
    final selectedRow = _rowId == null ? null : rowById[_rowId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter toolbar ───────────────────────────────────────────────
        Row(
          children: [
            // PopupMenu bỏ qua value null → dùng '' làm "Tất cả dãy".
            MgmtDropdown<String>(
              width: 150,
              valueLabel: selectedRow == null ? 'Tất cả dãy' : selectedRow.rowName,
              items: [
                ('', 'Tất cả dãy'),
                for (final r in widget.rows) (r.id, r.rowName),
              ],
              onSelected: (v) => setState(() {
                _rowId = v.isEmpty ? null : v;
                _resetPage();
              }),
            ),
            const SizedBox(width: 10),
            MgmtDropdown<_BoxFilter>(
              width: 190,
              valueLabel: switch (_boxFilter) {
                _BoxFilter.all => 'Tất cả trạng thái hộp',
                _BoxFilter.occupied => 'Đang nuôi',
                _BoxFilter.empty => 'Hộp trống',
              },
              items: const [
                (_BoxFilter.all, 'Tất cả trạng thái hộp'),
                (_BoxFilter.occupied, 'Đang nuôi'),
                (_BoxFilter.empty, 'Hộp trống'),
              ],
              onSelected: (v) => setState(() {
                _boxFilter = v;
                _resetPage();
              }),
            ),
            const SizedBox(width: 10),
            MgmtDropdown<_CrabFilter>(
              width: 190,
              valueLabel: switch (_crabFilter) {
                _CrabFilter.all => 'Tất cả trạng thái cua',
                _CrabFilter.normal => 'Bình thường',
                _CrabFilter.watch => 'Theo dõi',
                _CrabFilter.alert => 'Cảnh báo',
                _CrabFilter.molting => 'Lột xác',
              },
              items: const [
                (_CrabFilter.all, 'Tất cả trạng thái cua'),
                (_CrabFilter.normal, 'Bình thường'),
                (_CrabFilter.watch, 'Theo dõi'),
                (_CrabFilter.alert, 'Cảnh báo'),
                (_CrabFilter.molting, 'Lột xác'),
              ],
              onSelected: (v) => setState(() {
                _crabFilter = v;
                _resetPage();
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 42,
                child: MgmtSearchField(
                  controller: _search,
                  onChanged: (_) => setState(_resetPage),
                  hint: 'Tìm kiếm theo mã hộp, mã cua...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            MgmtPrimaryButton(
              icon: Icons.add_rounded,
              label: 'Thêm hộp',
              onTap: widget.onAddBox == null
                  ? null
                  : () => widget.onAddBox!(selectedRow),
            ),
            const SizedBox(width: 8),
            MgmtIconToggle(
              icon: Icons.table_rows_rounded,
              active: true,
              tooltip: 'Dạng bảng',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            MgmtOutlineButton(
              icon: _refreshing ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
              tooltip: 'Tải lại',
              height: 42,
              onTap: _refreshing ? null : _refresh,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Bảng ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: mgmtCardDeco(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Danh sách hộp (${all.length})',
                      style: bvText(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ),
                  MgmtInlineSort<_BoxSort>(
                    value: _sort,
                    items: const [
                      (_BoxSort.codeAsc, 'Mã hộp (A → Z)'),
                      (_BoxSort.codeDesc, 'Mã hộp (Z → A)'),
                      (_BoxSort.newest, 'Cập nhật mới nhất'),
                      (_BoxSort.alertFirst, 'Cảnh báo trước'),
                    ],
                    onChanged: (v) => setState(() {
                      _sort = v;
                      _resetPage();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HeaderRow(
                allSelected: allOnPageSelected,
                anySelected: pageIds.any(_selected.contains),
                onToggleAll: (v) => setState(() {
                  if (v == true) {
                    _selected.addAll(pageIds);
                  } else {
                    _selected.removeAll(pageIds);
                  }
                }),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      widget.boxes.isEmpty
                          ? 'Khu này chưa có hộp.'
                          : 'Không có hộp khớp bộ lọc.',
                      style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                    ),
                  ),
                )
              else
                for (final b in shown)
                  _BoxLine(
                    box: b,
                    rowName: b.rowName ?? rowById[b.rowId]?.rowName ?? '—',
                    selected: _selected.contains(b.id),
                    onSelected: (v) => setState(() {
                      if (v == true) {
                        _selected.add(b.id);
                      } else {
                        _selected.remove(b.id);
                      }
                    }),
                    onOpen: widget.onOpenBox == null ? null : () => widget.onOpenBox!(b),
                    onOpenCrab: widget.onOpenCrab == null || !b.hasCrab
                        ? null
                        : () => widget.onOpenCrab!(b),
                    onEdit: widget.onEditBox == null ? null : () => widget.onEditBox!(b),
                    onDelete: widget.onDeleteBoxes == null
                        ? null
                        : () async {
                            final ok = await widget.onDeleteBoxes!([b]);
                            if (ok && mounted) {
                              setState(() => _selected.remove(b.id));
                            }
                          },
                  ),
              const SizedBox(height: 12),

              // ── Bulk + pagination ──────────────────────────────────────
              Row(
                children: [
                  Icon(
                    _selected.isEmpty
                        ? Icons.check_box_outline_blank_rounded
                        : Icons.check_box_rounded,
                    size: 18,
                    color: _selected.isEmpty
                        ? DashboardColors.textMuted
                        : DashboardColors.brand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đã chọn ${_selected.length} hộp',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  MgmtOutlineButton(
                    icon: Icons.delete_outline_rounded,
                    label: _deleting ? 'Đang xoá...' : 'Xóa',
                    color: DashboardColors.risk,
                    borderColor: DashboardColors.risk.withValues(alpha: 0.5),
                    height: 34,
                    onTap: _selected.isEmpty || _deleting ? null : _deleteSelected,
                  ),
                  const Spacer(),
                  MgmtPageBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: page > 0 ? () => setState(() => _page = page - 1) : null,
                  ),
                  for (var i = 0; i < totalPages.clamp(1, 12); i++) ...[
                    const SizedBox(width: 6),
                    MgmtPageBtn(
                      label: '${i + 1}',
                      active: i == page,
                      onTap: () => setState(() => _page = i),
                    ),
                  ],
                  const SizedBox(width: 6),
                  MgmtPageBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: page < totalPages - 1
                        ? () => setState(() => _page = page + 1)
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    'Hiển thị',
                    style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 34,
                    child: MgmtDropdown<int>(
                      width: 120,
                      valueLabel: '$_pageSize / trang',
                      items: const [
                        (10, '10 / trang'),
                        (20, '20 / trang'),
                        (50, '50 / trang'),
                      ],
                      onSelected: (v) => setState(() {
                        _pageSize = v;
                        _resetPage();
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cột ─────────────────────────────────────────────────────────────────────

const _kCols = <(String, int, TextAlign)>[
  ('MÃ HỘP', 10, TextAlign.left),
  ('DÃY', 7, TextAlign.left),
  ('CUA TRONG HỘP', 16, TextAlign.left),
  ('TRẠNG THÁI HỘP', 13, TextAlign.left),
  ('TRẠNG THÁI CUA', 13, TextAlign.left),
  ('AI GIÁM SÁT', 15, TextAlign.left),
  ('CẬP NHẬT CUỐI', 13, TextAlign.left),
  ('THAO TÁC', 11, TextAlign.center),
];

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.allSelected,
    required this.anySelected,
    required this.onToggleAll,
  });

  final bool allSelected;
  final bool anySelected;
  final ValueChanged<bool?> onToggleAll;

  @override
  Widget build(BuildContext context) {
    final head = bvText(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: DashboardColors.textMuted,
      letterSpacing: 0.4,
    );
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 6, right: 12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Check(
            value: allSelected,
            tristate: anySelected && !allSelected,
            onChanged: onToggleAll,
          ),
          for (final (label, flex, align) in _kCols)
            Expanded(
              flex: flex,
              child: Text(label, style: head, textAlign: align),
            ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.value,
    required this.onChanged,
    this.tristate = false,
  });

  final bool value;
  final bool tristate;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Checkbox(
        value: tristate ? null : value,
        tristate: tristate,
        onChanged: (v) => onChanged(v ?? true),
        activeColor: DashboardColors.brand,
        side: BorderSide(color: DashboardColors.textMuted.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _BoxLine extends StatefulWidget {
  const _BoxLine({
    required this.box,
    required this.rowName,
    required this.selected,
    required this.onSelected,
    this.onOpen,
    this.onOpenCrab,
    this.onEdit,
    this.onDelete,
  });

  final BoxRecord box;
  final String rowName;
  final bool selected;
  final ValueChanged<bool?> onSelected;
  final VoidCallback? onOpen;
  final VoidCallback? onOpenCrab;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_BoxLine> createState() => _BoxLineState();
}

class _BoxLineState extends State<_BoxLine> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.box;
    final hasCrab = b.hasCrab;
    final crab = _crabStateOf(b);
    final abnormal = hasCrab && _aiAbnormal(b);
    final updated = _updatedAt(b);
    final crabTag = (b.crabTag?.trim().isNotEmpty ?? false)
        ? b.crabTag!.trim()
        : (b.crabId != null && b.crabId != 'null' ? b.crabId! : '—');
    final dash = bvText(fontSize: 13, color: DashboardColors.textMuted);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 6, right: 12),
        decoration: BoxDecoration(
          color: widget.selected
              ? DashboardColors.mint.withValues(alpha: 0.55)
              : _hover
                  ? DashboardColors.lightMint.withValues(alpha: 0.7)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(color: DashboardColors.cardBorder, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            _Check(value: widget.selected, onChanged: widget.onSelected),
            // Mã hộp
            Expanded(
              flex: _kCols[0].$2,
              child: InkWell(
                onTap: widget.onOpen,
                child: Text(
                  b.boxCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ),
            // Dãy
            Expanded(
              flex: _kCols[1].$2,
              child: Text(
                widget.rowName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
              ),
            ),
            // Cua trong hộp
            Expanded(
              flex: _kCols[2].$2,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: (crab?.color ?? kMgmtSlate).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      hasCrab ? Icons.set_meal_rounded : Icons.inventory_2_outlined,
                      size: 15,
                      color: crab?.color ?? kMgmtSlate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: widget.onOpenCrab,
                          child: Text(
                            hasCrab ? crabTag : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bvText(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: hasCrab && widget.onOpenCrab != null
                                  ? DashboardColors.brand
                                  : DashboardColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _crabSubtitle(b),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bvText(
                            fontSize: 10.5,
                            color: crab == _CrabState.molting
                                ? kMoltPurple
                                : DashboardColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Trạng thái hộp
            Expanded(
              flex: _kCols[3].$2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _DotBadge(
                  label: hasCrab ? 'Đang nuôi' : 'Hộp trống',
                  color: hasCrab ? kMgmtAmber : kMgmtSlate,
                ),
              ),
            ),
            // Trạng thái cua
            Expanded(
              flex: _kCols[4].$2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: crab == null
                    ? Text('—', style: dash)
                    : _DotBadge(label: crab.label, color: crab.color),
              ),
            ),
            // AI giám sát
            Expanded(
              flex: _kCols[5].$2,
              child: !hasCrab
                  ? Text('—', style: dash)
                  : Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: abnormal
                                ? DashboardColors.risk
                                : DashboardColors.brandGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            abnormal ? 'Phát hiện bất thường' : 'Bình thường',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bvText(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: abnormal
                                  ? DashboardColors.risk
                                  : DashboardColors.brandGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            // Cập nhật
            Expanded(
              flex: _kCols[6].$2,
              child: Text(
                updated == null ? '—' : fmtDateTimeVn(updated),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
              ),
            ),
            // Thao tác
            Expanded(
              flex: _kCols[7].$2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Xem chi tiết',
                    color: DashboardColors.textPrimary,
                    bg: DashboardColors.lightMint,
                    onTap: widget.onOpen,
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    tooltip: 'Chỉnh sửa',
                    color: DashboardColors.brand,
                    bg: DashboardColors.mint,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Xóa',
                    color: DashboardColors.risk,
                    bg: DashboardColors.risk.withValues(alpha: 0.1),
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotBadge extends StatelessWidget {
  const _DotBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: bvText(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.bg,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 15, color: onTap == null ? color.withValues(alpha: 0.4) : color),
          ),
        ),
      ),
    );
  }
}
