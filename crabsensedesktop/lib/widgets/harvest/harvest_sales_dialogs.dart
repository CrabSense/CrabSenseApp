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
  HarvestSalesService service,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CreateHarvestDialog(service: service),
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

Future<void> showSalesOrderDetailDialog(BuildContext context, Object order) {
  if (order is SalesOrderDetail) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: Text(
          'Đơn ${order.code}',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Khách hàng', order.customerName),
              if (order.customerPhone.isNotEmpty)
                _kv('Số điện thoại', order.customerPhone),
              _kv('Ngày bán', formatHarvestDate(order.orderDate)),
              _kv('Người bán', order.sellerName),
              _kv(
                'Thanh toán',
                order.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
              ),
              _kv('Tổng', formatVnd(order.revenueVnd)),
              const SizedBox(height: 10),
              Text(
                'Cua trong đơn',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              for (final line in order.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${line.crabCode} · ${line.weightG}g · ${formatVnd(line.unitPricePerKg)}/kg → ${formatVnd(line.totalVnd)}',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
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
  const _CreateHarvestDialog({required this.service});

  final HarvestSalesService service;

  @override
  State<_CreateHarvestDialog> createState() => _CreateHarvestDialogState();
}

class _CreateHarvestDialogState extends State<_CreateHarvestDialog> {
  late DateTime _when;
  late final TextEditingController _note;
  final _selected = <HarvestableCrab>[];
  final _gradesById = <String, String>{};
  final _resultsById = <String, String>{};
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
        photoUrls: _photos.where((p) => p.startsWith('http')).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thu hoạch. Cua vào tồn kho, chưa bán.'),
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
        'Tạo phiếu thu hoạch',
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
                  'Chọn nhiều cua cùng lúc. Mỗi con lưu trọng lượng và chất lượng riêng.',
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
                    onGrade: (v) => setState(() => _gradesById[c.id] = v),
                    onResult: (v) => setState(() => _resultsById[c.id] = v),
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
          child: Text(_saving ? 'Đang lưu…' : 'Xác nhận thu hoạch'),
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
    required this.onGrade,
    required this.onResult,
    required this.onRemove,
    required this.onWeight,
  });

  final HarvestableCrab crab;
  final TextEditingController weightCtrl;
  final String grade;
  final String result;
  final ValueChanged<String> onGrade;
  final ValueChanged<String> onResult;
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
        ],
      ),
    );
  }
}

class _PickHarvestCrabsDialog extends StatefulWidget {
  const _PickHarvestCrabsDialog({
    required this.crabs,
    required this.already,
  });

  final List<HarvestableCrab> crabs;
  final Set<String> already;

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
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.boxCode.toLowerCase().contains(q) ||
          c.locationLine.toLowerCase().contains(q);
    }).toList();
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Chọn cua thu hoạch',
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
                      'Không còn cua đang nuôi.',
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
                              '${c.lotCode.isEmpty ? '' : ' · ${c.lotCode}'}',
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

class _CreateSaleDialog extends StatefulWidget {
  const _CreateSaleDialog({required this.service});

  final HarvestSalesService service;

  @override
  State<_CreateSaleDialog> createState() => _CreateSaleDialogState();
}

class _CreateSaleDialogState extends State<_CreateSaleDialog> {
  late final TextEditingController _customer;
  late final TextEditingController _phone;
  late final TextEditingController _price;
  late final TextEditingController _search;
  var _paid = true;
  final _selected = <String>{};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _customer = TextEditingController();
    _phone = TextEditingController();
    _price = TextEditingController(text: '250000');
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _price.dispose();
    _search.dispose();
    super.dispose();
  }

  List<InventoryCrab> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return widget.service.inventory.where((c) {
      if (q.isEmpty) return true;
      return c.code.toLowerCase().contains(q) ||
          c.boxCode.toLowerCase().contains(q);
    }).toList();
  }

  int get _total {
    final price = int.tryParse(_price.text) ?? 0;
    return widget.service.inventory
        .where((c) => _selected.contains(c.id))
        .fold<int>(0, (s, c) => s + ((c.weightG / 1000) * price).round());
  }

  Future<void> _save() async {
    final crabs = widget.service.inventory
        .where((c) => _selected.contains(c.id))
        .toList();
    if (crabs.isEmpty || _customer.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.service.createSaleOrder(
        orderDate: DateTime.now(),
        customerName: _customer.text.trim(),
        customerPhone: _phone.text.trim(),
        paymentStatus: _paid ? 'Paid' : 'Pending',
        sellerName: widget.service.performerName,
        crabs: crabs,
        unitPricePerKg: int.tryParse(_price.text) ?? 0,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo đơn. Cua chuyển sang Đã bán.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final crabs = _filtered;
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Tạo đơn bán hàng',
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mã đơn tự động · Người bán: ${widget.service.performerName}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customer,
                decoration: const InputDecoration(labelText: 'Khách hàng'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đơn giá (đ/kg)'),
                onChanged: (_) => setState(() {}),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đã thanh toán'),
                value: _paid,
                onChanged: (v) => setState(() => _paid = v),
              ),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Tìm cua tồn kho…',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cua tồn kho — đã thu hoạch, chưa bán (${_selected.length})',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                child: crabs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Chưa có cua tồn kho. Hãy thu hoạch trước.',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final c in crabs)
                            CheckboxListTile(
                              dense: true,
                              value: _selected.contains(c.id),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(c.id);
                                } else {
                                  _selected.remove(c.id);
                                }
                              }),
                              title: Text(
                                '${c.code} · ${c.weightG}g · Loại ${c.grade}',
                                style: GoogleFonts.notoSans(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thành tiền: ${formatVnd(_total)}',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w800),
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
          onPressed: _saving ||
                  _selected.isEmpty ||
                  _customer.text.trim().isEmpty
              ? null
              : _save,
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: Text(_saving ? 'Đang lưu…' : 'Tạo đơn'),
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
