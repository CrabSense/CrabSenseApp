import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/area_environment_metric.dart';
import '../../services/area_environment_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

/// Cảm biến bể chung khu — read-only, dùng chung cho Quản lý hộp & chi tiết hộp.
class AreaEnvironmentPanel extends StatefulWidget {
  const AreaEnvironmentPanel({
    super.key,
    required this.service,
    required this.areaId,
    this.boxId,
    this.boxCode,
    this.areaName,
    this.areaCode,
    this.showInheritedHint = true,
    this.compact = false,
  });

  final AreaEnvironmentService service;
  final String? areaId;
  final String? boxId;
  final String? boxCode;
  final String? areaName;
  final String? areaCode;
  final bool showInheritedHint;
  final bool compact;

  @override
  State<AreaEnvironmentPanel> createState() => _AreaEnvironmentPanelState();
}

class _AreaEnvironmentPanelState extends State<AreaEnvironmentPanel> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(AreaEnvironmentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId ||
        oldWidget.boxId != widget.boxId) {
      _scheduleLoad();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _load() {
    final boxId = widget.boxId;
    if (boxId != null && boxId.isNotEmpty) {
      widget.service.startLiveRefreshByBox(boxId);
      return;
    }
    final id = widget.areaId;
    if (id == null || id.isEmpty) {
      widget.service.clear();
      return;
    }
    widget.service.startLiveRefresh(id);
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasBox = widget.boxId != null && widget.boxId!.isNotEmpty;
    if (!hasBox && (widget.areaId == null || widget.areaId!.isEmpty)) {
      return _message(
        Icons.map_outlined,
        'Chọn khu hoặc hộp để xem cảm biến bể chung',
      );
    }

    final svc = widget.service;
    if (svc.loading) {
      return const Center(child: CircularProgressIndicator(color: DashboardColors.cyan));
    }

    if (svc.error != null && svc.metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off, size: 48, color: DashboardColors.textMuted),
            const SizedBox(height: 12),
            Text(
              svc.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final data = svc.data;
    final metrics = svc.metrics;
    final title = widget.areaName ?? data?.areaName ?? 'Khu';
    final code = widget.areaCode ?? data?.areaCode ?? '';
    final boxLabel = widget.boxCode ?? data?.boxCode;
    final inherited = data?.isBoxInherited ?? (hasBox && widget.showInheritedHint);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.showInheritedHint && inherited)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardColors.cyan.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: DashboardColors.cyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    boxLabel != null && boxLabel.isNotEmpty
                        ? 'Hộp $boxLabel kế thừa chỉ số bể chung khu $title'
                            '${code.isNotEmpty ? ' ($code)' : ''} — chỉ xem, không đo riêng từng hộp.'
                        : 'Dữ liệu chung bể khu $title${code.isNotEmpty ? ' ($code)' : ''} — '
                            'các hộp trên dãy dùng chung (chỉ xem).',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Text(
              'Cảm biến khu',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (data?.lastUpdatedAt != null)
              Text(
                _formatTime(data!.lastUpdatedAt!),
                style: GoogleFonts.robotoMono(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
            IconButton(
              onPressed: _load,
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (metrics.isEmpty)
          _message(Icons.sensors, 'Chưa có chỉ số — sync ESP32 khu (areaCode, không boxCode)')
        else
          Wrap(
            spacing: widget.compact ? 10 : 16,
            runSpacing: widget.compact ? 10 : 16,
            children: metrics.map((m) => _metricCard(m, widget.compact)).toList(),
          ),
      ],
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: DashboardColors.textMuted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(AreaEnvironmentMetric m, bool compact) {
    final color = _statusColor(m.status);
    return GlassCard(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: SizedBox(
        width: compact ? 150 : 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_metricIcon(m.icon), size: compact ? 18 : 24, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.label,
                    style: GoogleFonts.notoSans(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${m.value}${m.unit.isNotEmpty ? ' ${m.unit}' : ''}',
              style: GoogleFonts.robotoMono(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.day}/${local.month}/${local.year}';
  }

  static Color _statusColor(String status) => switch (status) {
        'warning' => DashboardColors.monitoring,
        'critical' => DashboardColors.risk,
        _ => DashboardColors.seaGreen,
      };

  static IconData _metricIcon(String key) => switch (key) {
        'ph' => Icons.water,
        'temp' => Icons.thermostat,
        'do' => Icons.bubble_chart_outlined,
        'sal' => Icons.waves,
        'nh3' || 'no2' => Icons.science_outlined,
        'orp' => Icons.electric_bolt,
        'level' => Icons.vertical_align_top,
        'flow' => Icons.speed,
        'tds' => Icons.grain,
        _ => Icons.sensors_outlined,
      };
}
