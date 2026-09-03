import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_alerts_data.dart';
import '../../models/farm_alert.dart';
import '../../services/alert_service.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/ai_assistant_avatar.dart';

class AlertQuickStatsBar extends StatelessWidget {
  const AlertQuickStatsBar({super.key, required this.kpi});

  final AlertKpi kpi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _chip('Critical', '${kpi.critical}', DashboardColors.risk),
        _chip('Warning', '${kpi.warning}', DashboardColors.monitoring),
        _chip('Info', '${kpi.info}', DashboardColors.blue),
        _chip('Đã xử lý hôm nay', '${kpi.resolvedToday}', DashboardColors.healthy),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AlertKpiStrip extends StatelessWidget {
  const AlertKpiStrip({super.key, required this.kpi});

  final AlertKpi kpi;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard('Cảnh báo đang hoạt động', '${kpi.active}', Icons.notifications_active_outlined,
          DashboardColors.purple),
      _KpiCard('Critical', '${kpi.critical}', Icons.emergency_outlined, DashboardColors.risk),
      _KpiCard('Warning', '${kpi.warning}', Icons.warning_amber_outlined,
          DashboardColors.monitoring),
      _KpiCard('Info', '${kpi.info}', Icons.info_outline, DashboardColors.blue),
      _KpiCard('Phản hồi TB', '${kpi.avgResponseMinutes}m', Icons.timer_outlined,
          DashboardColors.cyan),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Wrap(spacing: 10, runSpacing: 10, children: cards);
        }
        return Row(
          children: cards
              .map((card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: card,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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

class AlertFilterChips extends StatelessWidget {
  const AlertFilterChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MockAlertsData.filterOptions.map((f) {
          final active = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(f),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: active
                      ? LinearGradient(
                          colors: [
                            DashboardColors.purple.withValues(alpha: 0.6),
                            DashboardColors.blue.withValues(alpha: 0.4),
                          ],
                        )
                      : null,
                  color: active
                      ? null
                      : DashboardColors.cardBorder.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? DashboardColors.purple : DashboardColors.cardBorder,
                  ),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active
                        ? DashboardColors.textPrimary
                        : DashboardColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AlertLevelBadge extends StatelessWidget {
  const AlertLevelBadge({super.key, required this.level, this.compact = false});

  final AlertLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: level.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        level.label,
        style: GoogleFonts.notoSans(
          color: level.color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class AlertStatusCell extends StatelessWidget {
  const AlertStatusCell({super.key, required this.status});

  final AlertWorkflowStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: GoogleFonts.notoSans(fontSize: 11),
        ),
      ],
    );
  }
}

class AlertTable extends StatelessWidget {
  const AlertTable({
    super.key,
    required this.alerts,
    required this.service,
    required this.selectedId,
  });

  final List<FarmAlert> alerts;
  final AlertService service;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'DANH SÁCH CẢNH BÁO CHI TIẾT',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Lọc dữ liệu'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 64,
              showCheckboxColumn: false,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(fontSize: 11),
              columns: const [
                DataColumn(label: Text('Thời gian')),
                DataColumn(label: Text('Mức độ')),
                DataColumn(label: Text('Loại cảnh báo')),
                DataColumn(label: Text('Vị trí')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Người xử lý')),
              ],
              rows: alerts.map((a) {
                final selected = a.id == selectedId;
                return DataRow(
                  selected: selected,
                  onSelectChanged: (_) => service.selectAlert(a.id),
                  cells: [
                    DataCell(Text(a.time)),
                    DataCell(AlertLevelBadge(level: a.level, compact: true)),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(a.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(Text(a.location)),
                    DataCell(AlertStatusCell(status: a.status)),
                    DataCell(Text(a.handler)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả lịch sử cảnh báo'),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertSpotlightCard extends StatelessWidget {
  const AlertSpotlightCard({
    super.key,
    required this.alert,
    required this.service,
  });

  final FarmAlert alert;
  final AlertService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      highlight: true,
      borderColor: DashboardColors.risk.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.diamond_outlined, color: DashboardColors.risk, size: 16),
              const SizedBox(width: 8),
              Text(
                'TIÊU ĐIỂM KHẨN CẤP',
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: DashboardColors.risk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${alert.title} — ${alert.location.split(' -').first}',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _metric('GIÁ TRỊ HIỆN TẠI', alert.currentValue),
          const SizedBox(height: 10),
          _metric('NGƯỠNG AN TOÀN', alert.threshold),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: DashboardColors.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () => service.selectAlert(alert.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    service.markResolved(alert.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đánh dấu xử lý')),
                    );
                  },
                  child: const Text('Đã xử lý'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DashboardColors.cyan,
          ),
        ),
      ],
    );
  }
}

class AlertAssistantPanel extends StatelessWidget {
  const AlertAssistantPanel({
    super.key,
    required this.insight,
    required this.recommendations,
    required this.onActionTap,
  });

  final String insight;
  final List<String> recommendations;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AiAssistantAvatar(size: 40),
              const SizedBox(width: 10),
              Text(
                'Crab Assistant AI',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Gợi ý hành động',
            style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...recommendations.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onActionTap(e.value),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: DashboardColors.darkNavy.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DashboardColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.purple,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.notoSans(fontSize: 12),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: DashboardColors.textMuted),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AlertFrequencyChart extends StatelessWidget {
  const AlertFrequencyChart({super.key, required this.points});

  final List<AlertFrequencyPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => p.count).reduce((a, b) => a > b ? a : b).toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tần suất cảnh báo (24h qua)',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY + 2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: DashboardColors.cardBorder.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final h = v.toInt();
                        if (h % 8 != 0) return const SizedBox.shrink();
                        return Text(
                          '${h}h',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: points
                    .map(
                      (p) => BarChartGroupData(
                        x: p.hour,
                        barRods: [
                          BarChartRodData(
                            toY: p.count.toDouble(),
                            color: DashboardColors.purple.withValues(alpha: 0.7),
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertDetailPanel extends StatelessWidget {
  const AlertDetailPanel({
    super.key,
    required this.alert,
    required this.service,
  });

  final FarmAlert alert;
  final AlertService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AlertLevelBadge(level: alert.level),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _row('Mức độ', alert.level.labelVi),
          _row('Vị trí', alert.location),
          _row('Thiết bị', alert.device),
          _row('Giá trị hiện tại', alert.currentValue),
          _row('Ngưỡng an toàn', alert.threshold),
          _row('Thời gian phát hiện', alert.detectedAt),
          _row('Trạng thái', alert.status.label),
          _row('Người xử lý', alert.handler),
          if (alert.recommendations.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Khuyến nghị',
              style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...alert.recommendations.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${e.key + 1}. ${e.value}',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
          ],
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _snack(context, 'Đã gửi lệnh bật sủi oxy'),
                style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
                child: const Text('Bật sủi oxy'),
              ),
              OutlinedButton(
                onPressed: () => _snack(context, 'Tăng lưu lượng bơm'),
                child: const Text('Tăng lưu lượng bơm'),
              ),
              OutlinedButton(
                onPressed: () => service.markInProgress(alert.id),
                child: const Text('Đang xử lý'),
              ),
              OutlinedButton(
                onPressed: () => service.markResolved(alert.id),
                child: const Text('Đã xử lý'),
              ),
              OutlinedButton(
                onPressed: () => _snack(context, 'Mở form ghi chú'),
                child: const Text('Tạo ghi chú'),
              ),
              OutlinedButton(
                onPressed: () => _snack(context, 'Đã gửi thông báo'),
                child: const Text('Gửi thông báo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                k,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Text(v, style: GoogleFonts.notoSans(fontSize: 12))),
          ],
        ),
      );
}

class AlertCardPreview extends StatelessWidget {
  const AlertCardPreview({super.key, required this.alert, required this.service});

  final FarmAlert alert;
  final AlertService service;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => service.selectAlert(alert.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AlertLevelBadge(level: alert.level, compact: true),
              const Spacer(),
              Text(
                alert.time,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.title,
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(
            '${alert.location} · ${alert.device}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Giá trị: ${alert.currentValue}',
            style: GoogleFonts.notoSans(fontSize: 12),
          ),
          Text(
            'Ngưỡng: ${alert.threshold}',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => service.selectAlert(alert.id),
                  child: const Text('Xem chi tiết', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => service.markResolved(alert.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.purple.withValues(alpha: 0.6),
                  ),
                  child: const Text('Đã xử lý', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AlertHistoryTable extends StatelessWidget {
  const AlertHistoryTable({super.key, required this.rows});

  final List<AlertHistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lịch sử cảnh báo',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 40,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: GoogleFonts.notoSans(fontSize: 11),
              columns: const [
                DataColumn(label: Text('Ngày')),
                DataColumn(label: Text('Loại')),
                DataColumn(label: Text('Mức độ')),
                DataColumn(label: Text('Vị trí')),
                DataColumn(label: Text('Thời gian xử lý')),
                DataColumn(label: Text('Kết quả')),
              ],
              rows: rows.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r.date)),
                    DataCell(Text(r.typeLabel)),
                    DataCell(AlertLevelBadge(level: r.level, compact: true)),
                    DataCell(Text(r.location)),
                    DataCell(Text(r.responseTime)),
                    DataCell(Text(r.result)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertNotificationRules extends StatelessWidget {
  const AlertNotificationRules({super.key, required this.rules});

  final List<NotificationChannelConfig> rules;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kênh thông báo',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ...rules.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlertLevelBadge(level: r.level, compact: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.channels.join(' + '),
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
