import '../entities/notification_preferences.dart';

/// Repository interface for persisting notification preferences.
///
/// Implementations must store preferences locally so they survive
/// app restarts and are available offline without any network call.
///
/// Requirements: 14.9-14.10
abstract class NotificationPreferencesRepository {
  /// Returns the user's saved notification preferences.
  ///
  /// Returns [NotificationPreferences] with default values (all enabled)
  /// when no preferences have been saved yet.
  Future<NotificationPreferences> getPreferences();

  /// Persists [prefs] to local storage.
  ///
  /// Overwrites any previously stored preferences.
  Future<void> savePreferences(NotificationPreferences prefs);
}
