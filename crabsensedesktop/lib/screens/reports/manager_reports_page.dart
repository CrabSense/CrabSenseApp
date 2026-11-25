import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../services/cloud_api_client.dart';

class ManagerReportsPage extends StatefulWidget {
  const ManagerReportsPage({super.key, required this.session, required this.api});
  final AuthSession session;
  final CloudApiClient api;
  @override
  State<ManagerReportsPage> createState() => _ManagerReportsPageState();
}

class _ManagerReportsPageState extends State<ManagerReportsPage> {
  static const reports = {
    'harvest': 'Tổng quan thu hoạch',
    'harvest/period': 'Sản lượng theo ngày',
    'inventory/filtered': 'Tồn kho đông lạnh',
    'survival-rate': 'Tỷ lệ sống',
    'molting/filtered': 'Tỷ lệ lột xác',
    'operational-efficiency': 'Hiệu quả vận hành',
    'crab-lots/compare': 'So sánh lô cua',
  };
  String _report = 'harvest';
  DateTimeRange? _range;
  late Future<Object?> _result;

  @override
  void initState() {
    super.initState();
    _result = _fetch();
  }
  @override
  void didUpdateWidget(covariant ManagerReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.token != widget.session.token ||
        oldWidget.session.selectedFarm.id != widget.session.selectedFarm.id) {
      _result = _fetch();
    }
  }
  Future<Object?> _fetch() => widget.api.fetchManagerReport(
    widget.session.token, _report, areaId: widget.session.selectedFarm.id,
    from: _range?.start, to: _range?.end.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
  );
  void _reload() => setState(() => _result = _fetch());
  Future<void> _pickRange() async {
    final today = DateTime.now();
    final next = await showDateRangePicker(context: context,
      firstDate: DateTime(2020), lastDate: today, initialDateRange: _range);
    if (next == null || !mounted) return;
    setState(() { _range = next; _result = _fetch(); });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.selectedFarm.isUnassigned) {
      return const Center(child: Text('Chưa được phân công khu nuôi.'));
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Báo cáo vận hành', style: Theme.of(context).textTheme.headlineSmall),
        Text('Khu đang chọn: ${widget.session.selectedFarm.name}'),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          DropdownButton<String>(value: _report,
            items: reports.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) { if (v != null) setState(() { _report = v; _result = _fetch(); }); }),
          if (_report != 'crab-lots/compare') OutlinedButton.icon(
            onPressed: _pickRange, icon: const Icon(Icons.date_range),
            label: Text(_range == null ? 'Khoảng thời gian' : '${_range!.start.toLocal().toString().split(' ').first} – ${_range!.end.toLocal().toString().split(' ').first}')),
          if (_range != null) TextButton(onPressed: () => setState(() { _range = null; _result = _fetch(); }), child: const Text('Bỏ lọc')),
          IconButton(onPressed: _reload, tooltip: 'Tải lại', icon: const Icon(Icons.refresh)),
        ]),
        if (_report == 'inventory/filtered') const Text('Tồn kho: sử dụng ngày kết thúc làm ngày đối chiếu.'),
        const SizedBox(height: 12),
        Expanded(child: FutureBuilder<Object?>(future: _result, builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Không tải được báo cáo: ${snap.error}'), TextButton(onPressed: _reload, child: const Text('Thử lại')),
          ]));
          final data = snap.data;
          if (data == null || (data is List && data.isEmpty) || (data is Map && data.isEmpty)) {
            return const Center(child: Text('Không có dữ liệu phù hợp.'));
          }
          return ListView(children: [_ReportValue(value: data)]);
        })),
      ]),
    );
  }
}

class _ReportValue extends StatelessWidget {
  const _ReportValue({required this.value});
  final Object? value;
  static const labels = {
    'totalCrabs': 'Tổng cua', 'aliveCrabs': 'Cua còn sống', 'deadCrabs': 'Cua chết',
    'harvestedCrabs': 'Cua thu hoạch', 'survivalRate': 'Tỷ lệ sống',
    'missingCrabs': 'Cua thất lạc', 'missingRate': 'Tỷ lệ thất lạc',
    'missingCountAtClose': 'Thất lạc khi đóng lô',
    'moltingRate': 'Tỷ lệ lột xác', 'lotCode': 'Mã lô', 'totalWeight': 'Tổng khối lượng',
    'date': 'Ngày', 'period': 'Kỳ báo cáo',
  };
  @override
  Widget build(BuildContext context) {
    final data = value;
    if (data is List) {
      if (data.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Không có dữ liệu'));
      return Column(children: [for (final row in data) Card(child: Padding(padding: const EdgeInsets.all(12), child: _ReportValue(value: row)))]);
    }
    if (data is Map) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final e in data.entries)
          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: e.value is Map || e.value is List
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(labels[e.key] ?? e.key.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                _ReportValue(value: e.value),
              ])
            : Row(children: [Expanded(child: Text(labels[e.key] ?? e.key.toString())),
                Expanded(child: Text(e.value?.toString() ?? '—', textAlign: TextAlign.end))])),
      ]);
    }
    return Text(data?.toString() ?? '—');
  }
}
