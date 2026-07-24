/// Service that translates FCM notification payloads into go_router
/// navigation actions.
///
/// This class is the single place where notification → screen routing
/// decisions are made.  It parses the [RemoteMessage.data] payload and
/// calls [GoRouter.go] (or [GoRouter.push]) with the appropriate path.
///
/// Payload convention (agreed with backend):
/// ```json
/// {
///   "category"    : "CRITICAL_ALERT",        // NotificationCategory.*
///   "deepLink"    : "/alerts",               // optional full path
///   "screen"      : "alerts",                // named screen key
///   "resourceId"  : "abc123",                // optional resource id
///   "resourceType": "box"                    // optional: box | sensor | alert
/// }
/// ```
///
/// Requirements: 14.5 – navigate to relevant screen on notification tap.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../app/routes.dart';
import 'notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen key constants
// ─────────────────────────────────────────────────────────────────────────────

/// Known `screen` values that the server can set in the FCM data payload.
///
/// These are stable identifiers shared between mobile and backend teams.
/// Keep in sync with the server-side notification dispatch logic.
class NotificationScreenKeys {
  NotificationScreenKeys._();

  static const String alerts = 'alerts';
  static const String waterQuality = 'water_quality';
  static const String boxDetails = 'box_details';
  static const String dashboard = 'dashboard';
  static const String operations = 'operations';
  static const String harvest = 'harvest';
  static const String profile = 'profile';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Handles deep-link navigation triggered by notification taps.
///
/// Usage:
/// ```dart
/// NotificationNavigationService(router: _router, logger: sl()).navigate(message);
/// ```
///
/// Requirements: 14.5
class NotificationNavigationService {
  const NotificationNavigationService({required this._router, required this._logger});

  final GoRouter _router;
  final Logger _logger;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Resolves the target route from [message] and navigates to it.
  ///
  /// Resolution order:
  ///   1. `deepLink` field — use the explicit path directly.
  ///   2. `screen` + `resourceId` + `resourceType` — construct path.
  ///   3. `category` — fall back to a category-default screen.
  ///   4. Alerts screen as final fallback.
  ///
  /// Requirements: 14.5
  void navigate(RemoteMessage message) {
    final path = _resolveRoute(message);
    _logger.d(
      'NotificationNavigationService: navigating to $path '
      '(messageId=${message.messageId})',
    );
    try {
      _router.go(path);
    } on Exception catch (e) {
      // Navigation errors are non-fatal — log and fall back to alerts.
      _logger.w(
        'NotificationNavigationService: navigation error: $e, '
        'falling back to ${RoutePaths.alerts}',
      );
      _router.go(RoutePaths.alerts);
    }
  }

  // ── Route resolution ──────────────────────────────────────────────────────

  /// Determines the target [RoutePaths] path for [message].
  String _resolveRoute(RemoteMessage message) {
    final data = message.data;

    // 1. Explicit deep-link path supplied by server.
    final deepLink = data['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      _logger.d('NotificationNavigationService: using deepLink=$deepLink');
      return deepLink;
    }

    // 2. screen + optional resourceId / resourceType.
    final screen = data['screen'] as String?;
    final resourceId = data['resourceId'] as String?;
    final resourceType = data['resourceType'] as String?;

    if (screen != null && screen.isNotEmpty) {
      final path = _pathFromScreen(screen, resourceId, resourceType);
      if (path != null) return path;
    }

    // 3. Category default.
    final category = data['category'] as String? ?? '';
    return _categoryDefaultPath(category);
  }

  /// Maps a `screen` key (plus optional resource metadata) to a route path.
  String? _pathFromScreen(String screen, String? resourceId, String? resourceType) {
    switch (screen) {
      case NotificationScreenKeys.alerts:
        return RoutePaths.alerts;
      case NotificationScreenKeys.waterQuality:
        return RoutePaths.waterQuality;
      case NotificationScreenKeys.dashboard:
        return RoutePaths.dashboard;
      case NotificationScreenKeys.operations:
        return RoutePaths.operations;
      case NotificationScreenKeys.harvest:
        return RoutePaths.harvest;
      case NotificationScreenKeys.profile:
        return RoutePaths.profile;
      case NotificationScreenKeys.boxDetails:
        if (resourceId != null && resourceId.isNotEmpty) {
          return RoutePaths.boxDetails(resourceId);
        }
        return RoutePaths.dashboard;
      default:
        // Unknown screen key — try to guess from resourceType.
        if (resourceType == 'box' && resourceId != null && resourceId.isNotEmpty) {
          return RoutePaths.boxDetails(resourceId);
        }
        _logger.w('NotificationNavigationService: unknown screen key "$screen"');
        return null;
    }
  }

  /// Returns the default navigation target for a notification [category].
  ///
  /// - Critical Alert → Alerts screen (most urgent).
  /// - Warning → Alerts screen.
  /// - Task Reminder → Dashboard (video due list not yet implemented).
  /// - System Update → Profile/Settings.
  /// - Unknown → Alerts screen.
  String _categoryDefaultPath(String category) {
    switch (category) {
      case NotificationCategory.criticalAlert:
      case NotificationCategory.warning:
        return RoutePaths.alerts;
      case NotificationCategory.taskReminder:
        return RoutePaths.dashboard;
      case NotificationCategory.systemUpdate:
        return RoutePaths.profile;
      default:
        return RoutePaths.alerts;
    }
  }
}
