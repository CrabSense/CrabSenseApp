import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/farm_record.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/box_management_service.dart';
import '../../services/cloud_api_client.dart';
import '../../services/production_management_service.dart';
import '../../services/row_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../row/row_dialogs.dart';
import '../shared/mgmt_ui.dart';

const _kOverlay = Color.fromRGBO(15, 35, 30, 0.45);
const _kCancelBorder = Color(0xFFBFDCD3);
const _kAmber = Color(0xFFF5B700);
const _kBlue = Color(0xFF2495E8);
const _kSlate = Color(0xFF94A3B8);

Future<void> showAddBoxModal(
  BuildContext context, {
  required ProductionManagementService productionService,
  BoxManagementService? boxService,
  RowManagementService? rowService,
  void Function(AppRoute route)? onNavigate,
}) async {
  if (productionService.areas.isEmpty) {
    await productionService.loadAreas();
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: _kOverlay,
    builder: (_) => _AddBoxModal(
      production: productionService,
      boxService: boxService,
      rowService: rowService,
      onNavigate: onNavigate,
    ),
  );
}

class _AddBoxModal extends StatefulWidget {
  const _AddBoxModal({
    required this.production,
    this.boxService,
    this.rowService,
    this.onNavigate,
  });

  final ProductionManagementService production;
  final BoxManagementService? boxService;
  final RowManagementService? rowService;
  final void Function(AppRoute route)? onNavigate;

  @override
  State<_AddBoxModal> createState() => _AddBoxModalState();
}

class _AddBoxModalState extends State<_AddBoxModal> {
  var _step = 1;
  String? _areaId;
  String? _rowId;
  List<RowRecord> _rows = [];
  var _loadingRows = false;
  var _loadingRow = false;
  var _submitting = false;
  String? _qtyError;
  String? _capacityError;
  final _qtyCtrl = TextEditingController(text: '1');

  List<AreaRecord> get _areas =>
      widget.boxService?.areas ?? widget.production.areas;

  @override
  void initState() {
    super.initState();
    final box = widget.boxService;
    _areaId = box?.areaFilterId ??
        widget.production.selectedAreaId ??
        (_areas.isNotEmpty ? _areas.first.id : null);
    _rowId = box?.rowFilterId ?? widget.production.selectedRowId;
    if (_areaId != null) {
      _loadRows(_areaId!, keepRow: true);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  RowRecord? get _row {
    final id = _rowId;
    if (id == null) return null;
    for (final r in _rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  AreaRecord? get _area {
    final id = _areaId;
    if (id == null) return null;
    for (final a in _areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  int remainingOf(RowRecord r) {
    if (r.capacity <= 0) return 50;
    return (r.capacity - r.boxCount).clamp(0, r.capacity);
  }

  bool isFull(RowRecord r) => r.capacity > 0 && r.boxCount >= r.capacity;

  bool isSelectable(RowRecord r) =>
      r.status == FarmStatus.active && !isFull(r);

  int get _qty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  int get _maxQty {
    final r = _row;
    if (r == null) return 1;
    final rem = remainingOf(r);
    return rem < 1 ? 1 : rem;
  }

  bool get _canContinue {
    final r = _row;
    if (_areaId == null || r == null) return false;
    if (!isSelectable(r)) return false;
    final q = _qty;
    if (q < 1) return false;
    if (q > remainingOf(r)) return false;
    return true;
  }

  String _rowTitle(RowRecord r) {
    final name = r.rowName.trim();
    final code = r.rowCode.trim();
    if (name.isEmpty) return code;
    if (code.isEmpty || code.toLowerCase() == name.toLowerCase()) return name;
    return '$name — $code';
  }

  String _rowOptionLabel(RowRecord r) {
    final title = _rowTitle(r);
    if (r.status != FarmStatus.active) return '$title · Tạm ngưng';
    if (r.capacity <= 0) return '$title · không giới hạn';
    if (isFull(r)) return '$title · Đã đầy · ${r.boxCount}/${r.capacity} hộp';
    return '$title · còn ${remainingOf(r)}/${r.capacity} hộp';
  }

  Future<void> _loadRows(String areaId, {bool keepRow = false}) async {
    setState(() {
      _loadingRows = true;
      if (!keepRow) {
        _rowId = null;
        _capacityError = null;
        _qtyError = null;
      }
      _rows = [];
    });
    try {
      final rows = await widget.production.fetchRowsForArea(areaId);
      if (!mounted) return;
      var nextRow = keepRow ? _rowId : null;
      if (nextRow != null && !rows.any((r) => r.id == nextRow)) {
        nextRow = null;
      }
      if (nextRow == null) {
        final preferred = widget.boxService?.rowFilterId;
        if (preferred != null &&
            rows.any((r) => r.id == preferred && isSelectable(r))) {
          nextRow = preferred;
        }
      }
      setState(() {
        _rows = rows;
        _rowId = nextRow;
        _loadingRows = false;
      });
      if (_rowId != null) await _refreshSelectedRow();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRows = false;
        _rows = [];
      });
    }
  }

  Future<void> _refreshSelectedRow() async {
    final id = _rowId;
    if (id == null) return;
    setState(() => _loadingRow = true);
    try {
      final fresh = await widget.production.fetchRowById(id);
      if (!mounted) return;
      setState(() {
        _rows = [
          for (final r in _rows) if (r.id == fresh.id) fresh else r,
        ];
        _loadingRow = false;
        _syncQtyToRemaining();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRow = false);
    }
  }

  void _syncQtyToRemaining() {
    final r = _row;
    if (r == null) return;
    final rem = remainingOf(r);
    var q = _qty;
    if (q < 1) q = 1;
    if (rem > 0 && q > rem) q = rem;
    if ('$q' != _qtyCtrl.text.trim()) _qtyCtrl.text = '$q';
    _validateQty();
  }

  void _validateQty() {
    final r = _row;
    if (r == null) {
      setState(() => _qtyError = null);
      return;
    }
    final q = _qty;
    final rem = remainingOf(r);
    String? err;
    if (q < 1) err = '⚠ Số hộp phải lớn hơn 0.';
    if (rem > 0 && q > rem) {
      err = '⚠ Dãy ${r.rowName} chỉ còn sức chứa cho $rem hộp.';
    }
    setState(() => _qtyError = err);
  }

  Future<void> _onAreaChanged(String? id) async {
    setState(() {
      _areaId = id;
      _rowId = null;
      _step = 1;
      _qtyCtrl.text = '1';
      _qtyError = null;
      _capacityError = null;
    });
    if (id != null) await _loadRows(id);
  }

  Future<void> _onRowChanged(String? id) async {
    setState(() {
      _rowId = id;
      _qtyCtrl.text = '1';
      _qtyError = null;
      _capacityError = null;
      _step = 1;
    });
    if (id != null) await _refreshSelectedRow();
  }

  void _bump(int d) {
    final r = _row;
    if (r == null || !isSelectable(r) || _submitting) return;
    var next = _qty + d;
    if (next < 1) next = 1;
    final max = remainingOf(r);
    if (next > max) next = max;
    _qtyCtrl.text = '$next';
    _validateQty();
  }

  Future<void> _goConfirm() async {
    if (!_canContinue) return;
    await _refreshSelectedRow();
    if (!mounted) return;
    final r = _row;
    if (r == null || !isSelectable(r) || _qty > remainingOf(r)) {
      setState(() {
        _capacityError =
            '⚠ Sức chứa của dãy ${r?.rowName ?? ''} vừa được cập nhật.';
      });
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _submit() async {
    final r = _row;
    if (r == null || _submitting || !_canContinue) return;
    setState(() => _submitting = true);
    try {
      final created = await widget.production.createBoxesInRow(
        rowId: r.id,
        count: _qty,
      );
      if (!mounted) return;
      final boxSvc = widget.boxService;
      if (boxSvc != null) {
        if (boxSvc.areaFilterId != _areaId && _areaId != null) {
          boxSvc.setAreaFilter(_areaId);
        }
        boxSvc.setRowFilter(r.id);
        await boxSvc.load();
      }
      if (!mounted) return;
      Navigator.pop(context);
      final msg = created.length <= 1
          ? '✓ Đã tạo hộp ${created.isEmpty ? '' : created.first.boxCode} thành công.'
          : '✓ Đã tạo ${created.length} hộp trong dãy ${r.rowName} thành công.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: DashboardColors.brand,
          content: Text(
            msg,
            style: bvText(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      );
    } on CloudApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final full = (e.statusCode == 409) ||
          e.message.toLowerCase().contains('full') ||
          e.message.toLowerCase().contains('capacity') ||
          e.message.toLowerCase().contains('remaining');
      if (full) {
        await _showFullConflict();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showFullConflict() async {
    final r = _row;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '⚠ Không thể tạo hộp',
          style: bvText(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: Text(
          'Sức chứa của dãy ${r?.rowName ?? ''} vừa được cập nhật.\n'
          'Dãy hiện đã đủ ${r == null ? '' : '${r.capacity}/${r.capacity}'} hộp.',
          style: bvText(fontSize: 13.5, color: DashboardColors.textMuted, height: 1.45),
        ),
        actions: [
          MgmtPrimaryButton(
            label: 'Làm mới',
            onTap: () => Navigator.pop(ctx, true),
            height: 40,
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _step = 1);
      await _refreshSelectedRow();
    }
  }

  Future<void> _createRow() async {
    final areaId = _areaId;
    if (areaId == null) return;
    final svc = widget.rowService;
    if (svc == null) {
      _openRows();
      return;
    }
    await showCreateRowDialog(context, svc, areaId: areaId);
    if (!mounted) return;
    await _loadRows(areaId);
  }

  void _openRows() {
    Navigator.pop(context);
    widget.onNavigate?.call(AppRoute.rowManagement);
  }

  void _close() => Navigator.pop(context);

  InputDecoration _dec({String? hint, Widget? prefix}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: bvText(fontSize: 13, color: DashboardColors.textMuted),
      prefixIcon: prefix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: b(DashboardColors.cardBorder),
      enabledBorder: b(DashboardColors.cardBorder),
      focusedBorder: b(DashboardColors.brandGreen, 1.4),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: bvText(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: DashboardColors.risk,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final modalW = size.width < 600
        ? size.width - 24
        : size.width < 900
            ? size.width * 0.9
            : 700.0;
    final narrow = modalW < 560;

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
        constraints: BoxConstraints(maxWidth: modalW, maxHeight: size.height * 0.9),
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
            _header(),
            if (_step == 2) _stepIndicator(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                child: _step == 1 ? _locationStep(narrow) : _confirmStep(),
              ),
            ),
            _footer(narrow),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardColors.brand,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm hộp mới',
                  style: bvText(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _step == 1
                      ? 'Chọn khu vực và dãy muốn thêm hộp.'
                      : 'Xác nhận thông tin trước khi tạo hộp.',
                  style: bvText(fontSize: 13, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: _submitting ? null : _close,
            icon: Icon(Icons.close_rounded, color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _stepIndicator() {
    Widget node(int n, String label, {required bool done, required bool active}) {
      final color = done || active ? DashboardColors.brand : DashboardColors.textMuted;
      return Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done || active ? DashboardColors.brand : DashboardColors.mint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: bvText(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: done || active ? Colors.white : DashboardColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Row(
        children: [
          node(1, 'Chọn vị trí', done: true, active: false),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(height: 2, color: DashboardColors.brand),
            ),
          ),
          node(2, 'Xác nhận', done: false, active: true),
        ],
      ),
    );
  }

  Widget _locationStep(bool narrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Khu vực', required: true),
        DropdownButtonFormField<String>(
          key: ValueKey('area-$_areaId'),
          initialValue: _areas.any((a) => a.id == _areaId) ? _areaId : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: _dec(
            hint: 'Chọn khu nuôi',
            prefix: const Icon(Icons.home_outlined, size: 18, color: DashboardColors.brand),
          ),
          style: bvText(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary,
          ),
          items: [
            for (final a in _areas)
              DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.areaCode} — ${a.areaName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _submitting ? null : _onAreaChanged,
        ),
        const SizedBox(height: 14),
        _label('Dãy', required: true),
        if (_loadingRows)
          Container(
            height: 46,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: DashboardColors.brand),
                ),
                const SizedBox(width: 10),
                Text('Đang tải dãy...', style: bvText(color: DashboardColors.textMuted)),
              ],
            ),
          )
        else if (_areaId != null && _rows.isEmpty)
          _emptyRows()
        else if (_areaId != null && _rows.isNotEmpty && !_rows.any(isSelectable))
          _noCapacity()
        else
          DropdownButtonFormField<String>(
            key: ValueKey('row-dd-$_areaId-${_rows.length}'),
            initialValue: _rows.any((r) => r.id == _rowId) ? _rowId : null,
            isExpanded: true,
            dropdownColor: Colors.white,
            decoration: _dec(
              hint: 'Chọn dãy',
              prefix: const Icon(Icons.grid_view_rounded, size: 18, color: DashboardColors.brand),
            ),
            style: bvText(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
            items: [
              for (final r in _rows)
                DropdownMenuItem(
                  value: r.id,
                  child: Text(
                    _rowOptionLabel(r),
                    overflow: TextOverflow.ellipsis,
                    style: bvText(
                      fontSize: 13.5,
                      color: isSelectable(r)
                          ? DashboardColors.textPrimary
                          : DashboardColors.textMuted,
                    ),
                  ),
                ),
            ],
            onChanged: _submitting || _areaId == null ? null : _onRowChanged,
          ),
        if (_row != null) ...[
          const SizedBox(height: 14),
          if (_loadingRow) const _RowCardSkeleton() else _rowCapacityCard(narrow),
        ],
        if (_capacityError != null) ...[
          const SizedBox(height: 8),
          Text(
            _capacityError!,
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.risk),
          ),
        ],
        if (_row != null && isSelectable(_row!)) ...[
          const SizedBox(height: 16),
          _quantityField(),
          const SizedBox(height: 14),
          _notesBox(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _emptyRows() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không có dãy trong khu vực này.',
            style: bvText(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bạn cần tạo dãy trước khi thêm hộp.',
            style: bvText(fontSize: 13, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 10),
          MgmtPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Tạo dãy',
            onTap: _createRow,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _noCapacity() {
    final area = _area;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠ Không còn dãy có sức chứa.',
            style: bvText(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tất cả các dãy trong ${area?.areaCode ?? 'khu này'} đã đạt sức chứa tối đa.',
            style: bvText(fontSize: 13, color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 10),
          MgmtOutlineButton(
            label: 'Quản lý dãy',
            onTap: _openRows,
            color: DashboardColors.brand,
            borderColor: _kCancelBorder,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _rowCapacityCard(bool narrow) {
    final r = _row!;
    final rem = remainingOf(r);
    final full = isFull(r);
    final usage = r.capacity <= 0 ? 0.0 : (r.boxCount / r.capacity).clamp(0.0, 1.0);
    final kpis = [
      (Icons.inventory_2_outlined, 'Sức chứa tối đa', '${r.capacity <= 0 ? '∞' : r.capacity} hộp', _kAmber),
      (Icons.grid_view_rounded, 'Đã tạo', '${r.boxCount} hộp', _kBlue),
      (Icons.add_box_outlined, 'Có thể tạo thêm', full ? '0 hộp' : '$rem hộp', DashboardColors.brand),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.view_week_rounded, color: DashboardColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dãy ${r.rowName}',
                      style: bvText(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    Text(r.rowCode, style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
                  ],
                ),
              ),
              MgmtStatusBadge(
                label: r.status.label,
                color: r.status == FarmStatus.active ? DashboardColors.brand : _kAmber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (narrow)
            Column(
              children: [
                for (final k in kpis) ...[
                  _miniKpi(k.$1, k.$2, k.$3, k.$4),
                  const SizedBox(height: 8),
                ],
              ],
            )
          else
            Row(
              children: [
                for (var i = 0; i < kpis.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _miniKpi(kpis[i].$1, kpis[i].$2, kpis[i].$3, kpis[i].$4)),
                ],
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Mức sử dụng', style: bvText(fontSize: 12.5, color: DashboardColors.textMuted)),
              const Spacer(),
              Text(
                r.capacity <= 0
                    ? '${r.boxCount} hộp'
                    : '${r.boxCount} / ${r.capacity} hộp  •  ${(usage * 100).round()}%',
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
              height: 8,
              child: Stack(
                children: [
                  const ColoredBox(color: DashboardColors.mint, child: SizedBox.expand()),
                  FractionallySizedBox(
                    widthFactor: usage,
                    child: ColoredBox(
                      color: full ? DashboardColors.risk : DashboardColors.brand,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (full) ...[
            const SizedBox(height: 10),
            Text(
              '⚠ Dãy ${r.rowName} đã đạt sức chứa tối đa.\nKhông thể tạo thêm hộp.',
              style: bvText(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: DashboardColors.risk,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniKpi(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: bvText(fontSize: 11, color: DashboardColors.textMuted)),
                Text(
                  value,
                  style: bvText(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

  Widget _quantityField() {
    final r = _row!;
    final rem = remainingOf(r);
    final enabled = isSelectable(r) && !_submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Số lượng hộp muốn tạo', required: true),
        Row(
          children: [
            _stepperBtn(
              icon: Icons.remove_rounded,
              onTap: enabled ? () => _bump(-1) : null,
              semantic: 'Giảm số lượng hộp',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _qtyCtrl,
                enabled: enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _validateQty(),
                style: bvText(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                ),
                decoration: _dec(hint: '1'),
              ),
            ),
            const SizedBox(width: 10),
            _stepperBtn(
              icon: Icons.add_rounded,
              onTap: enabled ? () => _bump(1) : null,
              semantic: 'Tăng số lượng hộp',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Có thể tạo tối đa $rem hộp trong dãy này.',
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        ),
        if (_qtyError != null) ...[
          const SizedBox(height: 4),
          Text(
            _qtyError!,
            style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.risk),
          ),
        ],
      ],
    );
  }

  Widget _stepperBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required String semantic,
  }) {
    return Semantics(
      button: true,
      label: semantic,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kCancelBorder),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: onTap == null ? _kSlate : DashboardColors.brand,
            ),
          ),
        ),
      ),
    );
  }

  Widget _notesBox() {
    final name = _row?.rowName ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: DashboardColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lưu ý',
                  style: bvText(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Hộp mới sẽ được tạo trong dãy $name.\n'
                  '• Mã hộp sẽ được hệ thống tự động tạo.\n'
                  '• Sau khi tạo, hộp ở trạng thái Trống.\n'
                  '• Bạn có thể thêm cua sau khi tạo hộp.\n'
                  '• Không thể tạo vượt quá sức chứa tối đa của dãy.',
                  style: bvText(
                    fontSize: 12.5,
                    color: DashboardColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmStep() {
    final area = _area;
    final r = _row;
    final q = _qty;
    Widget cell(String label, List<String> lines) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
            const SizedBox(height: 4),
            for (final line in lines)
              Text(
                line,
                style: bvText(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                  height: 1.25,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác nhận tạo hộp',
          style: bvText(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(
            color: DashboardColors.lightMint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DashboardColors.mint),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell('Khu vực', [area?.areaCode ?? '—', area?.areaName ?? '']),
              cell('Dãy', [r?.rowName ?? '—', r?.rowCode ?? '']),
              cell('Số lượng hộp', ['$q hộp']),
              cell('Mã hộp', ['Hệ thống tự động tạo']),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái ban đầu',
                      style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    const MgmtStatusBadge(label: 'Trống', color: _kSlate),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer(bool narrow) {
    if (_step == 2) {
      final qty = _qty;
      final label = _submitting
          ? 'Đang tạo...'
          : (qty <= 1 ? 'Tạo hộp' : 'Tạo $qty hộp');
      final back = MgmtOutlineButton(
        label: 'Quay lại',
        icon: Icons.arrow_back_rounded,
        onTap: _submitting ? null : () => setState(() => _step = 1),
        color: DashboardColors.brand,
        borderColor: _kCancelBorder,
        height: 46,
      );
      final submit = _PrimaryBtn(
        label: label,
        loading: _submitting,
        icon: _submitting ? null : Icons.check_rounded,
        onTap: _submitting ? null : _submit,
        expand: narrow,
      );
      if (narrow) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [submit, const SizedBox(height: 8), back],
          ),
        );
      }
      return _footerBar(left: back, right: submit);
    }

    final cancel = MgmtOutlineButton(
      label: 'Hủy',
      onTap: _submitting ? null : _close,
      color: DashboardColors.brand,
      borderColor: _kCancelBorder,
      height: 46,
    );
    final next = _PrimaryBtn(
      label: 'Tiếp tục',
      trailing: Icons.arrow_forward_rounded,
      onTap: _canContinue && !_submitting ? _goConfirm : null,
      expand: narrow,
    );
    if (narrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [next, const SizedBox(height: 8), cancel],
        ),
      );
    }
    return _footerBar(left: cancel, right: next);
  }

  Widget _footerBar({required Widget left, required Widget right}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        border: Border(top: BorderSide(color: DashboardColors.mint)),
      ),
      child: Row(
        children: [
          left,
          const Spacer(),
          right,
        ],
      ),
    );
  }
}

class _RowCardSkeleton extends StatelessWidget {
  const _RowCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 18}) => Container(
          height: h,
          decoration: BoxDecoration(
            color: DashboardColors.mint,
            borderRadius: BorderRadius.circular(10),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.lightMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.mint),
      ),
      child: Column(
        children: [
          box(h: 44),
          const SizedBox(height: 12),
          box(h: 72),
          const SizedBox(height: 12),
          box(h: 10),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailing;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: enabled ? DashboardColors.brand : const Color(0xFFC5DDD6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                else if (icon != null)
                  Icon(icon, size: 18, color: Colors.white),
                if (loading || icon != null) const SizedBox(width: 8),
                Text(
                  label,
                  style: bvText(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : DashboardColors.textMuted,
                  ),
                ),
                if (trailing != null && !loading) ...[
                  const SizedBox(width: 6),
                  Icon(trailing, size: 16, color: enabled ? Colors.white : DashboardColors.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
