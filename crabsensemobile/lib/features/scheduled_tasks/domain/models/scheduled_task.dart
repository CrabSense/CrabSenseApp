class ScheduledTask {
  const ScheduledTask({
    required this.id,
    required this.title,
    this.description,
    this.farmingAreaId,
    required this.recurrenceType,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.reminderMinuteOfDay,
    required this.isEnabled,
    this.nextRunAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? farmingAreaId;
  final String recurrenceType;
  final List<int> daysOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final int reminderMinuteOfDay;
  final bool isEnabled;
  final DateTime? nextRunAt;

  factory ScheduledTask.fromJson(Map<String, dynamic> json) => ScheduledTask(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        description: json['description']?.toString(),
        farmingAreaId: json['farmingAreaId']?.toString(),
        recurrenceType: '${json['recurrenceType'] ?? 'once'}',
        daysOfWeek: (json['daysOfWeek'] as List?)
                ?.whereType<num>()
                .map((day) => day.toInt())
                .toList() ??
            const [],
        startDate: DateTime.tryParse('${json['startDate']}') ??
            DateTime.now(),
        endDate: json['endDate'] == null
            ? null
            : DateTime.tryParse('${json['endDate']}'),
        reminderMinuteOfDay:
            (json['reminderMinuteOfDay'] as num?)?.toInt() ?? 420,
        isEnabled: json['isEnabled'] as bool? ?? true,
        nextRunAt: json['nextRunAt'] == null
            ? null
            : DateTime.tryParse('${json['nextRunAt']}'),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'farmingAreaId': farmingAreaId,
        'recurrenceType': recurrenceType,
        'daysOfWeek': daysOfWeek,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'reminderMinuteOfDay': reminderMinuteOfDay,
        'isEnabled': isEnabled,
      };
}
