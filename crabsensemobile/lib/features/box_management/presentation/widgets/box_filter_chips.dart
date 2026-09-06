import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
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
    final hasActive = !activeFilters.contains(BoxQuickFilter.all) ||
        activeFilters.length > 1;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...BoxQuickFilter.values.map((filter) {
            final selected = activeFilters.contains(filter) ||
                (filter == BoxQuickFilter.all &&
                    activeFilters.length == 1 &&
                    activeFilters.contains(BoxQuickFilter.all));
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                label: Text(filter.label),
                onSelected: (_) => onToggle(filter),
                selectedColor: kHomeBlue.withValues(alpha: 0.22),
                backgroundColor: kHomeBg.withValues(alpha: 0.75),
                checkmarkColor: kHomeBlueLight,
                labelStyle: TextStyle(
                  color: selected
                      ? kHomeBlueLight
                      : const Color(0xFF5A7184),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected
                      ? kHomeBlue.withValues(alpha: 0.8)
                      : kHomeBorderBlue.withValues(alpha: 0.4),
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
                foregroundColor: Colors.redAccent,
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
        color: kHomeBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          _ModeBtn(
            icon: Icons.grid_view_rounded,
            label: 'Lưới',
            selected: mode == BoxesViewMode.grid,
            onTap: () => onChanged(BoxesViewMode.grid),
          ),
          _ModeBtn(
            icon: Icons.view_list_rounded,
            label: 'Danh sách',
            selected: mode == BoxesViewMode.list,
            onTap: () => onChanged(BoxesViewMode.list),
          ),
          _ModeBtn(
            icon: Icons.map_rounded,
            label: 'Bản đồ',
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
        color: selected ? kHomeBlue.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 40,
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kHomeBlue.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kHomeBlue.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? kHomeBlueLight
                      : const Color(0xFF5A7184),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? kHomeBlueLight
                          : const Color(0xFF5A7184),
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
