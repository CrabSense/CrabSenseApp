import 'package:hive/hive.dart';

import '../../domain/entities/notification_preferences.dart';

// ── Hive storage keys ────────────────────────────────────────────────────────

/// Name of the Hive box used to store notification preferences.
const String kNotifPrefsBoxName = 'notification_preferences';

/// Individual Hive keys for each preference field.
const String kKeyCriticalAlerts = 'critical_alerts_enabled';
const String kKeyWarnings = 'warnings_enabled';
const String kKeyTaskReminders = 'task_reminders_enabled';
const String kKeySystemUpdates = 'system_updates_enabled';
const String kKeySound = 'sound_enabled';
const String kKeyVibration = 'vibration_enabled';
const String kKeyLedIndicator = 'led_indicator_enabled';

// ── Abstract interface ───────────────────────────────────────────────────────

/// Contract for local notification-preference storage.
///
/// Requirements: 14.9-14.10
abstract class NotificationPreferencesLocalDataSource {
  /// Returns stored preferences, or defaults if nothing is saved yet.
  Future<NotificationPreferences> getPreferences();

  /// Persists all fields of [prefs] to local storage.
  Future<void> savePreferences(NotificationPreferences prefs);
}

// ── Hive implementation ──────────────────────────────────────────────────────

/// [NotificationPreferencesLocalDataSource] backed by a Hive box.
///
/// Each preference is stored as a separate key so reads are fast and
/// partial writes are safe. The box must be opened before this
/// class is used (typically during app initialisation in `main.dart`).
///
/// Requirements: 14.9-14.10
class NotificationPreferencesLocalDataSourceImpl implements NotificationPreferencesLocalDataSource {
  NotificationPreferencesLocalDataSourceImpl({required this.box});

  /// The open Hive box for notification preferences.
  final Box<dynamic> box;

  // ── NotificationPreferencesLocalDataSource ───────────────────────────────

  @override
  Future<NotificationPreferences> getPreferences() async {
    // Read each key, falling back to the entity default when absent.
    return NotificationPreferences(
      criticalAlertsEnabled: _readBool(kKeyCriticalAlerts, defaultValue: true),
      warningsEnabled: _readBool(kKeyWarnings, defaultValue: true),
      taskRemindersEnabled: _readBool(kKeyTaskReminders, defaultValue: true),
      systemUpdatesEnabled: _readBool(kKeySystemUpdates, defaultValue: true),
      soundEnabled: _readBool(kKeySound, defaultValue: true),
      vibrationEnabled: _readBool(kKeyVibration, defaultValue: true),
      ledIndicatorEnabled: _readBool(kKeyLedIndicator, defaultValue: true),
    );
  }

  @override
  Future<void> savePreferences(NotificationPreferences prefs) async {
    // Critical alerts are always true — persist the canonical value.
    await box.put(kKeyCriticalAlerts, true);
    await box.put(kKeyWarnings, prefs.warningsEnabled);
    await box.put(kKeyTaskReminders, prefs.taskRemindersEnabled);
    await box.put(kKeySystemUpdates, prefs.systemUpdatesEnabled);
    await box.put(kKeySound, prefs.soundEnabled);
    await box.put(kKeyVibration, prefs.vibrationEnabled);
    await box.put(kKeyLedIndicator, prefs.ledIndicatorEnabled);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  bool _readBool(String key, {required bool defaultValue}) {
    final value = box.get(key);
    if (value is bool) return value;
    return defaultValue;
  }
}
