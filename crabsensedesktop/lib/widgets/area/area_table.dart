import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/area_status.dart';
import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';

typedef AreaRowAction = void Function(AreaRecord area, AreaTableAction action);

enum AreaTableAction { view, edit, delete }

class AreaDataTable extends StatelessWidget {
  const AreaDataTable({
    super.key,
    required this.areas,
    required this.onAction,
  });

  final List<AreaRecord> areas;
  final AreaRowAction onAction;

  static final _headingStyle = GoogleFonts.notoSans(
    color: DashboardColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  static final _cellStyle = GoogleFonts.notoSans(
    color: DashboardColors.textPrimary,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 80,
              columnSpacing: 28,
              horizontalMargin: 16,
              dividerThickness: 0.5,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: DashboardColors.cardBorder.withValues(alpha: 0.6),
                ),
              ),
              headingRowColor: WidgetStateProperty.all(
                DashboardColors.darkNavy.withValues(alpha: 0.5),
              ),
              headingTextStyle: _headingStyle,
              dataTextStyle: _cellStyle,
              columns: [
                DataColumn(label: Text('MÃ KHU', style: _headingStyle)),
                DataColumn(label: Text('TÊN KHU', style: _headingStyle)),
                DataColumn(
                  label: Text('SỐ DÃY', style: _headingStyle),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('SỐ HỘP', style: _headingStyle),
                  numeric: true,
                ),
                DataColumn(label: Text('TRẠNG THÁI', style: _headingStyle)),
                DataColumn(label: Text('NGÀY TẠO', style: _headingStyle)),
                DataColumn(label: Text('THAO TÁC', style: _headingStyle)),
              ],
              rows: areas.map(_row).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(AreaRecord a) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            a.areaCode,
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  a.areaName,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (a.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    a.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text('${a.rowCount}', style: _cellStyle),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text('${a.boxCount}', style: _cellStyle),
          ),
        ),
        DataCell(AreaStatusBadge(status: a.status)),
        DataCell(
          Text(
            a.createdAt != null ? _formatDate(a.createdAt!) : '—',
            style: _cellStyle,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIcon(
                icon: Icons.visibility_outlined,
                tooltip: 'Xem chi tiết',
                onTap: () => onAction(a, AreaTableAction.view),
              ),
              _ActionIcon(
                icon: Icons.edit_outlined,
                tooltip: 'Chỉnh sửa',
                onTap: () => onAction(a, AreaTableAction.edit),
              ),
              _ActionIcon(
                icon: Icons.delete_outline,
                tooltip: 'Xóa',
                color: DashboardColors.risk,
                onTap: () => onAction(a, AreaTableAction.delete),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class AreaStatusBadge extends StatelessWidget {
  const AreaStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final dot = AreaStatusUi.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dot.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dot.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            AreaStatusUi.label(status),
            style: GoogleFonts.notoSans(
              color: dot,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 20,
        color: color ?? DashboardColors.textPrimary.withValues(alpha: 0.85),
      ),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 20,
    );
  }
}
