import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../datasources/notification_preferences_local_data_source.dart';

/// Local Hive + remote `/auth/me/notification-preferences`.
class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl({
    required NotificationPreferencesLocalDataSource localDataSource,
    required ApiClient api,
  })  : _localDataSource = localDataSource,
        _api = api;

  final NotificationPreferencesLocalDataSource _localDataSource;
  final ApiClient _api;

  @override
  Future<NotificationPreferences> getPreferences() async {
    try {
      final res = await _api.get(ApiConstants.notificationPreferences);
      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data is Map<String, dynamic>
            ? res.data['data'] ?? res.data
            : null;
        if (raw is Map<String, dynamic>) {
          final prefs = _fromJson(raw);
          await _localDataSource.savePreferences(prefs);
          return prefs;
        }
      }
    } catch (_) {}
    return _localDataSource.getPreferences();
  }

  @override
  Future<void> savePreferences(NotificationPreferences prefs) async {
    await _localDataSource.savePreferences(prefs);
    try {
      await _api.put(
        ApiConstants.notificationPreferences,
        data: {
          'warningsEnabled': prefs.warningsEnabled,
          'taskRemindersEnabled': prefs.taskRemindersEnabled,
          'systemUpdatesEnabled': prefs.systemUpdatesEnabled,
          'soundEnabled': prefs.soundEnabled,
          'vibrationEnabled': prefs.vibrationEnabled,
          'ledIndicatorEnabled': prefs.ledIndicatorEnabled,
        },
      );
    } catch (_) {
      // Keep local copy if offline / BE unavailable.
    }
  }

  NotificationPreferences _fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      warningsEnabled: json['warningsEnabled'] as bool? ?? true,
      taskRemindersEnabled: json['taskRemindersEnabled'] as bool? ?? true,
      systemUpdatesEnabled: json['systemUpdatesEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      ledIndicatorEnabled: json['ledIndicatorEnabled'] as bool? ?? true,
    );
  }
}
