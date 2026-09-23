import 'package:flutter/material.dart';

import '../../models/crab_individual.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/mgmt_ui.dart';
import 'crab_status_badge.dart';

enum CrabManagementAction {
  view,
  edit,
  history,
  viewBox,
  move,
  molt,
  readyHarvest,
  dead,
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
    required this.selectedId,
    required this.checkedIds,
    required this.onToggle,
    required this.onToggleAll,
    required this.onSelectRow,
    this.onOpenCode,
    this.sortColumn,
    this.sortAsc = true,
    this.onSort,
  });

  final List<CrabIndividual> crabs;
  final CrabManagementActionCallback onAction;
  final String? selectedId;
  final Set<String> checkedIds;
  final ValueChanged<CrabIndividual> onToggle;
  final VoidCallback onToggleAll;
  final ValueChanged<CrabIndividual> onSelectRow;
  final ValueChanged<CrabIndividual>? onOpenCode;
  final int? sortColumn;
  final bool sortAsc;
  final void Function(int column, bool asc)? onSort;

  bool get _allChecked =>
      crabs.isNotEmpty && crabs.every((c) => checkedIds.contains(c.id));

  bool get _someChecked => crabs.any((c) => checkedIds.contains(c.id));

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
                dataRowMinHeight: 54,
                dataRowMaxHeight: 62,
                columnSpacing: 14,
                horizontalMargin: 12,
                headingRowColor:
                    const WidgetStatePropertyAll(DashboardColors.lightMint),
                headingTextStyle: bvText(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                showCheckboxColumn: false,
                sortColumnIndex: sortColumn,
                sortAscending: sortAsc,
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
                  DataColumn(
                    label: const Text('MÃ CUA'),
                    onSort: onSort == null ? null : (i, a) => onSort!(i, a),
                  ),
                  const DataColumn(label: Text('LÔ CUA')),
                  const DataColumn(label: Text('DÃY / HỘP')),
                  const DataColumn(label: Text('GIỚI TÍNH')),
                  DataColumn(
                    label: const Text('CÂN NẶNG'),
                    numeric: true,
                    onSort: onSort == null ? null : (i, a) => onSort!(i, a),
                  ),
                  const DataColumn(label: Text('KÍCH THƯỚC')),
                  DataColumn(
                    label: const Text('SỨC KHỎE'),
                    onSort: onSort == null ? null : (i, a) => onSort!(i, a),
                  ),
                  DataColumn(
                    label: const Text('TRẠNG THÁI'),
                    onSort: onSort == null ? null : (i, a) => onSort!(i, a),
                  ),
                  DataColumn(
                    label: const Text('CẬP NHẬT'),
                    onSort: onSort == null ? null : (i, a) => onSort!(i, a),
                  ),
                  const DataColumn(label: Text('THAO TÁC')),
                ],
                rows: crabs.map(_row).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _row(CrabIndividual c) {
    final selected = c.id == selectedId;
    final checked = checkedIds.contains(c.id);
    return DataRow(
      selected: selected,
      color: WidgetStateProperty.resolveWith((states) {
        if (selected) return DashboardColors.lightMint;
        if (states.contains(WidgetState.hovered)) {
          return DashboardColors.mint.withValues(alpha: 0.35);
        }
        return Colors.white;
      }),
      onSelectChanged: (_) => onSelectRow(c),
      cells: [
        DataCell(
          Checkbox(
            value: checked,
            onChanged: (_) => onToggle(c),
            activeColor: DashboardColors.brand,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        DataCell(
          CrabCodeCell(
            code: c.code,
            onTap: () => (onOpenCode ?? onSelectRow)(c),
          ),
        ),
        DataCell(Text(
          c.batchId.trim().isEmpty ? '—' : c.batchId,
          style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
        )),
        DataCell(Text(
          '${c.rowLabel} / ${c.boxLabel}',
          style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
        )),
        DataCell(CrabGenderBadge(gender: c.gender)),
        DataCell(Text(
          c.weightLabel,
          style: bvText(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
        )),
        DataCell(Text(
          c.sizeLabel,
          style: bvText(fontSize: 12.5, color: DashboardColors.textPrimary),
        )),
        DataCell(CrabHealthBadge(status: c.displayHealth)),
        DataCell(CrabLifecycleBadge(status: c.lifecycleStatus)),
        DataCell(Text(
          _stamp(c.lastUpdated),
          style: bvText(fontSize: 12, color: DashboardColors.textMuted),
        )),
        DataCell(_actions(c)),
      ],
    );
  }

  Widget _actions(CrabIndividual c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Xem nhanh',
          onPressed: () => onSelectRow(c),
          icon: Icon(Icons.visibility_outlined, size: 18, color: DashboardColors.textMuted),
          visualDensity: VisualDensity.compact,
          splashRadius: 16,
        ),
        PopupMenuButton<CrabManagementAction>(
          icon: Icon(Icons.more_horiz, color: DashboardColors.textMuted, size: 20),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (a) => onAction(c, a),
          itemBuilder: (_) => [
            _item(CrabManagementAction.view, Icons.visibility_outlined, 'Xem chi tiết'),
            _item(CrabManagementAction.edit, Icons.edit_outlined, 'Cập nhật thông tin'),
            _item(CrabManagementAction.history, Icons.history_rounded, 'Xem lịch sử'),
            _item(CrabManagementAction.viewBox, Icons.inventory_2_outlined, 'Xem hộp hiện tại'),
            _item(CrabManagementAction.move, Icons.swap_horiz_rounded, 'Chuyển hộp'),
            _item(CrabManagementAction.molt, Icons.sync_outlined, 'Đánh dấu lột xác'),
            _item(
              CrabManagementAction.readyHarvest,
              Icons.shopping_basket_outlined,
              'Đánh dấu sắp thu hoạch',
            ),
            _item(
              CrabManagementAction.dead,
              Icons.heart_broken_outlined,
              'Đánh dấu chết',
              danger: true,
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<CrabManagementAction> _item(
    CrabManagementAction value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? DashboardColors.risk : DashboardColors.textPrimary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: danger ? DashboardColors.risk : DashboardColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: bvText(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  String _stamp(DateTime d) {
    final l = d.isUtc ? d.toLocal() : d;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}\n${two(l.hour)}:${two(l.minute)}';
  }
}
