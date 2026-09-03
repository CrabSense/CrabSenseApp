import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_crab_data.dart';
import '../../models/crab_individual.dart';
import '../../theme/dashboard_theme.dart';
import 'crab_status_badge.dart';

enum CrabManagementAction {
  view,
  edit,
  recordHealth,
  recordMolt,
  recordDead,
  recordHarvest,
  delete,
}

typedef CrabManagementActionCallback = void Function(
  CrabIndividual crab,
  CrabManagementAction action,
);

class CrabManagementDataTable extends StatelessWidget {
  const CrabManagementDataTable({
    super.key,
    required this.crabs,
    required this.onAction,
  });

  final List<CrabIndividual> crabs;
  final CrabManagementActionCallback onAction;

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
              dataRowMaxHeight: 72,
              columnSpacing: 16,
              headingTextStyle: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              columns: const [
                DataColumn(label: Text('MÃ CUA')),
                DataColumn(label: Text('ĐỢT NUÔI')),
                DataColumn(label: Text('KHU')),
                DataColumn(label: Text('DÃY')),
                DataColumn(label: Text('HỘP')),
                DataColumn(label: Text('GIỚI TÍNH')),
                DataColumn(label: Text('CÂN NẶNG')),
                DataColumn(label: Text('KÍCH THƯỚC MAI')),
                DataColumn(label: Text('LỘT XÁC')),
                DataColumn(label: Text('SỨC KHỎE')),
                DataColumn(label: Text('TRẠNG THÁI')),
                DataColumn(label: Text('CẬP NHẬT')),
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
        DataCell(_codeCell(c)),
        DataCell(Text(c.batchId, style: _cellStyle())),
        DataCell(Text(c.areaName, style: _cellStyle())),
        DataCell(Text(c.rowName, style: _cellStyle())),
        DataCell(Text(c.boxLabel, style: _cellStyle())),
        DataCell(_genderChip(c.gender.label)),
        DataCell(Text('${c.weightGram.toStringAsFixed(0)}g', style: _cellStyle(bold: true))),
        DataCell(Text('${c.shellSizeCm.toStringAsFixed(1)} cm', style: _cellStyle())),
        DataCell(Text('${c.moltCount}', style: _cellStyle())),
        DataCell(CrabHealthBadge(status: c.healthStatus)),
        DataCell(CrabOperationalBadge(status: c.operationalStatus)),
        DataCell(Text(_relativeUpdate(c.lastUpdated), style: _cellStyle(muted: true))),
        DataCell(_actions(c)),
      ],
    );
  }

  Widget _codeCell(CrabIndividual c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: DashboardColors.oceanBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.pets, size: 16, color: DashboardColors.oceanBlue),
        ),
        const SizedBox(width: 8),
        Text(
          c.code,
          style: GoogleFonts.notoSans(
            color: DashboardColors.oceanBlue,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _genderChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DashboardColors.cardBorder.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: GoogleFonts.notoSans(fontSize: 11)),
    );
  }

  Widget _actions(CrabIndividual c) {
    return PopupMenuButton<CrabManagementAction>(
      icon: Icon(Icons.more_horiz, color: DashboardColors.textMuted, size: 20),
      color: DashboardColors.card,
      onSelected: (a) => onAction(c, a),
      itemBuilder: (_) => [
        _menuItem(CrabManagementAction.view, Icons.visibility_outlined, 'Xem chi tiết'),
        _menuItem(CrabManagementAction.edit, Icons.edit_outlined, 'Chỉnh sửa'),
        _menuItem(CrabManagementAction.recordHealth, Icons.monitor_heart_outlined, 'Ghi nhận sức khỏe'),
        _menuItem(CrabManagementAction.recordMolt, Icons.sync_outlined, 'Ghi nhận lột xác'),
        _menuItem(CrabManagementAction.recordDead, Icons.heart_broken_outlined, 'Ghi nhận chết'),
        _menuItem(CrabManagementAction.recordHarvest, Icons.shopping_basket_outlined, 'Ghi nhận thu hoạch'),
        const PopupMenuDivider(),
        _menuItem(CrabManagementAction.delete, Icons.delete_outline, 'Xóa', danger: true),
      ],
    );
  }

  PopupMenuItem<CrabManagementAction> _menuItem(
    CrabManagementAction value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: danger ? DashboardColors.risk : DashboardColors.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: danger ? DashboardColors.risk : DashboardColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _cellStyle({bool bold = false, bool muted = false}) {
    return GoogleFonts.notoSans(
      color: muted ? DashboardColors.textMuted : DashboardColors.textPrimary,
      fontSize: 12,
      fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
    );
  }

  String _relativeUpdate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} Hôm nay';
    }
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return MockCrabData.formatDate(d);
  }
}
