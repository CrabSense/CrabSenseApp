import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/dashboard_summary.dart';

/// A single row in the video-task list displayed on the dashboard.
///
/// Shows:
/// - Box identifier / QR code label
/// - Farm name
/// - Scheduled capture time
/// - An "overdue" badge when [VideoTask.isOverdue] is true
///
/// Requirements: 2.3
class VideoTaskItem extends StatelessWidget {
  const VideoTaskItem({required this.task, super.key, this.onTap});

  /// The video-capture task to render.
  final VideoTask task;

  /// Optional tap callback (e.g. navigate to video capture screen).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task.isOverdue
                    ? CrabSenseColors.error.withValues(alpha: 0.15)
                    : CrabSenseColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.videocam_outlined,
                size: 20,
                color: task.isOverdue ? CrabSenseColors.error : CrabSenseColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            // ── Text ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.boxIdentifier,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.farmName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CrabSenseColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Overdue badge / scheduled time ────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (task.isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CrabSenseColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Overdue',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: CrabSenseColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(task.scheduledAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Formats a [DateTime] as HH:mm.
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
