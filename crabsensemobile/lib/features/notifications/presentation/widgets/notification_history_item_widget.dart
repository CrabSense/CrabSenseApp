import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';
import '../../../../../shared/services/notification_service.dart';
import '../../domain/entities/notification_history_item.dart';

/// Widget that displays a single notification history item.
///
/// Shows the category icon (colour-coded), title, body, and a relative
/// timestamp. Read items are rendered at reduced opacity.
///
/// Requirements: 14.6
class NotificationHistoryItemWidget extends StatelessWidget {
  const NotificationHistoryItemWidget({required this.item, super.key, this.onTap});

  final NotificationHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: item.isRead ? 0.7 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: CrabSenseColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? CrabSenseColors.outlineVariant
                  : CrabSenseColors.primary.withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category icon ─────────────────────────────────────
              _CategoryIcon(category: item.category),
              const SizedBox(width: 12),

              // ── Text content ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: CrabSenseColors.textPrimary,
                        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Message body
                    Text(
                      item.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CrabSenseColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      _formatTimestamp(item.receivedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: CrabSenseColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Unread dot ────────────────────────────────────────
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CrabSenseColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats [receivedAt] as a relative or absolute string.
  ///
  /// - < 1 min ago  → "Just now"
  /// - < 60 min     → "X min ago"
  /// - < 24 h       → "X hr ago" / "HH:mm"
  /// - older        → "HH:mm" (date shown in the group header)
  String _formatTimestamp(DateTime receivedAt) {
    final now = DateTime.now();
    final diff = now.difference(receivedAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';

    // Older: show time only (date is shown in the group header)
    final h = receivedAt.hour.toString().padLeft(2, '0');
    final m = receivedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Private category icon ─────────────────────────────────────────────────────

/// Coloured rounded icon that represents the notification category.
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final (iconData, color) = _iconAndColor(category);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, size: 20, color: color),
    );
  }

  /// Maps a [NotificationCategory] constant to an icon + colour pair.
  (IconData, Color) _iconAndColor(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return (Icons.warning_rounded, CrabSenseColors.error);
      case NotificationCategory.warning:
        return (Icons.info_rounded, CrabSenseColors.warning);
      case NotificationCategory.taskReminder:
        return (Icons.task_rounded, CrabSenseColors.primary);
      case NotificationCategory.systemUpdate:
        return (Icons.system_update_rounded, CrabSenseColors.textSecondary);
      default:
        return (Icons.notifications_rounded, CrabSenseColors.textSecondary);
    }
  }
}
