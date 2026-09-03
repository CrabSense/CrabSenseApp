import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_history_data.dart';
import '../../models/farm_history_event.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/accent_strip_container.dart';
import 'farm_device_dialogs.dart';

class FarmHistoryTab extends StatefulWidget {
  const FarmHistoryTab({super.key});

  @override
  State<FarmHistoryTab> createState() => _FarmHistoryTabState();
}

class _FarmHistoryTabState extends State<FarmHistoryTab> {
  int _timeIndex = 0;
  String _eventFilter = 'Tất cả loại';
  bool _urgentOnly = false;
  bool _infoOnly = false;

  static const _timeFilters = ['Ngày', 'Tuần', 'Tháng'];
  static const _eventTypes = [
    'Tất cả loại',
    'Cảnh báo',
    'Bảo trì',
    'Cho ăn',
    'Môi trường',
  ];

  List<FarmHistoryEvent> get _filtered {
    var list = MockFarmHistoryData.events();
    if (_eventFilter != 'Tất cả loại') {
      list = list.where((e) {
        return switch (_eventFilter) {
          'Cảnh báo' => e.type == HistoryEventType.warning,
          'Bảo trì' => e.type == HistoryEventType.maintenance,
          'Cho ăn' => e.type == HistoryEventType.info,
          'Môi trường' => e.type == HistoryEventType.environment,
          _ => true,
        };
      }).toList();
    }
    if (_urgentOnly) {
      list = list.where((e) => e.priority == HistoryPriority.urgent).toList();
    }
    if (_infoOnly) {
      list = list.where((e) => e.type == HistoryEventType.info).toList();
    }
    return list;
  }

  void _toggleUrgent() {
    setState(() => _urgentOnly = !_urgentOnly);
  }

  void _toggleInfo() {
    setState(() => _infoOnly = !_infoOnly);
  }

  @override
  Widget build(BuildContext context) {
    final events = _filtered;
    final groups = <String, List<FarmHistoryEvent>>{};
    for (final e in events) {
      groups.putIfAbsent(e.dateGroup, () => []).add(e);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1000;
        final timeline = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Breadcrumb(),
                const SizedBox(height: 8),
                Text(
                  'Lịch sử Hoạt động Khu vực',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _FilterBar(
                  timeIndex: _timeIndex,
                  eventFilter: _eventFilter,
                  timeFilters: _timeFilters,
                  eventTypes: _eventTypes,
                  urgentOnly: _urgentOnly,
                  infoOnly: _infoOnly,
                  onTime: (i) => setState(() => _timeIndex = i),
                  onEvent: (v) => setState(() => _eventFilter = v),
                  onToggleUrgent: _toggleUrgent,
                  onToggleInfo: _toggleInfo,
                  onExport: () => showExportHistoryReportDialog(
                    context,
                    eventCount: events.length,
                    timeRange: _timeFilters[_timeIndex],
                    eventType: _exportFilterLabel(),
                  ),
                ),
                const SizedBox(height: 24),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Không có sự kiện phù hợp bộ lọc',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                for (final entry in groups.entries) ...[
                  Text(
                    entry.key,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EventCard(event: e),
                      )),
                  const SizedBox(height: 16),
                ],
              ],
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: timeline),
                    const SizedBox(width: 24),
                    SizedBox(width: 300, child: _SummaryPanel()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    timeline,
                    const SizedBox(height: 24),
                    _SummaryPanel(),
                  ],
                ),
        );
      },
    );
  }

  String _exportFilterLabel() {
    final parts = <String>[_eventFilter];
    if (_urgentOnly) parts.add('Ưu tiên cao');
    if (_infoOnly) parts.add('Thông tin');
    return parts.join(' · ');
  }
}

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Khu vực Nuôi',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
        ),
        Text('  >  ', style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
        Text(
          MockFarmHistoryData.pondId,
          style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.timeIndex,
    required this.eventFilter,
    required this.timeFilters,
    required this.eventTypes,
    required this.urgentOnly,
    required this.infoOnly,
    required this.onTime,
    required this.onEvent,
    required this.onToggleUrgent,
    required this.onToggleInfo,
    required this.onExport,
  });

  final int timeIndex;
  final String eventFilter;
  final List<String> timeFilters;
  final List<String> eventTypes;
  final bool urgentOnly;
  final bool infoOnly;
  final ValueChanged<int> onTime;
  final ValueChanged<String> onEvent;
  final VoidCallback onToggleUrgent;
  final VoidCallback onToggleInfo;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THỜI GIAN',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(timeFilters.length, (i) {
                  final selected = timeIndex == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i < timeFilters.length - 1 ? 6 : 0),
                    child: FilterChip(
                      label: Text(timeFilters[i]),
                      selected: selected,
                      onSelected: (_) => onTime(i),
                      selectedColor: DashboardColors.purple.withValues(alpha: 0.3),
                      labelStyle: GoogleFonts.notoSans(fontSize: 11),
                    ),
                  );
                }),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOẠI SỰ KIỆN',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: eventFilter,
                dropdownColor: DashboardColors.card,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 12,
                ),
                items: eventTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onEvent(v);
                },
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickFilterIcon(
                selected: urgentOnly,
                onPressed: onToggleUrgent,
                icon: Icons.priority_high,
                color: DashboardColors.risk,
                tooltip: urgentOnly
                    ? 'Bỏ lọc ưu tiên cao'
                    : 'Chỉ sự kiện ưu tiên cao',
              ),
              _QuickFilterIcon(
                selected: infoOnly,
                onPressed: onToggleInfo,
                icon: Icons.info_outline,
                color: DashboardColors.cyan,
                tooltip:
                    infoOnly ? 'Bỏ lọc thông tin' : 'Chỉ sự kiện thông tin',
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Xuất Báo cáo'),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterIcon extends StatelessWidget {
  const _QuickFilterIcon({
    required this.selected,
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  final bool selected;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: selected ? color : color.withValues(alpha: 0.55),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final FarmHistoryEvent event;

  @override
  Widget build(BuildContext context) {
    return AccentStripContainer(
      borderRadius: 12,
      accentColor: event.type.borderColor,
      padding: const EdgeInsets.all(16),
      backgroundColor: DashboardColors.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              event.time,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.location,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontSize: 11,
                  ),
                ),
                if (event.performer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Thực hiện bởi: ${event.performer}',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                if (event.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: event.tags.map(_tag).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) {
    final urgent = t.contains('KHẨN');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (urgent ? DashboardColors.risk : DashboardColors.healthy)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        t,
        style: GoogleFonts.notoSans(
          color: urgent ? DashboardColors.risk : DashboardColors.healthy,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summaries = MockFarmHistoryData.eventSummaries();
    final heatmap = MockFarmHistoryData.activityHeatmap();
    const barColors = [
      Color(0xFFFF6B8A),
      DashboardColors.blue,
      DashboardColors.cyan,
    ];

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biểu đồ tóm lược sự kiện',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < summaries.length; i++) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        summaries[i].label,
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: summaries[i].fraction,
                          minHeight: 8,
                          backgroundColor: DashboardColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation(barColors[i]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${summaries[i].count}',
                      style: GoogleFonts.notoSans(
                        color: barColors[i],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MẬT ĐỘ HOẠT ĐỘNG',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...heatmap.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: row
                        .map(
                          (v) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              height: 14,
                              decoration: BoxDecoration(
                                color: DashboardColors.purple
                                    .withValues(alpha: 0.15 + v * 0.75),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: DashboardColors.monitoring, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Phân tích',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                MockFarmHistoryData.aiInsight(),
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
