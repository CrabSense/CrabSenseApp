// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/operation_log.dart';
import '../../domain/entities/operation_type.dart';
import '../bloc/operation_bloc.dart' show OperationBloc;

// ── Extensions ────────────────────────────────────────────────────────────────

/// Display helpers for [OperationType] used inside this widget.
extension _OperationTypeUiExtension on OperationType {
  /// Material icon for this operation type.
  IconData get icon {
    switch (this) {
      case OperationType.feeding:
        return Icons.restaurant_outlined;
      case OperationType.waterChange:
        return Icons.water_drop_outlined;
      case OperationType.mineralAddition:
        return Icons.science_outlined;
      case OperationType.cleaning:
        return Icons.cleaning_services_outlined;
      case OperationType.medication:
        return Icons.medical_services_outlined;
      case OperationType.inspection:
        return Icons.manage_search_outlined;
    }
  }

  /// Vietnamese label for this operation type.
  String get labelVi {
    switch (this) {
      case OperationType.feeding:
        return 'Cho ăn';
      case OperationType.waterChange:
        return 'Thay nước';
      case OperationType.mineralAddition:
        return 'Bổ sung khoáng';
      case OperationType.cleaning:
        return 'Vệ sinh';
      case OperationType.medication:
        return 'Điều trị';
      case OperationType.inspection:
        return 'Kiểm tra';
    }
  }

  /// Accent color for this operation type.
  Color get accentColor {
    switch (this) {
      case OperationType.feeding:
        return CrabSenseColors.success;
      case OperationType.waterChange:
        return kHomeCyan;
      case OperationType.mineralAddition:
        return CrabSenseColors.warning;
      case OperationType.cleaning:
        return kHomeBlueLight;
      case OperationType.medication:
        return CrabSenseColors.error;
      case OperationType.inspection:
        return kHomePurple;
    }
  }
}

// ── Filter model ──────────────────────────────────────────────────────────────

/// Encapsulates the current filter / search state for [OperationTimeline].
///
/// Immutable — use [copyWith] to derive changed copies.
class OperationTimelineFilter {
  const OperationTimelineFilter({
    this.operationType,
    this.boxId,
    this.dateRange,
    this.searchQuery = '',
  });

  /// When non-null, only logs of this type are displayed.
  final OperationType? operationType;

  /// When non-null, only logs that include this box ID are displayed.
  final String? boxId;

  /// When non-null, only logs within this range are displayed.
  final DateTimeRange? dateRange;

  /// Free-text keyword filter applied to [OperationLog.notes].
  /// Empty string means no keyword filter.
  final String searchQuery;

  /// Returns true if no filter is active.
  bool get isEmpty =>
      operationType == null && boxId == null && dateRange == null && searchQuery.isEmpty;

  /// Returns a copy of this filter with the given fields replaced.
  OperationTimelineFilter copyWith({
    Object? operationType = _sentinel,
    Object? boxId = _sentinel,
    Object? dateRange = _sentinel,
    String? searchQuery,
  }) => OperationTimelineFilter(
    operationType: operationType == _sentinel
        ? this.operationType
        : operationType as OperationType?,
    boxId: boxId == _sentinel ? this.boxId : boxId as String?,
    dateRange: dateRange == _sentinel ? this.dateRange : dateRange as DateTimeRange?,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

const _sentinel = Object();

// ── Public widget ─────────────────────────────────────────────────────────────

/// Displays a paginated, chronological timeline of [OperationLog] entries
/// grouped by date, with type / box / date-range filters and a keyword
/// search on notes.
///
/// This is a pure presentation widget: data is provided via constructor
/// parameters and all user actions are reported through callbacks.
/// Parent widgets (e.g. a screen using [OperationBloc]) are responsible
/// for fetching pages and applying filters server-side or in-memory.
///
/// Requirements: 10.8
class OperationTimeline extends StatefulWidget {
  const OperationTimeline({
    required this.logs,
    required this.totalCount,
    this.availableBoxIds = const [],
    this.isLoading = false,
    this.hasMoreItems = false,
    this.onLoadMore,
    this.onFilterChanged,
    super.key,
  });

  /// Currently loaded operation logs (may be a page of a larger dataset).
  final List<OperationLog> logs;

  /// Total number of logs matching the current filter (used in the header).
  final int totalCount;

  /// Distinct box IDs to populate the box-filter dropdown.
  /// May be left empty; the dropdown is hidden when empty.
  final List<String> availableBoxIds;

  /// When true the widget shows skeleton placeholders.
  final bool isLoading;

  /// When true a "Load more" button is shown at the bottom.
  final bool hasMoreItems;

  /// Called when the user scrolls to or taps "Load more".
  final VoidCallback? onLoadMore;

  /// Called whenever the active filter / search query changes.
  final void Function(OperationTimelineFilter filter)? onFilterChanged;

  @override
  State<OperationTimeline> createState() => _OperationTimelineState();
}

class _OperationTimelineState extends State<OperationTimeline> {
  late OperationTimelineFilter _filter;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filter = const OperationTimelineFilter();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter helpers ────────────────────────────────────────────────────────

  void _updateFilter(OperationTimelineFilter updated) {
    setState(() => _filter = updated);
    widget.onFilterChanged?.call(updated);
  }

  void _selectType(OperationType? type) => _updateFilter(_filter.copyWith(operationType: type));

  void _selectBoxId(String? boxId) => _updateFilter(_filter.copyWith(boxId: boxId));

  void _onSearchChanged(String query) => _updateFilter(_filter.copyWith(searchQuery: query));

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filter.dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: kHomeBlue,
            onPrimary: Colors.white,
            surface: kHomeNavy,
            onSurface: Colors.white,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      _updateFilter(_filter.copyWith(dateRange: picked));
    }
  }

  void _clearDateRange() => _updateFilter(_filter.copyWith(dateRange: null));

  void _clearAll() {
    _searchController.clear();
    _updateFilter(const OperationTimelineFilter());
  }

  // ── Date group helpers ────────────────────────────────────────────────────

  static String _dateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) {
      return 'Hôm nay';
    }
    if (d == yesterday) {
      return 'Hôm qua';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static Map<String, List<OperationLog>> _groupByDate(List<OperationLog> logs) {
    final grouped = <String, List<OperationLog>>{};
    for (final log in logs) {
      final key = _dateGroupLabel(log.timestamp);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _TimelineHeader(
        totalCount: widget.totalCount,
        hasActiveFilter: !_filter.isEmpty,
        onClearAll: _clearAll,
      ),
      const SizedBox(height: 8),
      _SearchBar(controller: _searchController, onChanged: _onSearchChanged),
      const SizedBox(height: 8),
      _TypeFilterRow(selected: _filter.operationType, onSelected: _selectType),
      const SizedBox(height: 8),
      _SecondaryFilterRow(
        availableBoxIds: widget.availableBoxIds,
        selectedBoxId: _filter.boxId,
        selectedDateRange: _filter.dateRange,
        onBoxSelected: _selectBoxId,
        onPickDate: _pickDateRange,
        onClearDate: _clearDateRange,
      ),
      const SizedBox(height: 12),
      if (widget.isLoading)
        const _TimelineSkeletonList()
      else if (widget.logs.isEmpty)
        _TimelineEmptyState(hasFilter: !_filter.isEmpty)
      else
        _TimelineList(
          grouped: _groupByDate(widget.logs),
          hasMore: widget.hasMoreItems,
          onLoadMore: widget.onLoadMore,
        ),
    ],
  );
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({
    required this.totalCount,
    required this.hasActiveFilter,
    required this.onClearAll,
  });

  final int totalCount;
  final bool hasActiveFilter;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.history,
          size: 18,
          color: kHomeBlueLight,
          shadows: [
            Shadow(color: kHomeBlueLight.withValues(alpha: 0.8), blurRadius: 10),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          'DÒNG THỜI GIAN',
          style: theme.textTheme.titleSmall?.copyWith(
            color: kHomeBlueLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 12.5,
          ),
        ),
        const Spacer(),
        if (hasActiveFilter)
          GestureDetector(
            onTap: onClearAll,
            child: Text(
              'Xóa bộ lọc',
              style: theme.textTheme.labelSmall?.copyWith(
                color: kHomeBlueLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            '$totalCount bản ghi',
            style: theme.textTheme.labelSmall?.copyWith(color: CrabSenseColors.textSecondary),
          ),
      ],
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
    decoration: InputDecoration(
      hintText: 'Tìm trong ghi chú…',
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      filled: true,
      fillColor: kHomeNavyDeep.withValues(alpha: 0.75),
      prefixIcon: const Icon(Icons.search, size: 18, color: kHomeBlueLight),
      suffixIcon: controller.text.isNotEmpty
          ? GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Icon(Icons.close, size: 16, color: kHomeBlueLight),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kHomeBorderBlue.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kHomeBlue.withValues(alpha: 0.9), width: 1.4),
      ),
    ),
  );
}

// ── Type filter chip row ──────────────────────────────────────────────────────

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({required this.selected, required this.onSelected});

  final OperationType? selected;
  final void Function(OperationType?) onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _FilterChip(
          label: 'Tất cả loại',
          icon: Icons.list_alt_outlined,
          accentColor: kHomeBlueLight,
          isSelected: selected == null,
          onTap: () => onSelected(null),
        ),
        ...OperationType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _FilterChip(
              label: type.labelVi,
              icon: type.icon,
              accentColor: type.accentColor,
              isSelected: selected == type,
              onTap: () => onSelected(type),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isSelected ? accentColor : CrabSenseColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : kHomeNavyDeep.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.8)
                : kHomeBorderBlue.withValues(alpha: 0.4),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
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

// ── Secondary filter row (box + date) ────────────────────────────────────────

class _SecondaryFilterRow extends StatelessWidget {
  const _SecondaryFilterRow({
    required this.availableBoxIds,
    required this.selectedBoxId,
    required this.selectedDateRange,
    required this.onBoxSelected,
    required this.onPickDate,
    required this.onClearDate,
  });

  final List<String> availableBoxIds;
  final String? selectedBoxId;
  final DateTimeRange? selectedDateRange;
  final void Function(String?) onBoxSelected;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        if (availableBoxIds.isNotEmpty)
          _BoxFilterDropdown(
            boxIds: availableBoxIds,
            selected: selectedBoxId,
            onSelected: onBoxSelected,
          ),
        if (availableBoxIds.isNotEmpty) const SizedBox(width: 8),
        _DatePickerButton(onTap: onPickDate),
        if (selectedDateRange != null) ...[
          const SizedBox(width: 8),
          _DateRangeChip(range: selectedDateRange!, onClear: onClearDate),
        ],
      ],
    ),
  );
}

// ── Box filter dropdown ───────────────────────────────────────────────────────

class _BoxFilterDropdown extends StatelessWidget {
  const _BoxFilterDropdown({
    required this.boxIds,
    required this.selected,
    required this.onSelected,
  });

  final List<String> boxIds;
  final String? selected;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected != null
            ? kHomeBlue.withValues(alpha: 0.18)
            : kHomeNavyDeep.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected != null
              ? kHomeBlue.withValues(alpha: 0.8)
              : kHomeBorderBlue.withValues(alpha: 0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isDense: true,
          dropdownColor: kHomeNavy,
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: kHomeBlueLight),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: kHomeBlueLight,
              ),
              const SizedBox(width: 4),
              Text(
                'Tất cả hộp',
                style: theme.textTheme.labelSmall?.copyWith(color: kHomeBlueLight),
              ),
            ],
          ),
          onChanged: onSelected,
          items: [
            DropdownMenuItem<String?>(
              child: Text(
                'Tất cả hộp',
                style: theme.textTheme.labelSmall?.copyWith(color: CrabSenseColors.textSecondary),
              ),
            ),
            ...boxIds.map(
              (id) => DropdownMenuItem<String?>(
                value: id,
                child: Text(
                  id,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date picker button + chip ─────────────────────────────────────────────────

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
          color: kHomeNavyDeep.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range_outlined, size: 14, color: kHomeBlueLight),
            const SizedBox(width: 4),
            Text(
              'Khoảng ngày',
              style: theme.textTheme.labelSmall?.copyWith(color: kHomeBlueLight),
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
    final fmt = DateFormat('dd/MM');
    final label = '${fmt.format(range.start)} – ${fmt.format(range.end)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kHomeBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kHomeBlue.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: kHomeBlue.withValues(alpha: 0.3), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: kHomeBlueLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 14, color: kHomeBlueLight),
          ),
        ],
      ),
    );
  }
}

// ── Timeline list (grouped by date) ──────────────────────────────────────────

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.grouped, required this.hasMore, required this.onLoadMore});

  final Map<String, List<OperationLog>> grouped;
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
            _TimelineRow(
              log: groups[g].value[i],
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
              color: kHomeBlueLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: kHomeBorderBlue.withValues(alpha: 0.35),
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline row (single operation entry) ─────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.log, this.isLast = false});

  final OperationLog log;
  final bool isLast;

  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = log.type.accentColor;
    final icon = log.type.icon;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Vertical timeline rail ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: kHomeBorderBlue.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Content card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Type badge + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              log.type.labelVi,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.schedule_outlined,
                        size: 12,
                        color: CrabSenseColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeFmt.format(log.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Box IDs
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: CrabSenseColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                        Expanded(
                        child: Text(
                          log.boxIds.join(', '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Row 3: Quantity + unit (conditional)
                  if (log.quantity != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten_outlined,
                          size: 14,
                          color: CrabSenseColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${log.quantity}${log.unit != null ? ' ${log.unit}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Row 4: Notes (truncated)
                  if (log.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kHomeNavyDeep.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kHomeBorderBlue.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        log.notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: CrabSenseColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  // Row 5: Operator + photo count
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 12,
                        color: CrabSenseColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          log.operatorName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: CrabSenseColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (log.photoUrls.isNotEmpty) ...[
                        const Icon(
                          Icons.photo_camera_outlined,
                          size: 12,
                          color: CrabSenseColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${log.photoUrls.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: CrabSenseColors.textSecondary,
                          ),
                        ),
                      ],
                      if (log.isEditable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kHomeBlue.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: kHomeBlue.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'Có thể sửa',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: kHomeBlueLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loading list ─────────────────────────────────────────────────────

class _TimelineSkeletonList extends StatelessWidget {
  const _TimelineSkeletonList();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(5, (index) => _SkeletonRow(isLast: index == 4)),
  );
}

class _SkeletonRow extends StatefulWidget {
  const _SkeletonRow({this.isLast = false});

  final bool isLast;

  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _shimmerAnimation,
    builder: (context, child) {
      final opacity = _shimmerAnimation.value;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline rail skeleton
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: kHomeNavyLift.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: kHomeBorderBlue.withValues(alpha: opacity),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Card skeleton
            Expanded(
              child: Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kHomeNavyDeep.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kHomeBorderBlue.withValues(alpha: opacity),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge placeholder
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 22,
                          decoration: BoxDecoration(
                            color: kHomeNavyLift.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 14,
                          decoration: BoxDecoration(
                            color: kHomeNavyLift.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Box IDs placeholder
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kHomeNavyLift.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    // Bottom row placeholder
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: kHomeNavyLift.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({this.hasFilter = false});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kHomeBlue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: kHomeBlue.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: kHomeBlue.withValues(alpha: 0.3),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(
              hasFilter ? Icons.filter_list_off_outlined : Icons.history_outlined,
              size: 36,
              color: kHomeBlueLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Không có thao tác phù hợp' : 'Chưa có nhật ký nào',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm.'
                : 'Nhật ký vận hành bạn ghi nhận sẽ hiển thị ở đây theo thời gian.',
            style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: kHomeBlue.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kHomeBlue.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: kHomeBlue.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.expand_more_rounded, size: 18, color: kHomeBlueLight),
                const SizedBox(width: 6),
                Text(
                  'Tải thêm',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: kHomeBlueLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
