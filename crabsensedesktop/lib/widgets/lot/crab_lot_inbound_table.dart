import 'package:flutter/material.dart';

import '../../models/crab_lot_status.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';
import '../../utils/app_formatters.dart';
import '../shared/mgmt_ui.dart';
import 'crab_lot_status_badge.dart';

enum CrabLotRowMenu {
  view,
  edit,
  place,
  crabs,
  boxes,
  printSlip,
  cancel,
}

Color lotProgressColor(FarmingBatchRecord lot) {
  final p = lot.allocationPercent;
  if (p >= 100) return DashboardColors.brand;
  if (p >= 50) return kLotBlue;
  if (p >= 1) return kLotAmber;
  return lot.workflowStatus == CrabLotWorkflowStatus.cancelled
      ? DashboardColors.risk
      : kLotSlate;
}

class CrabLotInboundTable extends StatelessWidget {
  const CrabLotInboundTable({
    super.key,
    required this.lots,
    required this.selectedId,
    required this.checkedIds,
    required this.onToggle,
    required this.onToggleAll,
    required this.onSelectRow,
    required this.onOpenCode,
    required this.onView,
    required this.onMenu,
  });

  final List<FarmingBatchRecord> lots;
  final String? selectedId;
  final Set<String> checkedIds;
  final ValueChanged<FarmingBatchRecord> onToggle;
  final VoidCallback onToggleAll;
  final ValueChanged<FarmingBatchRecord> onSelectRow;
  final ValueChanged<FarmingBatchRecord> onOpenCode;
  final ValueChanged<FarmingBatchRecord> onView;
  final void Function(FarmingBatchRecord lot, CrabLotRowMenu action) onMenu;

  bool get _allChecked =>
      lots.isNotEmpty && lots.every((l) => checkedIds.contains(l.id));

  bool get _someChecked => lots.any((l) => checkedIds.contains(l.id));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 58,
                columnSpacing: 14,
                horizontalMargin: 12,
                headingRowColor: const WidgetStatePropertyAll(DashboardColors.lightMint),
                headingTextStyle: bvText(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                showCheckboxColumn: false,
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 28,
                      child: Checkbox(
                        value: _allChecked
                            ? true
                            : _someChecked
                                ? null
                                : false,
                        tristate: true,
                        onChanged: (_) => onToggleAll(),
                        activeColor: DashboardColors.brand,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const DataColumn(label: Text('MÃ LÔ')),
                  const DataColumn(label: Text('TÊN LÔ')),
                  const DataColumn(label: Text('NGÀY NHẬP')),
                  const DataColumn(label: Text('NHÀ CUNG CẤP')),
                  const DataColumn(label: Text('SỐ LƯỢNG'), numeric: true),
                  const DataColumn(label: Text('ĐÃ PHÂN HỘP'), numeric: true),
                  const DataColumn(label: Text('TỶ LỆ')),
                  const DataColumn(label: Text('TRẠNG THÁI')),
                  const DataColumn(label: Text('THAO TÁC')),
                ],
                rows: lots.map(_row).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(FarmingBatchRecord lot) {
    final selected = lot.id == selectedId;
    final checked = checkedIds.contains(lot.id);
    final pct = lot.allocationPercent;
    final color = lotProgressColor(lot);
    return DataRow(
      selected: selected,
      color: WidgetStateProperty.resolveWith((states) {
        if (selected) return DashboardColors.lightMint;
        if (states.contains(WidgetState.hovered)) {
          return DashboardColors.mint.withValues(alpha: 0.35);
        }
        return Colors.white;
      }),
      onSelectChanged: (_) => onSelectRow(lot),
      cells: [
        DataCell(
          Checkbox(
            value: checked,
            onChanged: (_) => onToggle(lot),
            activeColor: DashboardColors.brand,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => onOpenCode(lot),
            child: Text(
              lot.batchCode.isEmpty ? '—' : lot.batchCode,
              style: bvText(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: DashboardColors.brand,
              ),
            ),
          ),
        ),
        DataCell(Text(
          lot.lotName,
          style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
        )),
        DataCell(Text(
          formatDate(lot.startDate),
          style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
        )),
        DataCell(Text(
          (lot.supplierName?.trim().isNotEmpty == true)
              ? lot.supplierName!.trim()
              : '—',
          style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
        )),
        DataCell(Text(
          formatInt(lot.initialQuantity),
          style: bvText(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary,
          ),
        )),
        DataCell(Text(
          formatInt(lot.placedCount),
          style: bvText(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DashboardColors.textPrimary,
          ),
        )),
        DataCell(
          SizedBox(
            width: 88,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pct%',
                  style: bvText(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 3,
                    backgroundColor: DashboardColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(CrabLotStatusBadge(status: lot.workflowStatus)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Xem chi tiết',
                onPressed: () => onView(lot),
                icon: Icon(Icons.visibility_outlined, size: 18, color: DashboardColors.textMuted),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
              ),
              PopupMenuButton<CrabLotRowMenu>(
                tooltip: 'Thao tác',
                padding: EdgeInsets.zero,
                offset: const Offset(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                onSelected: (a) => onMenu(lot, a),
                itemBuilder: (_) => [
                  _item(CrabLotRowMenu.view, 'Xem chi tiết'),
                  _item(CrabLotRowMenu.edit, 'Chỉnh sửa thông tin'),
                  if (lot.workflowStatus.canAllocate)
                    _item(CrabLotRowMenu.place, 'Tiếp tục phân hộp'),
                  _item(CrabLotRowMenu.crabs, 'Xem danh sách cua'),
                  _item(CrabLotRowMenu.boxes, 'Xem hộp đã phân'),
                  _item(CrabLotRowMenu.printSlip, 'In phiếu nhập'),
                  if (lot.workflowStatus.canCancel)
                    const PopupMenuItem(
                      value: CrabLotRowMenu.cancel,
                      height: 38,
                      child: Text(
                        'Hủy lô',
                        style: TextStyle(
                          color: DashboardColors.risk,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
                child: Icon(Icons.more_horiz_rounded, size: 20, color: DashboardColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<CrabLotRowMenu> _item(CrabLotRowMenu v, String label) {
    return PopupMenuItem(
      value: v,
      height: 38,
      child: Text(
        label,
        style: bvText(fontSize: 13, color: DashboardColors.textPrimary),
      ),
    );
  }
}
