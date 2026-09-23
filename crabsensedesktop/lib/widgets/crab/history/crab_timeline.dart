import 'package:flutter/material.dart';

import '../../../models/crab_lifecycle_event.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

class CrabTimeline extends StatelessWidget {
  const CrabTimeline({
    super.key,
    required this.items,
    required this.sort,
    required this.onSort,
    required this.selectedId,
    required this.onSelect,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    this.loading = false,
    this.emptyFiltered = false,
    this.onClearFilters,
  });

  final List<CrabLifecycleEvent> items;
  final CrabHistorySort sort;
  final ValueChanged<CrabHistorySort> onSort;
  final String? selectedId;
  final ValueChanged<CrabLifecycleEvent> onSelect;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final bool loading;
  final bool emptyFiltered;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: mgmtCardDeco(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 16, color: DashboardColors.brand),
              const SizedBox(width: 7),
              Text(
                'Dòng thời gian',
                style: bvText(fontSize: 14, fontWeight: FontWeight.w800, color: DashboardColors.textPrimary),
              ),
              const Spacer(),
              MgmtInlineSort<CrabHistorySort>(
                value: sort,
                items: const [
                  (CrabHistorySort.newest, 'Mới nhất trước'),
                  (CrabHistorySort.oldest, 'Cũ nhất trước'),
                ],
                onChanged: onSort,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const _TimelineSkeleton()
          else if (items.isEmpty)
            _empty()
          else ...[
            ..._groups(),
            const SizedBox(height: 8),
            if (hasMore)
              Center(
                child: MgmtOutlineButton(
                  label: loadingMore ? 'Đang tải...' : 'Tải thêm sự kiện',
                  icon: Icons.expand_more_rounded,
                  onTap: loadingMore ? null : onLoadMore,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Đã hiển thị toàn bộ lịch sử.',
                  textAlign: TextAlign.center,
                  style: bvText(fontSize: 12, color: DashboardColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    if (emptyFiltered) {
      return MgmtEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy sự kiện',
        message: 'Không có lịch sử phù hợp với bộ lọc hiện tại.',
        action: onClearFilters == null
            ? null
            : MgmtOutlineButton(label: 'Xóa bộ lọc', onTap: onClearFilters),
      );
    }
    return const MgmtEmptyState(
      icon: Icons.schedule_rounded,
      title: 'Chưa có lịch sử',
      message: 'Các sự kiện của cua sẽ xuất hiện tại đây.',
    );
  }

  List<Widget> _groups() {
    final groups = <String, List<CrabLifecycleEvent>>{};
    for (final e in items) {
      groups.putIfAbsent(historyDayLabel(e.occurredAt), () => []).add(e);
    }
    final out = <Widget>[];
    for (final entry in groups.entries) {
      out.add(CrabTimelineGroup(
        label: entry.key,
        events: entry.value,
        selectedId: selectedId,
        onSelect: onSelect,
      ));
    }
    return out;
  }
}

class CrabTimelineGroup extends StatelessWidget {
  const CrabTimelineGroup({
    super.key,
    required this.label,
    required this.events,
    required this.selectedId,
    required this.onSelect,
  });

  final String label;
  final List<CrabLifecycleEvent> events;
  final String? selectedId;
  final ValueChanged<CrabLifecycleEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              label,
              style: bvText(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textMuted,
              ),
            ),
          ),
          for (var i = 0; i < events.length; i++)
            CrabEventRow(
              event: events[i],
              selected: events[i].id == selectedId,
              last: i == events.length - 1,
              onTap: () => onSelect(events[i]),
            ),
        ],
      ),
    );
  }
}

class CrabEventRow extends StatelessWidget {
  const CrabEventRow({
    super.key,
    required this.event,
    required this.selected,
    required this.last,
    required this.onTap,
  });

  final CrabLifecycleEvent event;
  final bool selected;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = event.eventType.color;
    return Material(
      color: selected ? DashboardColors.lightMint : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 46,
                child: Text(
                  historyTimeLabel(event.occurredAt),
                  style: bvText(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardColors.textMuted),
                ),
              ),
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(event.eventType.icon, size: 13, color: color),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 22,
                        margin: const EdgeInsets.only(top: 4),
                        color: DashboardColors.mint,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: bvText(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                    ),
                    if (event.summary.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bvText(fontSize: 12, color: DashboardColors.textPrimary.withValues(alpha: 0.82)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 88,
                child: Text(
                  event.boxLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: Text(
                  event.actorLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bvText(fontSize: 11.5, color: DashboardColors.textMuted),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: DashboardColors.textMuted.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(width: 40, height: 12, color: DashboardColors.mint),
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(color: DashboardColors.mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 140, color: DashboardColors.mint),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 220, color: DashboardColors.mint),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
