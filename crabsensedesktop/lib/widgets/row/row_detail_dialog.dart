import 'package:flutter/material.dart';

import '../../models/crab_condition.dart';
import '../../models/farm_record.dart';
import '../../models/production_models.dart';
import '../../models/row_list_item.dart';
import '../../services/production_management_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';

const _kOverlay = Color.fromRGBO(15, 35, 30, 0.45);
const _kCancelBorder = Color(0xFFBFDCD3);
const _kBlue = Color(0xFF2495E8);
const _kAmber = Color(0xFFF5B700);
const _kSlate = Color(0xFF94A3B8);

Future<void> showRowDetailDialog(
  BuildContext context, {
  required RowListItem item,
  required VoidCallback onEdit,
  VoidCallback? onViewBoxes,
  Future<void> Function()? onDelete,
  RowManagementService? rowService,
  ProductionManagementService? productionService,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: _kOverlay,
    builder: (_) => _RowDetailDialog(
      item: item,
      onEdit: onEdit,
      onViewBoxes: onViewBoxes,
      onDelete: onDelete,
      rowService: rowService,
      productionService: productionService,
    ),
  );
}

class _RowDetailDialog extends StatefulWidget {
  const _RowDetailDialog({
    required this.item,
    required this.onEdit,
    this.onViewBoxes,
    this.onDelete,
    this.rowService,
    this.productionService,
  });

  final RowListItem item;
  final VoidCallback onEdit;
  final VoidCallback? onViewBoxes;
  final Future<void> Function()? onDelete;
  final RowManagementService? rowService;
  final ProductionManagementService? productionService;

  @override
  State<_RowDetailDialog> createState() => _RowDetailDialogState();
}

class _CrabBuckets {
  const _CrabBuckets({
    this.normal = 0,
    this.monitoring = 0,
    this.warning = 0,
  });

  final int normal;
  final int monitoring;
  final int warning;
  int get total => normal + monitoring + warning;
}

class _RowDetailDialogState extends State<_RowDetailDialog> {
  late RowRecord _row;
  List<BoxRecord> _boxes = const [];
  var _loading = true;
  String? _error;
  var _acting = false;

  @override
  void initState() {
    super.initState();
    _row = widget.item.row;
    if (widget.rowService == null && widget.productionService == null) {
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.item.rowId;
      if (widget.rowService != null) {
        final d = await widget.rowService!.fetchDetail(id);
        if (!mounted) return;
        setState(() {
          _row = d.row;
          _boxes = d.boxes;
          _loading = false;
        });
        return;
      }
      if (widget.productionService != null) {
        final row = await widget.productionService!.fetchRowById(id);
        final boxes = await widget.productionService!.fetchBoxesOfRow(id);
        if (!mounted) return;
        setState(() {
          _row = row;
          _boxes = boxes;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  int get _totalBoxes => _row.boxCount;
  int get _occupied {
    final n = _row.occupiedBoxes;
    if (n > 0) return n.clamp(0, _totalBoxes);
    return _row.crabCount.clamp(0, _totalBoxes);
  }

  int get _empty => (_totalBoxes - _occupied).clamp(0, _totalBoxes);
  int get _boxWarning => _row.alertBoxCount.clamp(0, _totalBoxes);
  int get _maxBoxes => _row.capacity > 0 ? _row.capacity : _totalBoxes;

  double get _usage {
    if (_maxBoxes <= 0) return 0;
    return (_occupied / _maxBoxes).clamp(0.0, 1.0);
  }

  _CrabBuckets get _crabs {
    if (_boxes.isEmpty) return const _CrabBuckets();
    var normal = 0, monitoring = 0, warning = 0;
    for (final b in _boxes) {
      if (!b.hasCrab) continue;
      final n = b.crabCount > 0 ? b.crabCount : 1;
      final c = CrabConditionX.parse(
        condition: b.crabCondition,
        moltingStage: b.crabMoltingStage,
        crabStatus: b.crabStatus,
        hasCrab: true,
      );
      switch (c) {
        case CrabCondition.problem:
        case CrabCondition.weak:
          warning += n;
        case CrabCondition.premolt:
        case CrabCondition.molting:
        case CrabCondition.softshell:
          monitoring += n;
        case CrabCondition.normal:
          normal += n;
        case CrabCondition.empty:
          break;
      }
    }
    return _CrabBuckets(normal: normal, monitoring: monitoring, warning: warning);
  }

  String _pct(int n, int den) {
    if (den <= 0) return '0%';
    return '${((n / den) * 100).round()}%';
  }

  String get _areaLabel {
    final code = widget.item.areaCode.trim();
    final name = (_row.areaName ?? widget.item.areaName).trim();
    if (code.isEmpty && name.isEmpty) return '—';
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$code — $name';
  }

  String get _note {
    final t = _row.description?.trim() ?? '';
    return t.isEmpty ? '—' : t;
  }

  Color get _statusColor => switch (_row.status) {
        FarmStatus.active => DashboardColors.brand,
        FarmStatus.suspended => _kAmber,
        FarmStatus.closed => _kSlate,
      };

  void _close() => Navigator.of(context).pop();

  void _edit() {
    _close();
    widget.onEdit();
  }

  void _viewBoxes() {
    _close();
    widget.onViewBoxes?.call();
  }

  Future<void> _toggleStatus() async {
    final svc = widget.rowService;
    if (svc == null || _acting) return;
    final next = _row.status == FarmStatus.active
        ? FarmStatus.suspended
        : FarmStatus.active;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmSheet(
        title: next == FarmStatus.suspended
            ? 'Tạm ngưng dãy ${_row.rowName}?'
            : 'Kích hoạt lại dãy ${_row.rowName}?',
        body: next == FarmStatus.suspended
            ? 'Dãy sẽ chuyển sang trạng thái Tạm ngưng.'
            : 'Dãy sẽ chuyển sang Đang hoạt động.',
        confirmLabel: next == FarmStatus.suspended ? 'Tạm ngưng' : 'Kích hoạt',
        danger: false,
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _acting = true);
    try {
      final updated = await svc.update(
        _row,
        name: _row.rowName,
        location: _row.location,
        capacity: _row.capacity,
        description: _row.description,
        status: next,
        sortOrder: _row.sortOrder,
      );
      if (!mounted) return;
      setState(() {
        _row = updated;
        _acting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: DashboardColors.brand,
          content: Text(
            next == FarmStatus.suspended
                ? '✓ Đã tạm ngưng dãy ${_row.rowName}.'
                : '✓ Đã kích hoạt dãy ${_row.rowName}.',
            style: bvText(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete() async {
    if (_acting) return;
    if (_occupied > 0 || _row.crabCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ConfirmSheet(
          title: 'Không thể xóa dãy ${_row.rowName}',
          body:
              'Dãy hiện có $_occupied hộp đang nuôi.\nVui lòng di chuyển hoặc xử lý các hộp trước khi xóa.',
          confirmLabel: 'Đã hiểu',
          danger: false,
          hideCancel: true,
        ),
      );
      return;
    }
    if (_totalBoxes > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ConfirmSheet(
          title: 'Không thể xóa dãy ${_row.rowName}',
          body:
              'Dãy hiện còn $_totalBoxes hộp.\nVui lòng xóa hoặc chuyển hộp trước khi xóa dãy.',
          confirmLabel: 'Đã hiểu',
          danger: false,
          hideCancel: true,
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmSheet(
        title: 'Xóa dãy ${_row.rowName}?',
        body:
            'Dãy ${_row.rowCode} sẽ bị xóa khỏi ${widget.item.areaCode.isEmpty ? 'khu vực' : widget.item.areaCode}.\n\nHành động này không thể hoàn tác.',
        confirmLabel: 'Xóa dãy',
        danger: true,
      ),
    );
    if (ok != true || !mounted) return;
    if (widget.onDelete == null) return;
    setState(() => _acting = true);
    try {
      await widget.onDelete!();
      if (!mounted) return;
      _close();
    } catch (_) {
      if (!mounted) return;
      setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final modalW = size.width < 600
        ? size.width - 24
        : size.width < 960
            ? size.width * 0.9
            : 800.0;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width < 600 ? 12 : 28,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Container(
        width: modalW,
        constraints: BoxConstraints(
          maxWidth: modalW,
          maxHeight: size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F231E).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _topBar(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: _body(),
              ),
            ),
            _footer(size.width < 640),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Chi tiết dãy',
              style: bvText(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Thêm',
            padding: EdgeInsets.zero,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'edit') _edit();
              if (v == 'suspend') _toggleStatus();
              if (v == 'delete') _delete();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Text('Chỉnh sửa', style: bvText(fontSize: 13.5)),
              ),
              if (widget.rowService != null)
                PopupMenuItem(
                  value: 'suspend',
                  child: Text(
                    _row.status == FarmStatus.active ? 'Tạm ngưng dãy' : 'Kích hoạt lại',
                    style: bvText(fontSize: 13.5),
                  ),
                ),
              if (widget.onDelete != null)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Xóa dãy',
                    style: bvText(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.risk,
                    ),
                  ),
                ),
            ],
            icon: Icon(Icons.more_horiz_rounded, color: DashboardColors.textMuted),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _close,
            icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _identity(),
        const SizedBox(height: 14),
        if (_loading) ...[
          const _DetailSkeleton(),
        ] else if (_error != null) ...[
          _errorState(),
        ] else ...[
          _RowInfoPanel(
            areaLabel: _areaLabel,
            location: _row.displayLocation,
            maxBoxes: _maxBoxes,
            createdAt: _row.createdAt ?? _row.updatedAt,
            createdBy: '—',
          ),
          const SizedBox(height: 18),
          _sectionTitle('Thống kê hộp'),
          const SizedBox(height: 8),
          _BoxStats(
            total: _totalBoxes,
            occupied: _occupied,
            empty: _empty,
            warning: _boxWarning,
            pct: _pct,
          ),
          const SizedBox(height: 18),
          _sectionTitle('Tình trạng cua trong dãy'),
          const SizedBox(height: 8),
          _CrabStats(buckets: _crabs, fallbackTotal: _row.crabCount, pct: _pct),
          const SizedBox(height: 18),
          _CapacityProgress(
            occupied: _occupied,
            maxBoxes: _maxBoxes,
            usage: _usage,
          ),
          if (_usage >= 0.8) ...[
            const SizedBox(height: 8),
            Text(
              _usage >= 0.95
                  ? '⚠ Dãy đã đạt sức chứa tối đa.'
                  : '⚠ Dãy gần đạt sức chứa tối đa.',
              style: bvText(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _usage >= 0.95 ? DashboardColors.risk : _kAmber,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _metaRow(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _identity() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DashboardColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.view_week_rounded, color: DashboardColors.brand, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _row.rowName,
                style: bvText(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _row.rowCode,
                style: bvText(fontSize: 13.5, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        MgmtStatusBadge(label: _row.status.label, color: _statusColor),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: bvText(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: DashboardColors.textPrimary,
      ),
    );
  }

  Widget _errorState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            '⚠ Không thể tải thông tin dãy.',
            style: bvText(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vui lòng thử lại.',
            style: bvText(fontSize: 13, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 12),
          MgmtPrimaryButton(
            label: 'Thử lại',
            onTap: _load,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _metaRow() {
    return LayoutBuilder(
      builder: (context, c) {
        final left = _metaCell(
          Icons.schedule_rounded,
          'Cập nhật lần cuối',
          fmtDateTimeVn(_row.updatedAt),
        );
        final right = _metaCell(Icons.notes_rounded, 'Ghi chú', _note);
        if (c.maxWidth < 520) {
          return Column(
            children: [
              left,
              const SizedBox(height: 10),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _metaCell(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DashboardColors.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: bvText(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer(bool narrow) {
    final closeBtn = MgmtOutlineButton(
      label: 'Đóng',
      onTap: _close,
      color: DashboardColors.brand,
      borderColor: _kCancelBorder,
      height: 44,
    );
    final editBtn = MgmtOutlineButton(
      icon: Icons.edit_outlined,
      label: 'Chỉnh sửa',
      onTap: _acting ? null : _edit,
      color: DashboardColors.brand,
      borderColor: _kCancelBorder,
      height: 44,
    );
    final viewBtn = _PrimaryCta(
      label: 'Xem hộp',
      onTap: _acting ? null : _viewBoxes,
      expand: narrow,
    );

    if (narrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            viewBtn,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: closeBtn),
                const SizedBox(width: 8),
                Expanded(child: editBtn),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        border: Border(top: BorderSide(color: DashboardColors.mint)),
      ),
      child: Row(
        children: [
          closeBtn,
          const Spacer(),
          editBtn,
          const SizedBox(width: 8),
          viewBtn,
        ],
      ),
    );
  }
}

class _RowInfoPanel extends StatelessWidget {
  const _RowInfoPanel({
    required this.areaLabel,
    required this.location,
    required this.maxBoxes,
    required this.createdAt,
    required this.createdBy,
  });

  final String areaLabel;
  final String location;
  final int maxBoxes;
  final DateTime? createdAt;
  final String createdBy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final cells = [
            _cell(Icons.home_outlined, 'Khu vực', areaLabel),
            _cell(Icons.place_outlined, 'Vị trí', location),
            _cell(Icons.inventory_2_outlined, 'Sức chứa tối đa', '$maxBoxes hộp'),
            _cell(Icons.calendar_today_outlined, 'Ngày tạo', fmtDateVn(createdAt)),
            _cell(Icons.person_outline_rounded, 'Người tạo', createdBy),
          ];
          if (c.maxWidth < 520) {
            return Column(children: cells);
          }
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cells[0]),
                  Expanded(child: cells[1]),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cells[2]),
                  Expanded(child: cells[3]),
                  Expanded(child: cells[4]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: DashboardColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
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

class _BoxStats extends StatelessWidget {
  const _BoxStats({
    required this.total,
    required this.occupied,
    required this.empty,
    required this.warning,
    required this.pct,
  });

  final int total;
  final int occupied;
  final int empty;
  final int warning;
  final String Function(int n, int den) pct;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.inventory_2_outlined, 'Tổng hộp', '$total', null as String?, _kAmber),
      (Icons.grid_view_rounded, 'Đang nuôi', '$occupied', pct(occupied, total), _kBlue),
      (Icons.crop_square_rounded, 'Hộp trống', '$empty', pct(empty, total), _kSlate),
      (
        Icons.warning_amber_rounded,
        'Hộp cảnh báo',
        '$warning',
        pct(warning, total),
        DashboardColors.risk
      ),
    ];
    return _StatGrid(items: items);
  }
}

class _CrabStats extends StatelessWidget {
  const _CrabStats({
    required this.buckets,
    required this.fallbackTotal,
    required this.pct,
  });

  final _CrabBuckets buckets;
  final int fallbackTotal;
  final String Function(int n, int den) pct;

  @override
  Widget build(BuildContext context) {
    final total = buckets.total > 0 ? buckets.total : fallbackTotal;
    if (total <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Text(
          'Chưa có cua trong dãy này.',
          style: bvText(fontSize: 13.5, color: DashboardColors.textMuted),
        ),
      );
    }
    if (buckets.total == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardColors.cardBorder),
        ),
        child: Text(
          '$fallbackTotal cua đang nuôi — mở Xem hộp để xem chi tiết tình trạng.',
          style: bvText(fontSize: 13.5, color: DashboardColors.textMuted),
        ),
      );
    }
    final den = buckets.total;
    final items = [
      (Icons.pets_rounded, 'Bình thường', '${buckets.normal}', pct(buckets.normal, den), DashboardColors.brand),
      (Icons.visibility_outlined, 'Theo dõi', '${buckets.monitoring}', pct(buckets.monitoring, den), _kAmber),
      (
        Icons.warning_amber_rounded,
        'Cảnh báo',
        '${buckets.warning}',
        pct(buckets.warning, den),
        DashboardColors.risk
      ),
    ];
    return _StatGrid(items: items, columnsAtWide: 3);
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items, this.columnsAtWide = 4});

  final List<(IconData, String, String, String?, Color)> items;
  final int columnsAtWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 640
            ? columnsAtWide
            : c.maxWidth >= 420
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisExtent: 86,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, i) {
            final it = items[i];
            return _StatCard(
              icon: it.$1,
              label: it.$2,
              value: it.$3,
              pct: it.$4,
              color: it.$5,
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.pct,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: bvText(fontSize: 11.5, color: DashboardColors.textMuted)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: bvText(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    if (pct != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        pct!,
                        style: bvText(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityProgress extends StatelessWidget {
  const _CapacityProgress({
    required this.occupied,
    required this.maxBoxes,
    required this.usage,
  });

  final int occupied;
  final int maxBoxes;
  final double usage;

  @override
  Widget build(BuildContext context) {
    final pct = '${(usage * 100).round()}%';
    final barColor = usage >= 0.95
        ? DashboardColors.risk
        : usage >= 0.80
            ? _kAmber
            : DashboardColors.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Mức sử dụng hộp',
              style: bvText(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: DashboardColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$occupied / $maxBoxes hộp  •  $pct',
              style: bvText(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 9,
            child: Stack(
              children: [
                const ColoredBox(color: DashboardColors.mint, child: SizedBox.expand()),
                FractionallySizedBox(
                  widthFactor: usage,
                  child: ColoredBox(color: barColor, child: const SizedBox.expand()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 18, double r = 10}) => Container(
          height: h,
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Column(
      children: [
        box(h: 96, r: 14),
        const SizedBox(height: 14),
        box(h: 86, r: 12),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: box(h: 86, r: 12)),
            const SizedBox(width: 8),
            Expanded(child: box(h: 86, r: 12)),
            const SizedBox(width: 8),
            Expanded(child: box(h: 86, r: 12)),
          ],
        ),
        const SizedBox(height: 14),
        box(h: 28, r: 8),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap, this.expand = false});

  final String label;
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: DashboardColors.brand,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.brand.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: bvText(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.danger,
    this.hideCancel = false,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool danger;
  final bool hideCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: bvText(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: DashboardColors.textPrimary,
        ),
      ),
      content: Text(
        body,
        style: bvText(fontSize: 13.5, color: DashboardColors.textMuted, height: 1.45),
      ),
      actions: [
        if (!hideCancel)
          MgmtOutlineButton(
            label: 'Hủy',
            onTap: () => Navigator.pop(context, false),
            color: DashboardColors.textMuted,
            height: 40,
          ),
        if (danger)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context, true),
              borderRadius: BorderRadius.circular(11),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: DashboardColors.risk,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  confirmLabel,
                  style: bvText(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        else
          MgmtPrimaryButton(
            label: confirmLabel,
            onTap: () => Navigator.pop(context, true),
            height: 40,
          ),
      ],
    );
  }
}
