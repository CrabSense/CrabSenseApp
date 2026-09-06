import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_activity_log.dart';
import '../../models/farm_alert.dart';
import '../../models/farm_layout.dart';
import '../../models/ras_flow.dart';
import '../../models/water_analysis.dart';
import '../../models/water_quality.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/ai_assistant_avatar.dart';
import 'glass_card.dart';

class OwnerWelcome extends StatelessWidget {
  const OwnerWelcome({
    super.key,
    required this.userName,
    required this.stable,
    required this.statusMessage,
  });

  final String userName;
  final bool stable;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    final first = userName.trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chào $first',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: stable ? DashboardColors.healthy : DashboardColors.risk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusMessage,
                style: GoogleFonts.notoSans(
                  color: stable ? DashboardColors.healthy : DashboardColors.risk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OwnerKpiStrip extends StatelessWidget {
  const OwnerKpiStrip({super.key, required this.items});

  final List<(String, String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1100
            ? items.length
            : c.maxWidth > 700
                ? 3
                : 2;
        final gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: w,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        style: GoogleFonts.notoSans(
                          color: item.$3,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class OwnerAttentionCard extends StatelessWidget {
  const OwnerAttentionCard({
    super.key,
    required this.items,
    required this.onViewAll,
  });

  final List<(Color, String)> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: items.isEmpty
          ? DashboardColors.healthy.withValues(alpha: 0.35)
          : DashboardColors.risk.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                items.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: items.isEmpty
                    ? DashboardColors.healthy
                    : DashboardColors.risk,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'CẦN XỬ LÝ NGAY',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'Không có việc cần xử lý ngay.',
              style: GoogleFonts.notoSans(color: DashboardColors.healthy),
            )
          else
            for (final item in items.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: item.$1),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAll,
              child: const Text('Xem tất cả cảnh báo →'),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerWaterCard extends StatelessWidget {
  const OwnerWaterCard({
    super.key,
    required this.readings,
    required this.onOpenRealtime,
  });

  final List<WaterSensorReading> readings;
  final VoidCallback onOpenRealtime;

  WaterSensorReading? _of(WaterSensorType t) {
    for (final r in readings) {
      if (r.type == t) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final picks = [
      _of(WaterSensorType.temperature),
      _of(WaterSensorType.salinity),
      _of(WaterSensorType.tds),
    ].whereType<WaterSensorReading>().toList();
    final safe = picks.isNotEmpty &&
        picks.every(
          (r) =>
              r.status == WaterSensorStatus.normal ||
              r.status == WaterSensorStatus.good,
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GIÁM SÁT NƯỚC',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 14),
          if (picks.isEmpty)
            Text(
              'Chưa có cảm biến realtime trên khu này.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          else
            Row(
              children: [
                for (final r in picks)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(r.type.icon, color: r.type.accent, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          r.displayValue,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          r.type.label,
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: safe ? DashboardColors.healthy : DashboardColors.monitoring,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  picks.isEmpty
                      ? 'Chưa có dữ liệu ngưỡng'
                      : safe
                          ? 'Tất cả trong ngưỡng an toàn'
                          : 'Có chỉ số cần theo dõi',
                  style: GoogleFonts.notoSans(
                    color: safe
                        ? DashboardColors.healthy
                        : DashboardColors.monitoring,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenRealtime,
              child: const Text('Xem giám sát Realtime →'),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerAnalysisCard extends StatelessWidget {
  const OwnerAnalysisCard({
    super.key,
    required this.run,
    required this.onOpen,
  });

  final WaterAnalysisRun? run;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PHÂN TÍCH GẦN NHẤT',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          if (run == null)
            Text(
              'Chưa có lần phân tích hóa học.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          else ...[
            for (final m in run!.metrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        m.label,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        m.displayValue,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.circle, size: 8, color: _metricColor(m.status)),
                  ],
                ),
              ),
            Text(
              _when(run!.completedAt ?? run!.startedAt),
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Phân tích nước →'),
            ),
          ),
        ],
      ),
    );
  }

  static Color _metricColor(String status) => switch (status) {
        'good' => DashboardColors.healthy,
        'watch' => DashboardColors.monitoring,
        'alert' => DashboardColors.risk,
        _ => DashboardColors.textMuted,
      };

  static String _when(DateTime at) {
    final l = at.toLocal();
    final now = DateTime.now();
    final day = l.year == now.year && l.month == now.month && l.day == now.day
        ? 'Hôm nay'
        : '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}';
    final t =
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return '$t · $day';
  }
}

class OwnerRasCard extends StatelessWidget {
  const OwnerRasCard({
    super.key,
    required this.nodes,
    required this.onOpen,
  });

  final List<RasFlowNodeLive> nodes;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final shown = nodes.take(4).toList();
    final ok = nodes.isNotEmpty &&
        nodes.every((n) => n.isOnline != false && (n.hasRelay ? n.isOn != false : true));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HỆ THỐNG RAS',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: ok ? DashboardColors.healthy : DashboardColors.monitoring,
              ),
              const SizedBox(width: 6),
              Text(
                nodes.isEmpty
                    ? 'Chưa có sơ đồ RAS'
                    : ok
                        ? 'Hoạt động bình thường'
                        : 'Có thiết bị cần kiểm tra',
                style: GoogleFonts.notoSans(
                  color: ok ? DashboardColors.healthy : DashboardColors.monitoring,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final n in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      n.displayLabel,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: (n.isOnline == false)
                        ? DashboardColors.risk
                        : (n.hasRelay && n.isOn == false)
                            ? DashboardColors.textMuted
                            : DashboardColors.healthy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    n.isOnline == false
                        ? 'Offline'
                        : n.hasRelay
                            ? (n.isOn == true ? 'Bật' : 'Tắt')
                            : 'Online',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Điều khiển RAS →'),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerCrabStatusCard extends StatelessWidget {
  const OwnerCrabStatusCard({super.key, required this.summary});

  final FarmLayoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final segs = [
      (summary.normal, 'Bình thường', DashboardColors.healthy),
      (summary.watch, 'Theo dõi', DashboardColors.monitoring),
      (summary.molting, 'Lột xác', const Color(0xFFA78BFA)),
      (summary.alert, 'Cảnh báo', DashboardColors.risk),
      (summary.deceased, 'Sự cố', DashboardColors.dead),
    ];
    final total = segs.fold<int>(0, (n, s) => n + s.$1);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TÌNH TRẠNG CUA / HỘP',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: total == 0
                    ? Center(
                        child: Text(
                          '—',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 24,
                          ),
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 38,
                          sections: [
                            for (final s in segs)
                              if (s.$1 > 0)
                                PieChartSectionData(
                                  value: s.$1.toDouble(),
                                  color: s.$3,
                                  radius: 28,
                                  showTitle: false,
                                ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final s in segs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: s.$3),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.$2,
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '${s.$1}',
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OwnerAssistantCard extends StatelessWidget {
  const OwnerAssistantCard({
    super.key,
    required this.lines,
    required this.onOpen,
  });

  final List<String> lines;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: DashboardColors.purple.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AiAssistantAvatar(size: 40),
              const SizedBox(width: 10),
              Text(
                'TRỢ LÝ CUA',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Xem chi tiết →'),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerActivityCard extends StatelessWidget {
  const OwnerActivityCard({super.key, required this.entries});

  final List<FarmActivityLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOẠT ĐỘNG GẦN ĐÂY',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'Chưa có hoạt động gần đây.',
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            )
          else
            for (final e in entries.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        e.time,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(e.type.icon, size: 16, color: e.type.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

List<(Color, String)> ownerAttentionItems({
  required List<FarmAlert> alerts,
  required FarmLayoutSummary summary,
  required List<WaterSensorReading> water,
}) {
  final items = <(Color, String)>[];
  for (final a in alerts.where((a) => a.isOpen).take(4)) {
    items.add((a.level.color, a.title.isEmpty ? a.location : a.title));
  }
  if (summary.alert > 0) {
    items.add((DashboardColors.risk, '${summary.alert} hộp đang cảnh báo'));
  }
  if (summary.watch > 0) {
    items.add((DashboardColors.monitoring, '${summary.watch} hộp đang theo dõi'));
  }
  for (final r in water) {
    if (r.status == WaterSensorStatus.exceeded ||
        r.status == WaterSensorStatus.danger) {
      items.add((DashboardColors.risk, '${r.type.label} ${r.displayValue}'));
    }
  }
  final seen = <String>{};
  return [
    for (final i in items)
      if (seen.add(i.$2)) i,
  ];
}

List<String> ownerAssistantLines({
  required FarmLayoutSummary summary,
  required String hint,
  required int openAlerts,
}) {
  final lines = <String>[];
  if (openAlerts == 0 && summary.alert == 0) {
    lines.add('Hôm nay hệ thống ổn định.');
  } else {
    lines.add('Có việc cần Owner xem ngay.');
  }
  if (summary.watch > 0) {
    lines.add('${summary.watch} hộp / cua đang theo dõi.');
  }
  if (summary.molting > 0) {
    lines.add('${summary.molting} hộp có khả năng sắp / đang lột.');
  }
  if (hint.trim().isNotEmpty) lines.add(hint.trim());
  return lines.take(4).toList();
}
