import 'dart:async';
import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../features/notifications/data/datasources/notification_history_local_data_source.dart';
import '../../features/notifications/data/models/notification_history_item_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background message handler
//
// Must be a top-level function per firebase_messaging requirements.
// It runs in an isolate without access to the DI container, so keep
// it lightweight (no API calls, minimal state).
// ─────────────────────────────────────────────────────────────────────────────

/// Top-level FCM background / terminated message handler.
///
/// Called by the Firebase SDK when a data-only message arrives and the
/// app is in the background or terminated state.  Foreground messages
/// are handled by [NotificationService.initForegroundHandlers].
///
/// Requirements: 14.4, 14.5
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialised before using any Firebase plugin in an
  // isolate.  If already initialised this is a no-op.
  await Firebase.initializeApp();

  // Show a local notification so the user sees the message in the
  // system tray even when the app is not running.
  final flutterLocalNotifications = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await flutterLocalNotifications.initialize(initSettings);

  final category = message.data['category'] as String? ?? '';
  final importance = NotificationService.importanceForCategory(category);

  final androidDetails = AndroidNotificationDetails(
    NotificationService.channelIdForCategory(category),
    NotificationService.channelNameForCategory(category),
    importance: importance,
    priority: importance == Importance.max ? Priority.high : Priority.defaultPriority,
  );
  final notifDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotifications.show(
    message.hashCode,
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    notifDetails,
    payload: message.data['deepLink'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification categories
// ─────────────────────────────────────────────────────────────────────────────

/// Strongly typed notification categories supported by the CrabSense system.
///
/// These values correspond to the `category` field in FCM message data
/// payloads sent by the server.
///
/// Requirements: 14.3
class NotificationCategory {
  NotificationCategory._();

  /// High-priority alert requiring immediate attention (e.g. water quality
  /// threshold breached, equipment failure).
  static const String criticalAlert = 'CRITICAL_ALERT';

  /// Moderate-severity alert for conditions requiring prompt action.
  static const String warning = 'WARNING';

  /// Reminder for a scheduled crab monitoring or inspection task.
  static const String taskReminder = 'TASK_REMINDER';

  /// General platform or firmware update notification.
  static const String systemUpdate = 'SYSTEM_UPDATE';
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification service interface
// ─────────────────────────────────────────────────────────────────────────────

/// Abstract interface for the push notification service.
///
/// This abstraction makes it easy to swap the real implementation with a
/// test double in unit / widget tests.
abstract class NotificationService {
  /// Initialise Firebase Messaging and local notifications, request
  /// permission from the user, and (if granted) register the device
  /// token with the server.
  ///
  /// Must be awaited during app start-up, after [Firebase.initializeApp].
  ///
  /// Requirements: 14.1, 14.2
  Future<void> initialize();

  /// Stream of [RemoteMessage] objects for foreground messages.
  ///
  /// UI layers subscribe to this stream to display in-app banners.
  ///
  /// Requirements: 14.4
  Stream<RemoteMessage> get foregroundMessages;

  /// Stream of [RemoteMessage] objects for notification taps that
  /// open the app from background / terminated state.
  ///
  /// Requirements: 14.5
  Stream<RemoteMessage> get notificationTaps;

  /// Returns the FCM device token, or `null` when permission was denied
  /// or the token is not yet available.
  Future<String?> getDeviceToken();

  /// Dispose resources and close streams.
  void dispose();

  // ───────────────────────────────────────────────────────────────────────────
  // Static helpers used by both the service and the background handler
  // ───────────────────────────────────────────────────────────────────────────

  /// Returns the Android notification channel importance for [category].
  static Importance importanceForCategory(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return Importance.max;
      case NotificationCategory.warning:
        return Importance.high;
      case NotificationCategory.taskReminder:
        return Importance.defaultImportance;
      case NotificationCategory.systemUpdate:
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Returns the Android notification channel ID for [category].
  static String channelIdForCategory(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return 'crabsense_critical';
      case NotificationCategory.warning:
        return 'crabsense_warning';
      case NotificationCategory.taskReminder:
        return 'crabsense_tasks';
      case NotificationCategory.systemUpdate:
        return 'crabsense_system';
      default:
        return 'crabsense_general';
    }
  }

  /// Returns a human-readable channel name for [category].
  static String channelNameForCategory(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
        return 'Critical Alerts';
      case NotificationCategory.warning:
        return 'Warnings';
      case NotificationCategory.taskReminder:
        return 'Task Reminders';
      case NotificationCategory.systemUpdate:
        return 'System Updates';
      default:
        return 'General';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Storage key constants
// ─────────────────────────────────────────────────────────────────────────────

/// Secure-storage key used to persist the FCM token for offline access.
const String _kFcmTokenKey = 'fcm_device_token';

// ─────────────────────────────────────────────────────────────────────────────
// Concrete implementation
// ─────────────────────────────────────────────────────────────────────────────

/// Production implementation of [NotificationService].
///
/// Integrates:
///   - [FirebaseMessaging] for FCM token management and message streams.
///   - [FlutterLocalNotificationsPlugin] for in-app foreground banners.
///   - [FlutterSecureStorage] to persist the token across sessions.
///   - [ApiClient] to register / refresh the token on the server.
///   - [NotificationHistoryLocalDataSource] to persist received messages.
///
/// Lifecycle:
///   1. Call [initialize] once from main.dart / app startup.
///   2. Subscribe to [foregroundMessages] in the UI layer for banners.
///   3. Subscribe to [notificationTaps] for deep-link navigation.
///
/// Requirements: 14.1–14.3, 14.6
class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl({
    required this._logger,
    required this._apiClient,
    required this._secureStorage,
    required this._historyDataSource,
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _firebaseMessagingOverride = firebaseMessaging,
       _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  final Logger _logger;
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  final FirebaseMessaging? _firebaseMessagingOverride;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final NotificationHistoryLocalDataSource _historyDataSource;

  FirebaseMessaging? get _messaging {
    if (_firebaseMessagingOverride != null) return _firebaseMessagingOverride;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseMessaging.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  final _foregroundController = StreamController<RemoteMessage>.broadcast();
  final _tapController = StreamController<RemoteMessage>.broadcast();

  bool _initialized = false;

  // ───────────────────────────────────────────────────────────────────────────
  // NotificationService
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;

  @override
  Stream<RemoteMessage> get notificationTaps => _tapController.stream;

  /// Initialise notification infrastructure.
  ///
  /// Steps:
  ///   1. Register the background message handler.
  ///   2. Initialise flutter_local_notifications channels.
  ///   3. Request OS permission (alert, badge, sound).
  ///   4. If granted, retrieve the FCM token and register with server.
  ///   5. Listen for token refresh events.
  ///   6. Set up foreground and tap handlers.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  ///
  /// Requirements: 14.1, 14.2
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _logger.i('NotificationService: initialising');

    if (Firebase.apps.isEmpty || _messaging == null) {
      _logger.w('NotificationService: Firebase not initialized – running in local notification mode');
      await _initLocalNotifications();
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      _logger.w('NotificationService: onBackgroundMessage setup skipped: $e');
    }

    await _initLocalNotifications();

    final granted = await _requestPermission();
    if (!granted) {
      _logger.w(
        'NotificationService: permission denied – '
        'skipping token registration',
      );
      return;
    }

    await _fetchAndRegisterToken();

    try {
      _messaging?.onTokenRefresh.listen(
        _onTokenRefresh,
        onError: (Object e) {
          _logger.w('NotificationService: onTokenRefresh error: $e');
        },
      );
    } catch (e) {
      _logger.w('NotificationService: onTokenRefresh setup failed: $e');
    }

    initForegroundHandlers();

    _logger.i('NotificationService: initialised successfully');
  }

  @override
  Future<String?> getDeviceToken() async {
    try {
      final cached = await _secureStorage.read(key: _kFcmTokenKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      if (_messaging != null) {
        final token = await _messaging!.getToken();
        if (token != null) {
          await _secureStorage.write(key: _kFcmTokenKey, value: token);
        }
        return token;
      }
      return null;
    } on Exception catch (e) {
      _logger.w('NotificationService: getDeviceToken failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _foregroundController.close();
    _tapController.close();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Sets up Android notification channels and initialises the plugin.
  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // We handle permission via FCM.
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create per-category channels on Android.
    if (!kIsWeb && Platform.isAndroid) {
      await _createAndroidChannels();
    }
  }

  /// Creates the four notification channels required on Android 8+.
  Future<void> _createAndroidChannels() async {
    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) {
      return;
    }

    final channels = [
      const AndroidNotificationChannel(
        'crabsense_critical',
        'Critical Alerts',
        description: 'Immediate alerts for critical farm conditions.',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        'crabsense_warning',
        'Warnings',
        description: 'Warnings for conditions requiring prompt attention.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'crabsense_tasks',
        'Task Reminders',
        description: 'Reminders for scheduled monitoring tasks.',
      ),
      const AndroidNotificationChannel(
        'crabsense_system',
        'System Updates',
        description: 'Platform and firmware update notifications.',
        importance: Importance.low,
      ),
    ];

    for (final channel in channels) {
      await plugin.createNotificationChannel(channel);
    }
    _logger.d('NotificationService: Android channels created');
  }

  /// Requests notification permission from the OS.
  ///
  /// Returns `true` if the user granted at least alert permission.
  ///
  /// Requirements: 14.1
  Future<bool> _requestPermission() async {
    if (_messaging == null) return false;
    try {
      final settings = await _messaging!.requestPermission();

      final status = settings.authorizationStatus;
      _logger.i('NotificationService: permission status = $status');

      return status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
    } on Exception catch (e) {
      _logger.e('NotificationService: requestPermission error', error: e);
      return false;
    }
  }

  /// Fetches the FCM token, persists it, and sends it to the server.
  ///
  /// On iOS also reads the APNS token for diagnostics.
  ///
  /// Requirements: 14.2
  Future<void> _fetchAndRegisterToken() async {
    if (_messaging == null) return;
    try {
      // iOS: ensure APNS token is available before requesting FCM token.
      if (!kIsWeb && Platform.isIOS) {
        final apnsToken = await _messaging!.getAPNSToken();
        _logger.d(
          'NotificationService: APNS token available = '
          '${apnsToken != null}',
        );
      }

      final token = await _messaging!.getToken();
      if (token == null) {
        _logger.w('NotificationService: FCM token is null');
        return;
      }

      _logger.d('NotificationService: FCM token obtained');

      // Persist for offline access.
      await _secureStorage.write(key: _kFcmTokenKey, value: token);

      // Register with server.
      await _registerTokenWithServer(token);
    } catch (e) {
      _logger.e('NotificationService: _fetchAndRegisterToken error', error: e);
    }
  }

  /// POSTs the device token to [ApiConstants.registerDevice].
  ///
  /// Failures are logged but do not crash the app – the token is still
  /// persisted locally and will be re-sent on the next cold start or
  /// when the token refreshes.
  ///
  /// Requirements: 14.2
  Future<void> _registerTokenWithServer(String token) async {
    try {
      final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';
      final body = {'token': token, 'platform': platform};

      final result = await _apiClient.safePost<Map<String, dynamic>>(
        ApiConstants.registerDevice,
        data: body,
      );

      if (result.failure != null) {
        _logger.w(
          'NotificationService: token registration failed – '
          '${result.failure}',
        );
      } else {
        _logger.i('NotificationService: device token registered');
      }
    } on Exception catch (e) {
      // Non-fatal: log and continue.
      _logger.w('NotificationService: _registerTokenWithServer error: $e');
    }
  }

  /// Called when FCM rotates the token.
  Future<void> _onTokenRefresh(String newToken) async {
    _logger.i('NotificationService: token refreshed');
    await _secureStorage.write(key: _kFcmTokenKey, value: newToken);
    await _registerTokenWithServer(newToken);
  }

  /// Handles a tap on a local notification shown while the app is open.
  void _onLocalNotificationTap(NotificationResponse response) {
    // Emit as a synthetic RemoteMessage via the tap stream so UI layers
    // can perform deep-link navigation using a single listener.
    // The payload carries the deep-link URI set when the notification
    // was displayed.
    _logger.d(
      'NotificationService: local notification tapped '
      '(payload=${response.payload})',
    );
    // Note: deep-link routing is handled by the presentation layer that
    // listens to [notificationTaps].  We emit a minimal RemoteMessage
    // here; the payload is accessible via [RemoteMessage.data].
    final syntheticMessage = RemoteMessage(
      data: {
        if (response.payload != null) 'deepLink': response.payload,
        'source': 'local_notification',
      },
    );
    _tapController.add(syntheticMessage);
  }

  /// Shows a heads-up notification while the app is in the foreground,
  /// and emits the [RemoteMessage] on [foregroundMessages] for in-app
  /// banner widgets.
  ///
  /// Requirements: 14.4
  void initForegroundHandlers() {
    if (Firebase.apps.isEmpty || _messaging == null) return;
    try {
      // Foreground messages.
      FirebaseMessaging.onMessage.listen(
        (message) async {
          _logger.d(
            'NotificationService: foreground message received '
            '(messageId=${message.messageId})',
          );

          // Emit to the UI stream for in-app banner display.
          _foregroundController.add(message);

          // Also surface a local notification so the content is
          // visible in the system tray when the user is on a different
          // screen.
          await _showLocalNotification(message);
        },
        onError: (Object e) {
          _logger.w('NotificationService: onMessage error: $e');
        },
      );

      // Notification tap when app is in background (not terminated).
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          _logger.d(
            'NotificationService: notification opened app '
            '(messageId=${message.messageId})',
          );
          _tapController.add(message);
        },
        onError: (Object e) {
          _logger.w('NotificationService: onMessageOpenedApp error: $e');
        },
      );
    } catch (e) {
      _logger.w('NotificationService: initForegroundHandlers error: $e');
    }
  }

  /// Displays a local notification for a foreground [RemoteMessage].
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    final category = message.data['category'] as String? ?? '';
    final importance = NotificationService.importanceForCategory(category);
    final channelId = NotificationService.channelIdForCategory(category);
    final channelName = NotificationService.channelNameForCategory(category);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.max ? Priority.high : Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(notification.body ?? ''),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: importance == Importance.max
          ? InterruptionLevel.critical
          : InterruptionLevel.active,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['deepLink'] as String?,
    );

    // Persist to notification history for the in-app centre.
    await _persistToHistory(message);
  }

  /// Persists a received [RemoteMessage] to the notification history store.
  ///
  /// Requirements: 14.6
  Future<void> _persistToHistory(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final item = NotificationHistoryItemModel(
        id: message.messageId ?? DateTime.now().toIso8601String(),
        title: notification.title ?? '',
        message: notification.body ?? '',
        category: message.data['category'] as String? ?? '',
        receivedAt: message.sentTime ?? DateTime.now(),
        deepLink: message.data['deepLink'] as String?,
      );

      await _historyDataSource.addItem(item);
    } on Exception catch (e) {
      // Non-fatal: log and continue so the notification still displays.
      _logger.w('NotificationService: failed to persist to history: $e');
    }
  }
}
