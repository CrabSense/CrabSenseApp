import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_lot_status.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';
import 'crab_lot_status_badge.dart';

enum CrabLotInboundAction { view, place, cancel }

typedef CrabLotInboundCallback = void Function(
  FarmingBatchRecord lot,
  CrabLotInboundAction action,
);

class CrabLotInboundTable extends StatelessWidget {
  const CrabLotInboundTable({
    super.key,
    required this.lots,
    required this.onAction,
  });

  final List<FarmingBatchRecord> lots;
  final CrabLotInboundCallback onAction;

  String _date(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String _kg(double? kg) => kg == null ? '—' : '${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)} kg';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 68,
              columnSpacing: 20,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              columns: const [
                DataColumn(label: Text('MÃ LÔ')),
                DataColumn(label: Text('TÊN LÔ')),
                DataColumn(label: Text('NGÀY NHẬP')),
                DataColumn(label: Text('SỐ LƯỢNG')),
                DataColumn(label: Text('TỔNG KL')),
                DataColumn(label: Text('NHÀ CUNG CẤP')),
                DataColumn(label: Text('TRẠNG THÁI')),
                DataColumn(label: Text('THAO TÁC')),
              ],
              rows: lots.map(_row).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(FarmingBatchRecord lot) {
    final cell = GoogleFonts.notoSans(
      color: DashboardColors.textPrimary,
      fontSize: 13,
    );
    final muted = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 12,
    );
    final placed = lot.placedCount;
    final qty = lot.initialQuantity;
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => onAction(lot, CrabLotInboundAction.view),
            child: Text(
              lot.batchCode,
              style: cell.copyWith(
                fontWeight: FontWeight.w700,
                color: DashboardColors.oceanBlue,
              ),
            ),
          ),
        ),
        DataCell(Text(lot.name?.trim().isNotEmpty == true ? lot.name! : lot.batchCode, style: cell)),
        DataCell(Text(_date(lot.startDate), style: cell)),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$qty con', style: cell),
              Text('Đã thả $placed/$qty', style: muted),
            ],
          ),
        ),
        DataCell(Text(_kg(lot.totalWeightKg), style: cell)),
        DataCell(Text(lot.supplierName?.trim().isNotEmpty == true ? lot.supplierName! : '—', style: cell)),
        DataCell(CrabLotStatusBadge(status: lot.workflowStatus)),
        DataCell(
          PopupMenuButton<CrabLotInboundAction>(
            tooltip: 'Thao tác',
            onSelected: (a) => onAction(lot, a),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CrabLotInboundAction.view,
                child: Text('Xem chi tiết'),
              ),
              if (lot.workflowStatus != CrabLotWorkflowStatus.cancelled &&
                  lot.workflowStatus != CrabLotWorkflowStatus.completed)
                const PopupMenuItem(
                  value: CrabLotInboundAction.place,
                  child: Text('Phân cua vào hộp'),
                ),
              if (lot.workflowStatus != CrabLotWorkflowStatus.cancelled &&
                  lot.workflowStatus != CrabLotWorkflowStatus.completed)
                const PopupMenuItem(
                  value: CrabLotInboundAction.cancel,
                  child: Text('Hủy lô'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
