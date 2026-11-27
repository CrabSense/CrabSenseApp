import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../models/water_bench_monitor.dart';
import '../../services/water_bench_monitor_service.dart';
import '../../theme/dashboard_theme.dart';

class WaterBenchMonitorPage extends StatefulWidget {
  const WaterBenchMonitorPage({super.key, required this.session, this.service});
  final AuthSession session;
  final WaterBenchMonitorService? service;
  @override
  State<WaterBenchMonitorPage> createState() => _WaterBenchMonitorPageState();
}

class _WaterBenchMonitorPageState extends State<WaterBenchMonitorPage> {
  late final WaterBenchMonitorService _service;
  BenchOverview? _overview;
  BenchDetail? _detail;
  BenchBatch? _selected;
  String? _error;
  bool _busy = false;
  int _generation = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? WaterBenchMonitorService();
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_busy && _error == null) unawaited(_refresh());
    });
  }

  @override
  void didUpdateWidget(covariant WaterBenchMonitorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.session, next = widget.session;
    if (old.user.id != next.user.id || old.user.role != next.user.role ||
        old.token != next.token || old.selectedFarm.id != next.selectedFarm.id ||
        !next.farms.any((f) => f.id == next.selectedFarm.id)) {
      _overview = null;
      _selected = null;
      _detail = null;
      unawaited(_refresh());
    }
  }

  bool _current(int generation) => mounted && generation == _generation;

  Future<void> _refresh() async {
    final generation = ++_generation;
    final session = widget.session;
    final oldKey = _selected?.key;
    setState(() { _busy = true; _error = null; _detail = null; });
    try {
      final overview = await _service.overview(session);
      if (!_current(generation)) return;
      BenchBatch? selected;
      for (final batch in overview.batches) {
        if (batch.key == oldKey) selected = batch;
      }
      selected ??= overview.batches.isEmpty ? null : overview.batches.first;
      setState(() { _overview = overview; _selected = selected; });
      final detail = selected == null ? null : await _service.detail(session, selected!);
      if (_current(generation)) setState(() { _detail = detail; });
    } catch (e) {
      if (_current(generation)) setState(() {
        _overview = null; _selected = null; _detail = null; _error = '$e';
      });
    } finally {
      if (_current(generation)) setState(() { _busy = false; });
    }
  }

  Future<void> _select(BenchBatch batch) async {
    final generation = ++_generation;
    final session = widget.session;
    setState(() { _selected = batch; _detail = null; _busy = true; _error = null; });
    try {
      final detail = await _service.detail(session, batch);
      if (_current(generation)) setState(() { _detail = detail; });
    } catch (e) {
      if (_current(generation)) setState(() { _detail = null; _error = '$e'; });
    } finally {
      if (_current(generation)) setState(() { _busy = false; });
    }
  }

  @override
  void dispose() {
    ++_generation;
    _timer?.cancel();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  String _label(Object? status) => switch (status) {
    'running_observed' => 'Đã quan sát đang chạy',
    'firmware_complete_reported' => 'Firmware báo hoàn tất',
    'fault_reported' => 'Firmware báo lỗi',
    'interrupted_observed' => 'Gián đoạn',
    'waiting' => 'Đang chờ',
    'preparing_observed' => 'Đã quan sát chuẩn bị',
    'reacting_observed' => 'Đã quan sát phản ứng',
    'capture_requested' => 'Đã yêu cầu chụp',
    'drained_reported' => 'Đã báo xả',
    'awaiting_firmware_completion' => 'Chờ hoàn tất firmware',
    'awaiting_media' => 'Chờ ảnh',
    'awaiting_assessment' => 'Chờ đánh giá',
    'operator_confirmation_required' => 'Chờ Admin xác nhận điều kiện',
    'already_assessed' => 'Đã đánh giá',
    'estimate_review_required' => 'Ước tính – chờ duyệt',
    'needs_retest' || 'retest_recommended' => 'Cần đo lại',
    'not_attempted' => 'Chưa phân tích',
    'inference_running' => 'AI đang xử lý',
    'retry_available' => 'Có thể retry (Farm Admin)',
    'retry_backoff' => 'Chờ thời gian retry',
    'retry_exhausted' => 'Hết lượt retry',
    'technical_review_required' => 'Cần kiểm tra kỹ thuật',
    'pending_review' => 'Chờ xét duyệt',
    'approved' => 'Đã duyệt, chưa công bố',
    'rejected' => 'Đã từ chối',
    'published' => 'Đã công bố hồ sơ',
    'missing_session' => 'Thiếu phiên',
    'incomplete_evidence' => 'Thiếu bằng chứng',
    _ => status?.toString() ?? 'Chưa có dữ liệu',
  };
  String _value(Object? value) => value?.toString() ?? '—';
  String _time(Object? raw) => DateTime.tryParse(raw?.toString() ?? '')?.toLocal().toString().split('.').first ?? '—';
  Widget _panel(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: DashboardColors.card,
      borderRadius: BorderRadius.circular(12), border: Border.all(color: DashboardColors.cardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
      const SizedBox(height: 12), ...children,
    ]),
  );
  Widget _line(String name, Object? value) => Padding(
    padding: const EdgeInsets.only(bottom: 6), child: Text('$name: ${_value(value)}',
      style: TextStyle(color: DashboardColors.textPrimary)),
  );
  Widget _note(String text) => Text(text, style: TextStyle(color: DashboardColors.textMuted));

  Widget _channel(BenchChannel channel, bool stale) {
    final estimate = channel.estimate, published = channel.publishedReference;
    return _panel(channel.analyte, [
      if (channel.observation == null) _note('Không nằm trong phiên hoặc chưa có bằng chứng.'),
      _line('Quan sát firmware', stale ? 'Quan sát cũ — ${_label(channel.observation?['status'])}' : _label(channel.observation?['status'])),
      _line('Thời gian phản ứng (ms)', channel.observation?['reactionDurationMs']),
      _line('Capture ID', channel.observation?['captureId']),
      _line('Trạng thái kết quả', _label(channel.result?['status'])),
      _line('Ước tính AI', estimate == null ? '—' : '$estimate ${channel.unit}'),
      _note('Ước tính không phải kết quả hóa học chính thức.'),
      _line('Điều kiện AI', _label(channel.readiness?['status'])),
      _line('Retry', _label(channel.retry?['status'])),
      _line('Lượt thử', '${_value(channel.retry?['attempts'])}/${_value(channel.retry?['maxAttempts'])}'),
      _line('Xét duyệt', channel.reviewUnavailable ? 'Không đọc được trạng thái' : _label(channel.review?['status'])),
      if (published != null) ...[
        const Divider(),
        _line('Đối chứng đã công bố', '$published ${channel.publication['unit']}'),
        _line('Thời điểm công bố', _time(channel.publication['publishedAt'])),
        _note('Hồ sơ WaterBench do người có thẩm quyền xác nhận, không phải dữ liệu cảm biến.'),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview, detail = _detail, station = overview?.station;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12, runSpacing: 8, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Giám sát phân tích nước', style: Theme.of(context).textTheme.headlineSmall),
            _note(widget.session.selectedFarm.toString()),
            _note('WaterBench · Farm Manager · chỉ đọc'),
          ]),
          OutlinedButton.icon(key: const Key('bench-refresh'), onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh), label: const Text('Tải lại')),
        ]),
        const SizedBox(height: 12),
        _note('Hiệu chuẩn, retry AI, xét duyệt và công bố thực hiện trên Farm Admin Web. Không phát lệnh hóa chất từ màn hình này.'),
        if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator()),
        if (_error != null) _panel('Không tải được dữ liệu', [Text(_error!, style: const TextStyle(color: DashboardColors.danger))]),
        if (overview != null) ...[
          const SizedBox(height: 16),
          _panel('Trạm và lịch định kỳ', [
            if (station == null) const Text('Chưa đăng ký trạm WaterBench.')
            else ...[
              _line('Phiên bản cấu hình', station['configurationVersion']),
              _line('Lịch', station['enabled'] == true ? 'Có hiệu lực' : 'Chưa có hiệu lực'),
              _line('Hiệu chuẩn', station['profilesReady'] == true ? 'Sẵn sàng' : 'Chưa sẵn sàng'),
              _line('Giờ chạy', station['times'] is List ? (station['times'] as List).join(', ') : null),
              _line('Múi giờ', station['timezone']),
              _line('Nguồn mẫu', station['sampleSource']),
              _note('Lịch cấu hình không xác nhận thiết bị đã thực thi.'),
            ],
          ]),
          const SizedBox(height: 16),
          _panel('Lịch sử phiên (tối đa 50)', [
            if (overview.batches.isEmpty) const Text('Chưa có phiên phân tích.')
            else DropdownButtonFormField<String>(
              key: ValueKey(_selected?.key), value: _selected?.key,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Phiên phân tích'),
              items: overview.batches.map((b) => DropdownMenuItem(value: b.key,
                child: Text('${b.batchId} · ${b.mode == "scheduled" ? "Định kỳ" : b.mode == "manual" ? "Thủ công" : "—"} · ${_time(b.createdAt)}',
                  overflow: TextOverflow.ellipsis))).toList(),
              onChanged: _busy ? null : (key) {
                if (key != null) unawaited(_select(overview.batches.firstWhere((b) => b.key == key)));
              },
            ),
          ]),
          if (detail != null) ...[
            const SizedBox(height: 16),
            _panel('Bằng chứng phiên', [
              _line('Trạng thái quan sát', _label(detail.timeline['status'])),
              _line('Quan sát cuối', _time(detail.timeline['lastObservedAt'])),
              if (detail.stale) const Text('Quan sát đã cũ hoặc không rõ — không suy ra trạng thái phần cứng hiện tại.',
                style: TextStyle(color: DashboardColors.warning)),
              _line('Biên nhận', detail.receipts['total']),
              _line('Ảnh đã ghi nhận', detail.receipts['mediaCount']),
              _line('Bằng chứng NH3', detail.receipts['nh3Count']),
              _note('Không xác nhận hoàn tất vật lý, độ sạch hoặc độ chính xác hóa học.'),
            ]),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final count = constraints.maxWidth >= 1050 ? 3 : constraints.maxWidth >= 680 ? 2 : 1;
              final width = (constraints.maxWidth - 12 * (count - 1)) / count;
              return Wrap(spacing: 12, runSpacing: 12, children: detail.channels
                .map((channel) => SizedBox(width: width, child: _channel(channel, detail.stale))).toList());
            }),
          ],
        ],
      ]),
    );
  }
}
