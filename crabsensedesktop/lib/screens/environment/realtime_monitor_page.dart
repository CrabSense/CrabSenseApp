import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_alert.dart';
import '../../models/water_quality.dart';
import '../../services/alert_service.dart';
import '../../services/water_quality_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/environment/realtime_monitor_widgets.dart';

/// Giám sát thời gian thực — chỉ số cảm biến liên tục, không phân tích AI.
class RealtimeMonitorPage extends StatefulWidget {
  const RealtimeMonitorPage({
    super.key,
    required this.service,
    required this.alertService,
  });

  final WaterQualityService service;
  final AlertService alertService;

  @override
  State<RealtimeMonitorPage> createState() => _RealtimeMonitorPageState();
}

class _RealtimeMonitorPageState extends State<RealtimeMonitorPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.alertService.addListener(_onUpdate);
    widget.service.startLiveUpdates();
    widget.alertService.load();
  }

  @override
  void dispose() {
    widget.service.stopLiveUpdates();
    widget.service.removeListener(_onUpdate);
    widget.alertService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final locations = svc.locationGroups;
    final alerts = _mergedAlerts(svc);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RealtimeStatusHeader(
            live: svc.isLive,
            systemOnline: svc.cloudLive,
            deviceOnline: svc.deviceOnline,
            deviceLabel: svc.deviceCode ?? 'ESP32',
            lastUpdateLabel: svc.lastUpdateLabel,
            lastUpdateClock: svc.lastUpdateClock,
            error: svc.cloudError,
            loading: svc.isLoading && svc.readings.isEmpty,
            onRefresh: () => svc.refresh(full: true),
          ),
          if (svc.isLoading && svc.readings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 20),
          RealtimeMetricGrid(readings: svc.readings),
          const SizedBox(height: 20),
          RealtimeTrendCard(
            metric: svc.chartMetric,
            metrics: svc.availableMetrics,
            points: svc.chartSeries,
            rangeIndex: svc.chartRangeIndex,
            rangeMinutes: svc.chartRangeMinutesValue,
            loading: svc.chartLoading,
            live: svc.isLive,
            onMetricChanged: svc.setChartMetric,
            onRangeChanged: svc.setChartRangeIndex,
          ),
          if (locations.isNotEmpty) ...[
            const SizedBox(height: 20),
            RealtimeLocationSection(groups: locations),
          ],
          const SizedBox(height: 20),
          RealtimeAlertSection(alerts: alerts),
        ],
      ),
    );
  }

  List<RealtimeWaterAlert> _mergedAlerts(WaterQualityService svc) {
    final fromSensors = svc.thresholdAlerts;
    final fromFarm = widget.alertService.filteredAlerts
        .where((a) => a.isOpen)
        .take(6)
        .map(
          (a) => RealtimeWaterAlert(
            title: a.title,
            detail: a.currentValue == '—'
                ? (a.location.isEmpty ? a.device : a.location)
                : 'Hiện tại: ${a.currentValue}',
            status: switch (a.level) {
              AlertLevel.critical => WaterSensorStatus.danger,
              AlertLevel.warning => WaterSensorStatus.exceeded,
              AlertLevel.info => WaterSensorStatus.monitoring,
            },
          ),
        )
        .toList();
    final seen = <String>{};
    final out = <RealtimeWaterAlert>[];
    for (final a in [...fromSensors, ...fromFarm]) {
      if (seen.add(a.title)) out.add(a);
    }
    return out;
  }
}

class RealtimeStatusHeader extends StatelessWidget {
  const RealtimeStatusHeader({
    super.key,
    required this.live,
    required this.systemOnline,
    required this.deviceOnline,
    required this.deviceLabel,
    required this.lastUpdateLabel,
    required this.lastUpdateClock,
    required this.loading,
    this.error,
    this.onRefresh,
  });

  final bool live;
  final bool systemOnline;
  final bool deviceOnline;
  final String deviceLabel;
  final String lastUpdateLabel;
  final String lastUpdateClock;
  final bool loading;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ssid_chart, color: DashboardColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Giám sát thời gian thực',
                  style: GoogleFonts.notoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const SizedBox(width: 8),
              _LivePill(live: live),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            live
                ? 'LIVE • $deviceLabel Online • Cập nhật $lastUpdateClock'
                : 'Dữ liệu cảm biến liên tục từ ESP32 — không phân tích AI',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatusChip(
                color: systemOnline
                    ? DashboardColors.healthy
                    : DashboardColors.risk,
                label: systemOnline ? 'Hệ thống Online' : 'Hệ thống mất kết nối',
              ),
              _StatusChip(
                color: deviceOnline
                    ? DashboardColors.healthy
                    : DashboardColors.textMuted,
                label: deviceOnline
                    ? '$deviceLabel kết nối'
                    : '$deviceLabel chưa gửi dữ liệu',
              ),
              _StatusChip(
                color: live
                    ? DashboardColors.healthy
                    : DashboardColors.monitoring,
                label: 'Cập nhật lần cuối: $lastUpdateLabel',
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: GoogleFonts.notoSans(
                color: DashboardColors.risk,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? DashboardColors.healthy : DashboardColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            live ? 'LIVE' : 'OFFLINE',
            style: GoogleFonts.notoSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
