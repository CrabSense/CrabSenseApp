import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../home/presentation/widgets/home_palette.dart';

// ── Domain model ─────────────────────────────────────────────────────────────

/// Type of event that can appear in a box timeline.
///
/// Requirements: 4.8
enum BoxTimelineEventType {
  feeding,
  waterChange,
  mineralAddition,
  cleaning,
  medication,
  inspection,
  videoCapture,
  alert,
  harvest,
  crabAdded,
  crabTransfer,
}

/// Extension providing display helpers for [BoxTimelineEventType].
extension BoxTimelineEventTypeExtension on BoxTimelineEventType {
  /// Human-readable label.
  String get label {
    switch (this) {
      case BoxTimelineEventType.feeding:
        return 'Feeding';
      case BoxTimelineEventType.waterChange:
        return 'Water Change';
      case BoxTimelineEventType.mineralAddition:
        return 'Mineral Addition';
      case BoxTimelineEventType.cleaning:
        return 'Cleaning';
      case BoxTimelineEventType.medication:
        return 'Medication';
      case BoxTimelineEventType.inspection:
        return 'Inspection';
      case BoxTimelineEventType.videoCapture:
        return 'Video Capture';
      case BoxTimelineEventType.alert:
        return 'Alert';
      case BoxTimelineEventType.harvest:
        return 'Harvest';
      case BoxTimelineEventType.crabAdded:
        return 'Crab Added';
      case BoxTimelineEventType.crabTransfer:
        return 'Crab Transfer';
    }
  }

  /// Material icon for this event type.
  IconData get icon {
    switch (this) {
      case BoxTimelineEventType.feeding:
        return Icons.restaurant_outlined;
      case BoxTimelineEventType.waterChange:
        return Icons.water_drop_outlined;
      case BoxTimelineEventType.mineralAddition:
        return Icons.science_outlined;
      case BoxTimelineEventType.cleaning:
        return Icons.cleaning_services_outlined;
      case BoxTimelineEventType.medication:
        return Icons.medical_services_outlined;
      case BoxTimelineEventType.inspection:
        return Icons.manage_search_outlined;
      case BoxTimelineEventType.videoCapture:
        return Icons.videocam_outlined;
      case BoxTimelineEventType.alert:
        return Icons.notifications_outlined;
      case BoxTimelineEventType.harvest:
        return Icons.inventory_2_outlined;
      case BoxTimelineEventType.crabAdded:
        return Icons.add_circle_outline;
      case BoxTimelineEventType.crabTransfer:
        return Icons.swap_horiz;
    }
  }

  /// Brand color for this event type.
  Color get color {
    switch (this) {
      case BoxTimelineEventType.feeding:
        return CrabSenseColors.success;
      case BoxTimelineEventType.waterChange:
        return CrabSenseColors.info;
      case BoxTimelineEventType.mineralAddition:
        return CrabSenseColors.warning;
      case BoxTimelineEventType.cleaning:
        return CrabSenseColors.primary;
      case BoxTimelineEventType.medication:
        return CrabSenseColors.error;
      case BoxTimelineEventType.inspection:
        return CrabSenseColors.primary;
      case BoxTimelineEventType.videoCapture:
        return CrabSenseColors.info;
      case BoxTimelineEventType.alert:
        return CrabSenseColors.warning;
      case BoxTimelineEventType.harvest:
        return CrabSenseColors.success;
      case BoxTimelineEventType.crabAdded:
        return CrabSenseColors.success;
      case BoxTimelineEventType.crabTransfer:
        return CrabSenseColors.textSecondary;
    }
  }
}

/// A single event in the box timeline.
///
/// Requirements: 4.8
class BoxTimelineEvent {
  const BoxTimelineEvent({
    required this.id,
    required this.boxId,
    required this.eventType,
    required this.title,
    required this.timestamp,
    this.description,
    this.operatorName,
    this.metadata,
  });

  final String id;
  final String boxId;
  final BoxTimelineEventType eventType;
  final String title;
  final String? description;
  final DateTime timestamp;
  final String? operatorName;
  final Map<String, String>? metadata;
}

/// Filter state for [BoxTimelineWidget].
class BoxTimelineFilter {
  const BoxTimelineFilter({this.eventType, this.dateRange});

  final BoxTimelineEventType? eventType;
  final DateTimeRange? dateRange;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Displays a chronological, paginated list of box timeline events grouped
/// by date, with operation-type and date-range filter controls.
///
/// Pure presentation widget — data is provided via constructor params and
/// user actions are reported via callbacks.
///
/// Requirements: 4.8
class BoxTimelineWidget extends StatefulWidget {
  const BoxTimelineWidget({
    required this.events,
    required this.totalCount,
    this.isLoading = false,
    this.hasMoreItems = false,
    this.onLoadMore,
    this.onFilterChanged,
    super.key,
  });

  /// All currently loaded events (may be a page of a larger dataset).
  final List<BoxTimelineEvent> events;

  /// Total number of events matching the current filter.
  final int totalCount;

  /// When true, show skeleton placeholders instead of events.
  final bool isLoading;

  /// When true, show the "Load more" button at the bottom.
  final bool hasMoreItems;

  /// Called when the user requests additional pages.
  final VoidCallback? onLoadMore;

  /// Called whenever the active filter changes.
  final void Function(BoxTimelineFilter filter)? onFilterChanged;

  @override
  State<BoxTimelineWidget> createState() => _BoxTimelineWidgetState();
}

class _BoxTimelineWidgetState extends State<BoxTimelineWidget> {
  BoxTimelineEventType? _selectedType;
  DateTimeRange? _selectedDateRange;

  // ── Filter helpers ────────────────────────────────────────────────────────

  void _selectType(BoxTimelineEventType? type) {
    setState(() => _selectedType = type);
    widget.onFilterChanged?.call(BoxTimelineFilter(eventType: type, dateRange: _selectedDateRange));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: CrabSenseColors.primary,
            onPrimary: Colors.black,
            surface: CrabSenseColors.surface,
            onSurface: CrabSenseColors.textPrimary,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      widget.onFilterChanged?.call(BoxTimelineFilter(eventType: _selectedType, dateRange: picked));
    }
  }

  void _clearDateRange() {
    setState(() => _selectedDateRange = null);
    widget.onFilterChanged?.call(BoxTimelineFilter(eventType: _selectedType));
  }

  // ── Date group helpers ────────────────────────────────────────────────────

  static String _dateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) {
      return 'Today';
    }
    if (d == yesterday) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Groups the events by calendar date preserving insertion order.
  static Map<String, List<BoxTimelineEvent>> _groupByDate(List<BoxTimelineEvent> events) {
    final grouped = <String, List<BoxTimelineEvent>>{};
    for (final event in events) {
      final key = _dateGroupLabel(event.timestamp);
      grouped.putIfAbsent(key, () => []).add(event);
    }
    return grouped;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _TimelineHeader(totalCount: widget.totalCount),
      const SizedBox(height: 8),
      _TypeFilterRow(selected: _selectedType, onSelected: _selectType),
      const SizedBox(height: 8),
      _DateFilterRow(
        selectedRange: _selectedDateRange,
        onPickDate: _pickDateRange,
        onClear: _clearDateRange,
      ),
      const SizedBox(height: 12),
      if (widget.isLoading)
        const _TimelineSkeletonList()
      else if (widget.events.isEmpty)
        const _TimelineEmptyState()
      else
        _TimelineList(
          grouped: _groupByDate(widget.events),
          hasMore: widget.hasMoreItems,
          onLoadMore: widget.onLoadMore,
        ),
    ],
  );
}

// ── Section header ────────────────────────────────────────────────────────────

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.history_rounded,
          size: 16,
          color: kHomeBlueLight,
          shadows: [
            Shadow(color: kHomeBlueLight.withValues(alpha: 0.7), blurRadius: 8),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          'Sự kiện',
          style: theme.textTheme.titleSmall?.copyWith(
            color: kHomeBlueLight,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        Text(
          '$totalCount bản ghi',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

// ── Type filter chip row ──────────────────────────────────────────────────────

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({required this.selected, required this.onSelected});

  final BoxTimelineEventType? selected;
  final void Function(BoxTimelineEventType?) onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _TypeChip(
          label: 'Tất cả',
          icon: Icons.list_alt_outlined,
          color: kHomeBlueLight,
          isSelected: selected == null,
          onTap: () => onSelected(null),
        ),
        ...BoxTimelineEventType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _TypeChip(
              label: type.label,
              icon: type.icon,
              color: type.color,
              isSelected: selected == type,
              onTap: () => onSelected(type),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isSelected ? color : CrabSenseColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : kHomeNavyDeep.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.75)
                : kHomeBorderBlue.withValues(alpha: 0.4),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: activeColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: activeColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date range filter row ─────────────────────────────────────────────────────

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.selectedRange,
    required this.onPickDate,
    required this.onClear,
  });

  final DateTimeRange? selectedRange;
  final VoidCallback onPickDate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _DatePickerButton(onTap: onPickDate),
      if (selectedRange != null) ...[
        const SizedBox(width: 8),
        _DateRangeChip(range: selectedRange!, onClear: onClear),
      ],
    ],
  );
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CrabSenseColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CrabSenseColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range_outlined, size: 14, color: CrabSenseColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Filter by date',
              style: theme.textTheme.labelSmall?.copyWith(color: CrabSenseColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({required this.range, required this.onClear});

  final DateTimeRange range;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d');
    final label = '${fmt.format(range.start)} – ${fmt.format(range.end)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CrabSenseColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CrabSenseColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: CrabSenseColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 14, color: CrabSenseColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Timeline list ─────────────────────────────────────────────────────────────

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.grouped, required this.hasMore, required this.onLoadMore});

  final Map<String, List<BoxTimelineEvent>> grouped;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final groups = grouped.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int g = 0; g < groups.length; g++) ...[
          _DateGroupHeader(label: groups[g].key),
          const SizedBox(height: 8),
          for (int i = 0; i < groups[g].value.length; i++)
            _TimelineEventRow(
              event: groups[g].value[i],
              isLast: i == groups[g].value.length - 1 && g == groups.length - 1 && !hasMore,
            ),
          if (g < groups.length - 1) const SizedBox(height: 4),
        ],
        if (hasMore) _LoadMoreButton(onTap: onLoadMore),
      ],
    );
  }
}

// ── Date group header ─────────────────────────────────────────────────────────

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: CrabSenseColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: CrabSenseColors.outlineVariant, thickness: 1, height: 1),
          ),
        ],
      ),
    );
  }
}

// ── Single timeline event row ─────────────────────────────────────────────────

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event, required this.isLast});

  final BoxTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineConnector(eventType: event.eventType, isLast: isLast),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TimelineEventCard(event: event),
          ),
        ),
      ],
    ),
  );
}

// ── Connector dot + vertical line ─────────────────────────────────────────────

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.eventType, required this.isLast});

  final BoxTimelineEventType eventType;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = eventType.color;
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(eventType.icon, size: 14, color: color),
          ),
          if (!isLast)
            Expanded(
              child: Center(child: Container(width: 2, color: CrabSenseColors.outlineVariant)),
            ),
        ],
      ),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _TimelineEventCard extends StatelessWidget {
  const _TimelineEventCard({required this.event});

  final BoxTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kHomeNavyDeep.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: kHomeBlue.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitleRow(event: event),
          if (event.description != null) ...[
            const SizedBox(height: 4),
            Text(
              event.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
          if (event.operatorName != null) ...[
            const SizedBox(height: 6),
            _OperatorLabel(name: event.operatorName!),
          ],
        ],
      ),
    );
  }
}

class _CardTitleRow extends StatelessWidget {
  const _CardTitleRow({required this.event});

  final BoxTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            event.title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('HH:mm').format(event.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _OperatorLabel extends StatelessWidget {
  const _OperatorLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 12, color: CrabSenseColors.textDisabled),
        const SizedBox(width: 4),
        Text(
          name,
          style: theme.textTheme.labelSmall?.copyWith(color: CrabSenseColors.textDisabled),
        ),
      ],
    );
  }
}

// ── Load more button ──────────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.expand_more, size: 18, color: CrabSenseColors.primary),
        label: Text(
          'Load more',
          style: theme.textTheme.labelMedium?.copyWith(color: CrabSenseColors.primary),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off, size: 48, color: CrabSenseColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'No events found',
              style: theme.textTheme.titleSmall?.copyWith(color: CrabSenseColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your filters or check back\n'
              'after more operations are recorded.',
              style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textDisabled),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

class _TimelineSkeletonList extends StatelessWidget {
  const _TimelineSkeletonList();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      3,
      (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: _TimelineSkeletonItem()),
    ),
  );
}

class _TimelineSkeletonItem extends StatelessWidget {
  const _TimelineSkeletonItem();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: CrabSenseColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: CrabSenseColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
  );
}
