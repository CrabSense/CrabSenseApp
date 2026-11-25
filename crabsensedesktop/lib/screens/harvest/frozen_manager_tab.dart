import 'package:flutter/material.dart';
import '../../services/harvest_sales_service.dart';
import 'frozen_lot_tools.dart';

class FrozenManagerTab extends StatefulWidget {
  const FrozenManagerTab({super.key, required this.service});
  final HarvestSalesService service;
  @override
  State<FrozenManagerTab> createState() => _FrozenManagerTabState();
}

class _FrozenManagerTabState extends State<FrozenManagerTab> {
  late Future<List<List<Map<String, dynamic>>>> _data;
  bool _busy = false;

  Future<List<List<Map<String, dynamic>>>> _fetch() => Future.wait([
    widget.service.loadFrozenLots(),
    widget.service.loadFrozenTransactions(),
    widget.service.loadFrozenOpeningBalances(),
  ]);
  @override
  void initState() { super.initState(); _data = _fetch(); }
  void _reload() => setState(() => _data = _fetch());
  String _value(Map<String, dynamic> row, String key) =>
      (row[key] ?? row[key[0].toUpperCase() + key.substring(1)] ?? '—').toString();

  Future<void> _decide(Map<String, dynamic> row, bool approve) async {
    if (_busy) return;
    final area = widget.service.areaId;
    var reason = '';
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(approve ? 'Duyệt phiếu nhập/xuất kho?' : 'Từ chối phiếu nhập/xuất kho'),
      content: approve ? Text('${_value(row, 'transactionCode')} — chỉ phê duyệt, chưa thay đổi tồn kho.')
        : TextField(onChanged: (v) => reason = v, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Lý do bắt buộc')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () { if (approve || reason.trim().isNotEmpty) Navigator.pop(ctx, true); },
          child: Text(approve ? 'Duyệt' : 'Từ chối')),
      ],
    ));
    if (!mounted || accepted != true || area != widget.service.areaId || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.decideFrozen(row, approve: approve, reason: reason);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve
        ? 'Đã duyệt. Chờ Staff thực hiện trên Mobile.' : 'Đã từ chối phiếu.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.service.canManageFrozen) return const Center(child: Text('Chưa được phân công khu nuôi.'));
    return Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Kho đông lạnh — ${widget.service.areaName}',
            style: Theme.of(context).textTheme.titleLarge)),
          FilledButton.icon(onPressed: _busy ? null : () => editFrozenLotDialog(context, widget.service, onChanged: () { if (mounted) _reload(); }),
            icon: const Icon(Icons.add), label: const Text('Tạo lô')),
          const SizedBox(width: 8),
          IconButton(onPressed: _busy ? null : _reload, icon: const Icon(Icons.refresh), tooltip: 'Tải lại'),
        ]),
        const Text('Farm Manager duyệt yêu cầu. Farm Staff ghi nhận số lượng và khối lượng thực tế.'),
        const SizedBox(height: 12),
        Expanded(child: FutureBuilder<List<List<Map<String, dynamic>>>>(future: _data, builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Không tải được kho: ${snap.error}'),
            TextButton(onPressed: _reload, child: const Text('Thử lại')),
          ]));
          final lots = snap.data?[0] ?? [];
          final transactions = snap.data?[1] ?? [];
          final balances = snap.data?[2] ?? [];
          final lotCodes = {for (final lot in lots) _value(lot, 'id'): _value(lot, 'lotCode')};
          return ListView(children: [
            Text('Lô cấp đông (${lots.length})', style: Theme.of(context).textTheme.titleMedium),
            if (lots.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Chưa có lô cấp đông.')),
            for (final lot in lots) FrozenLotCard(
              key: ValueKey(_value(lot, 'id')),
              service: widget.service, lot: lot,
              hasTransactions: transactions.any((r) => _value(r, 'frozenLotId') == _value(lot, 'id')),
              onChanged: _reload,
            ),
            const SizedBox(height: 20),
            Text('Số dư đầu kỳ (${balances.length})', style: Theme.of(context).textTheme.titleMedium),
            if (balances.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Chưa có số dư đầu kỳ cần rà soát trong khu.')),
            for (final row in balances) FrozenOpeningBalanceCard(
              key: ValueKey(_value(row, 'id')), service: widget.service, row: row,
              lotCode: lotCodes[_value(row, 'frozenLotId')] ?? _value(row, 'frozenLotId'),
              onChanged: _reload,
            ),
            const SizedBox(height: 20),
            Text('Phiếu nhập/xuất (${transactions.length})', style: Theme.of(context).textTheme.titleMedium),
            if (transactions.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Chưa có phiếu nhập/xuất.')),
            for (final row in transactions) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_value(row, 'transactionCode')} · ${_value(row, 'status')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Yêu cầu: ${_value(row, 'requestedQuantity')} cua · ${_value(row, 'requestedWeightKg')} kg'),
                Text('Thực tế: ${_value(row, 'actualQuantity')} cua · ${_value(row, 'actualWeightKg')} kg'),
                if (_value(row, 'rejectionReason') != '—') Text('Lý do từ chối: ${_value(row, 'rejectionReason')}'),
                if (_value(row, 'status').toLowerCase() == 'pendingapproval') Wrap(spacing: 8, children: [
                  FilledButton(onPressed: _busy ? null : () => _decide(row, true), child: const Text('Duyệt')),
                  OutlinedButton(onPressed: _busy ? null : () => _decide(row, false), child: const Text('Từ chối')),
                ]),
              ],
            ))),
          ]);
        })),
      ],
    ));
  }
}
