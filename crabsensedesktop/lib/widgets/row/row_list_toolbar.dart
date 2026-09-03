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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 800;
        final search = Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm tên dãy hoặc mã dãy...',
              hintStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: DashboardColors.textMuted,
                size: 20,
              ),
              filled: true,
              fillColor: DashboardColors.darkNavy,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DashboardColors.cardBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
          ),
        );

        final areaDrop = _FilterDropdown<String?>(
          value: areaFilterId,
          hint: 'Tất cả khu',
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả khu')),
            ...areas.map(
              (a) => DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.areaCode} — ${a.areaName}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
          onChanged: loading ? null : onAreaChanged,
        );

        final statusDrop = _FilterDropdown<RowStatusFilter?>(
          value: statusFilter,
          hint: RowStatusFilter.all.label,
          items: RowStatusFilter.values
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.label),
                ),
              )
              .toList(),
          onChanged: loading
              ? null
              : (v) {
                  if (v != null) onStatusChanged(v);
                },
        );

        final filterBtn = IconButton(
          onPressed: loading ? null : onRefresh,
          tooltip: 'Tải lại',
          icon: Icon(Icons.filter_list, color: DashboardColors.textMuted),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: areaDrop),
                  const SizedBox(width: 8),
                  Expanded(child: statusDrop),
                  filterBtn,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            search,
            const SizedBox(width: 12),
            SizedBox(width: 180, child: areaDrop),
            const SizedBox(width: 8),
            SizedBox(width: 180, child: statusDrop),
            filterBtn,
          ],
        );
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    this.onChanged,
  });

  final T value;
  final String hint;
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
        fillColor: DashboardColors.darkNavy,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
