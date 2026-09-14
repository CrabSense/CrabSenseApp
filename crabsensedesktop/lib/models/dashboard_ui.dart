import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

class KpiItem {
  const KpiItem({
    required this.label,
    required this.value,
    this.color,
    this.badge,
  });

  final String label;
  final String value;
  final Color? color;
  final String? badge;
}

class StatusSegment {
  const StatusSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class EnvParameter {
  const EnvParameter({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final ParamStatus status;
}

class AlertItem {
  const AlertItem({required this.message, this.severity = ParamStatus.warning});

  final String message;
  final ParamStatus severity;
}
