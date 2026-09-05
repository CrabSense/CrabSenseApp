import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/row_list_item.dart';
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

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final item in items)
          ListTile(
            title: Text(item.rowName),
            subtitle: Text('${item.rowCode} · ${item.row.displayBoxes} hộp'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => onAction(item, RowTableActionType.edit),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => onAction(item, RowTableActionType.delete),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
