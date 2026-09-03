import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/area_status.dart';
import '../../theme/dashboard_theme.dart';

class AreaListToolbar extends StatelessWidget {
  const AreaListToolbar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.loading,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onAdd,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final AreaStatusFilter statusFilter;
  final bool loading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AreaStatusFilter> onFilterChanged;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 900;
        final filters = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in AreaStatusFilter.values)
              _FilterChip(
                label: f.label,
                selected: statusFilter == f,
                onTap: loading ? null : () => onFilterChanged(f),
              ),
          ],
        );
        final search = SizedBox(
          width: stacked ? double.infinity : 280,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo mã, tên...',
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: DashboardColors.seaGreen,
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
          ),
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: loading ? null : onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm Khu'),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.seaGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: loading ? null : onRefresh,
              icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
            ),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filters,
              const SizedBox(height: 12),
              search,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: filters),
            const SizedBox(width: 12),
            search,
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? DashboardColors.seaGreen.withValues(alpha: 0.12)
                : DashboardColors.darkNavy,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? DashboardColors.seaGreen
                  : DashboardColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check,
                  size: 16,
                  color: DashboardColors.seaGreen,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.notoSans(
                  color: selected
                      ? DashboardColors.seaGreen
                      : DashboardColors.textMuted,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AreaListPagination extends StatelessWidget {
  const AreaListPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.itemCount,
    required this.totalItems,
    required this.totalPages,
    required this.onPageChanged,
    this.itemLabel = 'khu',
  });

  final int page;
  final int pageSize;
  final int itemCount;
  final int totalItems;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : page * pageSize + 1;
    final end = totalItems == 0
        ? 0
        : (page * pageSize + itemCount).clamp(0, totalItems);
    final pages = totalPages.clamp(1, 99);

    return Row(
      children: [
        Text(
          totalItems == 0
              ? 'Không có dữ liệu'
              : 'Hiển thị $start - $end trong $totalItems $itemLabel',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
          icon: Icon(
            Icons.chevron_left,
            color: page > 0
                ? DashboardColors.textPrimary
                : DashboardColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
        for (var i = 0; i < pages; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _PageDot(
              label: '${i + 1}',
              selected: page == i,
              onTap: () => onPageChanged(i),
            ),
          ),
        IconButton(
          onPressed: page < pages - 1 ? () => onPageChanged(page + 1) : null,
          icon: Icon(
            Icons.chevron_right,
            color: page < pages - 1
                ? DashboardColors.textPrimary
                : DashboardColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? DashboardColors.seaGreen : Colors.transparent,
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSans(
              color: selected ? Colors.white : DashboardColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
