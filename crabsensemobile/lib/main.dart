import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/di/injection.dart' as di;
import 'features/authentication/data/datasources/auth_local_data_source.dart';
import 'features/notifications/data/datasources/notification_history_local_data_source.dart';
import 'features/profile/data/datasources/notification_preferences_local_data_source.dart';
import 'shared/services/background_sync_service.dart';
import 'shared/services/notification_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register FCM background handler & initialize Firebase safely
  try {
    await Firebase.initializeApp();
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      // Crashlytics — bắt lỗi Flutter (non-blocking nếu plugin chưa sẵn sàng)
      try {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e) {
        debugPrint('Crashlytics hook skipped: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase skipped/not configured: $e');
  }

  // Initialize Hive for local storage
  try {
    await Hive.initFlutter();
    await Hive.openBox(kNotifHistoryBoxName);
    await Hive.openBox(kNotifPrefsBoxName);
  } catch (e) {
    debugPrint('Hive initialization warning: $e');
  }

  // Initialize dependency injection
  try {
    await di.init();
  } catch (e) {
    debugPrint('DI initialization warning: $e');
  }

  // Purge leftover mock_* session BEFORE any API calls (Notification/Sync).
  try {
    if (di.sl.isRegistered<AuthLocalDataSource>()) {
      final purged = await di.sl<AuthLocalDataSource>().purgeMockSessionIfPresent();
      if (purged) {
        debugPrint('Cleared mock auth session — please log in again.');
      }
    }
  } catch (e) {
    debugPrint('Mock session purge warning: $e');
  }

  // Initialize notification service safely if registered
  try {
    if (di.sl.isRegistered<NotificationService>()) {
      await di.sl<NotificationService>().initialize();
    }
  } catch (e) {
    debugPrint('NotificationService initialization warning: $e');
  }

  // Initialize background sync safely if registered
  try {
    if (di.sl.isRegistered<BackgroundSyncService>()) {
      await di.sl<BackgroundSyncService>().initialize();
      await di.sl<BackgroundSyncService>().schedulePeriodicSync();
    }
  } catch (e) {
    debugPrint('BackgroundSyncService initialization warning: $e');
  }

  // Set preferred orientations for mobile
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('SystemChrome warning: $e');
  }

  runApp(
    const ProviderScope(
      child: CrabSenseApp(),
    ),
  );
}
