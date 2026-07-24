import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/boxes_models.dart';

class BoxFilterChips extends StatelessWidget {
  const BoxFilterChips({
    required this.activeFilters,
    required this.onToggle,
    required this.onClear,
    super.key,
  });

  final Set<BoxQuickFilter> activeFilters;
  final ValueChanged<BoxQuickFilter> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasActive =
        !activeFilters.contains(BoxQuickFilter.all) || activeFilters.length > 1;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...BoxQuickFilter.values.map((filter) {
            final selected =
                activeFilters.contains(filter) ||
                (filter == BoxQuickFilter.all &&
                    activeFilters.length == 1 &&
                    activeFilters.contains(BoxQuickFilter.all));
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                label: Text(filter.label),
                onSelected: (_) => onToggle(filter),
                selectedColor: CrabSenseColors.primary.withValues(alpha: 0.22),
                backgroundColor: CrabSenseColors.surface,
                checkmarkColor: CrabSenseColors.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? CrabSenseColors.primary
                      : CrabSenseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected
                      ? CrabSenseColors.primary.withValues(alpha: 0.6)
                      : CrabSenseColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }),
          if (hasActive)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: CrabSenseColors.danger,
                minimumSize: const Size(48, 36),
              ),
              child: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class ViewModeSwitcher extends StatelessWidget {
  const ViewModeSwitcher({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final BoxesViewMode mode;
  final ValueChanged<BoxesViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrabSenseColors.border),
      ),
      child: Row(
        children: [
          _ModeBtn(
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            selected: mode == BoxesViewMode.grid,
            onTap: () => onChanged(BoxesViewMode.grid),
          ),
          _ModeBtn(
            icon: Icons.view_list_rounded,
            label: 'List',
            selected: mode == BoxesViewMode.list,
            onTap: () => onChanged(BoxesViewMode.list),
          ),
          _ModeBtn(
            icon: Icons.map_rounded,
            label: 'Map',
            selected: mode == BoxesViewMode.farmMap,
            onTap: () => onChanged(BoxesViewMode.farmMap),
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  const _ModeBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? CrabSenseColors.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? CrabSenseColors.primary
                      : CrabSenseColors.hintText,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? CrabSenseColors.primary
                        : CrabSenseColors.hintText,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
