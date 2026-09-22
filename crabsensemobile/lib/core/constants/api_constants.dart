import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration and endpoint constants for CrabSense Mobile Application
class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  // ===========================================================================
  // Base URL Configuration
  // ===========================================================================

  /// Override full base, e.g. --dart-define=API_BASE_URL=http://10.33.248.225:5080
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// PC LAN IP for physical Android devices (same Wi‑Fi as the phone).
  /// Update when your Wi‑Fi IP changes, or pass via --dart-define=DEV_HOST_LAN=x.x.x.x
  static const String _devHostLan = String.fromEnvironment(
    'DEV_HOST_LAN',
    defaultValue: '103.69.96.143',
  );

  /// Resolves API host for the current platform:
  /// - Physical Android → http://&lt;LAN-IP&gt;:5080
  /// - Android emulator → pass --dart-define=API_BASE_URL=http://10.0.2.2:5080
  /// - iOS Simulator / desktop / web → http://localhost:5080
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb || (!kIsWeb && Platform.isAndroid)) {
      return 'http://$_devHostLan:5080';
    }
    return 'http://localhost:5080';
  }

  /// API version prefix (Aligned with Backend Swagger /api)
  static const String apiVersion = '/api';

  /// Full API base URL with version
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // ===========================================================================
  // Timeout Configuration
  // ===========================================================================

  /// Connection timeout duration
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Send timeout duration
  static const Duration sendTimeout = Duration(seconds: 30);

  // ===========================================================================
  // Authentication Endpoints (Swagger: 00. Auth)
  // ===========================================================================

  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String currentUser = '/auth/me';
  static const String notificationPreferences =
      '/auth/me/notification-preferences';

  // ===========================================================================
  // User Endpoints
  // ===========================================================================

  static const String userProfile = '/auth/me';
  static const String updateProfile = '/auth/me';
  static const String uploadProfilePhoto = '/users/profile/photo';
  static const String getUserPermissions = '/users/permissions';
  static const String getUsers = '/users';
  static String getUserById(String userId) => '/users/$userId';

  // ===========================================================================
  // Dashboard Endpoints
  // ===========================================================================

  static const String dashboardSummary = '/dashboard/overview';
  static const String dashboardOverview = '/dashboard/overview';
  static const String dashboardMetrics = '/dashboard/metrics';
  static const String dashboardAlerts = '/dashboard/alerts';
  static const String aiRecommendations = '/ai/recommendations';
  static const String operationsToday = '/operations/today';
  static const String operationsRecent = '/operations/recent';
  static const String scheduledTasks = '/operations/scheduled-tasks';
  static const String scheduledTasksToday = '$scheduledTasks/today';
  static String scheduledTask(String id) => '$scheduledTasks/$id';
  static String scheduledTaskToggle(String id) => '${scheduledTask(id)}/toggle';
  static const String operationsFeedingHistory = '/operations/feeding-history';
  static const String boxStatusHistoryDaily = '/crabs/status-history-daily';

  // ===========================================================================
  // Farm, Row & Box Endpoints (Swagger: 01-03)
  // ===========================================================================

  static const String farms = '/farming-areas';
  static const String farmingAreas = '/farming-areas';
  static String farmDetails(String farmId) => '/farming-areas/$farmId';

  static const String ponds = '/farming-rows';
  static const String farmingRows = '/farming-rows';
  static String pondDetails(String pondId) => '/farming-rows/$pondId';

  static const String boxes = '/boxes';
  static const String availableBoxes = '/boxes/available';

  /// Enriched Boxes tab payload (health, water, devices, alerts, AI, map).
  static const String boxesOverview = '/boxes/overview';
  static const String boxesFarmingStatus = '/boxes/farming-status';
  static String boxDetails(String boxId) => '/boxes/$boxId';
  static String boxStatus(String boxId) => '/boxes/$boxId/status';
  static String boxFarmingStatus(String boxId) =>
      '/boxes/$boxId/farming-status';
  static String boxTimeline(String boxId) => '/boxes/$boxId/farming-timeline';
  static String boxCrabs(String boxId) => '/boxes/$boxId/crabs';
  static String addCrabToBox(String boxId) => '/boxes/$boxId/crabs';

  /// Mobile QR resolve alias — `{ data: { boxId } }`.
  static String boxesQr(String code) =>
      '/boxes/qr/${Uri.encodeComponent(code)}';

  /// Mobile Scan QR Quick Result — single enriched payload.
  static String boxesQrQuickResult(String code) =>
      '/boxes/qr/${Uri.encodeComponent(code)}/quick-result';
  static String boxCamera(String boxId) => '/boxes/$boxId/camera';
  static String deleteCrab(String crabId) => '/crabs/$crabId';
  static const String transferCrab = '/allocations/transfer';
  static const String allocateCrab = '/allocations';

  // ===========================================================================
  // Crab & Allocation Endpoints (Swagger: 04-06)
  // ===========================================================================

  static const String crabs = '/crabs';
  static String crabDetails(String crabId) => '/crabs/$crabId';

  /// Upload ảnh cua lên S3 — trả về URL để gửi kèm khi tạo cua.
  static const String crabImages = '/crabs/images';
  static const String crabLots = '/crab-lots';
  static const String cropBatches = '/crop-batches';
  static const String allocations = '/allocations';
  static String crabAllocations(String crabId) => '/crabs/$crabId/allocations';
  static String crabMoltings(String crabId) => '/crabs/$crabId/moltings';
  static String crabProfile(String crabId) => '/crabs/$crabId/profile';
  static String crabWeights(String crabId) => '/crabs/$crabId/weights';
  static String crabStatusHistory(String crabId) =>
      '/crabs/$crabId/status-history';
  static String crabHarvests(String crabId) => '/crabs/$crabId/harvests';

  // ===========================================================================
  // QR Code Endpoints (Swagger: 07)
  // ===========================================================================

  static const String scanBox = '/box-qr/scan';
  static String boxQr(String boxId) => '/boxes/$boxId/qr';
  static String boxQrImage(String boxId) => '/boxes/$boxId/qr.png';
  static String updateCrabByQr(String code, String crabId) =>
      '/box-qr/$code/crabs/$crabId';
  static String moveCrabByQr(String code) => '/box-qr/$code/move-crab';
  static const String validateQR = '/qr/validate';
  static const String generateQR = '/qr/generate';

  // ===========================================================================
  // Sensor & IoT Endpoints (Swagger: 08-09)
  // ===========================================================================

  static const String iotLive = '/iot/live';
  static const String sensors = '/sensors';
  static const String devices = '/devices';
  static const String submitSensorData = '/iot/sensor-data';
  static String sensorData(String sensorId) => '/iot/sensor-data/$sensorId';

  static const String waterQuality = '/sensors';
  static const String waterQualityLatest = '/iot/live';
  static const String waterQualityHistorical = '/iot/history';
  static String waterQualityForFarm(String farmId) => '/sensors';
  static String waterQualityForPond(String pondId) => '/sensors';
  static const String waterQualityThresholds = '/alert-thresholds';

  // ===========================================================================
  // Mineral Dosing Endpoints (Swagger: 37 — Water / Ca-Mg)
  // ===========================================================================

  /// Mục tiêu Ca/Mg đề xuất theo độ mặn — `?salinityPpt=10`. Không cần thể tích.
  static const String mineralDosingTargets = '/mineral-dosing/targets';

  /// Tính liều CaCl2 / MgCl2 từ chênh lệch hiện tại → mục tiêu.
  static const String mineralDosingCalculate = '/mineral-dosing/calculate';

  /// Danh mục loại muối dùng khi pha độ mặn.
  static const String mineralDosingSaltTypes = '/mineral-dosing/salt-types';

  /// Tính lượng muối (tăng ‰) hoặc lượng nước ngọt (giảm ‰) kèm hướng dẫn pha.
  static const String mineralDosingSalinity = '/mineral-dosing/salinity';

  // ===========================================================================
  // Alert & Threshold Endpoints (Swagger: 10-11)
  // ===========================================================================

  static const String alerts = '/alerts';
  static String alertDetails(String alertId) => '/alerts/$alertId';
  static String acknowledgeAlert(String alertId) =>
      '/alerts/$alertId/acknowledge';
  static String resolveAlert(String alertId) => '/alerts/$alertId/resolve';

  /// Alias: resolve is used for dismiss on mobile.
  static String dismissAlert(String alertId) => '/alerts/$alertId/resolve';
  static const String alertThresholds = '/alert-thresholds';
  static const String alertHistory = '/alerts/history';
  static const String unreadAlertCount = '/alerts/unread/count';
  static String userNotifications(String userId) =>
      '/notifications/user/$userId';

  // ===========================================================================
  // Media / Video Endpoints (Swagger: 12)
  // ===========================================================================

  static const String media = '/media';
  static const String uploadMedia = '/media/upload';
  static const String videos = '/media';
  static const String uploadVideo = '/media/upload';
  static String videoDetails(String videoId) => '/media/$videoId';
  static const String videoDueSchedule = '/videos/schedule';
  static String videosForBox(String boxId) => '/boxes/$boxId/videos';

  // ===========================================================================
  // AI Detection Endpoints (Swagger: 13-14)
  // ===========================================================================

  static const String aiAnalyze = '/ai/analyze';
  static const String aiDetections = '/ai/detections';
  static String aiResults(String videoId) => '/ai/detections';
  static String aiDetectionForBox(String boxId) => '/ai/detections';
  static const String submitFeedback = '/ai/feedback';

  // ===========================================================================
  // Harvest & Frozen Lots Endpoints (Swagger: 20-21)
  // ===========================================================================

  static const String harvestVouchers = '/harvest-vouchers';
  static const String harvests = '/harvest-vouchers';
  static String harvestDetails(String harvestId) =>
      '/harvest-vouchers/$harvestId';
  static const String recordHarvest = '/harvest-vouchers';
  static const String harvestSummary = '/harvest-vouchers/statistics';
  static const String harvestStatistics = '/harvest-vouchers/statistics';
  static const String harvestHistory = '/harvest-vouchers';

  static const String frozenLots = '/frozen-lots';
  static String frozenLotDetails(String id) => '/frozen-lots/$id';
  static const String expiringFrozenLots = '/frozen-lots/expiring';

  // ===========================================================================
  // Operation Log Endpoints
  // ===========================================================================

  static const String operations = '/operations';
  static String operationDetails(String operationId) =>
      '/operations/$operationId';
  static String operationsForBox(String boxId) => '/operations/box/$boxId';

  /// Phiếu chăm sóc (cho ăn) của một con cua — lịch sử ăn.
  static String operationsForCrab(String crabId) => '/operations/crab/$crabId';

  /// Prefer POST /operations (create) and PUT /operations/{id} (update).
  static const String createOperation = '/operations';
  static String updateOperation(String operationId) =>
      '/operations/$operationId';
  static const String uploadOperationPhoto = '/operations/photo';

  // ===========================================================================
  // Sales Endpoints
  // ===========================================================================

  static const String sales = '/sales';
  static String saleDetails(String saleId) => '/sales/$saleId';
  static const String createSale = '/sales/create';
  static const String salesSummary = '/sales/summary';
  static const String salesHistory = '/sales/history';

  // ===========================================================================
  // Manual Inspection Endpoints
  // ===========================================================================

  static const String inspections = '/inspections';
  static String inspectionDetails(String inspectionId) =>
      '/inspections/$inspectionId';
  static String inspectionsForBox(String boxId) => '/inspections/box/$boxId';
  static const String submitInspection = '/inspections/submit';

  // ===========================================================================
  // Traceability Endpoints
  // ===========================================================================

  static const String traceability = '/traceability';
  static String traceabilityByProductId(String productId) =>
      '/traceability/$productId';
  static String traceabilityByQR(String qrCode) => '/traceability/qr/$qrCode';

  // ===========================================================================
  // Notification Endpoints
  // ===========================================================================

  static const String registerDevice = '/notifications/register';
  static const String unregisterDevice = '/notifications/unregister';
  static const String updateNotificationSettings = '/notifications/settings';
  static const String notificationHistory = '/notifications/history';

  // ===========================================================================
  // Sync Endpoints
  // ===========================================================================

  static const String syncQueue = '/sync/queue';
  static const String syncStatus = '/sync/status';
  static const String uploadBatch = '/sync/batch';

  // ===========================================================================
  // Health Check
  // ===========================================================================

  static const String healthCheck = '/health';
  static const String serverStatus = '/status';

  // ===========================================================================
  // Security — Certificate Pinning
  // ===========================================================================

  /// SHA-256 fingerprint (base64-encoded) of the production API server
  /// certificate.
  static const String certSha256Hash =
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
}
