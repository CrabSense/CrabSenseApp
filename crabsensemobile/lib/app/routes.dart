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

  /// Crab list for a box.
  static const String boxCrabs = 'boxCrabs';

  /// Single crab details.
  static const String crabDetails = 'crabDetails';

  /// AI results for a video.
  static const String aiResults = 'aiResults';

  /// Water quality monitoring.
  static const String waterQuality = 'waterQuality';

  /// Alert list.
  static const String alerts = 'alerts';

  /// Operation logs.
  static const String operations = 'operations';

  /// Operation history timeline.
  static const String operationHistory = 'operationHistory';

  /// Harvest recording.
  static const String harvest = 'harvest';

  /// Sales management.
  static const String sales = 'sales';

  /// User profile and settings.
  static const String profile = 'profile';

  /// IoT devices list.
  static const String devices = 'devices';

  /// AI center hub.
  static const String aiCenter = 'aiCenter';

  /// Reports & analytics hub.
  static const String reports = 'reports';

  /// Offline sync hub.
  static const String offlineSync = 'offlineSync';

  /// App settings hub.
  static const String appSettings = 'appSettings';

  /// Security & privacy hub.
  static const String securityPrivacy = 'securityPrivacy';

  /// Help & support hub.
  static const String helpSupport = 'helpSupport';

  /// App info hub.
  static const String appInfo = 'appInfo';

  /// Legal document (terms / privacy).
  static const String legalDocument = 'legalDocument';

  /// Firebase services hub.
  static const String firebaseHub = 'firebaseHub';

  /// Edit profile form.
  static const String editProfile = 'editProfile';

  /// Change password form.
  static const String changePassword = 'changePassword';

  /// Notification preferences.
  static const String notificationSettings = 'notificationSettings';

  /// Product traceability — public, no login required.
  static const String traceability = 'traceability';

  /// In-app notification history / notification centre.
  static const String notificationHistory = 'notificationHistory';

  /// Stock management — add crab to box.
  static const String addCrab = 'addCrab';

  /// Crab tracking — daily monitoring of crabs in a box.
  static const String crabTracking = 'crabTracking';
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

  /// `/box/:id/crabs` — Crab list for a box.
  static const String boxCrabsTemplate = '/box/:id/crabs';

  /// `/crab/:crabId` — Crab detail.
  static const String crabDetailsTemplate = '/crab/:crabId';

  /// `/ai-results/:videoId` — AI detection results.
  static const String aiResultsTemplate = '/ai-results/:videoId';

  /// `/water-quality` — Water quality.
  static const String waterQuality = '/water-quality';

  /// `/alerts` — Alert list.
  static const String alerts = '/alerts';

  /// `/operations` — Operation logs.
  static const String operations = '/operations';

  /// `/operations/history` — Operation history timeline.
  static const String operationHistory = '/operations/history';

  /// `/harvest` — Harvest recording.
  static const String harvest = '/harvest';

  /// `/sales` — Sales management.
  static const String sales = '/sales';

  /// `/profile` — User profile.
  static const String profile = '/profile';

  /// `/devices` — IoT devices list.
  static const String devices = '/devices';

  /// `/ai-center` — AI detections / recommendations hub.
  static const String aiCenter = '/ai-center';

  /// `/reports` — Reports & analytics hub (`?type=harvest|…`).
  static const String reports = '/reports';

  /// `/offline-sync` — Offline queue & sync status.
  static const String offlineSync = '/offline-sync';

  /// `/app-settings` — App preferences hub.
  static const String appSettings = '/app-settings';

  /// `/security` — Security & privacy hub.
  static const String securityPrivacy = '/security';

  /// `/help` — Help & support hub.
  static const String helpSupport = '/help';

  /// `/app-info` — Version, terms, licenses.
  static const String appInfo = '/app-info';

  /// `/legal` — Terms / privacy document.
  static const String legalDocument = '/legal';

  /// `/firebase` — Firebase services hub (`?service=authentication|…`).
  static const String firebaseHub = '/firebase';

  /// `/profile/edit` — Edit profile.
  static const String editProfile = '/profile/edit';

  /// `/profile/change-password` — Change password.
  static const String changePassword = '/profile/change-password';

  /// `/profile/notifications` — Notification preferences.
  static const String notificationSettings = '/profile/notifications';

  /// `/notifications` — Notification history / notification centre.
  static const String notificationHistory = '/notifications';

  /// `/add-crab` — Stock management: add crab to a box.
  static const String addCrab = '/add-crab';

  /// `/crab-tracking` — Daily crab tracking / monitoring.
  static const String crabTracking = '/crab-tracking';

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

  /// Returns `/box/<id>/crabs`.
  static String boxCrabs(String id, {String? boxCode}) {
    final query = boxCode == null || boxCode.isEmpty
        ? ''
        : '?boxCode=${Uri.encodeQueryComponent(boxCode)}';
    return '/box/$id/crabs$query';
  }

  /// Returns `/crab/<crabId>` with optional boxId / boxCode query.
  static String crabDetails(String crabId, {String? boxId, String? boxCode}) {
    final params = <String, String>{};
    if (boxId != null && boxId.isNotEmpty) params['boxId'] = boxId;
    if (boxCode != null && boxCode.isNotEmpty) params['boxCode'] = boxCode;
    if (params.isEmpty) return '/crab/$crabId';
    return '/crab/$crabId?${Uri(queryParameters: params).query}';
  }

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

  /// Path parameter key for crab id (`/crab/:crabId`).
  static const String crabId = 'crabId';

  /// Path parameter key for video id (`/ai-results/:videoId`).
  static const String videoId = 'videoId';

  /// Path parameter key for product id (`/traceability/:productId`).
  static const String productId = 'productId';
}
