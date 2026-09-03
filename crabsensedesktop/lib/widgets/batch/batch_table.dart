import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_batch.dart';
import '../../theme/dashboard_theme.dart';
import 'batch_status_badge.dart';

typedef BatchRowAction = void Function(CrabBatch batch, BatchAction action);

enum BatchAction { view, edit, stats, end }

class BatchDataTable extends StatelessWidget {
  const BatchDataTable({
    super.key,
    required this.batches,
    required this.onAction,
  });

  final List<CrabBatch> batches;
  final BatchRowAction onAction;

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
              dataRowMaxHeight: 64,
              columnSpacing: 24,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              dataTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 13,
              ),
              columns: const [
                DataColumn(label: Text('MÃ LỨA')),
                DataColumn(label: Text('NGÀY THẢ')),
                DataColumn(label: Text('CÒN SỐNG')),
                DataColumn(label: Text('TỶ LỆ SỐNG')),
                DataColumn(label: Text('TRẠNG THÁI')),
                DataColumn(label: Text('THAO TÁC')),
              ],
              rows: batches.map((b) => _row(b)).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(CrabBatch b) {
    final rate = b.survivalRate;
    final barColor = rate >= 95
        ? DashboardColors.healthy
        : rate >= 85
            ? DashboardColors.monitoring
            : DashboardColors.risk;

    return DataRow(
      cells: [
        DataCell(
          Text(
            b.id,
            style: GoogleFonts.notoSans(
              color: DashboardColors.cyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(Text(_formatDate(b.releaseDate))),
        DataCell(Text('${_formatNum(b.aliveCount)} con')),
        DataCell(
          Row(
            children: [
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate / 100,
                    minHeight: 6,
                    backgroundColor: DashboardColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${rate.toStringAsFixed(0)}%'),
            ],
          ),
        ),
        DataCell(BatchStatusBadge(status: b.status)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIcon(
                icon: Icons.visibility_outlined,
                tooltip: 'Xem chi tiết',
                onTap: () => onAction(b, BatchAction.view),
              ),
              _ActionIcon(
                icon: Icons.edit_outlined,
                tooltip: 'Chỉnh sửa',
                onTap: () => onAction(b, BatchAction.edit),
              ),
              _ActionIcon(
                icon: Icons.bar_chart_outlined,
                tooltip: 'Thống kê',
                onTap: () => onAction(b, BatchAction.stats),
              ),
              _ActionIcon(
                icon: Icons.flag_outlined,
                tooltip: 'Kết thúc lứa',
                onTap: () => onAction(b, BatchAction.end),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatNum(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return n.toString();
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: DashboardColors.textMuted),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
