import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/harvest_sales.dart';
import '../../services/harvest_sales_service.dart';
import '../../theme/dashboard_theme.dart';

const _grades = ['A', 'B', 'C'];

Future<void> showCreateHarvestSlipDialog(
  BuildContext context,
  HarvestSalesService service, {
  bool softshellMode = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CreateHarvestDialog(
      service: service,
      softshellMode: softshellMode,
    ),
  );
}

Future<void> showHarvestSlipDetailDialog(
  BuildContext context,
  HarvestSlipDetail slip,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        slip.code,
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Trạng thái', slip.statusLabel),
              _kv('Ngày giờ', slip.harvestDate),
              _kv('Người thực hiện', slip.performedBy.isEmpty ? '—' : slip.performedBy),
              _kv('Khu', slip.area),
              if (slip.note != null && slip.note!.isNotEmpty)
                _kv('Ghi chú', slip.note!),
              const SizedBox(height: 10),
              Text(
                'Danh sách cua',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 6),
              for (final line in slip.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${line.crabCode.isEmpty ? '—' : line.crabCode}  ·  ${line.locationLine}\n'
                    '${line.weightG}g  ·  Loại ${line.grade.isEmpty ? '—' : line.grade}'
                    '${line.lotCode.isEmpty ? '' : '  ·  Lô ${line.lotCode}'}'
                    '${line.isSoftshell ? '  ·  Cua lột' : ''}'
                    '  ·  ${line.passed ? 'Đạt' : 'Không đạt'}',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Tổng ${slip.quantity} con  ·  ${slip.totalWeightKg.toStringAsFixed(2)} kg  ·  '
                'TB ${slip.averageWeightG.toStringAsFixed(0)}g  ·  '
                'Đạt ${slip.passedCount}'
                '${slip.failedCount > 0 ? '  ·  Không đạt ${slip.failedCount}' : ''}',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              if (slip.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ảnh thu hoạch: ${slip.photoUrls.length} tệp',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ],
    ),
  );
}

Future<void> showCreateSalesOrderDialog(
  BuildContext context,
  HarvestSalesService service,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CreateSaleDialog(service: service),
  );
}

Future<void> showSalesOrderDetailDialog(
  BuildContext context,
  Object order, {
  HarvestSalesService? service,
}) {
  if (order is SalesOrderDetail) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _SalesOrderDetailDialog(
        order: order,
        service: service,
      ),
    );
  }
  if (order is SalesOrder) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text(
          'Chi tiết đơn ${order.code}',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Khách hàng', order.customerName),
            _kv('Ngày', order.orderDate),
            _kv('Tổng', formatVnd(order.revenueVnd)),
            _kv('Trạng thái', order.status.label),
          ],
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
  return Future.value();
}

class _CreateHarvestDialog extends StatefulWidget {
  const _CreateHarvestDialog({
    required this.service,
    this.softshellMode = false,
  });

  final HarvestSalesService service;
  final bool softshellMode;

  @override
  State<_CreateHarvestDialog> createState() => _CreateHarvestDialogState();
}

class _CreateHarvestDialogState extends State<_CreateHarvestDialog> {
  late DateTime _when;
  late final TextEditingController _note;
  final _selected = <HarvestableCrab>[];
  final _gradesById = <String, String>{};
  final _resultsById = <String, String>{};
  final _softshellById = <String, bool>{};
  final _weights = <String, TextEditingController>{};
  final _photos = <String>[];
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _when = DateTime.now();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _note.dispose();
    for (final c in _weights.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<HarvestableCrab> get _picked => _selected;

  int _weightOf(HarvestableCrab c) =>
      int.tryParse(_weights[c.id]?.text.trim() ?? '') ?? c.weightG;

  int get _totalG => _picked.fold<int>(0, (s, c) => s + _weightOf(c));
  int get _passed =>
      _picked.where((c) => (_resultsById[c.id] ?? 'passed') != 'failed').length;

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _when.hour,
        t?.minute ?? _when.minute,
      );
    });
  }

  Future<void> _pickCrabs() async {
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _PickHarvestCrabsDialog(
        crabs: widget.service.harvestableCrabs,
        already: _selected.map((c) => c.id).toSet(),
        softshellOnly: widget.softshellMode,
      ),
    );
    if (chosen == null) return;
    setState(() {
      for (final c in widget.service.harvestableCrabs) {
        if (!chosen.contains(c.id)) continue;
        if (_selected.any((e) => e.id == c.id)) continue;
        _selected.add(c);
        _gradesById.putIfAbsent(c.id, () => 'A');
        _resultsById.putIfAbsent(c.id, () => 'passed');
        _softshellById.putIfAbsent(
          c.id,
          () => widget.softshellMode || c.isSoftshell,
        );
        _weights.putIfAbsent(
          c.id,
          () => TextEditingController(text: '${c.weightG}'),
        );
      }
      _selected.removeWhere((c) => !chosen.contains(c.id));
    });
  }

  Future<void> _pickPhotos() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (picked == null) return;
    for (final f in picked.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final url = await widget.service.uploadPhoto(path);
        if (url != null && mounted) setState(() => _photos.add(url));
      } catch (_) {
        if (mounted) setState(() => _photos.add(f.name));
      }
    }
  }

  Future<void> _save() async {
    if (_picked.isEmpty) return;
    if (_picked.any((c) => _weightOf(c) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mỗi con cua cần trọng lượng > 0')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.createHarvestFromCrabs(
        harvestDate: _when,
        performedBy: widget.service.performerName,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        crabs: _picked,
        grades: _gradesById,
        conditions: {for (final c in _picked) c.id: c.condition},
        weights: {for (final c in _picked) c.id: _weightOf(c)},
        results: _resultsById,
        softshell: _softshellById,
        photoUrls: _photos.where((p) => p.startsWith('http')).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.softshellMode
                ? 'Đã xuất cua lột vào tồn kho, chưa bán.'
                : 'Đã thu hoạch. Cua vào tồn kho, chưa bán.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _picked.length;
    final avg = count == 0 ? 0 : _totalG / count;
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        widget.softshellMode
            ? 'Xuất cua lột'
            : 'Tạo phiếu thu hoạch',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mã phiếu: ${widget.service.nextVoucherPreview}  ·  Trạng thái: Hoàn thành khi xác nhận',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickWhen,
                icon: const Icon(Icons.schedule, size: 16),
                label: Text(formatHarvestDateTime(_when)),
              ),
              const SizedBox(height: 6),
              Text(
                'Người thực hiện: ${widget.service.performerName}',
                style: GoogleFonts.notoSans(fontSize: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Danh sách cua',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _pickCrabs,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Chọn cua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_picked.isEmpty)
                Text(
                    widget.softshellMode
                        ? 'Chọn cua đã lột / đang lột để xuất ra tồn kho.'
                        : 'Chọn nhiều cua cùng lúc. Mỗi con lưu trọng lượng và chất lượng riêng.',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                )
              else
                for (final c in _picked)
                  _HarvestCrabCard(
                    crab: c,
                    weightCtrl: _weights[c.id]!,
                    grade: _gradesById[c.id] ?? 'A',
                    result: _resultsById[c.id] ?? 'passed',
                    isSoftshell: _softshellById[c.id] ??
                        (widget.softshellMode || c.isSoftshell),
                    onGrade: (v) => setState(() => _gradesById[c.id] = v),
                    onResult: (v) => setState(() => _resultsById[c.id] = v),
                    onSoftshell: (v) =>
                        setState(() => _softshellById[c.id] = v),
                    onRemove: () => setState(() {
                      _selected.removeWhere((e) => e.id == c.id);
                    }),
                    onWeight: () => setState(() {}),
                  ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardColors.darkNavy.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tổng $count con  ·  ${(_totalG / 1000).toStringAsFixed(2)} kg  ·  '
                  'TB ${avg.toStringAsFixed(0)}g/con  ·  Đạt $_passed'
                  '${count - _passed > 0 ? '  ·  Không đạt ${count - _passed}' : ''}',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  _photos.isEmpty
                      ? 'Ảnh thu hoạch (không bắt buộc)'
                      : '${_photos.length} ảnh đã chọn',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving || _picked.isEmpty ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.cyan),
          child: Text(
            _saving
                ? 'Đang lưu…'
                : (widget.softshellMode
                    ? 'Xác nhận xuất cua lột'
                    : 'Xác nhận thu hoạch'),
          ),
        ),
      ],
    );
  }
}

class _HarvestCrabCard extends StatelessWidget {
  const _HarvestCrabCard({
    required this.crab,
    required this.weightCtrl,
    required this.grade,
    required this.result,
    required this.isSoftshell,
    required this.onGrade,
    required this.onResult,
    required this.onSoftshell,
    required this.onRemove,
    required this.onWeight,
  });

  final HarvestableCrab crab;
  final TextEditingController weightCtrl;
  final String grade;
  final String result;
  final bool isSoftshell;
  final ValueChanged<String> onGrade;
  final ValueChanged<String> onResult;
  final ValueChanged<bool> onSoftshell;
  final VoidCallback onRemove;
  final VoidCallback onWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  crab.code,
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            crab.locationLine,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          if (crab.lotCode.isNotEmpty)
            Text(
              'Lô ${crab.lotCode}',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: weightCtrl,
                  onChanged: (_) => onWeight(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Trọng lượng (g)',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: grade,
                items: [
                  for (final g in _grades)
                    DropdownMenuItem(value: g, child: Text('Loại $g')),
                ],
                onChanged: (v) {
                  if (v != null) onGrade(v);
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: result,
                items: const [
                  DropdownMenuItem(value: 'passed', child: Text('Đạt')),
                  DropdownMenuItem(value: 'failed', child: Text('Không đạt')),
                ],
                onChanged: (v) {
                  if (v != null) onResult(v);
                },
              ),
            ],
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: isSoftshell,
            onChanged: (v) => onSoftshell(v ?? false),
            title: Text(
              'Cua lột',
              style: GoogleFonts.notoSans(fontSize: 13),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}

class _PickHarvestCrabsDialog extends StatefulWidget {
  const _PickHarvestCrabsDialog({
    required this.crabs,
    required this.already,
    this.softshellOnly = false,
  });

  final List<HarvestableCrab> crabs;
  final Set<String> already;
  final bool softshellOnly;

  @override
  State<_PickHarvestCrabsDialog> createState() => _PickHarvestCrabsDialogState();
}

class _PickHarvestCrabsDialogState extends State<_PickHarvestCrabsDialog> {
  late final Set<String> _sel;
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sel = {...widget.already};
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final items = widget.crabs.where((c) {
      if (widget.softshellOnly && !c.readyForSoftshellExport) return false;
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.boxCode.toLowerCase().contains(q) ||
          c.locationLine.toLowerCase().contains(q);
    }).toList();
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        widget.softshellOnly ? 'Chọn cua lột' : 'Chọn cua thu hoạch',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Tìm mã cua / hộp / khu…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: items.isEmpty
                  ? Text(
                      widget.softshellOnly
                          ? 'Chưa có cua lột. Ghi nhận lột xác trong Quản lý cua trước.'
                          : 'Không còn cua đang nuôi.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final c in items)
                          CheckboxListTile(
                            dense: true,
                            value: _sel.contains(c.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _sel.add(c.id);
                              } else {
                                _sel.remove(c.id);
                              }
                            }),
                            title: Text(
                              c.code,
                              style: GoogleFonts.notoSans(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${c.locationLine} · ${c.weightG}g'
                              '${c.lotCode.isEmpty ? '' : ' · ${c.lotCode}'}'
                              '${c.readyForSoftshellExport ? ' · Cua lột' : ''}',
                              style: GoogleFonts.notoSans(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _sel),
          child: Text('Thêm ${_sel.length} cua'),
        ),
      ],
    );
  }
}

class _SalesOrderDetailDialog extends StatefulWidget {
  const _SalesOrderDetailDialog({required this.order, this.service});

  final SalesOrderDetail order;
  final HarvestSalesService? service;

  @override
  State<_SalesOrderDetailDialog> createState() => _SalesOrderDetailDialogState();
}

class _SalesOrderDetailDialogState extends State<_SalesOrderDetailDialog> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final service = widget.service;
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Đơn ${order.code}',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Trạng thái đơn', order.orderStatusLabel),
              _kv('Ngày giờ', formatHarvestDateTime(order.orderDate)),
              _kv('Người bán', order.sellerName.isEmpty ? '—' : order.sellerName),
              _kv('Khách hàng', order.customerName),
              if (order.customerPhone.isNotEmpty)
                _kv('Số điện thoại', order.customerPhone),
              if (order.customerAddress.isNotEmpty)
                _kv('Địa chỉ', order.customerAddress),
              _kv('Thanh toán', order.paymentStatusLabel),
              _kv('Phương thức', order.paymentMethodLabel),
              _kv('Giao hàng', order.deliveryStatusLabel),
              if (order.notes != null && order.notes!.isNotEmpty)
                _kv('Ghi chú', order.notes!),
              const SizedBox(height: 10),
              Text(
                'Danh sách cua',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${line.crabCode}  ·  ${line.weightG}g  ·  ${line.typeLabel}'
                    '${line.grade.isEmpty ? '' : '  ·  Loại ${line.grade}'}\n'
                    '${formatVnd(line.unitPricePerKg)}/kg  →  ${formatVnd(line.totalVnd)}',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              _kv('Tổng trọng lượng', '${order.totalWeightKg.toStringAsFixed(2)} kg'),
              _kv('Tạm tính', formatVnd(order.subtotalVnd)),
              if (order.discountVnd > 0) _kv('Giảm giá', formatVnd(order.discountVnd)),
              if (order.shippingVnd > 0)
                _kv('Phí vận chuyển', formatVnd(order.shippingVnd)),
              _kv('Tổng cộng', formatVnd(order.revenueVnd)),
              if (order.isPartial) _kv('Đã thu', formatVnd(order.paidVnd)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (service != null && !order.isCancelled && order.isDraft)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => service.completeSaleOrder(order.id),
                      'Đã xác nhận bán. Cua chuyển sang Đã bán.',
                    ),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
            child: Text(_busy ? 'Đang lưu…' : 'Xác nhận bán hàng'),
          ),
        if (service != null && !order.isCancelled)
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => service.cancelSaleOrder(order.id),
                      'Đã hủy đơn. Cua trở lại kho nếu đã bán.',
                    ),
            child: const Text('Hủy đơn'),
          ),
      ],
    );
  }
}

class _CreateSaleDialog extends StatefulWidget {
  const _CreateSaleDialog({required this.service});

  final HarvestSalesService service;

  @override
  State<_CreateSaleDialog> createState() => _CreateSaleDialogState();
}

class _CreateSaleDialogState extends State<_CreateSaleDialog> {
  late DateTime _when;
  late final TextEditingController _customer;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _note;
  late final TextEditingController _discount;
  late final TextEditingController _shipping;
  late final TextEditingController _paid;
  final _selected = <InventoryCrab>[];
  final _grades = <String, String>{};
  final _weights = <String, TextEditingController>{};
  final _prices = <String, TextEditingController>{};
  var _paymentStatus = 'Paid';
  var _paymentMethod = 'cash';
  var _delivery = 'pickup';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _when = DateTime.now();
    _customer = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _note = TextEditingController();
    _discount = TextEditingController(text: '0');
    _shipping = TextEditingController(text: '0');
    _paid = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    _discount.dispose();
    _shipping.dispose();
    _paid.dispose();
    for (final c in _weights.values) {
      c.dispose();
    }
    for (final c in _prices.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _weightOf(InventoryCrab c) =>
      int.tryParse(_weights[c.id]?.text.trim() ?? '') ?? c.weightG;

  int _priceOf(InventoryCrab c) =>
      int.tryParse(_prices[c.id]?.text.trim() ?? '') ?? 300000;

  int _lineTotal(InventoryCrab c) =>
      ((_weightOf(c) / 1000) * _priceOf(c)).round();

  int get _subtotal => _selected.fold<int>(0, (s, c) => s + _lineTotal(c));

  int get _discountVnd => int.tryParse(_discount.text.trim()) ?? 0;

  int get _shippingVnd => int.tryParse(_shipping.text.trim()) ?? 0;

  int get _grand => (_subtotal - _discountVnd + _shippingVnd).clamp(0, 1 << 31);

  double get _totalKg =>
      _selected.fold<double>(0, (s, c) => s + _weightOf(c) / 1000);

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _when.hour,
        t?.minute ?? _when.minute,
      );
    });
  }

  Future<void> _pickCrabs() async {
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _PickInventoryCrabsDialog(
        crabs: widget.service.inventory,
        already: _selected.map((c) => c.id).toSet(),
      ),
    );
    if (chosen == null) return;
    setState(() {
      for (final c in widget.service.inventory) {
        if (!chosen.contains(c.id)) continue;
        if (_selected.any((e) => e.id == c.id)) continue;
        _selected.add(c);
        _grades.putIfAbsent(c.id, () => c.grade.isEmpty ? 'A' : c.grade);
        _weights.putIfAbsent(
          c.id,
          () => TextEditingController(text: '${c.weightG}'),
        );
        _prices.putIfAbsent(
          c.id,
          () => TextEditingController(text: '300000'),
        );
      }
      _selected.removeWhere((c) => !chosen.contains(c.id));
    });
  }

  Future<void> _save(String status) async {
    if (_selected.isEmpty || _customer.text.trim().isEmpty) return;
    if (_selected.any((c) => _weightOf(c) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mỗi con cua cần trọng lượng > 0')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.createSaleOrder(
        orderDate: _when,
        customerName: _customer.text.trim(),
        customerPhone: _phone.text.trim(),
        customerAddress: _address.text.trim(),
        paymentStatus: _paymentStatus,
        paymentMethod: _paymentMethod,
        orderStatus: status,
        sellerName: widget.service.performerName,
        notes: _note.text.trim(),
        discountAmount: _discountVnd,
        shippingFee: _shippingVnd,
        paidAmount: int.tryParse(_paid.text.trim()) ?? 0,
        deliveryStatus: _delivery,
        crabs: _selected,
        weights: {for (final c in _selected) c.id: _weightOf(c)},
        grades: _grades,
        prices: {for (final c in _selected) c.id: _priceOf(c)},
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Draft'
                ? 'Đã lưu nháp. Cua vẫn còn trong kho.'
                : 'Đã xác nhận bán. Cua chuyển sang Đã bán.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Tạo đơn bán hàng',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mã đơn: ${widget.service.nextSalePreview}  ·  Người bán: ${widget.service.performerName}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickWhen,
                icon: const Icon(Icons.schedule, size: 16),
                label: Text(formatHarvestDateTime(_when)),
              ),
              const SizedBox(height: 12),
              Text(
                'Khách hàng',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
              ),
              TextField(
                controller: _customer,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Tên khách hàng *'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Địa chỉ (tuỳ chọn)'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Danh sách cua',
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _pickCrabs,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Chọn cua từ kho'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selected.isEmpty)
                Text(
                  'Chọn cua đã thu hoạch / tồn kho. Đơn giá nhập theo kg, hệ thống tự tính thành tiền.',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                )
              else
                for (final c in _selected)
                  _SaleCrabCard(
                    crab: c,
                    grade: _grades[c.id] ?? 'A',
                    weightCtrl: _weights[c.id]!,
                    priceCtrl: _prices[c.id]!,
                    lineTotal: _lineTotal(c),
                    onGrade: (g) => setState(() => _grades[c.id] = g),
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() {
                      _selected.removeWhere((e) => e.id == c.id);
                    }),
                  ),
              const SizedBox(height: 12),
              Text(
                'Thanh toán',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Tổng trọng lượng: ${_totalKg.toStringAsFixed(2)} kg',
                style: GoogleFonts.notoSans(fontSize: 12),
              ),
              Text(
                'Tạm tính: ${formatVnd(_subtotal)}',
                style: GoogleFonts.notoSans(fontSize: 12),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Giảm giá (đ)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _shipping,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Phí vận chuyển (đ)',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tổng cộng: ${formatVnd(_grand)}',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Phương thức',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                  DropdownMenuItem(value: 'transfer', child: Text('Chuyển khoản')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Chưa thanh toán')),
                ],
                onChanged: (v) => setState(() {
                  _paymentMethod = v ?? 'cash';
                  if (_paymentMethod == 'unpaid') _paymentStatus = 'Pending';
                }),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái thanh toán',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Paid', child: Text('Đã thanh toán')),
                  DropdownMenuItem(
                    value: 'Partial',
                    child: Text('Thanh toán một phần'),
                  ),
                  DropdownMenuItem(value: 'Pending', child: Text('Chưa thanh toán')),
                ],
                onChanged: (v) => setState(() => _paymentStatus = v ?? 'Paid'),
              ),
              if (_paymentStatus == 'Partial')
                TextField(
                  controller: _paid,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Số tiền đã thu (đ)',
                    isDense: true,
                  ),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _delivery,
                decoration: const InputDecoration(
                  labelText: 'Giao hàng',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'pickup', child: Text('Nhận tại trại')),
                  DropdownMenuItem(value: 'delivery', child: Text('Giao hàng')),
                  DropdownMenuItem(value: 'shipping', child: Text('Đang giao')),
                  DropdownMenuItem(value: 'delivered', child: Text('Đã giao')),
                ],
                onChanged: (v) => setState(() => _delivery = v ?? 'pickup'),
              ),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: _saving ||
                  _selected.isEmpty ||
                  _customer.text.trim().isEmpty
              ? null
              : () => _save('Draft'),
          child: const Text('Lưu nháp'),
        ),
        FilledButton(
          onPressed: _saving ||
                  _selected.isEmpty ||
                  _customer.text.trim().isEmpty
              ? null
              : () => _save('Completed'),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: Text(_saving ? 'Đang lưu…' : 'Xác nhận bán hàng'),
        ),
      ],
    );
  }
}

class _SaleCrabCard extends StatelessWidget {
  const _SaleCrabCard({
    required this.crab,
    required this.grade,
    required this.weightCtrl,
    required this.priceCtrl,
    required this.lineTotal,
    required this.onGrade,
    required this.onChanged,
    required this.onRemove,
  });

  final InventoryCrab crab;
  final String grade;
  final TextEditingController weightCtrl;
  final TextEditingController priceCtrl;
  final int lineTotal;
  final ValueChanged<String> onGrade;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: DashboardColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  crab.code,
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            '${crab.typeLabel}${crab.boxCode.isEmpty ? '' : '  ·  ${crab.boxCode}'}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: weightCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Trọng lượng (g)',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: ['A', 'B', 'C'].contains(grade) ? grade : 'A',
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Loại A')),
                  DropdownMenuItem(value: 'B', child: Text('Loại B')),
                  DropdownMenuItem(value: 'C', child: Text('Loại C')),
                ],
                onChanged: (v) {
                  if (v != null) onGrade(v);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: priceCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá (đ/kg)',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '= ${formatVnd(lineTotal)}',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PickInventoryCrabsDialog extends StatefulWidget {
  const _PickInventoryCrabsDialog({
    required this.crabs,
    required this.already,
  });

  final List<InventoryCrab> crabs;
  final Set<String> already;

  @override
  State<_PickInventoryCrabsDialog> createState() =>
      _PickInventoryCrabsDialogState();
}

class _PickInventoryCrabsDialogState extends State<_PickInventoryCrabsDialog> {
  late final Set<String> _sel;
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sel = {...widget.already};
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final items = widget.crabs.where((c) {
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.boxCode.toLowerCase().contains(q) ||
          c.typeLabel.toLowerCase().contains(q);
    }).toList();
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Chọn cua từ kho',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Tìm mã cua / loại / hộp…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: items.isEmpty
                  ? Text(
                      'Chưa có cua tồn kho. Hãy thu hoạch trước.',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final c in items)
                          CheckboxListTile(
                            dense: true,
                            value: _sel.contains(c.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _sel.add(c.id);
                              } else {
                                _sel.remove(c.id);
                              }
                            }),
                            title: Text(
                              c.code,
                              style: GoogleFonts.notoSans(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${c.typeLabel} · ${c.weightG}g · Loại ${c.grade.isEmpty ? '—' : c.grade}',
                              style: GoogleFonts.notoSans(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _sel),
          child: Text('Thêm ${_sel.length} cua'),
        ),
      ],
    );
  }
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
