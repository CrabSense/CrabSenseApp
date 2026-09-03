import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_individual.dart';
import '../../theme/dashboard_theme.dart';
import 'crab_status_badge.dart';

typedef CrabRowAction = void Function(CrabIndividual crab);

class CrabDataTable extends StatelessWidget {
  const CrabDataTable({
    super.key,
    required this.crabs,
    required this.onView,
    this.onHealth,
  });

  final List<CrabIndividual> crabs;
  final CrabRowAction onView;
  final CrabRowAction? onHealth;

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
              dataRowMinHeight: 52,
              dataRowMaxHeight: 96,
              columnSpacing: 20,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
              columns: const [
                DataColumn(label: Text('MÃ CUA')),
                DataColumn(label: Text('HỘP / LỨA')),
                DataColumn(label: Text('CHI TIẾT')),
                DataColumn(label: Text('LỘT XÁC')),
                DataColumn(label: Text('SỨC KHỎE')),
                DataColumn(label: Text('TRẠNG THÁI')),
                DataColumn(label: Text('THAO TÁC')),
              ],
              rows: crabs.map(_row).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(CrabIndividual c) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, size: 16, color: DashboardColors.cyan.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                c.id,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.cyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hộp: ${c.boxId}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.cyan,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
              Text(
                'Lứa: ${c.batchId}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
            ),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GIỚI TÍNH',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 8,
                  height: 1.0,
                ),
              ),
              Text(
                c.gender.label,
                style: GoogleFonts.notoSans(fontSize: 11, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'TRỌNG LƯỢNG',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 8,
                  height: 1.0,
                ),
              ),
              Text(
                '${c.weightGram.toStringAsFixed(0)}g',
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
            ),
          ),
        ),
        DataCell(Text('${c.moltCount} lần')),
        DataCell(CrabHealthBadge(status: c.healthStatus)),
        DataCell(CrabLifeBadge(status: c.lifeStatus)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onView(c),
                tooltip: 'Xem hồ sơ',
                icon: const Icon(Icons.visibility_outlined, size: 18),
                color: DashboardColors.textMuted,
              ),
              if (onHealth != null)
                IconButton(
                  onPressed: () => onHealth!(c),
                  tooltip: 'Health Monitoring',
                  icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                  color: DashboardColors.cyan,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
