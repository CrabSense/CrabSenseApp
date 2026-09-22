import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/crab_lot_status.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/crab_lot_inbound_service.dart';
import '../../services/crab_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/app_formatters.dart';
import '../../widgets/crab/crab_auth_image.dart';
import '../../widgets/crab/crab_bulk_add_dialog.dart';
import '../../widgets/crab/crab_lot_import_dialog.dart';
import '../../widgets/lot/crab_lot_inbound_detail_panel.dart';
import '../../widgets/lot/crab_lot_inbound_table.dart';
import '../../widgets/shared/mgmt_ui.dart';

class CrabLotInboundPage extends StatefulWidget {
  const CrabLotInboundPage({
    super.key,
    required this.service,
    required this.crabService,
    this.onNavigate,
    this.onOpenDetail,
  });

  final CrabLotInboundService service;
  final CrabService crabService;
  final void Function(AppRoute route)? onNavigate;
  final void Function(FarmingBatchRecord lot)? onOpenDetail;

  @override
  State<CrabLotInboundPage> createState() => _CrabLotInboundPageState();
}

class _CrabLotInboundPageState extends State<CrabLotInboundPage> {
  final _searchCtrl = TextEditingController();
  final _qtyFrom = TextEditingController();
  final _qtyTo = TextEditingController();
  final _checked = <String>{};
  String? _selectedId;
  var _hidePanel = false;
  var _advanced = false;
  String _areaFilter = '';
  String _rowFilter = '';

  CrabLotInboundService get _svc => widget.service;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
    widget.crabService.addListener(_onUpdate);
    _searchCtrl.text = _svc.search;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_svc.lots.isEmpty && !_svc.loading) _svc.load();
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    widget.crabService.removeListener(_onUpdate);
    _searchCtrl.dispose();
    _qtyFrom.dispose();
    _qtyTo.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (_searchCtrl.text != _svc.search) _searchCtrl.text = _svc.search;
    setState(() {});
  }

  List<FarmingBatchRecord> get _filtered {
    var list = _svc.filtered;
    if (_areaFilter.isNotEmpty || _rowFilter.isNotEmpty) {
      list = list.where((lot) {
        final crabs = widget.crabService.crabsInLot(
          lotId: lot.id,
          lotCode: lot.batchCode,
        );
        if (crabs.isEmpty) {
          return _areaFilter.isEmpty && _rowFilter.isEmpty;
        }
        if (_areaFilter.isNotEmpty &&
            !crabs.any((c) => c.areaName == _areaFilter)) {
          return false;
        }
        if (_rowFilter.isNotEmpty &&
            !crabs.any((c) => c.rowName == _rowFilter)) {
          return false;
        }
        return true;
      }).toList();
    }
    return list;
  }

  List<FarmingBatchRecord> get _paged {
    final list = _filtered;
    final start = _svc.currentPage * _svc.pageSize;
    if (start >= list.length) return const [];
    return list.sublist(
      start,
      (start + _svc.pageSize).clamp(0, list.length),
    );
  }

  FarmingBatchRecord? get _selected {
    if (_hidePanel) return null;
    final id = _selectedId;
    if (id != null) {
      for (final l in _svc.lots) {
        if (l.id == id) return l;
      }
    }
    final page = _paged;
    return page.isEmpty ? null : page.first;
  }

  Future<void> _import() async {
    final lot = await showCrabLotImportDialog(context, widget.crabService);
    if (!mounted || lot == null) return;
    await _svc.upsert(lot);
    await widget.crabService.refreshLots();
    if (!mounted) return;
    setState(() {
      _selectedId = lot.id;
      _hidePanel = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã nhập ${lot.displayLabel}.')),
    );
  }

  Future<void> _place(FarmingBatchRecord lot) async {
    await showCrabBulkAddDialog(
      context,
      widget.crabService,
      initialLotId: lot.id,
    );
    await _svc.load();
    await widget.crabService.load();
  }

  Future<void> _cancel(FarmingBatchRecord lot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hủy lô ${lot.batchCode}?',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: Text(
          'Lô sẽ chuyển sang trạng thái Đã hủy. Cua đã phân hộp (nếu có) vẫn giữ nguyên.',
          style: bvText(fontSize: 13, color: DashboardColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Không', style: bvText(color: DashboardColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hủy lô',
              style: bvText(
                fontWeight: FontWeight.w700,
                color: DashboardColors.risk,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final updated = await _svc.cancel(lot.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated != null ? 'Đã hủy ${lot.batchCode}' : (_svc.error ?? 'Không hủy được lô'),
        ),
      ),
    );
  }

  Future<void> _edit(FarmingBatchRecord lot) async {
    final name = TextEditingController(text: lot.name ?? '');
    final supplier = TextEditingController(text: lot.supplierName ?? '');
    final notes = TextEditingController(text: lot.notes ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Chỉnh sửa thông tin',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên lô'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: supplier,
                decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.brand),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    await _svc.updateInfo(
      lot.id,
      name: name.text.trim(),
      supplierName: supplier.text.trim(),
      notes: notes.text.trim(),
    );
    name.dispose();
    supplier.dispose();
    notes.dispose();
  }

  Future<void> _export(List<FarmingBatchRecord> lots) async {
    if (lots.isEmpty) return;
    final sb = StringBuffer()
      ..writeln('Ma lo,Ten lo,Ngay nhap,Nha cung cap,So luong,Da phan hop,Ty le,Trang thai');
    String csv(String v) =>
        v.contains(',') || v.contains('"') || v.contains('\n')
            ? '"${v.replaceAll('"', '""')}"'
            : v;
    for (final l in lots) {
      sb.writeln([
        csv(l.batchCode),
        csv(l.lotName),
        csv(formatDate(l.startDate)),
        csv(l.supplierName ?? ''),
        l.initialQuantity,
        l.placedCount,
        '${l.allocationPercent}%',
        csv(l.workflowStatus.label),
      ].join(','));
    }
    final now = DateTime.now();
    final name =
        'crabsense_nhaphang_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất dữ liệu lô nhập',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (path == null || !mounted) return;
    try {
      await File(path).writeAsString('\uFEFF$sb');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất ${lots.length} lô: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không ghi được file: $e')),
      );
    }
  }

  void _printSlips(List<FarmingBatchRecord> lots) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lots.length == 1 ? 'Phiếu nhập ${lots.first.batchCode}' : 'In ${lots.length} phiếu nhập',
          style: bvText(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DashboardColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in lots.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${l.batchCode} · ${l.lotName} · ${formatInt(l.initialQuantity)} con · ${dash(l.supplierName)}',
                    style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
                  ),
                ),
              if (lots.length > 8)
                Text(
                  '… và ${lots.length - 8} lô khác',
                  style: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _onMenu(FarmingBatchRecord lot, CrabLotRowMenu action) {
    switch (action) {
      case CrabLotRowMenu.view:
        setState(() {
          _selectedId = lot.id;
          _hidePanel = false;
        });
      case CrabLotRowMenu.edit:
        _edit(lot);
      case CrabLotRowMenu.place:
        _place(lot);
      case CrabLotRowMenu.crabs:
      case CrabLotRowMenu.boxes:
        widget.onOpenDetail?.call(lot);
      case CrabLotRowMenu.printSlip:
        _printSlips([lot]);
      case CrabLotRowMenu.cancel:
        _cancel(lot);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _svc.from != null && _svc.to != null
          ? DateTimeRange(start: _svc.from!, end: _svc.to!)
          : DateTimeRange(
              start: DateTime(now.year, now.month - 1, 1),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: DashboardColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: DashboardColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    _svc.setDateRange(picked.start, picked.end);
  }

  void _applyAdvanced() {
    final min = int.tryParse(_qtyFrom.text.trim());
    final max = int.tryParse(_qtyTo.text.trim());
    _svc.setQtyRange(min, max);
    setState(() => _advanced = false);
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _qtyFrom.clear();
    _qtyTo.clear();
    _areaFilter = '';
    _rowFilter = '';
    _svc.clearFilters();
    setState(() {});
  }

  List<String> _lotImages(FarmingBatchRecord lot) {
    if (lot.imageUrls.isNotEmpty) {
      return lot.imageUrls.where((u) => u.trim().isNotEmpty).toList();
    }
    final crabs = widget.crabService.crabsInLot(
      lotId: lot.id,
      lotCode: lot.batchCode,
    );
    final urls = <String>[];
    for (final c in crabs) {
      final p = widget.crabService.profileOf(c.id);
      if (p == null) continue;
      for (final u in [...p.imageUrls, if (p.avatarUrl != null) p.avatarUrl!]) {
        if (u.trim().isEmpty) continue;
        if (!urls.contains(u)) urls.add(u);
      }
    }
    return urls;
  }

  void _openImage(FarmingBatchRecord lot, String url) {
    final urls = _lotImages(lot);
    final index = urls.indexOf(url);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CrabAuthImage(
                  crabId: '',
                  index: index < 0 ? 0 : index,
                  token: widget.crabService.token,
                  fallbackUrl: url,
                  proxyUrl: lot.imageUrls.isNotEmpty && index >= 0
                      ? CrabAuthImage.lotProxyUrl(lot.id, index)
                      : null,
                  fit: BoxFit.contain,
                  error: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLotPhotos(FarmingBatchRecord lot) async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'],
    );
    if (picked == null) return;
    final paths = [
      for (final f in picked.files)
        if (f.path != null && f.path!.isNotEmpty) f.path!,
    ];
    if (paths.isEmpty) return;
    final updated = await _svc.uploadPhotos(lot.id, paths);
    if (!mounted) return;
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_svc.error ?? 'Không tải được ảnh lô')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lots = _paged;
    final filtered = _filtered;
    final selected = _selected;
    final k = _svc.kpis;
    final wide = MediaQuery.sizeOf(context).width >= 1280;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 12),
          _kpis(k),
          if (_svc.error != null) ...[
            const SizedBox(height: 8),
            Text(
              _svc.error!,
              style: bvText(color: DashboardColors.risk, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 12),
          _toolbar(),
          if (_advanced) ...[
            const SizedBox(height: 10),
            _advancedPanel(),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 68, child: _listCard(lots, filtered)),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 32,
                        child: selected == null
                            ? _emptyDetail()
                            : CrabLotInboundDetailPanel(
                                lot: selected,
                                crabs: widget.crabService.crabsInLot(
                                  lotId: selected.id,
                                  lotCode: selected.batchCode,
                                ),
                                imageUrls: _lotImages(selected),
                                token: widget.crabService.token,
                                onClose: () => setState(() {
                                  _hidePanel = true;
                                  _selectedId = null;
                                }),
                                onPlace: selected.workflowStatus.canAllocate
                                    ? () => _place(selected)
                                    : null,
                                onOpenFull: () => widget.onOpenDetail?.call(selected),
                                onOpenImage: (url) => _openImage(selected, url),
                                onAddPhotos: () => _addLotPhotos(selected),
                              ),
                      ),
                    ],
                  )
                : _listCard(lots, filtered),
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
                    'Quản lý nhập hàng',
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
                'Quản lý nhập hàng',
                style: bvText(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: DashboardColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Theo dõi lô cua nhập kho, tiến độ phân hộp và lịch sử nhà cung cấp.',
                style: bvText(fontSize: 13, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
        MgmtPrimaryButton(
          icon: Icons.add_rounded,
          label: 'Nhập lô mới',
          onTap: _svc.loading ? null : _import,
        ),
      ],
    );
  }

  Widget _kpis(CrabLotInboundKpis k) {
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
            icon: Icons.local_shipping_outlined,
            label: 'TỔNG LÔ NHẬP',
            value: formatInt(k.totalLots),
            hint: k.lotsThisMonth == 0 ? 'Tháng này —' : '+${k.lotsThisMonth} tháng này',
            color: DashboardColors.brand,
          ),
          _Kpi(
            icon: Icons.set_meal_outlined,
            label: 'TỔNG CUA NHẬP',
            value: formatInt(k.totalCrabs),
            hint: k.crabsThisMonth == 0 ? 'Tháng này —' : '+${formatInt(k.crabsThisMonth)} tháng này',
            color: kLotCoral,
          ),
          _Kpi(
            icon: Icons.check_circle_outline_rounded,
            label: 'ĐÃ PHÂN HỘP',
            value: formatInt(k.placedCrabs),
            hint: k.totalCrabs == 0 ? '—' : '${k.placedPct}%',
            color: DashboardColors.brandGreen,
          ),
          _Kpi(
            icon: Icons.timelapse_rounded,
            label: 'CHỜ XỬ LÝ',
            value: formatInt(k.pendingCrabs),
            hint: k.totalCrabs == 0 ? '—' : '${k.pendingPct}%',
            color: kLotAmber,
          ),
          _Kpi(
            icon: Icons.warning_amber_rounded,
            label: 'HỦY / LOẠI',
            value: formatInt(k.rejectedCrabs),
            hint: k.totalCrabs == 0 ? '—' : '${k.rejectedPct}%',
            color: DashboardColors.risk,
          ),
          _Kpi(
            icon: Icons.groups_outlined,
            label: 'NHÀ CUNG CẤP',
            value: formatInt(k.supplierCount),
            hint: k.supplierCount == 0 ? '—' : '${k.supplierCount} đối tác',
            color: kLotTeal,
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

  Widget _toolbar() {
    final rangeLabel = _svc.from == null && _svc.to == null
        ? 'Tất cả thời gian'
        : '${_svc.from == null ? '…' : formatDate(_svc.from!)} → ${_svc.to == null ? '…' : formatDate(_svc.to!)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: mgmtCardDeco(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: MgmtSearchField(
              controller: _searchCtrl,
              onChanged: _svc.setSearch,
              hint: 'Tìm kiếm mã lô, tên lô, nhà cung cấp, khu vực...',
            ),
          ),
          const SizedBox(width: 10),
          MgmtDropdown<CrabLotWorkflowStatus?>(
            width: 170,
            valueLabel: _svc.statusFilter?.label ?? 'Tất cả trạng thái',
            items: [
              (null, 'Tất cả trạng thái'),
              for (final s in CrabLotWorkflowStatus.values) (s, s.label),
            ],
            onSelected: _svc.setStatusFilter,
          ),
          const SizedBox(width: 10),
          MgmtDropdown<String>(
            width: 180,
            valueLabel: _svc.supplierFilter.isEmpty
                ? 'Tất cả nhà cung cấp'
                : _svc.supplierFilter,
            items: [
              ('', 'Tất cả nhà cung cấp'),
              for (final s in _svc.supplierOptions) (s, s),
            ],
            onSelected: _svc.setSupplierFilter,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 210,
            child: InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: DashboardColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          MgmtOutlineButton(
            icon: Icons.tune_rounded,
            label: 'Bộ lọc nâng cao',
            onTap: () => setState(() => _advanced = !_advanced),
            color: _advanced ? DashboardColors.brand : DashboardColors.textMuted,
            height: 42,
          ),
        ],
      ),
    );
  }

  Widget _advancedPanel() {
    final areas = widget.crabService.crabs
        .map((c) => c.areaName.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final rows = widget.crabService.crabs
        .where((c) => _areaFilter.isEmpty || c.areaName == _areaFilter)
        .map((c) => c.rowName.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mgmtCardDeco(radius: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _areaFilter.isEmpty ? 'Tất cả khu' : _areaFilter,
                  items: [
                    ('', 'Tất cả khu'),
                    for (final a in areas) (a, a),
                  ],
                  onSelected: (v) => setState(() {
                    _areaFilter = v;
                    _rowFilter = '';
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: _rowFilter.isEmpty ? 'Tất cả dãy' : _rowFilter,
                  items: [
                    ('', 'Tất cả dãy'),
                    for (final r in rows) (r, r),
                  ],
                  onSelected: (v) => setState(() => _rowFilter = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyFrom,
                        keyboardType: TextInputType.number,
                        style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
                        decoration: _qtyDec('Từ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _qtyTo,
                        keyboardType: TextInputType.number,
                        style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
                        decoration: _qtyDec('Đến'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<CrabLotProgressBand>(
                  valueLabel: 'Tỷ lệ: ${_svc.progressBand.label}',
                  items: [
                    for (final b in CrabLotProgressBand.values) (b, b.label),
                  ],
                  onSelected: _svc.setProgressBand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MgmtDropdown<String>(
                  valueLabel: 'Người nhập: Tất cả',
                  items: const [('all', 'Tất cả')],
                  onSelected: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              MgmtOutlineButton(
                label: 'Xóa bộ lọc',
                onTap: _clearFilters,
                color: DashboardColors.textMuted,
              ),
              const SizedBox(width: 8),
              MgmtPrimaryButton(label: 'Áp dụng', onTap: _applyAdvanced),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _qtyDec(String hint) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: bvText(fontSize: 12.5, color: DashboardColors.textMuted),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: b(DashboardColors.cardBorder),
      enabledBorder: b(DashboardColors.cardBorder),
      focusedBorder: b(DashboardColors.brandGreen),
    );
  }

  Widget _listCard(List<FarmingBatchRecord> lots, List<FarmingBatchRecord> filtered) {
    return Container(
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  'Danh sách lô nhập (${filtered.length})',
                  style: bvText(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                const Spacer(),
                MgmtInlineSort<CrabLotSort>(
                  value: _svc.sort,
                  items: [
                    for (final s in CrabLotSort.values) (s, s.label),
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
          Expanded(child: _body(lots, filtered)),
          _bottomBar(filtered),
        ],
      ),
    );
  }

  Widget _body(List<FarmingBatchRecord> lots, List<FarmingBatchRecord> filtered) {
    if (_svc.loading && _svc.lots.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (filtered.isEmpty) {
      if (_svc.lots.isEmpty) {
        return MgmtEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Chưa có lô cua nhập',
          message: 'Các lô cua mới nhập vào trại sẽ xuất hiện tại đây.',
          action: MgmtPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Nhập lô đầu tiên',
            onTap: _import,
          ),
        );
      }
      return MgmtEmptyState(
        icon: Icons.search_rounded,
        title: 'Không tìm thấy lô nhập',
        message: 'Không có lô nào phù hợp với bộ lọc hiện tại.',
        action: MgmtOutlineButton(
          label: 'Xóa bộ lọc',
          onTap: _clearFilters,
        ),
      );
    }
    return CrabLotInboundTable(
      lots: lots,
      selectedId: _selected?.id,
      checkedIds: _checked,
      onToggle: (lot) {
        setState(() {
          if (_checked.contains(lot.id)) {
            _checked.remove(lot.id);
          } else {
            _checked.add(lot.id);
          }
        });
      },
      onToggleAll: () {
        setState(() {
          if (lots.every((l) => _checked.contains(l.id))) {
            for (final l in lots) {
              _checked.remove(l.id);
            }
          } else {
            for (final l in lots) {
              _checked.add(l.id);
            }
          }
        });
      },
      onSelectRow: (lot) => setState(() {
        _selectedId = lot.id;
        _hidePanel = false;
      }),
      onOpenCode: (lot) => widget.onOpenDetail?.call(lot),
      onView: (lot) => setState(() {
        _selectedId = lot.id;
        _hidePanel = false;
      }),
      onMenu: _onMenu,
    );
  }

  Widget _bottomBar(List<FarmingBatchRecord> filtered) {
    final selectedLots = _svc.lots.where((l) => _checked.contains(l.id)).toList();
    final n = selectedLots.length;
    final pages = filtered.isEmpty
        ? 1
        : (filtered.length / _svc.pageSize).ceil().clamp(1, 99);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: DashboardColors.mint)),
      ),
      child: Row(
        children: [
          Text(
            'Đã chọn $n lô',
            style: bvText(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textMuted,
            ),
          ),
          if (n > 0) ...[
            const SizedBox(width: 10),
            MgmtOutlineButton(
              label: 'Xuất dữ liệu',
              icon: Icons.download_outlined,
              onTap: () => _export(selectedLots),
              height: 34,
            ),
            const SizedBox(width: 8),
            MgmtOutlineButton(
              label: 'In phiếu',
              icon: Icons.print_outlined,
              onTap: () => _printSlips(selectedLots),
              height: 34,
            ),
          ],
          const Spacer(),
          MgmtPageBtn(
            icon: Icons.chevron_left_rounded,
            onTap: _svc.currentPage > 0
                ? () => _svc.goToPage(_svc.currentPage - 1)
                : null,
          ),
          for (var i = 0; i < pages; i++) ...[
            const SizedBox(width: 6),
            MgmtPageBtn(
              label: '${i + 1}',
              active: i == _svc.currentPage,
              onTap: () => _svc.goToPage(i),
            ),
          ],
          const SizedBox(width: 6),
          MgmtPageBtn(
            icon: Icons.chevron_right_rounded,
            onTap: _svc.currentPage < pages - 1
                ? () => _svc.goToPage(_svc.currentPage + 1)
                : null,
          ),
          const SizedBox(width: 16),
          Text('Hiển thị', style: bvText(fontSize: 12, color: DashboardColors.textMuted)),
          const SizedBox(width: 8),
          MgmtDropdown<int>(
            width: 110,
            valueLabel: '${_svc.pageSize} / trang',
            items: const [
              (10, '10 / trang'),
              (20, '20 / trang'),
              (50, '50 / trang'),
              (100, '100 / trang'),
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
        'Chọn một lô để xem chi tiết',
        style: bvText(fontSize: 13, color: DashboardColors.textMuted),
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
