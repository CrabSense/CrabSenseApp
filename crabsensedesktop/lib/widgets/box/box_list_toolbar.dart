import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_condition.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';

class BoxListToolbar extends StatelessWidget {
  const BoxListToolbar({
    super.key,
    required this.searchController,
    required this.areas,
    required this.rows,
    required this.areaFilterId,
    required this.rowFilterId,
    required this.occupancyFilter,
    required this.crabFilter,
    required this.loading,
    required this.onSearchChanged,
    required this.onAreaChanged,
    required this.onRowChanged,
    required this.onOccupancyChanged,
    required this.onCrabChanged,
    required this.onRefresh,
    this.onAdd,
  });

  final TextEditingController searchController;
  final List<AreaRecord> areas;
  final List<RowRecord> rows;
  final String? areaFilterId;
  final String? rowFilterId;
  final BoxOccupancyFilter occupancyFilter;
  final CrabConditionFilter crabFilter;
  final bool loading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String?> onRowChanged;
  final ValueChanged<BoxOccupancyFilter> onOccupancyChanged;
  final ValueChanged<CrabConditionFilter> onCrabChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: GoogleFonts.notoSans(
        color: DashboardColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo mã hộp hoặc mã cua...',
        hintStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.search, color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardColors.purple, width: 1.2),
        ),
      ),
    );

    final khuDrop = SizedBox(
      width: 170,
      child: _FilterDropdown<String?>(
        value: areaFilterId,
        items: [
          const DropdownMenuItem(value: null, child: Text('Tất cả khu')),
          ...areas.map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.areaName, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: loading ? null : onAreaChanged,
      ),
    );

    final dayDrop = SizedBox(
      width: 170,
      child: _FilterDropdown<String?>(
        value: rowFilterId,
        items: [
          const DropdownMenuItem(value: null, child: Text('Tất cả dãy')),
          ...rows.map(
            (r) => DropdownMenuItem(
              value: r.id,
              child: Text(r.rowName, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: loading ? null : onRowChanged,
      ),
    );

    final occupancyDrop = SizedBox(
      width: 170,
      child: _FilterDropdown<BoxOccupancyFilter>(
        value: occupancyFilter,
        items: BoxOccupancyFilter.values
            .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
            .toList(),
        onChanged: loading
            ? null
            : (v) {
                if (v != null) onOccupancyChanged(v);
              },
      ),
    );

    final crabDrop = SizedBox(
      width: 170,
      child: _FilterDropdown<CrabConditionFilter>(
        value: crabFilter,
        items: CrabConditionFilter.values
            .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
            .toList(),
        onChanged: loading
            ? null
            : (v) {
                if (v != null) onCrabChanged(v);
              },
      ),
    );

    final addBtn = onAdd == null
        ? null
        : FilledButton.icon(
            onPressed: loading ? null : onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm hộp'),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          );

    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 1100;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  khuDrop,
                  dayDrop,
                  occupancyDrop,
                  crabDrop,
                  if (addBtn != null) addBtn,
                  IconButton(
                    onPressed: loading ? null : onRefresh,
                    tooltip: 'Tải lại',
                    icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ],
          );
        }
        return Column(
          children: [
            search,
            const SizedBox(height: 12),
            Row(
              children: [
                khuDrop,
                const SizedBox(width: 10),
                dayDrop,
                const SizedBox(width: 10),
                occupancyDrop,
                const SizedBox(width: 10),
                crabDrop,
                const Spacer(),
                if (addBtn != null) addBtn,
                IconButton(
                  onPressed: loading ? null : onRefresh,
                  tooltip: 'Tải lại',
                  icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final unique = <DropdownMenuItem<T>>[];
    final seen = <T?>{};
    for (final item in items) {
      if (seen.add(item.value)) unique.add(item);
    }
    final resolved = unique.any((e) => e.value == value)
        ? value
        : (unique.isNotEmpty ? unique.first.value : null);
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: resolved,
      decoration: InputDecoration(
        filled: true,
        fillColor: DashboardColors.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
      dropdownColor: DashboardColors.card,
      style: GoogleFonts.notoSans(
        color: DashboardColors.textPrimary,
        fontSize: 13,
      ),
      items: unique,
      onChanged: onChanged,
    );
  }
}
