import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';

class AlertFilterChips extends StatelessWidget {
  const AlertFilterChips({
    required this.activeFilters,
    required this.onToggle,
    required this.onClear,
    super.key,
  });

  final Set<AlertQuickFilter> activeFilters;
  final ValueChanged<AlertQuickFilter> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final showClear =
        !(activeFilters.length == 1 &&
            activeFilters.contains(AlertQuickFilter.all));

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in AlertQuickFilter.values) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected:
                    activeFilters.contains(f) ||
                    (f == AlertQuickFilter.all &&
                        activeFilters.contains(AlertQuickFilter.all)),
                onSelected: (_) => onToggle(f),
                selectedColor: kHomeCyan.withValues(alpha: 0.22),
                backgroundColor: kHomeNavyDeep,
                checkmarkColor: kHomeCyan,
                labelStyle: TextStyle(
                  color: activeFilters.contains(f)
                      ? kHomeCyan
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: activeFilters.contains(f)
                      ? kHomeCyan
                      : kHomeBorderBlue,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
          if (showClear)
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Xóa bộ lọc',
                style: TextStyle(
                  color: kHomeCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
