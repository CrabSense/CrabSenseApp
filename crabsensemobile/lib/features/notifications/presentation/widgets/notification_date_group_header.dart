import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';

/// A horizontal date-group divider with a centred date label.
///
/// Renders as:
///   ──────── Today ────────
///
/// Used between date groups in the notification history list.
///
/// Requirements: 14.6
class NotificationDateGroupHeader extends StatelessWidget {
  const NotificationDateGroupHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        const Expanded(
          child: Divider(color: CrabSenseColors.outlineVariant, thickness: 1, endIndent: 8),
        ),
        Text(
          label,
          style: const TextStyle(
            color: CrabSenseColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const Expanded(
          child: Divider(color: CrabSenseColors.outlineVariant, thickness: 1, indent: 8),
        ),
      ],
    ),
  );
}
