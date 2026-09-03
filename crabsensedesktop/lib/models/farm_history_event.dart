import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum HistoryEventType { warning, info, maintenance, environment }

enum HistoryPriority { urgent, normal }

class FarmHistoryEvent {
  const FarmHistoryEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.dateGroup,
    required this.location,
    required this.description,
    required this.type,
    this.priority = HistoryPriority.normal,
    this.tags = const [],
    this.performer,
  });

  final String id;
  final String title;
  final String time;
  final String dateGroup;
  final String location;
  final String description;
  final HistoryEventType type;
  final HistoryPriority priority;
  final List<String> tags;
  final String? performer;
}

extension HistoryEventTypeX on HistoryEventType {
  Color get borderColor => switch (this) {
        HistoryEventType.warning => const Color(0xFFFF6B8A),
        HistoryEventType.info => DashboardColors.cyan,
        HistoryEventType.maintenance => DashboardColors.blue,
        HistoryEventType.environment => DashboardColors.purple,
      };

  String get label => switch (this) {
        HistoryEventType.warning => 'Cảnh báo',
        HistoryEventType.info => 'Thông tin',
        HistoryEventType.maintenance => 'Bảo trì',
        HistoryEventType.environment => 'Môi trường',
      };
}
