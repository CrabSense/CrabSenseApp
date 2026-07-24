import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../services/sync_conflict.dart';

/// Interactive modal dialog for manual conflict resolution on simultaneous edits.
///
/// Prompts the user to review the server version and local version side-by-side
/// and choose which version to preserve.
///
/// Requirements: 13.9
class ConflictResolutionDialog extends StatelessWidget {
  const ConflictResolutionDialog({
    required this.conflict,
    super.key,
  });

  /// The conflict object containing local and server versions.
  final SyncConflict conflict;

  /// Displays the conflict resolution dialog and returns the user's selected [ConflictResolutionChoice].
  static Future<ConflictResolutionChoice?> show({
    required BuildContext context,
    required SyncConflict conflict,
  }) async {
    return showDialog<ConflictResolutionChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConflictResolutionDialog(conflict: conflict),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: CrabSenseColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: CrabSenseColors.primary.withValues(alpha: 0.3)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simultaneous Edit Conflict',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: CrabSenseColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Entity: ${conflict.entityType.code} (#${conflict.entityId})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Both you and the server modified this record at the same time. Please choose which version to save.',
              style: theme.textTheme.bodyMedium?.copyWith(color: CrabSenseColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Version Comparison Cards
            Row(
              children: [
                // Server Version Card
                Expanded(
                  child: _VersionCard(
                    title: 'Server Version',
                    icon: Icons.cloud_download_outlined,
                    timestamp: conflict.serverTimestamp,
                    payload: conflict.serverVersion,
                    accentColor: CrabSenseColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Local Version Card
                Expanded(
                  child: _VersionCard(
                    title: 'Local Version',
                    icon: Icons.phone_android_outlined,
                    timestamp: conflict.localTimestamp,
                    payload: conflict.localVersion,
                    accentColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(ConflictResolutionChoice.useLocal),
                    icon: const Icon(Icons.phone_android, size: 18),
                    label: const Text('Keep Local'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(ConflictResolutionChoice.useServer),
                    icon: const Icon(Icons.cloud, size: 18),
                    label: const Text('Keep Server'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrabSenseColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.title,
    required this.icon,
    required this.timestamp,
    required this.payload,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _formatPayload(payload),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: CrabSenseColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPayload(Map<String, dynamic> payload) {
    final buffer = StringBuffer();
    payload.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}
