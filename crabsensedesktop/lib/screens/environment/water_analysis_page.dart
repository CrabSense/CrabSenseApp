import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_analysis.dart';
import '../../services/water_analysis_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';

/// Phân tích hóa học (thuốc thử + camera + AI) — không phải sensor realtime.
class WaterAnalysisPage extends StatefulWidget {
  const WaterAnalysisPage({
    super.key,
    required this.service,
    this.areaName,
  });

  final WaterAnalysisService service;
  final String? areaName;

  @override
  State<WaterAnalysisPage> createState() => _WaterAnalysisPageState();
}

class _WaterAnalysisPageState extends State<WaterAnalysisPage> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    widget.service.load();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final snap = svc.snapshot;
    final latest = snap?.latest;
    final active = snap?.active;
    final station = snap?.station ?? const <WaterAnalysisStationPart>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: DashboardColors.cyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích nước',
                        style: GoogleFonts.notoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kiểm tra hóa học pH · NH3 · NO2 · NO3 — thuốc thử + camera + AI. '
                        'Không lấy số từ sensor realtime.',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: svc.load,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
          if (svc.loading && snap == null) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (svc.error != null) ...[
            const SizedBox(height: 12),
            Text(
              svc.error!,
              style: GoogleFonts.notoSans(color: DashboardColors.risk),
            ),
          ],
          const SizedBox(height: 20),
          _LatestCard(run: latest),
          const SizedBox(height: 16),
          _StationCard(parts: station),
          const SizedBox(height: 16),
          _StartCard(
            running: svc.isRunning,
            starting: svc.starting,
            active: active,
            onStart: () async {
              final ok = await svc.start();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(svc.error ?? 'Không bắt đầu được')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({this.run});

  final WaterAnalysisRun? run;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_outlined, color: DashboardColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'KẾT QUẢ PHÂN TÍCH MỚI NHẤT',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (run == null)
            Text(
              'Chưa có lần phân tích nào trên khu này.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          else ...[
            for (final m in run!.metrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        m.label,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        m.displayValue,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (m.unit.isNotEmpty)
                      SizedBox(
                        width: 48,
                        child: Text(
                          m.unit,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    _StatusDot(status: m.status, label: m.statusLabel),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Phân tích lúc: ${_clock(run!.completedAt ?? run!.startedAt)}',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _clock(DateTime at) {
    final l = at.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.parts});

  final List<WaterAnalysisStationPart> parts;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_outlined,
                  color: DashboardColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'HỆ THỐNG PHÂN TÍCH',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (parts.isEmpty)
            Text(
              'Đang tải trạng thái trạm…',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          else
            for (final p in parts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(_icon(p.code), size: 18, color: DashboardColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.label,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _StatusDot(
                      status: p.ready ? 'good' : 'alert',
                      label: p.stateLabel,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static IconData _icon(String code) => switch (code) {
        'reagent' => Icons.science_outlined,
        'samplePump' => Icons.water_drop_outlined,
        'camera' => Icons.photo_camera_outlined,
        'ai' => Icons.auto_awesome_outlined,
        _ => Icons.sensors,
      };
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.running,
    required this.starting,
    required this.onStart,
    this.active,
  });

  final bool running;
  final bool starting;
  final VoidCallback onStart;
  final WaterAnalysisRun? active;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: running || starting ? null : onStart,
            icon: starting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science),
            label: Text(
              running
                  ? 'Đang phân tích… bước ${active?.currentStep ?? 1}/6'
                  : 'Bắt đầu phân tích nước',
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < WaterAnalysisSteps.labels.length; i++)
            _StepRow(
              index: i + 1,
              label: WaterAnalysisSteps.labels[i],
              active: running && (active?.currentStep ?? 0) == i + 1,
              done: running
                  ? (active?.currentStep ?? 0) > i + 1
                  : false,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? DashboardColors.healthy
        : active
            ? DashboardColors.cyan
            : DashboardColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Text(
              '$index',
              style: GoogleFonts.notoSans(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSans(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (active)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else if (done)
            Icon(Icons.check, size: 16, color: color),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'good' => DashboardColors.healthy,
      'watch' => DashboardColors.monitoring,
      'alert' => DashboardColors.risk,
      _ => DashboardColors.textMuted,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
