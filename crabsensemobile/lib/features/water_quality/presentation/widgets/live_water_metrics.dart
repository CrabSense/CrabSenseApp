import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/water_quality.dart';

/// Display freshness, not the Backend's sensor disconnect timeout.
const liveMetricMaxAge = Duration(minutes: 5);

List<WaterQuality> scopedLiveMetrics(String area, String? row,
    List<WaterQuality> readings, DateTime now) {
  if (area.isEmpty || area == 'default') return [];
  final selected = readings.where((r) => r.farmId == area &&
      (row == null || r.pondId == row) && r.sensorId.isNotEmpty &&
      r.liveMetric != null && r.liveMetric!.value.isFinite &&
      !r.timestamp.isAfter(now.add(const Duration(seconds: 1))) &&
      !r.liveMetric!.receivedAt.isAfter(now.add(const Duration(seconds: 1))) &&
      !r.liveMetric!.receivedAt.isBefore(r.timestamp)).toList();
  final counts = <String,int>{};
  for (final r in selected) {
    counts[r.sensorId] = (counts[r.sensorId] ?? 0) + 1;
  }
  return selected.where((r) => counts[r.sensorId] == 1).toList()
    ..sort((a,b) {
      final byKind = a.liveMetric!.kind.index.compareTo(b.liveMetric!.kind.index);
      return byKind == 0 ? a.sensorId.compareTo(b.sensorId) : byKind;
    });
}

String liveMetricAssessment(WaterQuality reading, DateTime now) {
  final m = reading.liveMetric!;
  if (now.difference(reading.timestamp) > liveMetricMaxAge ||
      now.difference(m.receivedAt) > liveMetricMaxAge) return 'Dữ liệu cũ';
  if (m.status != 'Online') return 'Chưa xác minh hiện trạng';
  if (m.alarm != null || m.outsideThreshold) return 'Cảnh báo từ cấu hình';
  if (!m.hasConfiguredThreshold) return 'Chưa có ngưỡng cấu hình';
  return 'Trong giới hạn đã cấu hình';
}

String _number(double n) => n == 0 ? '0' : n.toString();

String liveMetricRange(LiveWaterMetric m) {
  if (m.min != null && m.max != null) {
    return '${_number(m.min!)} – ${_number(m.max!)} ${m.unit}';
  }
  if (m.min != null) return '≥ ${_number(m.min!)} ${m.unit}';
  if (m.max != null) return '≤ ${_number(m.max!)} ${m.unit}';
  return 'Chưa cấu hình';
}

class LiveWaterMetrics extends StatelessWidget {
  const LiveWaterMetrics({super.key, required this.areaId, required this.rowId,
    required this.readings, required this.online, required this.now});
  final String areaId;
  final String? rowId;
  final List<WaterQuality> readings;
  final bool online;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final items = online ? scopedLiveMetrics(areaId,rowId,readings,now) : <WaterQuality>[];
    final missing = LiveWaterKind.values.where((k) =>
        !items.any((r) => r.liveMetric!.kind == k)).map((k) => k.label).join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: homeCardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chỉ số từng cảm biến', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: kHomeTextMain)),
          const SizedBox(height: 6),
          const Text('Dữ liệu đại diện vòng nước RAS dùng chung cho các dãy và hộp trong khu; không đo riêng từng hộp.',
            style: TextStyle(color: kHomeTextSub)),
          const SizedBox(height: 6),
          const Text('Ngưỡng lấy từ cấu hình cảm biến tại Backend, không phải kết luận nước an toàn.',
            style: TextStyle(color: kHomeTextSub)),
          const SizedBox(height: 10),
          if (!online)
            const Text('Chưa xác minh dữ liệu online mới. Không hiển thị giá trị cũ.')
          else if (areaId.isEmpty || areaId == 'default')
            const Text('Chọn khu cụ thể để xem chỉ số.')
          else ...[
            if (items.isEmpty) const Text('Chưa có phép đo đủ điều kiện hiển thị.'),
            for (final r in items) ...[
              _SensorMetricTile(reading: r, now: now),
              const Divider(height: 18),
            ],
            if (missing.isNotEmpty)
              Text('Chưa có phép đo hợp lệ: $missing',
                style: const TextStyle(color: kHomeTextSub)),
          ],
          const SizedBox(height: 8),
          const Text('NH₃/NH₄, NO₂ và NO₃: xem kết quả xét nghiệm tại Phân tích nước. Không gộp với cảm biến.',
            style: TextStyle(color: kHomeTextSub)),
        ],
      ),
    );
  }
}

class _SensorMetricTile extends StatelessWidget {
  const _SensorMetricTile({required this.reading, required this.now});
  final WaterQuality reading;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final m = reading.liveMetric!;
    final assessment = liveMetricAssessment(reading, now);
    final status = switch (m.status) {
      'Online' => 'Trực tuyến', 'Offline' => 'Ngoại tuyến',
      'Error' => 'Lỗi đọc', 'Disabled' => 'Đã tắt', _ => 'Chưa xác minh',
    };
    final stamp = DateFormat('dd/MM/yyyy HH:mm:ss');
    final color = assessment == 'Cảnh báo từ cấu hình' ? kHomeDanger :
        assessment == 'Trong giới hạn đã cấu hình' ? kHomePrimaryDark : kHomeWarning;
    return Column(
      key: ValueKey('live-sensor-${reading.sensorId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${m.kind.label} · ${m.sensorCode}',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('${_number(m.value)} ${m.unit}', style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: kHomeTextMain)),
        Text('Đo: ${stamp.format(reading.timestamp.toLocal())}'),
        Text('Nhận: ${stamp.format(m.receivedAt.toLocal())}'),
        Text('Cảm biến: $status'),
        Text('Ngưỡng: ${liveMetricRange(m)}'),
        Text(assessment, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
