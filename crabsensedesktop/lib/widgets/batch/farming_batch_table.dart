import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farming_batch_group.dart';
import '../../models/batch_status.dart';
import '../../theme/dashboard_theme.dart';

enum FarmingBatchAction { view, edit, end, delete }

typedef FarmingBatchCallback = void Function(
  FarmingBatchGroup group,
  FarmingBatchAction action,
);

class FarmingBatchDataTable extends StatelessWidget {
  const FarmingBatchDataTable({
    super.key,
    required this.groups,
    required this.onAction,
  });

  final List<FarmingBatchGroup> groups;
  final FarmingBatchCallback onAction;

  static final _h = GoogleFonts.notoSans(
    color: DashboardColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'Chưa có đợt nuôi phù hợp.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              columnSpacing: 20,
              horizontalMargin: 12,
              dividerThickness: 0.5,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: DashboardColors.cardBorder.withValues(alpha: 0.6),
                ),
              ),
              headingRowColor: WidgetStateProperty.all(
                DashboardColors.darkNavy.withValues(alpha: 0.5),
              ),
              columns: [
                DataColumn(label: Text('MÃ ĐỢT', style: _h)),
                DataColumn(label: Text('SỐ HỘP', style: _h)),
                DataColumn(label: Text('KHU', style: _h)),
                DataColumn(label: Text('DÃY', style: _h)),
                DataColumn(label: Text('BẮT ĐẦU', style: _h)),
                DataColumn(label: Text('DỰ KIẾN THU', style: _h)),
                DataColumn(label: Text('SL BĐ', style: _h), numeric: true),
                DataColumn(label: Text('SL HT', style: _h), numeric: true),
                DataColumn(label: Text('TỶ LỆ SỐNG', style: _h)),
                DataColumn(label: Text('TRẠNG THÁI', style: _h)),
                DataColumn(label: Text('THAO TÁC', style: _h)),
              ],
              rows: groups.map((group) {
                final pct = group.survivalPercent;
                final col = FarmingBatchStatusUi.color(group.status);
                return DataRow(
                  cells: [
                    DataCell(Text(
                      group.batchCode,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                    DataCell(Text(
                      group.boxSummary,
                      style: GoogleFonts.notoSans(fontSize: 12),
                    )),
                    DataCell(Text(group.areaCode)),
                    DataCell(Text(group.rowCode)),
                    DataCell(Text(_fmt(group.startDate))),
                    DataCell(Text(
                      group.expectedHarvestDate != null
                          ? _fmt(group.expectedHarvestDate!)
                          : '—',
                    )),
                    DataCell(Text('${group.totalInitial}')),
                    DataCell(Text('${group.totalCurrent}')),
                    DataCell(_SurvivalBar(percent: pct, color: col)),
                    DataCell(_StatusPill(
                      label: FarmingBatchStatusUi.label(group.status),
                      color: col,
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Xem',
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          onPressed: () =>
                              onAction(group, FarmingBatchAction.view),
                        ),
                        IconButton(
                          tooltip: 'Sửa',
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () =>
                              onAction(group, FarmingBatchAction.edit),
                        ),
                        IconButton(
                          tooltip: 'Kết thúc',
                          icon: Icon(Icons.flag_outlined,
                              size: 18, color: DashboardColors.oceanBlue),
                          onPressed: () =>
                              onAction(group, FarmingBatchAction.end),
                        ),
                        IconButton(
                          tooltip: 'Xóa',
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: DashboardColors.risk),
                          onPressed: () =>
                              onAction(group, FarmingBatchAction.delete),
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _SurvivalBar extends StatelessWidget {
  const _SurvivalBar({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: DashboardColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percent.round()}%',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
