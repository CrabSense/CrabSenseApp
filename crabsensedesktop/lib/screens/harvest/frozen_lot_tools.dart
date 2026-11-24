import 'package:flutter/material.dart';
import '../../services/harvest_sales_service.dart';

String _text(Map<String, dynamic> row, String key) =>
    HarvestSalesService.frozenText(row, key);
num? _number(Map<String, dynamic> row, String key) =>
    HarvestSalesService.frozenNumber(row, key);
String _date(DateTime date) => date.toIso8601String().split('T').first;
String _dateField(Map<String, dynamic> row, String key) {
  final date = DateTime.tryParse(_text(row, key));
  return date == null ? '—' : _date(date);
}

void _message(BuildContext context, String value) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

Future<void> editFrozenLotDialog(BuildContext context, HarvestSalesService service, {
  Map<String, dynamic>? lot, required VoidCallback onChanged,
}) async {
  final area = service.areaId;
  final code = TextEditingController(text: lot == null ? '' : _text(lot, 'lotCode'));
  final location = TextEditingController(text: lot == null ? '' : _text(lot, 'storageLocation'));
  DateTime? frozen = lot == null ? DateTime.now() : DateTime.tryParse(_text(lot, 'frozenDate'));
  DateTime? expiry = lot == null ? null : DateTime.tryParse(_text(lot, 'expiryDate'));
  String grade = lot == null ? '' : _text(lot, 'grade');
  if (!const {'', 'S', 'M', 'L'}.contains(grade)) grade = '';
  String? voucher;
  String? error;
  bool busy = false;
  try {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false,
      builder: (dialog) => StatefulBuilder(builder: (dialog, setState) => PopScope(
        canPop: !busy,
        child: AlertDialog(
          title: Text(lot == null ? 'Tạo lô cấp đông' : 'Sửa thông tin lô'),
          content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Khu: ${service.areaName}'),
              TextField(controller: code, enabled: !busy && lot == null, decoration: const InputDecoration(labelText: 'Mã lô')),
              const SizedBox(height: 12),
              if (lot == null) DropdownButtonFormField<String>(
                value: voucher ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Phiếu thu hoạch đã hoàn tất (tùy chọn)'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Không liên kết')),
                  ...service.harvestSlips.where((v) => v.farmingAreaId == area && v.isCompleted)
                    .map((v) => DropdownMenuItem(value: v.id, child: Text(v.code))),
                ],
                onChanged: busy ? null : (v) => setState(() => voucher = v == null || v.isEmpty ? null : v),
              ),
              OutlinedButton(onPressed: busy ? null : () async {
                final picked = await showDatePicker(context: dialog, initialDate: frozen ?? DateTime.now(),
                  firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null && dialog.mounted) setState(() => frozen = picked);
              }, child: Text('Ngày cấp đông: ${frozen == null ? "Chọn ngày" : _date(frozen!)}')),
              OutlinedButton(onPressed: busy ? null : () async {
                final picked = await showDatePicker(context: dialog, initialDate: expiry ?? (frozen ?? DateTime.now()).add(const Duration(days: 1)),
                  firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null && dialog.mounted) setState(() => expiry = picked);
              }, child: Text('Ngày hết hạn: ${expiry == null ? "Chọn ngày" : _date(expiry!)}')),
              DropdownButtonFormField<String>(value: grade, decoration: const InputDecoration(labelText: 'Phân loại'),
                items: const ['', 'S', 'M', 'L'].map((v) => DropdownMenuItem(value: v, child: Text(v.isEmpty ? 'Chưa phân loại' : v))).toList(),
                onChanged: busy ? null : (v) => setState(() => grade = v ?? '')),
              TextField(controller: location, enabled: !busy, decoration: const InputDecoration(labelText: 'Vị trí lưu kho')),
              const SizedBox(height: 12),
              Text(lot == null ? 'Tạo lô với tồn bằng 0. Staff lập phiếu nhập kho để cập nhật số tồn.'
                : 'Số lượng, khối lượng và trạng thái được giữ nguyên.'),
              if (error != null) Text(error!, style: TextStyle(color: Theme.of(dialog).colorScheme.error)),
            ],
          ))),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(dialog, false), child: const Text('Hủy')),
            FilledButton(onPressed: busy ? null : () async {
              if (frozen == null || expiry == null || !expiry!.isAfter(frozen!) || code.text.trim().isEmpty) {
                setState(() => error = 'Nhập mã lô và ngày hết hạn sau ngày cấp đông.'); return;
              }
              if (service.areaId != area) { setState(() => error = 'Khu nuôi đã thay đổi.'); return; }
              setState(() { busy = true; error = null; });
              try {
                if (lot == null) {
                  await service.createFrozenLot(expectedArea: area, code: code.text, frozenDate: frozen!, expiryDate: expiry!,
                    grade: grade.isEmpty ? null : grade, location: location.text.trim(), voucherId: voucher);
                } else {
                  await service.editFrozenLot(lot, frozenDate: frozen!, expiryDate: expiry!,
                    grade: grade.isEmpty ? null : grade, location: location.text.trim());
                }
                if (dialog.mounted) Navigator.pop(dialog, true);
              } catch (e) {
                if (dialog.mounted) setState(() { busy = false; error = '$e'; });
              }
            }, child: Text(busy ? 'Đang lưu...' : 'Lưu')),
          ],
        ),
      )),
    );
    if (saved == true && context.mounted && service.areaId == area) {
      onChanged(); _message(context, 'Đã lưu thông tin lô.');
    }
  } finally { code.dispose(); location.dispose(); }
}

class FrozenLotCard extends StatefulWidget {
  const FrozenLotCard({super.key, required this.service, required this.lot,
    required this.hasTransactions, required this.onChanged});
  final HarvestSalesService service;
  final Map<String, dynamic> lot;
  final bool hasTransactions;
  final VoidCallback onChanged;
  @override
  State<FrozenLotCard> createState() => _FrozenLotCardState();
}

class _FrozenLotCardState extends State<FrozenLotCard> {
  bool _busy = false;
  Future<void> _details() async {
    final area = widget.service.areaId;
    setState(() => _busy = true);
    try {
      final data = await Future.wait([widget.service.loadFrozenItems(widget.lot),
        widget.service.loadFrozenAdjustments(widget.lot)]);
      if (!mounted || area != widget.service.areaId) return;
      final changed = await showDialog<bool>(context: context, builder: (_) => _LotDetail(
        service: widget.service, lot: widget.lot, items: data[0], adjustments: data[1]));
      if (mounted && changed == true && area == widget.service.areaId) widget.onChanged();
    } catch (e) { if (mounted) _message(context, '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _delete() async {
    final area = widget.service.areaId;
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Xóa lô cấp đông?'),
      content: Text('Xóa lô rỗng ${_text(widget.lot, "lotCode")}. Backend sẽ kiểm tra lại lịch sử kho.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa'))],
    ));
    if (!mounted || accepted != true || area != widget.service.areaId) return;
    setState(() => _busy = true);
    try {
      await widget.service.deleteFrozenLot(widget.lot);
      if (mounted && area == widget.service.areaId) { widget.onChanged(); _message(context, 'Đã xóa lô.'); }
    } catch (e) { if (mounted) _message(context, '$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    final expiry = DateTime.tryParse(_text(lot, 'expiryDate'));
    final today = DateUtils.dateOnly(DateTime.now());
    final days = expiry == null ? null : DateUtils.dateOnly(expiry.toLocal()).difference(today).inDays;
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_text(lot, "lotCode")} · ${_text(lot, "status")}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Tồn: ${_text(lot, "quantity")} cua · ${_text(lot, "weightKg")} kg · Loại: ${_text(lot, "grade")}'),
        Text('Cấp đông: ${_dateField(lot, "frozenDate")} · Hết hạn: ${_dateField(lot, "expiryDate")} · Kho: ${_text(lot, "storageLocation")}'),
        if (days != null && days <= 30) Text(days < 0 ? 'Đã quá hạn ${-days} ngày' : 'Còn $days ngày bảo quản',
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
        Wrap(spacing: 8, children: [
          TextButton.icon(onPressed: _busy ? null : _details, icon: const Icon(Icons.qr_code), label: const Text('Barcode & biến động')),
          TextButton(onPressed: _busy ? null : () => editFrozenLotDialog(context, widget.service, lot: lot, onChanged: widget.onChanged), child: const Text('Sửa')),
          if (!widget.hasTransactions && HarvestSalesService.isEmptyDeletableFrozenLot(lot))
            TextButton(onPressed: _busy ? null : _delete, child: const Text('Xóa lô rỗng')),
        ]),
      ],
    )));
  }
}

class _LotDetail extends StatefulWidget {
  const _LotDetail({required this.service, required this.lot, required this.items, required this.adjustments});
  final HarvestSalesService service;
  final Map<String, dynamic> lot;
  final List<Map<String, dynamic>> items, adjustments;
  @override
  State<_LotDetail> createState() => _LotDetailState();
}

class _LotDetailState extends State<_LotDetail> {
  final Set<String> _available = {};
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;
  bool get _legacy => widget.items.isNotEmpty &&
      widget.items.every((r) => _text(r, 'stockState').toLowerCase() == 'unverified');
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final grams = widget.items.where((r) => _available.contains(_text(r, 'id')))
        .fold<num>(0, (sum, r) => sum + (_number(r, 'weightGram') ?? 0));
    return PopScope(canPop: !_busy, child: AlertDialog(
      title: Text('Truy xuất lô ${_text(widget.lot, "lotCode")}'),
      content: SizedBox(width: 650, height: 470, child: ListView(children: [
        Text('Barcode (${widget.items.length})', style: Theme.of(context).textTheme.titleMedium),
        if (_legacy) const Text('Chỉ tích các barcode thực tế còn trong kho; xác nhận một lần và không thể ghi đè.'),
        if (widget.items.isEmpty) const Text('Chưa có barcode.'),
        for (final row in widget.items) CheckboxListTile(
          value: _legacy ? _available.contains(_text(row, 'id')) : _text(row, 'stockState').toLowerCase() == 'available',
          onChanged: !_legacy || _busy ? null : (v) => setState(() {
            if (v == true) { _available.add(_text(row, 'id')); } else { _available.remove(_text(row, 'id')); }
          }),
          title: Text('${_text(row, "barcodeValue")} · ${_text(row, "crabCode")}'),
          subtitle: Text('${_text(row, "weightGram")} g · ${_text(row, "grade")} · ${_text(row, "stockState")} · Phiếu: ${_text(row, "harvestVoucherCode")}'),
        ),
        if (_legacy) ...[
          Text('Đã chọn: ${_available.length} cua · ${(grams / 1000).toStringAsFixed(3)} kg; tồn yêu cầu: ${_text(widget.lot, "quantity")} cua · ${_text(widget.lot, "weightKg")} kg'),
          TextField(controller: _reason, enabled: !_busy, maxLength: 1000, decoration: const InputDecoration(labelText: 'Lý do đối soát bắt buộc')),
        ],
        const Divider(),
        Text('Nhật ký biến động (${widget.adjustments.length})', style: Theme.of(context).textTheme.titleMedium),
        if (widget.adjustments.isEmpty) const Text('Chưa có biến động.'),
        for (final row in widget.adjustments) ListTile(
          title: Text('${_text(row, "quantityBefore")} → ${_text(row, "quantityAfter")} cua · ${_text(row, "weightBeforeKg")} → ${_text(row, "weightAfterKg")} kg'),
          subtitle: Text('${_text(row, "createdAt")} · ${_text(row, "reason")}'),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ])),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Đóng')),
        if (_legacy) FilledButton(onPressed: _busy ? null : () async {
          setState(() { _busy = true; _error = null; });
          try {
            await widget.service.reconcileFrozenLot(widget.lot, _available.toList(), _reason.text);
            if (mounted) Navigator.pop(context, true);
          } catch (e) { if (mounted) setState(() { _busy = false; _error = '$e'; }); }
        }, child: Text(_busy ? 'Đang xác nhận...' : 'Xác nhận đối soát')),
      ],
    ));
  }
}

class FrozenOpeningBalanceCard extends StatefulWidget {
  const FrozenOpeningBalanceCard({super.key, required this.service, required this.row,
    required this.lotCode, required this.onChanged});
  final HarvestSalesService service;
  final Map<String, dynamic> row;
  final String lotCode;
  final VoidCallback onChanged;
  @override
  State<FrozenOpeningBalanceCard> createState() => _FrozenOpeningBalanceCardState();
}

class _FrozenOpeningBalanceCardState extends State<FrozenOpeningBalanceCard> {
  Future<void> _verify() async {
    final row = widget.row;
    final area = widget.service.areaId;
    final q = TextEditingController(text: _text(row, 'openingQuantity'));
    final w = TextEditingController(text: _text(row, 'openingWeightKg'));
    final reason = TextEditingController();
    String? error;
    bool busy = false;
    try {
      final saved = await showDialog<bool>(context: context, barrierDismissible: false, builder: (ctx) =>
        StatefulBuilder(builder: (ctx, setState) => PopScope(canPop: !busy, child: AlertDialog(
          title: Text('Xác nhận số dư đầu kỳ — ${widget.lotCode}'),
          content: SizedBox(width: 430, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Tồn hiện tại: ${_text(row, "actualCurrentQuantity")} cua · ${_text(row, "actualCurrentWeightKg")} kg'),
            Text('Biến động đã ghi: ${_text(row, "recordedQuantityDelta")} cua · ${_text(row, "recordedWeightDeltaKg")} kg'),
            TextField(controller: q, enabled: !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số lượng đầu kỳ')),
            TextField(controller: w, enabled: !busy, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Khối lượng đầu kỳ (kg)')),
            TextField(controller: reason, enabled: !busy, decoration: const InputDecoration(labelText: 'Lý do và bằng chứng')),
            const Text('Chỉ xác nhận sổ đầu kỳ, không thay đổi tồn kho hiện tại. Không thể sửa sau xác nhận.'),
            if (error != null) Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ])),
          actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: busy ? null : () async {
              final quantity = int.tryParse(q.text.trim()); final weight = num.tryParse(w.text.trim());
              if (quantity == null || weight == null || widget.service.areaId != area) {
                setState(() => error = 'Số dư hoặc khu không hợp lệ.'); return;
              }
              setState(() { busy = true; error = null; });
              try {
                await widget.service.verifyFrozenOpeningBalance(row, quantity, weight, reason.text);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) { if (ctx.mounted) setState(() { busy = false; error = '$e'; }); }
            }, child: Text(busy ? 'Đang xác nhận...' : 'Xác nhận')),
          ],
        ))));
      if (mounted && saved == true && area == widget.service.areaId) widget.onChanged();
    } finally { q.dispose(); w.dispose(); reason.dispose(); }
  }
  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final verified = _text(row, 'verificationStatus').toLowerCase() == 'verified';
    return Card(child: ListTile(
      title: Text('${widget.lotCode} · ${_text(row, "verificationStatus")}'),
      subtitle: Text('Đầu kỳ: ${_text(row, "openingQuantity")} cua · ${_text(row, "openingWeightKg")} kg\n'
        'Dự kiến: ${_text(row, "expectedCurrentQuantity")} cua · ${_text(row, "expectedCurrentWeightKg")} kg; thực tế: ${_text(row, "actualCurrentQuantity")} cua · ${_text(row, "actualCurrentWeightKg")} kg'),
      trailing: verified ? const Icon(Icons.verified) : TextButton(onPressed: _verify, child: const Text('Xác nhận')),
    ));
  }
}
