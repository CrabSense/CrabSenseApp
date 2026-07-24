import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../datasources/notification_preferences_local_data_source.dart';

/// [NotificationPreferencesRepository] backed by local Hive storage.
///
/// All reads and writes are delegated to
/// [NotificationPreferencesLocalDataSource]. There is no remote
/// data source — notification preferences are device-local only.
///
/// Requirements: 14.9-14.10
class NotificationPreferencesRepositoryImpl implements NotificationPreferencesRepository {
  const NotificationPreferencesRepositoryImpl({required this._localDataSource});

  final NotificationPreferencesLocalDataSource _localDataSource;

  @override
  Future<NotificationPreferences> getPreferences() => _localDataSource.getPreferences();

  @override
  Future<void> savePreferences(NotificationPreferences prefs) =>
      _localDataSource.savePreferences(prefs);
}
