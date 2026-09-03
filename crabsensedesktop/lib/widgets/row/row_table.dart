import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/row_list_item.dart';
import '../../models/row_status.dart';
import '../../theme/dashboard_theme.dart';

typedef RowTableAction = void Function(RowListItem item, RowTableActionType type);

enum RowTableActionType { edit, delete }

class RowDataTable extends StatelessWidget {
  const RowDataTable({
    super.key,
    required this.items,
    required this.onAction,
  });

  final List<RowListItem> items;
  final RowTableAction onAction;

  static final _heading = GoogleFonts.notoSans(
    color: DashboardColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dãy phù hợp bộ lọc.',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 72,
              columnSpacing: 24,
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
                DataColumn(label: Text('MÃ DÃY', style: _heading)),
                DataColumn(label: Text('TÊN DÃY', style: _heading)),
                DataColumn(label: Text('THUỘC KHU', style: _heading)),
                DataColumn(
                  label: Text('SỐ HỘP', style: _heading),
                  numeric: true,
                ),
                DataColumn(label: Text('THIẾT BỊ', style: _heading)),
                DataColumn(label: Text('TRẠNG THÁI', style: _heading)),
                DataColumn(label: Text('NGÀY TẠO', style: _heading)),
                DataColumn(label: Text('THAO TÁC', style: _heading)),
              ],
              rows: items.map(_row).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(RowListItem item) {
    final statusColor = RowStatusUi.color(item.status);
    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DashboardColors.darkNavy,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DashboardColors.cardBorder),
            ),
            child: Text(
              item.rowCode,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            item.rowName,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Text(
            item.areaName,
            style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
          ),
        ),
        DataCell(
          Text(
            '${item.boxCount} BOXES',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(_DeviceIcons(
          esp32: item.esp32Count,
          cameras: item.cameraCount,
        )),
        DataCell(_StatusPill(
          label: RowStatusUi.label(item.status),
          color: statusColor,
        )),
        const DataCell(Text('—')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Sửa',
                onPressed: () => onAction(item, RowTableActionType.edit),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: DashboardColors.textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Xóa',
                onPressed: () => onAction(item, RowTableActionType.delete),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: DashboardColors.risk.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceIcons extends StatelessWidget {
  const _DeviceIcons({required this.esp32, required this.cameras});

  final int esp32;
  final int cameras;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(Icons.router_outlined, esp32),
        const SizedBox(width: 10),
        _chip(Icons.videocam_outlined, cameras),
      ],
    );
  }

  Widget _chip(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: DashboardColors.textMuted),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
