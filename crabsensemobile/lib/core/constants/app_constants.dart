/// Application-wide constants for CrabSense Mobile Application
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ===========================================================================
  // Application Information
  // ===========================================================================

  /// Application name
  static const String appName = 'CrabSense';

  /// Application full name
  static const String appFullName = 'CrabSense Mobile';

  /// Application tagline
  static const String appTagline = 'Smart Crab Farming Operations';

  /// Package name for Android
  static const String androidPackageName = 'com.crabsense.mobile';

  /// Bundle ID for iOS
  static const String iosBundleId = 'com.crabsense.mobile';

  // ===========================================================================
  // Brand Colors (Material Design 3)
  // ===========================================================================

  /// Primary brand color (#00C8FF)
  static const int primaryColorValue = 0xFF00C8FF;

  /// Background color (#081528)
  static const int backgroundColorValue = 0xFF081528;

  // ===========================================================================
  // UI Configuration
  // ===========================================================================

  /// Default border radius for cards (in dp)
  static const double cardBorderRadius = 16;

  /// Default border radius for buttons (in dp)
  static const double buttonBorderRadius = 14;

  /// Grid spacing system (in dp)
  static const double gridSpacing = 8;

  /// Default padding (in dp)
  static const double defaultPadding = 16;

  /// Small padding (in dp)
  static const double smallPadding = 8;

  /// Large padding (in dp)
  static const double largePadding = 24;

  /// Default elevation for cards
  static const double defaultElevation = 2;

  // ===========================================================================
  // Font Configuration
  // ===========================================================================

  /// Primary font family
  static const String fontFamily = 'Inter';

  // ===========================================================================
  // Pagination
  // ===========================================================================

  /// Default page size for paginated lists
  static const int defaultPageSize = 50;

  /// Maximum page size
  static const int maxPageSize = 100;

  // ===========================================================================
  // Cache Configuration
  // ===========================================================================

  /// Cache expiration duration (30 days)
  static const Duration cacheExpiration = Duration(days: 30);

  /// Data staleness warning threshold (30 minutes)
  static const Duration stalenessThreshold = Duration(minutes: 30);

  /// Fresh data threshold (5 minutes)
  static const Duration freshDataThreshold = Duration(minutes: 5);

  /// Cache retention period for historical data (7 days)
  static const Duration historicalDataRetention = Duration(days: 7);

  /// Alert history retention (30 days)
  static const Duration alertHistoryRetention = Duration(days: 30);

  // ===========================================================================
  // Auto-Refresh Intervals
  // ===========================================================================

  /// Dashboard auto-refresh interval (60 seconds)
  static const Duration dashboardRefreshInterval = Duration(seconds: 60);

  /// Water quality auto-refresh interval (30 seconds)
  static const Duration waterQualityRefreshInterval = Duration(seconds: 30);

  /// Alert auto-refresh interval (30 seconds)
  static const Duration alertRefreshInterval = Duration(seconds: 30);

  // ===========================================================================
  // Video Configuration
  // ===========================================================================

  /// Minimum video duration (5 seconds)
  static const Duration minVideoDuration = Duration(seconds: 5);

  /// Maximum video duration (10 seconds)
  static const Duration maxVideoDuration = Duration(seconds: 10);

  /// Maximum video file size (10 MB)
  static const int maxVideoSizeMB = 10;

  /// Maximum video file size in bytes
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;

  /// Target video compression ratio (70%)
  static const double videoCompressionRatio = 0.70;

  // ===========================================================================
  // Image Configuration
  // ===========================================================================

  /// Maximum image file size (5 MB)
  static const int maxImageSizeMB = 5;

  /// Maximum image file size in bytes
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;

  /// Image compression quality (80%)
  static const int imageCompressionQuality = 80;

  /// Maximum images per operation log
  static const int maxImagesPerOperation = 10;

  // ===========================================================================
  // Storage Configuration
  // ===========================================================================

  /// Maximum offline video storage (200 MB)
  static const int maxOfflineVideoStorageMB = 200;

  /// Maximum offline video storage in bytes
  static const int maxOfflineVideoStorageBytes = maxOfflineVideoStorageMB * 1024 * 1024;

  /// Storage warning threshold (80%)
  static const double storageWarningThreshold = 0.80;

  /// Maximum image cache size (200 MB)
  static const int maxImageCacheSizeMB = 200;

  /// Maximum image cache size in bytes
  static const int maxImageCacheSizeBytes = maxImageCacheSizeMB * 1024 * 1024;

  // ===========================================================================
  // Authentication Configuration
  // ===========================================================================

  /// Maximum login attempts before account lockout
  static const int maxLoginAttempts = 3;

  /// Account lockout duration (15 minutes)
  static const Duration accountLockoutDuration = Duration(minutes: 15);

  /// Access token refresh interval (5 minutes before expiry)
  static const Duration tokenRefreshInterval = Duration(minutes: 5);

  /// Access token validity duration (60 minutes)
  static const Duration accessTokenValidity = Duration(minutes: 60);

  /// Refresh token validity duration (7 days)
  static const Duration refreshTokenValidity = Duration(days: 7);

  // ===========================================================================
  // Password Requirements
  // ===========================================================================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Password must contain uppercase letter
  static const bool passwordRequiresUppercase = true;

  /// Password must contain lowercase letter
  static const bool passwordRequiresLowercase = true;

  /// Password must contain number
  static const bool passwordRequiresNumber = true;

  /// Password must contain special character
  static const bool passwordRequiresSpecialChar = false;

  // ===========================================================================
  // Validation Constraints
  // ===========================================================================

  /// Maximum name length
  static const int maxNameLength = 100;

  /// Maximum email length
  static const int maxEmailLength = 255;

  /// Maximum notes length
  static const int maxNotesLength = 1000;

  /// Minimum weight value (kg)
  static const double minWeight = 0.01;

  /// Maximum weight value (kg)
  static const double maxWeight = 10000;

  /// Minimum quantity value
  static const int minQuantity = 1;

  /// Maximum quantity value
  static const int maxQuantity = 1000000;

  // ===========================================================================
  // Water Quality Thresholds
  // ===========================================================================

  /// Minimum temperature (Celsius)
  static const double minTemperature = 26;

  /// Maximum temperature (Celsius)
  static const double maxTemperature = 30;

  /// Minimum pH level
  static const double minPH = 7.5;

  /// Maximum pH level
  static const double maxPH = 8.5;

  /// Minimum dissolved oxygen (mg/L)
  static const double minDissolvedOxygen = 5;

  /// Minimum salinity (ppt)
  static const double minSalinity = 15;

  /// Maximum salinity (ppt)
  static const double maxSalinity = 25;

  // ===========================================================================
  // Sync Configuration
  // ===========================================================================

  /// Maximum sync retry attempts
  static const int maxSyncRetries = 5;

  /// Initial sync retry delay (1 second)
  static const Duration initialSyncRetryDelay = Duration(seconds: 1);

  /// Maximum sync retry delay (16 seconds)
  static const Duration maxSyncRetryDelay = Duration(seconds: 16);

  /// Sync batch size
  static const int syncBatchSize = 20;

  /// Network connectivity check interval (5 seconds)
  static const Duration connectivityCheckInterval = Duration(seconds: 5);

  /// Network connectivity timeout (10 seconds)
  static const Duration connectivityTimeout = Duration(seconds: 10);

  // ===========================================================================
  // AI Configuration
  // ===========================================================================

  /// Minimum AI confidence score for acceptance (70%)
  static const double minAIConfidence = 0.70;

  /// AI analysis timeout (60 seconds)
  static const Duration aiAnalysisTimeout = Duration(seconds: 60);

  // ===========================================================================
  // Notification Configuration
  // ===========================================================================

  /// Video reminder time before end of day (2 hours)
  static const Duration videoReminderTime = Duration(hours: 2);

  /// Maximum notifications in history
  static const int maxNotificationHistory = 100;

  // ===========================================================================
  // Operation Log Configuration
  // ===========================================================================

  /// Edit window for operation logs (24 hours)
  static const Duration operationEditWindow = Duration(hours: 24);

  // ===========================================================================
  // Date/Time Formats
  // ===========================================================================

  /// Default date format
  static const String dateFormat = 'yyyy-MM-dd';

  /// Default time format
  static const String timeFormat = 'HH:mm:ss';

  /// Default datetime format
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  /// Display date format
  static const String displayDateFormat = 'MMM dd, yyyy';

  /// Display time format
  static const String displayTimeFormat = 'hh:mm a';

  /// Display datetime format
  static const String displayDateTimeFormat = 'MMM dd, yyyy hh:mm a';

  // ===========================================================================
  // Secure Storage Keys
  // ===========================================================================

  /// Access token storage key
  static const String accessTokenKey = 'access_token';

  /// Refresh token storage key
  static const String refreshTokenKey = 'refresh_token';

  /// User ID storage key
  static const String userIdKey = 'user_id';

  /// Biometric enabled storage key
  static const String biometricEnabledKey = 'biometric_enabled';

  /// FCM token storage key
  static const String fcmTokenKey = 'fcm_token';

  // ===========================================================================
  // Shared Preferences Keys
  // ===========================================================================

  /// Theme mode key
  static const String themeModeKey = 'theme_mode';

  /// Language code key
  static const String languageCodeKey = 'language_code';

  /// Notification settings key
  static const String notificationSettingsKey = 'notification_settings';

  /// Last sync timestamp key
  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  /// Selected farm ID key
  static const String selectedFarmIdKey = 'selected_farm_id';

  /// Selected pond ID key
  static const String selectedPondIdKey = 'selected_pond_id';

  // ===========================================================================
  // Database Configuration
  // ===========================================================================

  /// Database name
  static const String databaseName = 'crabsense.db';

  /// Database version
  static const int databaseVersion = 1;

  // ===========================================================================
  // Asset Paths
  // ===========================================================================

  /// Logo asset path
  static const String logoPath = 'assets/images/Logo_CarbSense.png';

  /// Fonts directory
  static const String fontsDirectory = 'assets/fonts';

  /// Images directory
  static const String imagesDirectory = 'assets/images';

  // ===========================================================================
  // External Links
  // ===========================================================================

  /// Terms of service URL
  static const String termsOfServiceUrl = 'https://crabsense.app/terms';

  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://crabsense.app/privacy';

  /// Support email
  static const String supportEmail = 'support@crabsense.app';

  /// Website URL
  static const String websiteUrl = 'https://crabsense.app';

  // ===========================================================================
  // Supported Languages
  // ===========================================================================

  /// English language code
  static const String englishLanguageCode = 'en';

  /// Vietnamese language code
  static const String vietnameseLanguageCode = 'vi';

  /// Default language code
  static const String defaultLanguageCode = englishLanguageCode;

  /// Supported language codes
  static const List<String> supportedLanguages = [englishLanguageCode, vietnameseLanguageCode];

  // ===========================================================================
  // Error Messages
  // ===========================================================================

  /// Generic error message
  static const String genericErrorMessage = 'An error occurred. Please try again.';

  /// Network error message
  static const String networkErrorMessage = 'No internet connection. Please check your network.';

  /// Timeout error message
  static const String timeoutErrorMessage = 'Request timeout. Please try again.';

  /// Server error message
  static const String serverErrorMessage = 'Server error. Please try again later.';

  /// Permission denied message
  static const String permissionDeniedMessage = 'Permission denied. Please check your permissions.';

  /// Insufficient storage message
  static const String insufficientStorageMessage =
      'Insufficient storage space. Please free up some space.';
}
