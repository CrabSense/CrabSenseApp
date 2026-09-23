import 'package:flutter/material.dart';

import '../../../models/crab_lifecycle_event.dart';
import '../../../theme/dashboard_theme.dart';
import '../../shared/mgmt_ui.dart';

class CrabHistoryFilters extends StatelessWidget {
  const CrabHistoryFilters({
    super.key,
    required this.search,
    required this.onSearch,
    required this.type,
    required this.onType,
    required this.period,
    required this.onPeriod,
    required this.from,
    required this.to,
    required this.onPickRange,
    required this.onClear,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final CrabHistoryEventFilter type;
  final ValueChanged<CrabHistoryEventFilter> onType;
  final CrabHistoryPeriod period;
  final ValueChanged<CrabHistoryPeriod> onPeriod;
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: MgmtSearchField(
            controller: search,
            onChanged: onSearch,
            hint: 'Tìm kiếm sự kiện...',
          ),
        ),
        SizedBox(
          width: 180,
          child: MgmtDropdown<CrabHistoryEventFilter>(
            valueLabel: type.label,
            items: [
              for (final f in CrabHistoryEventFilter.values) (f, f.label),
            ],
            onSelected: onType,
          ),
        ),
        SizedBox(
          width: 150,
          child: MgmtDropdown<CrabHistoryPeriod>(
            valueLabel: period.label,
            items: [
              for (final p in CrabHistoryPeriod.values) (p, p.label),
            ],
            onSelected: onPeriod,
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPickRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: DashboardColors.brand),
                  const SizedBox(width: 8),
                  Text(
                    from == null && to == null
                        ? 'Chọn khoảng ngày'
                        : '${fmtDateVn(from)} → ${fmtDateVn(to)}',
                    style: bvText(fontSize: 12.5, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
        MgmtOutlineButton(
          label: 'Xóa lọc',
          icon: Icons.filter_alt_off_outlined,
          onTap: onClear,
        ),
      ],
    );
  }
}
