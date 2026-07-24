import 'package:equatable/equatable.dart';

/// Domain entity representing the user's notification preferences.
///
/// Controls per-category notification toggles and device-level
/// display options (sound, vibration, LED indicator).
///
/// Defaults: all categories enabled, all display options enabled.
/// Critical Alerts cannot be disabled by the user (Req 9.1).
///
/// Requirements: 14.9-14.10
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.criticalAlertsEnabled = true,
    this.warningsEnabled = true,
    this.taskRemindersEnabled = true,
    this.systemUpdatesEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.ledIndicatorEnabled = true,
  });

  // ── Per-category toggles ─────────────────────────────────────────────────

  /// Whether Critical Alert notifications are enabled.
  ///
  /// Always `true` by design — critical alerts cannot be disabled by
  /// the user to ensure farm emergencies are always surfaced (Req 9.1).
  final bool criticalAlertsEnabled;

  /// Whether Warning notifications are enabled. (Req 14.9)
  final bool warningsEnabled;

  /// Whether Task Reminder notifications are enabled. (Req 14.9)
  final bool taskRemindersEnabled;

  /// Whether System Update notifications are enabled. (Req 14.9)
  final bool systemUpdatesEnabled;

  // ── Display options ──────────────────────────────────────────────────────

  /// Whether notification sound is enabled. (Req 14.9)
  final bool soundEnabled;

  /// Whether notification vibration is enabled. (Req 14.9)
  final bool vibrationEnabled;

  /// Whether LED indicator is enabled (Android only). (Req 14.9)
  final bool ledIndicatorEnabled;

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns a copy with the given fields replaced.
  ///
  /// [criticalAlertsEnabled] is intentionally excluded — it is always
  /// `true` and cannot be overridden.
  NotificationPreferences copyWith({
    bool? warningsEnabled,
    bool? taskRemindersEnabled,
    bool? systemUpdatesEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? ledIndicatorEnabled,
  }) => NotificationPreferences(
    warningsEnabled: warningsEnabled ?? this.warningsEnabled,
    taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
    systemUpdatesEnabled: systemUpdatesEnabled ?? this.systemUpdatesEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    ledIndicatorEnabled: ledIndicatorEnabled ?? this.ledIndicatorEnabled,
  );

  @override
  List<Object?> get props => [
    criticalAlertsEnabled,
    warningsEnabled,
    taskRemindersEnabled,
    systemUpdatesEnabled,
    soundEnabled,
    vibrationEnabled,
    ledIndicatorEnabled,
  ];

  @override
  String toString() =>
      'NotificationPreferences('
      'criticalAlerts: $criticalAlertsEnabled, '
      'warnings: $warningsEnabled, '
      'taskReminders: $taskRemindersEnabled, '
      'systemUpdates: $systemUpdatesEnabled, '
      'sound: $soundEnabled, '
      'vibration: $vibrationEnabled, '
      'ledIndicator: $ledIndicatorEnabled)';
}
