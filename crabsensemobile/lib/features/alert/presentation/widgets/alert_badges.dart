import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';

class AlertSeverityBadge extends StatelessWidget {
  const AlertSeverityBadge({
    required this.severity,
    this.compact = false,
    super.key,
  });

  final AlertItemSeverity severity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = severity.color;
    return Semantics(
      label: 'Mức độ ${severity.labelVi}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(severity.icon, size: compact ? 12 : 14, color: color),
            const SizedBox(width: 4),
            Text(
              severity.labelVi,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertPriorityBadge extends StatelessWidget {
  const AlertPriorityBadge({required this.priority, super.key});

  final AlertPriorityScore priority;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Điểm ưu tiên ${priority.score}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kHomeNavyDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kHomeBorderBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 13, color: priority.color),
            const SizedBox(width: 3),
            Text(
              'P${priority.score}',
              style: TextStyle(
                color: priority.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertStatusBadge extends StatelessWidget {
  const AlertStatusBadge({required this.status, super.key});

  final AlertLifecycleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
