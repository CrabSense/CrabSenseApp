import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/row_list_item.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class RowOverviewCard extends StatelessWidget {
  const RowOverviewCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onEdit,
    this.onDelete,
  });

  final RowListItem item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final row = item.row;
    final hasAlert = row.alertBoxCount > 0;
    return GlassCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '📚  ${row.rowName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${row.status.emoji}  ${row.status.label}',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _MoreMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          Text(
            row.rowCode,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '📦  ${row.boxCount} Hộp',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                '🦀  ${row.crabCount} cua trong hộp',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasAlert
                ? '⚠️  ${row.alertBoxCount} Cảnh báo'
                : '🟢  Bình thường',
            style: GoogleFonts.notoSans(
              color: hasAlert ? DashboardColors.warning : DashboardColors.healthy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Xem chi tiết'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onEdit, this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Thao tác',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 20, color: DashboardColors.textMuted),
      color: DashboardColors.card,
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Text('Xóa', style: TextStyle(color: DashboardColors.risk)),
          ),
      ],
    );
  }
}

Future<void> showRowDetailDialog(
  BuildContext context, {
  required RowListItem item,
  required VoidCallback onEdit,
  VoidCallback? onDelete,
}) {
  final row = item.row;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '📚  ${row.rowName}',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${row.status.emoji}  ${row.status.label}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              row.rowCode,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
            if (row.location?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                '📍  ${row.displayLocation}',
                style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DetailStat(emoji: '📦', label: 'Tổng hộp', value: '${row.boxCount}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetailStat(emoji: '🦀', label: 'Cua trong hộp', value: '${row.crabCount}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DetailStat(
                    emoji: '🟢',
                    label: 'Hộp bình thường',
                    value: '${row.healthyBoxCount}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetailStat(
                    emoji: '⚠️',
                    label: 'Hộp cảnh báo',
                    value: '${row.alertBoxCount}',
                    warn: row.alertBoxCount > 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onEdit();
          },
          child: const Text('Sửa'),
        ),
        if (onDelete != null)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text('Xóa', style: TextStyle(color: DashboardColors.risk)),
          ),
      ],
    ),
  );
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.emoji,
    required this.label,
    required this.value,
    this.warn = false,
  });

  final String emoji;
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji  $label',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoSans(
              color: warn ? DashboardColors.warning : DashboardColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
