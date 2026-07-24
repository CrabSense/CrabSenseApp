/// Public reusable alert card widget for the CrabSense alert feature.
///
/// Extracted from the alert screen so it can be reused across other screens
/// such as the dashboard alert summary.
///
/// Requirements: 9.5, 9.6
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_enums.dart';
import '../bloc/alert_bloc.dart';
import '../bloc/alert_event.dart';

/// A standalone, reusable card that displays a single [Alert].
///
/// Shows the alert type icon with severity colour, a left-side severity
/// colour bar, title, status badge, type label, timestamp, message,
/// recommended action chips, and — when the alert is still active —
/// Acknowledge and Dismiss action buttons.
///
/// Navigation on card tap:
/// - [AlertType.waterQuality] → [RoutePaths.waterQuality]
/// - [AlertType.crabHealth], [AlertType.equipment],
///   [AlertType.maintenance] with a non-null [Alert.sourceId]
///   → [RoutePaths.boxDetails]
/// - [AlertType.task] → stays on [RoutePaths.alerts] (no-op)
/// - [AlertType.system] → no navigation
/// - Default when sourceId is null → no navigation
///
/// Requirements: 9.5, 9.6
class AlertCard extends StatelessWidget {
  const AlertCard({required this.alert, super.key, this.isProcessing = false});

  final Alert alert;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _severityColor(alert.severity);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: CrabSenseColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CrabSenseColors.primary.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Severity colour bar (4px) ─────────────────────────
              Container(width: 4, color: severityColor),

              // ── Card content ──────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: type icon + title + status badge
                      Row(
                        children: [
                          Icon(
                            _typeIcon(alert.type),
                            size: 16,
                            color: severityColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              alert.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: CrabSenseColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: alert.status),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Type label + timestamp row
                      Row(
                        children: [
                          Text(
                            alert.type.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: severityColor.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: CrabSenseColors.textDisabled,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(alert.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: CrabSenseColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Message (2 lines max)
                      Text(
                        alert.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Recommended actions chips (max 3)
                      if (alert.recommendedActions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: alert.recommendedActions
                              .take(3)
                              .map((action) => _ActionChip(label: action))
                              .toList(),
                        ),
                      ],

                      // Action buttons (only when alert is active)
                      if (alert.isActive) ...[
                        const SizedBox(height: 10),
                        _AlertActions(alert: alert, isProcessing: isProcessing),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  void _handleTap(BuildContext context) {
    switch (alert.type) {
      case AlertType.waterQuality:
        context.go(RoutePaths.waterQuality);
      case AlertType.crabHealth:
      case AlertType.equipment:
      case AlertType.maintenance:
        final sourceId = alert.sourceId;
        if (sourceId != null) {
          context.go(RoutePaths.boxDetails(sourceId));
        }
      case AlertType.task:
        // Already on the alerts screen — no navigation needed.
        break;
      case AlertType.system:
        // System alerts have no navigable target.
        break;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return CrabSenseColors.error;
      case AlertSeverity.warning:
        return CrabSenseColors.warning;
      case AlertSeverity.info:
        return CrabSenseColors.info;
    }
  }

  IconData _typeIcon(AlertType type) {
    switch (type) {
      case AlertType.waterQuality:
        return Icons.water_drop_outlined;
      case AlertType.equipment:
        return Icons.build_outlined;
      case AlertType.crabHealth:
        return Icons.pets_outlined;
      case AlertType.maintenance:
        return Icons.handyman_outlined;
      case AlertType.task:
        return Icons.assignment_outlined;
      case AlertType.system:
        return Icons.settings_outlined;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Alert actions ─────────────────────────────────────────────────────────────

/// Acknowledge / Dismiss action row shown when the alert is still active.
///
/// Shows a [CircularProgressIndicator] while [isProcessing] is true.
/// The Acknowledge button is only rendered when [Alert.status] is
/// [AlertStatus.unread] or [AlertStatus.read].
///
/// Requirements: 9.6
class _AlertActions extends StatelessWidget {
  const _AlertActions({required this.alert, required this.isProcessing});

  final Alert alert;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(CrabSenseColors.primary),
          ),
        ),
      );
    }

    final canAcknowledge =
        alert.status == AlertStatus.unread || alert.status == AlertStatus.read;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canAcknowledge)
          _ActionButton(
            label: 'Acknowledge',
            icon: Icons.check_circle_outline,
            color: CrabSenseColors.success,
            onTap: () => _acknowledge(context),
          ),
        if (canAcknowledge) const SizedBox(width: 8),
        _ActionButton(
          label: 'Dismiss',
          icon: Icons.close,
          color: CrabSenseColors.textSecondary,
          onTap: () => _dismiss(context),
        ),
      ],
    );
  }

  void _acknowledge(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : 'unknown';

    context.read<AlertBloc>().add(
      AlertAcknowledgeRequested(alertId: alert.id, acknowledgedBy: userId),
    );
  }

  void _dismiss(BuildContext context) {
    context.read<AlertBloc>().add(AlertDismissRequested(alertId: alert.id));
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Status badge ──────────────────────────────────────────────────────────────

/// Small coloured badge showing the alert's current [AlertStatus].
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AlertStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AlertStatus.unread => (CrabSenseColors.error, 'Unread'),
      AlertStatus.read => (CrabSenseColors.textSecondary, 'Read'),
      AlertStatus.acknowledged => (CrabSenseColors.success, 'Acknowledged'),
      AlertStatus.dismissed => (CrabSenseColors.textDisabled, 'Dismissed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ── Action chip ───────────────────────────────────────────────────────────────

/// Small chip representing a single recommended action string.
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: CrabSenseColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: CrabSenseColors.primary.withValues(alpha: 0.25),
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: CrabSenseColors.primary,
        fontSize: 10,
        fontFamily: 'Inter',
      ),
    ),
  );
}
