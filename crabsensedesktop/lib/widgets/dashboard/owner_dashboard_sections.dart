import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_activity_log.dart';
import '../../models/farm_alert.dart';
import '../../models/farm_layout.dart';
import '../../models/ras_flow.dart';
import '../../models/water_analysis.dart';
import '../../models/water_quality.dart';
import '../shared/mgmt_ui.dart' show fmtDateTimeVn;
import '../../theme/dashboard_theme.dart';
import '../shared/ai_assistant_avatar.dart';
import 'glass_card.dart';

TextStyle _bv({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.beVietnamPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

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
    final first = userName.trim().isEmpty
        ? 'Chủ trại'
        : userName.trim().split(RegExp(r'\s+')).first;
    final now = DateTime.now();
    final dateLabel = _viLongDate(now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 142,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/background_chao_user.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF7FFFC), Color(0xFFDDF7EE)],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.92),
                    Colors.white.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.28, 0.55, 0.82],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text('☀️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Chào $first!',
                              style: _bv(
                                color: DashboardColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hôm nay là $dateLabel',
                          style: _bv(
                            color: DashboardColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stable
                              ? 'Cùng CrabSense kiểm soát trại nuôi hiệu quả hơn mỗi ngày.'
                              : statusMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _bv(
                            color: DashboardColors.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _viLongDate(DateTime d) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    const months = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    final wd = weekdays[d.weekday - 1];
    return '$wd, ${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}

class OwnerKpiStrip extends StatelessWidget {
  const OwnerKpiStrip({super.key, required this.items});

  final List<OwnerKpiItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1100
            ? items.length
            : c.maxWidth > 700
                ? 3
                : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: w,
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, size: 18, color: item.color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _bv(
                                color: DashboardColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.value,
                        style: _bv(
                          color: DashboardColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.caption,
                        style: _bv(
                          color: item.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.progress != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: item.progress!.clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor:
                                item.color.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(item.color),
                          ),
                        ),
                      ],
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

class OwnerKpiItem {
  const OwnerKpiItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
    this.progress,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;
  final double? progress;
}

class OwnerAttentionCard extends StatelessWidget {
  const OwnerAttentionCard({
    super.key,
    required this.items,
    required this.onViewAll,
    this.areaLabel,
    this.alertBoxCount,
  });

  final List<(Color, String)> items;
  final VoidCallback onViewAll;
  final String? areaLabel;
  final int? alertBoxCount;

  @override
  Widget build(BuildContext context) {
    final hasIssues = items.isNotEmpty || (alertBoxCount ?? 0) > 0;
    final count = alertBoxCount;
    final area = (areaLabel == null || areaLabel!.isEmpty)
        ? 'khu hiện tại'
        : areaLabel!;

    return GlassCard(
      color: hasIssues ? const Color(0xFFFFF4F4) : const Color(0xFFF5F5F5),
      borderColor: hasIssues
          ? const Color(0xFFFECACA)
          : DashboardColors.textMuted.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(
            hasIssues ? Icons.warning_amber_rounded : Icons.info_outline,
            color: hasIssues ? DashboardColors.risk : DashboardColors.textMuted,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasIssues ? 'Có thông tin cần theo dõi' : 'Chưa có kết luận tổng thể',
                  style: _bv(
                    color: DashboardColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasIssues
                      ? ((count ?? 0) > 0
                          ? '$count hộp đang cảnh báo • $area'
                          : items.first.$2)
                      : 'Chưa xác minh toàn bộ trạng thái hệ thống.',
                  style: _bv(
                    color: DashboardColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onViewAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: hasIssues
                  ? DashboardColors.risk
                  : DashboardColors.brand,
              side: BorderSide(
                color: hasIssues
                    ? const Color(0xFFFECACA)
                    : DashboardColors.mintActive,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: Text(
              'Xem tất cả cảnh báo →',
              style: _bv(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Current readings only. Each sensor has its own timestamps, unit and
/// configured limits, never infer overall water safety.
String dashboardWaterAssessment(WaterSensorReading r, DateTime now) {
  final measured=r.measuredAt,received=r.receivedAt;
  if(measured==null || received==null || !r.value.isFinite)return 'Chưa xác minh dữ liệu';
  final a=now.difference(measured),b=now.difference(received);
  if(a.isNegative || b.isNegative || a>const Duration(minutes:5) ||
      b>const Duration(minutes:5))return 'Dữ liệu cũ / chưa xác minh';
  if(r.offline)return 'Chưa xác minh hiện trạng';
  if(r.status==WaterSensorStatus.exceeded || r.status==WaterSensorStatus.danger)
    return 'Cảnh báo từ cấu hình';
  if(r.threshold.min==null && r.threshold.max==null)return 'Chưa có ngưỡng cấu hình';
  return 'Trong giới hạn cấu hình';
}

class OwnerWaterCard extends StatelessWidget {
  const OwnerWaterCard({super.key,required this.readings,required this.onOpenRealtime});
  final List<WaterSensorReading> readings;
  final VoidCallback onOpenRealtime;
  @override
  Widget build(BuildContext context) => GlassCard(child:Column(
    crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Nước RAS chung khu',style:_bv(fontWeight:FontWeight.w800,fontSize:15)),
      const SizedBox(height:8),
      const Text('Dữ liệu đại diện chung các dãy/hộp. Không kết luận nước an toàn.'),
      if(readings.isEmpty)const Text('Chưa có phép đo đã xác minh.'),
      for(final r in readings) ...[
        const Divider(),
        Text(r.type.label+' · '+(r.sensorCode??r.sensorId??'—'),style:_bv(fontWeight:FontWeight.w700)),
        Text((r.value==0?'0':r.value.toString())+' '+r.unit,style:_bv(fontSize:18,fontWeight:FontWeight.w800)),
        if(r.location?.isNotEmpty??false)Text('Vị trí cảm biến: '+r.location!),
        Text('Đo: '+fmtDateTimeVn(r.measuredAt)),
        Text('Nhận: '+fmtDateTimeVn(r.receivedAt)),
        Text('Ngưỡng: '+r.threshold.goodRangeLabel),
        Text(dashboardWaterAssessment(r,DateTime.now()),style:_bv(color:DashboardColors.textMuted)),
      ],
      Align(alignment:Alignment.centerRight,child:TextButton(
        onPressed:onOpenRealtime,child:const Text('Xem giám sát Realtime →'))),
    ]));
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
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.science_outlined,
              size: 100,
              color: DashboardColors.brand.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('🧪', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Phân tích gần nhất',
                    style: _bv(
                      color: DashboardColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (run == null)
                Text(
                  'Chưa có lần phân tích hóa học.',
                  style: _bv(color: DashboardColors.textMuted, fontSize: 13.5),
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
                            style: _bv(
                              color: DashboardColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            m.displayValue,
                            style: _bv(
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
                  style: _bv(color: DashboardColors.textMuted, fontSize: 12),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpen,
                  child: Text(
                    'Phân tích nước →',
                    style: _bv(
                      color: DashboardColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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
    final groups = _deviceGroups(nodes);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thiết bị & hệ thống',
            style: _bv(
              color: DashboardColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            Text(
              'Chưa có dữ liệu thiết bị trên khu này.',
              style: _bv(color: DashboardColors.textMuted),
            )
          else
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(g.icon, size: 18, color: DashboardColors.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        g.label,
                        style: _bv(
                          color: DashboardColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: g.warn
                          ? DashboardColors.monitoring
                          : DashboardColors.healthy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      g.warn ? 'Có cảnh báo' : 'Hoạt động',
                      style: _bv(
                        color: g.warn
                            ? DashboardColors.monitoring
                            : DashboardColors.healthy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${g.active}/${g.total}',
                      style: _bv(
                        color: DashboardColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpen,
              child: Text(
                'Điều khiển RAS →',
                style: _bv(
                  color: DashboardColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<_DeviceGroup> _deviceGroups(List<RasFlowNodeLive> nodes) {
    if (nodes.isEmpty) return const [];

    _DeviceGroup summarize(
      String label,
      IconData icon,
      bool Function(RasFlowNodeLive) match,
    ) {
      final list = nodes.where(match).toList();
      if (list.isEmpty) {
        return _DeviceGroup(
          label: label,
          icon: icon,
          active: 0,
          total: 0,
          warn: false,
        );
      }
      final active = list.where((n) {
        if (n.isOnline == false) return false;
        if (n.hasRelay) return n.isOn == true;
        return true;
      }).length;
      final warn = list.any(
        (n) => n.isOnline == false || (n.hasRelay && n.isOn == false),
      );
      return _DeviceGroup(
        label: label,
        icon: icon,
        active: active,
        total: list.length,
        warn: warn,
      );
    }

    final pumps = summarize(
      'Bơm nước',
      Icons.water_outlined,
      (n) {
        final t = '${n.displayLabel} ${n.nodeType}'.toLowerCase();
        return t.contains('bơm') || t.contains('pump');
      },
    );
    final air = summarize(
      'Sủi khí',
      Icons.bubble_chart_outlined,
      (n) {
        final t = '${n.displayLabel} ${n.nodeType}'.toLowerCase();
        return t.contains('sủi') ||
            t.contains('aer') ||
            t.contains('khí') ||
            t.contains('air');
      },
    );
    final filter = summarize(
      'Lọc nước',
      Icons.filter_alt_outlined,
      (n) {
        final t = '${n.displayLabel} ${n.nodeType}'.toLowerCase();
        return t.contains('lọc') || t.contains('filter');
      },
    );
    final ctrl = summarize(
      'Controller',
      Icons.memory_outlined,
      (n) {
        final t = '${n.displayLabel} ${n.nodeType}'.toLowerCase();
        return t.contains('control') || t.contains('điều khiển') || t.contains('plc');
      },
    );

    final known = [pumps, air, filter, ctrl].where((g) => g.total > 0).toList();
    if (known.isNotEmpty) return known;

    final online = nodes.where((n) => n.isOnline != false).length;
    final warn = nodes.any((n) => n.isOnline == false);
    return [
      _DeviceGroup(
        label: 'Thiết bị RAS',
        icon: Icons.settings_input_component_outlined,
        active: online,
        total: nodes.length,
        warn: warn,
      ),
    ];
  }
}

class _DeviceGroup {
  const _DeviceGroup({
    required this.label,
    required this.icon,
    required this.active,
    required this.total,
    required this.warn,
  });

  final String label;
  final IconData icon;
  final int active;
  final int total;
  final bool warn;
}

class OwnerCrabStatusCard extends StatelessWidget {
  const OwnerCrabStatusCard({super.key, required this.summary});

  final FarmLayoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final segs = [
      (summary.normal, 'Bình thường', DashboardColors.healthy),
      (summary.molting, 'Lột xác', DashboardColors.moltPurple),
      (summary.alert, 'Cảnh báo', DashboardColors.monitoring),
    ];
    final occupied = summary.occupied > 0
        ? summary.occupied
        : segs.fold<int>(0, (n, s) => n + s.$1);
    final totalSeg = segs.fold<int>(0, (n, s) => n + s.$1);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tình trạng cua / hộp',
            style: _bv(
              color: DashboardColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: totalSeg == 0
                    ? Center(
                        child: Text(
                          '—',
                          style: _bv(
                            color: DashboardColors.textMuted,
                            fontSize: 24,
                          ),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 42,
                              sections: [
                                for (final s in segs)
                                  if (s.$1 > 0)
                                    PieChartSectionData(
                                      value: s.$1.toDouble(),
                                      color: s.$3,
                                      radius: 26,
                                      showTitle: false,
                                    ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$occupied',
                                style: _bv(
                                  color: DashboardColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'đang nuôi',
                                style: _bv(
                                  color: DashboardColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final s in segs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: s.$3),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.$2,
                                style: _bv(
                                  color: DashboardColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              totalSeg == 0
                                  ? '${s.$1}'
                                  : '${s.$1} (${((s.$1 / totalSeg) * 100).round()}%)',
                              style: _bv(
                                color: DashboardColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
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

class OwnerTrendCard extends StatelessWidget {
  const OwnerTrendCard({super.key,required this.readings,this.onOpenHistory});
  final List<WaterSensorReading> readings;
  final VoidCallback? onOpenHistory;
  @override
  Widget build(BuildContext context) => GlassCard(child:Column(
    crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Lịch sử nước RAS',style:_bv(fontSize:15,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const Text('Không suy ra lịch sử 7 ngày từ giá trị hiện tại. Chọn cảm biến gốc trong Giám sát thời gian thực để tải dữ liệu đã xác minh.'),
      if(onOpenHistory!=null)TextButton(onPressed:onOpenHistory,child:const Text('Mở lịch sử cảm biến →')),
    ]));
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
      borderColor: DashboardColors.brand.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AiAssistantAvatar(size: 40),
              const SizedBox(width: 10),
              Text(
                'Trợ lý Cua',
                style: _bv(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
                style: _bv(
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
              child: Text(
                'Xem chi tiết →',
                style: _bv(
                  color: DashboardColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            'Hoạt động gần đây',
            style: _bv(
              color: DashboardColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'Chưa có hoạt động gần đây.',
              style: _bv(color: DashboardColors.textMuted),
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
                        style: _bv(
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
                        style: _bv(
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
    items.add(
      (DashboardColors.monitoring, '${summary.watch} hộp đang theo dõi'),
    );
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
