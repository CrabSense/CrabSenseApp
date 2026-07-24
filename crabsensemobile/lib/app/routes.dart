/// Route name constants for the CrabSense mobile application.
///
/// Using named constants avoids magic strings throughout the codebase and
/// makes refactoring routes safe. All go_router [GoRoute.name] values and
/// any call to [GoRouter.pushNamed] / [GoRouter.goNamed] should reference
/// these constants instead of raw string literals.
///
/// Design ref: section 4.4 Navigation Architecture
/// Requirements: 1.3, 1.7, 17.1
library;

import 'package:go_router/go_router.dart' show GoRoute, GoRouter, GoRouterState;

/// Route names (used with GoRouter.pushNamed / goNamed).
class RouteNames {
  RouteNames._();

  /// Splash / loading screen shown on cold start.
  static const String splash = 'splash';

  /// Login screen — unauthenticated entry point.
  static const String login = 'login';

  /// Main dashboard — requires authentication.
  static const String dashboard = 'dashboard';

  /// Boxes management tab (Farm Digital Twin).
  static const String boxes = 'boxes';

  /// QR code scanner.
  static const String scanner = 'scanner';

  /// Box details view.
  static const String boxDetails = 'boxDetails';

  /// Video capture inside a box context.
  static const String boxVideo = 'boxVideo';

  /// Manual inspection inside a box context.
  static const String boxInspect = 'boxInspect';

  /// Camera feed for a box.
  static const String boxCamera = 'boxCamera';

  /// AI results for a video.
  static const String aiResults = 'aiResults';

  /// Water quality monitoring.
  static const String waterQuality = 'waterQuality';

  /// Alert list.
  static const String alerts = 'alerts';

  /// Operation logs.
  static const String operations = 'operations';

  /// Harvest recording.
  static const String harvest = 'harvest';

  /// Sales management.
  static const String sales = 'sales';

  /// User profile and settings.
  static const String profile = 'profile';

  /// Product traceability — public, no login required.
  static const String traceability = 'traceability';

  /// In-app notification history / notification centre.
  static const String notificationHistory = 'notificationHistory';
}

/// Route paths (used with GoRouter.go / push when a full path is needed,
/// e.g. for deep links).
class RoutePaths {
  RoutePaths._();

  /// `/` — Splash / loading.
  static const String splash = '/';

  /// `/login` — Login screen.
  static const String login = '/login';

  /// `/dashboard` — Dashboard.
  static const String dashboard = '/dashboard';

  /// `/boxes` — Boxes tab (Farm Digital Twin).
  static const String boxes = '/boxes';

  /// `/scanner` — QR scanner.
  static const String scanner = '/scanner';

  /// `/box/:id` — Box details.
  ///
  /// Use [boxDetails] to generate with a concrete id.
  static const String boxDetailsTemplate = '/box/:id';

  /// `/box/:id/video` — Video capture.
  static const String boxVideoTemplate = '/box/:id/video';

  /// `/box/:id/inspect` — Manual inspection.
  static const String boxInspectTemplate = '/box/:id/inspect';

  /// `/box/:id/camera` — Box camera feed.
  static const String boxCameraTemplate = '/box/:id/camera';

  /// `/ai-results/:videoId` — AI detection results.
  static const String aiResultsTemplate = '/ai-results/:videoId';

  /// `/water-quality` — Water quality.
  static const String waterQuality = '/water-quality';

  /// `/alerts` — Alert list.
  static const String alerts = '/alerts';

  /// `/operations` — Operation logs.
  static const String operations = '/operations';

  /// `/harvest` — Harvest recording.
  static const String harvest = '/harvest';

  /// `/sales` — Sales management.
  static const String sales = '/sales';

  /// `/profile` — User profile.
  static const String profile = '/profile';

  /// `/notifications` — Notification history / notification centre.
  static const String notificationHistory = '/notifications';

  /// `/traceability/:productId` — Product traceability (public).
  ///
  /// Use [traceability] to generate with a concrete productId.
  static const String traceabilityTemplate = '/traceability/:productId';

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns `/box/<id>`.
  static String boxDetails(String id) => '/box/$id';

  /// Returns `/box/<id>/video`.
  static String boxVideo(String id) => '/box/$id/video';

  /// Returns `/box/<id>/inspect`.
  static String boxInspect(String id) => '/box/$id/inspect';

  /// Returns `/box/<id>/camera`.
  static String boxCamera(String id) => '/box/$id/camera';

  /// Water quality scoped to a farming area.
  static String waterQualityForFarm(String farmId) =>
      '/water-quality?farmingAreaId=${Uri.encodeQueryComponent(farmId)}';

  /// Operation form prefilled with a box id.
  static String operationsForBox(String boxId) =>
      '/operations?boxId=${Uri.encodeQueryComponent(boxId)}';

  /// Harvest form prefilled with a box id.
  static String harvestForBox(String boxId, {String? farmId}) {
    final q = <String, String>{'boxId': boxId};
    if (farmId != null && farmId.isNotEmpty) q['farmId'] = farmId;
    final query = q.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '/harvest?$query';
  }

  /// Sales with optional box context.
  static String salesForBox(String boxId) =>
      '/sales?boxId=${Uri.encodeQueryComponent(boxId)}';

  /// Returns `/ai-results/<videoId>`.
  static String aiResults(String videoId) => '/ai-results/$videoId';

  /// Returns `/traceability/<productId>`.
  static String traceability(String productId) => '/traceability/$productId';
}

/// Route parameter keys used when extracting [GoRouterState.pathParameters].
class RouteParams {
  RouteParams._();

  /// Path parameter key for box id (`/box/:id`).
  static const String boxId = 'id';

  /// Path parameter key for video id (`/ai-results/:videoId`).
  static const String videoId = 'videoId';

  /// Path parameter key for product id (`/traceability/:productId`).
  static const String productId = 'productId';
}
