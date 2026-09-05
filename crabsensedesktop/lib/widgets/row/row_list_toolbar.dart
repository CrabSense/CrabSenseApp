import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../models/row_status.dart';
import '../../theme/dashboard_theme.dart';

class RowListToolbar extends StatelessWidget {
  const RowListToolbar({
    super.key,
    required this.searchController,
    required this.areas,
    required this.areaFilterId,
    required this.statusFilter,
    required this.loading,
    required this.onSearchChanged,
    required this.onAreaChanged,
    required this.onStatusChanged,
    required this.onRefresh,
    this.onAdd,
  });

  final TextEditingController searchController;
  final List<AreaRecord> areas;
  final String? areaFilterId;
  final RowStatusFilter statusFilter;
  final bool loading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<RowStatusFilter?> onStatusChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final showKhu = areas.length > 1;
    final search = Expanded(
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: GoogleFonts.notoSans(
          color: DashboardColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm dãy...',
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
      ),
    );

    final khuDrop = showKhu
        ? SizedBox(
            width: 200,
            child: _FilterDropdown<String?>(
              value: areaFilterId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Khu: Tất cả')),
                ...areas.map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      a.areaName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: loading ? null : onAreaChanged,
            ),
          )
        : null;

    final statusDrop = SizedBox(
      width: 200,
      child: _FilterDropdown<RowStatusFilter?>(
        value: statusFilter,
        items: RowStatusFilter.values
            .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
            .toList(),
        onChanged: loading
            ? null
            : (v) {
                if (v != null) onStatusChanged(v);
              },
      ),
    );

    return Row(
      children: [
        if (khuDrop != null) ...[khuDrop, const SizedBox(width: 12)],
        statusDrop,
        const SizedBox(width: 12),
        search,
        const SizedBox(width: 12),
        if (onAdd != null)
          FilledButton.icon(
            onPressed: loading ? null : onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm dãy'),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        IconButton(
          onPressed: loading ? null : onRefresh,
          tooltip: 'Tải lại',
          icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
        ),
      ],
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
