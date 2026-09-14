import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_list_item.dart';
import '../../models/crab_condition.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class BoxOverviewCard extends StatelessWidget {
  const BoxOverviewCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onEdit,
    this.onDelete,
    this.onAddCrab,
  });

  final BoxListItem item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddCrab;

  @override
  Widget build(BuildContext context) {
    final occupied = item.hasCrab;
    final condition = item.crabCondition;
    final badge = item.hasAlert ? '⚠️' : (occupied ? condition.emoji : '');

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
                  '📦  ${item.displayName.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badge.isNotEmpty)
                Text(
                  badge,
                  style: const TextStyle(fontSize: 16),
                ),
              _MoreMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          Text(
            item.box.boxCode,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '📍  ${item.placeLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (occupied) ...[
            Text(
              '🦀  ${item.box.crabCount > 1 ? '${item.box.crabCount} cua' : (item.box.crabTag?.trim().isNotEmpty == true ? item.box.crabTag : '1 cua')}',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${condition.emoji}  ${condition.label}',
              style: GoogleFonts.notoSans(
                color: condition.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '🤖  AI: ${item.box.aiSummary?.trim().isNotEmpty == true ? item.box.aiSummary : 'Không có bất thường'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.hasAlert
                  ? '⚠️  Cảnh báo: ${item.box.alertCount}'
                  : '⚠️  Cảnh báo: 0',
              style: GoogleFonts.notoSans(
                color: item.hasAlert
                    ? DashboardColors.warning
                    : DashboardColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              '🦀  Chưa có cua',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚪  Trạng thái: Trống',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: occupied
                ? TextButton(
                    onPressed: onOpen,
                    child: const Text('Xem chi tiết'),
                  )
                : TextButton.icon(
                    onPressed: onAddCrab ?? onOpen,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm cua'),
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
