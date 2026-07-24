import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../datasources/notification_preferences_local_data_source.dart';

/// Local Hive + remote `/auth/me/notification-preferences`.
class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl({
    required NotificationPreferencesLocalDataSource localDataSource,
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _localDataSource = localDataSource,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.apiBaseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _secureStorage.read(key: 'auth_access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
      ),
    );
  }

  final NotificationPreferencesLocalDataSource _localDataSource;
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<NotificationPreferences> getPreferences() async {
    try {
      final res = await _dio.get(ApiConstants.notificationPreferences);
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
      await _dio.put(
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
