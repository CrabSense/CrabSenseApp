import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

// Core
import '../constants/api_constants.dart';
import '../database/database.dart';
import '../network/api_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/token_refresh_interceptor.dart';
import '../network/network_info.dart';
import '../../shared/bloc/sync/sync_bloc.dart';


// Features - Authentication
import '../../features/authentication/data/datasources/auth_local_data_source.dart';
import '../../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../../features/authentication/data/datasources/biometric_auth_service.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/login_usecase.dart';
import '../../features/authentication/domain/usecases/logout_usecase.dart';
import '../../features/authentication/domain/usecases/refresh_token_usecase.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/biometric_cubit.dart';

// Features - Dashboard
import '../../features/dashboard/data/datasources/dashboard_local_data_source.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Features - QR Scanner
import '../../features/qr_scanner/data/datasources/scanner_local_data_source.dart';
import '../../features/qr_scanner/data/datasources/scanner_remote_data_source.dart';
import '../../features/qr_scanner/data/repositories/scanner_repository_impl.dart';
import '../../features/qr_scanner/domain/repositories/scanner_repository.dart';
import '../../features/qr_scanner/domain/usecases/scan_qr_code_usecase.dart';
import '../../features/qr_scanner/domain/usecases/scan_qr_quick_result_usecase.dart';
import '../../features/qr_scanner/domain/usecases/validate_qr_code_usecase.dart';
import '../../features/qr_scanner/presentation/bloc/scanner_bloc.dart';

// Features - Box Management
import '../../features/box/data/datasources/box_local_data_source.dart';
import '../../features/box/data/datasources/box_remote_data_source.dart';
import '../../features/box/data/repositories/box_repository_impl.dart';
import '../../features/box/domain/repositories/box_repository.dart';
import '../../features/box/domain/usecases/get_box_details_usecase.dart';
import '../../features/box/presentation/bloc/box_bloc.dart';

// Features - Video Capture
import '../../features/video_capture/data/datasources/video_local_data_source.dart';
import '../../features/video_capture/data/datasources/video_remote_data_source.dart';
import '../../features/video_capture/data/repositories/video_repository_impl.dart';
import '../../features/video_capture/data/services/video_compression_service.dart';
import '../../features/video_capture/domain/repositories/video_repository.dart';
import '../../features/video_capture/domain/usecases/capture_video_usecase.dart';
import '../../features/video_capture/domain/usecases/get_ai_results_usecase.dart';
import '../../features/video_capture/presentation/bloc/ai_results_bloc.dart';
import '../../features/video_capture/presentation/bloc/video_capture_bloc.dart';
import '../../shared/services/background_sync_service.dart';
import '../../shared/services/bidirectional_sync_manager.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/services/sync_progress.dart';
import '../../shared/services/sync_remote_data_source.dart';
import '../../shared/services/sync_service.dart';

// Features - Manual Inspection
import '../../features/manual_inspection/data/datasources/inspection_local_data_source.dart';
import '../../features/manual_inspection/data/datasources/inspection_remote_data_source.dart';
import '../../features/manual_inspection/data/repositories/inspection_repository_impl.dart';
import '../../features/manual_inspection/domain/repositories/inspection_repository.dart';
import '../../features/manual_inspection/domain/usecases/submit_feedback_use_case.dart';
import '../../features/manual_inspection/domain/usecases/submit_inspection_use_case.dart';
import '../../features/manual_inspection/presentation/bloc/inspection_bloc.dart';

// Features - Water Quality
import '../../features/water_quality/data/datasources/water_quality_local_data_source.dart';
import '../../features/water_quality/data/datasources/water_quality_remote_data_source.dart';
import '../../features/water_quality/data/repositories/water_quality_repository_impl.dart';
import '../../features/water_quality/domain/repositories/water_quality_repository.dart';
import '../../features/water_quality/domain/usecases/get_current_readings_usecase.dart';
import '../../features/water_quality/domain/usecases/get_historical_data_usecase.dart';
import '../../features/water_quality/presentation/bloc/water_quality_bloc.dart';

// Features - Alerts
import '../../features/alert/data/datasources/alert_local_data_source.dart';
import '../../features/alert/data/datasources/alert_remote_data_source.dart';
import '../../features/alert/data/repositories/alert_repository_impl.dart';
import '../../features/alert/domain/repositories/alert_repository.dart';
import '../../features/alert/domain/usecases/acknowledge_alert_usecase.dart';
import '../../features/alert/domain/usecases/dismiss_alert_usecase.dart';
import '../../features/alert/domain/usecases/get_alerts_usecase.dart';
import '../../features/alert/presentation/bloc/alert_bloc.dart';

// Features - Profile / Notification Preferences
import '../../features/profile/data/datasources/notification_preferences_local_data_source.dart';
import '../../features/profile/data/repositories/notification_preferences_repository_impl.dart';
import '../../features/profile/domain/repositories/notification_preferences_repository.dart';

// Features - Notification History
import '../../features/notifications/data/datasources/notification_history_local_data_source.dart';
import '../../features/notifications/data/repositories/notification_history_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_history_repository.dart';
import '../../features/notifications/domain/usecases/clear_notification_history_usecase.dart';
import '../../features/notifications/domain/usecases/get_notification_history_usecase.dart';
import '../../features/notifications/presentation/bloc/notification_history_bloc.dart';

// Features - Operation Logs
import '../../features/operation_logs/data/datasources/operation_local_data_source.dart';
import '../../features/operation_logs/data/datasources/operation_remote_data_source.dart';
import '../../features/operation_logs/data/repositories/operation_repository_impl.dart';
import '../../features/operation_logs/domain/repositories/operation_repository.dart';
import '../../features/operation_logs/domain/usecases/create_operation_log_usecase.dart';
import '../../features/operation_logs/domain/usecases/get_all_operation_logs_usecase.dart';
import '../../features/operation_logs/domain/usecases/get_operation_history_usecase.dart';
import '../../features/operation_logs/domain/usecases/update_operation_log_usecase.dart';
import '../../features/operation_logs/presentation/bloc/operation_bloc.dart';

// Features - Harvest
import '../../features/harvest/data/datasources/harvest_local_data_source.dart';
import '../../features/harvest/data/datasources/harvest_remote_data_source.dart';
import '../../features/harvest/data/repositories/harvest_repository_impl.dart';
import '../../features/harvest/domain/repositories/harvest_repository.dart';
import '../../features/harvest/domain/usecases/get_harvest_history_usecase.dart';
import '../../features/harvest/domain/usecases/get_harvest_summary_usecase.dart';
import '../../features/harvest/domain/usecases/record_harvest_usecase.dart';
import '../../features/harvest/presentation/bloc/harvest_bloc.dart';
import '../../features/harvest/presentation/bloc/harvest_history_bloc.dart';


// Features - Sales
import '../../features/sales/data/datasources/sales_local_data_source.dart';
import '../../features/sales/data/datasources/sales_remote_data_source.dart';
import '../../features/sales/data/repositories/sales_repository_impl.dart';
import '../../features/sales/domain/repositories/sales_repository.dart';
import '../../features/sales/domain/usecases/create_sale_usecase.dart';
import '../../features/sales/domain/usecases/get_sales_history_usecase.dart';
import '../../features/sales/domain/usecases/get_sales_summary_usecase.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';
import '../../features/sales/presentation/bloc/sales_history_bloc.dart';

// Features - Offline Sync
// import '../../features/offline_sync/data/datasources/sync_local_data_source.dart';
// import '../../features/offline_sync/data/repositories/sync_repository_impl.dart';
// import '../../features/offline_sync/domain/repositories/sync_repository.dart';
// import '../../features/offline_sync/domain/usecases/sync_pending_operations_usecase.dart';
// import '../../features/offline_sync/presentation/bloc/sync_bloc.dart';

/// Service Locator - Global GetIt instance
///
/// This is the single global instance of GetIt used throughout the application
/// for dependency injection. It provides access to all registered services,
/// repositories, data sources, use cases, and BLoCs.
final sl = GetIt.instance;

/// Initialize all dependencies
///
/// This function sets up the entire dependency injection container following
/// the Clean Architecture pattern. Dependencies are registered as lazy singletons
/// to ensure they are only instantiated when first accessed.
///
/// The registration follows this order:
/// 1. Core utilities (Logger, Network Info)
/// 2. External dependencies (Dio, Connectivity, Storage)
/// 3. Data sources (Remote and Local)
/// 4. Repositories
/// 5. Use cases
/// 6. BLoCs (registered as factories for fresh instances)
///
/// This function should be called once at app startup in main.dart
/// before runApp() is executed.
Future<void> init() async {
  //! ============================================================================
  //! Core Dependencies
  //! ============================================================================

  // Logger for structured logging throughout the app
  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    ),
  );

  // Network connectivity information
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! ============================================================================
  //! External Dependencies
  //! ============================================================================

  // Dio HTTP client for API communication
  // Configured with base URL, timeout, and interceptors
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // Auth + refresh — same JWT source as ApiClient / login persist.
    // AuthLocalDataSource is registered later in init(); factories stay lazy.
    dio.interceptors.add(
      AuthInterceptor(localDataSource: sl(), logger: sl()),
    );
    dio.interceptors.add(
      TokenRefreshInterceptor(localDataSource: sl(), dio: dio, logger: sl()),
    );
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, logPrint: (obj) => sl<Logger>().d(obj)),
    );

    return dio;
  });

  // ApiClient — Dio wrapper with auth interceptor, token refresh, cert pinning.
  // Registered after the raw Dio instance so AuthInterceptor can reference it.
  // Requirements: 1.1–1.10, 23.1–23.3
  sl.registerLazySingleton<ApiClient>(() => ApiClient(logger: sl(), authLocalDataSource: sl()));

  // Connectivity checker for network status monitoring
  sl.registerLazySingleton<Connectivity>(Connectivity.new);

  // Secure storage for sensitive data (JWT tokens, credentials)
  // Requirements: 1.6, 23.4 - JWT tokens stored in platform Keychain/Keystore
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      // Web: dùng localStorage với encryption key (hoạt động trên Chrome)
      webOptions: WebOptions(dbName: 'crabsense_secure', publicKey: 'CrabSenseWeb'),
    ),
  );

  // Biometric authenticator for fingerprint/face recognition (req 1.9)
  sl.registerLazySingleton<LocalAuthentication>(LocalAuthentication.new);

  // Drift SQLite database — single instance shared across all features.
  // Requirements: 13.3–13.10, 23.6
  sl.registerLazySingleton<AppDatabase>(AppDatabase.new);

  // Hive boxes for local key-value storage
  // These will be initialized in main.dart before calling init()
  // sl.registerLazySingleton<Box>(() => Hive.box('app_data'));
  // sl.registerLazySingleton<Box>(() => Hive.box('cache'));

  //! ============================================================================
  //! Shared Services
  //! ============================================================================

  // Notification service — FCM token management, permission request,
  // foreground / background message handling.
  // Requirements: 14.1–14.3, 14.6
  //
  // NOTE: NotificationHistoryLocalDataSource must be registered before
  // this line. The kNotifHistoryBoxName Hive box must be opened in
  // main.dart before init() is called.
  sl.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(
      logger: sl(),
      apiClient: sl(),
      secureStorage: sl(),
      historyDataSource: sl(),
    ),
  );

  // Sync service — offline queue management and DB queue operations.
  // Requirements: 13.3-13.4
  sl.registerLazySingleton<SyncService>(
    () => SyncServiceImpl(
      database: sl(),
      logger: sl(),
    ),
  );

  // Sync Remote Data Source — HTTP client wrapper for batch upload & server changes.
  // Requirements: 13.5
  sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSourceImpl(
      apiClient: sl(),
      logger: sl(),
    ),
  );

  // Bidirectional Sync Manager — detects network restoration, batches uploads,
  // downloads server changes, applies exponential backoff, and streams sync progress.
  // Requirements: 13.5-13.8
  sl.registerLazySingleton<BidirectionalSyncManager>(
    () => BidirectionalSyncManagerImpl(
      syncService: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      secureStorage: sl(),
      logger: sl(),
    ),
  );

  // Background Sync Service — WorkManager / BGTaskScheduler periodic sync scheduling
  // Requirements: 13.10
  sl.registerLazySingleton<BackgroundSyncService>(
    () => BackgroundSyncServiceImpl(
      syncService: sl(),
      syncManager: sl(),
      logger: sl(),
    ),
  );

  // Camera service for photo and video capture
  // Uncomment when implementation is ready
  // sl.registerLazySingleton<CameraService>(
  //   () => CameraServiceImpl(),
  // );

  //! ============================================================================
  //! Features - Authentication Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(dio: sl()));

  // Local data source uses FlutterSecureStorage for Keychain/Keystore storage.
  // JWT tokens are NEVER stored in SharedPreferences (req 1.6, 23.4).
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(secureStorage: sl()));

  // Repository - combines remote + local, maps exceptions to Failures
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      localAuth: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));

  // BiometricAuthService — wraps LocalAuthentication + FlutterSecureStorage
  // to provide availability checks, preference persistence, and biometric
  // challenge. Requirement: 1.9, 18.7, 23.4
  sl.registerLazySingleton<BiometricAuthService>(
    () => BiometricAuthServiceImpl(localAuth: sl(), secureStorage: sl()),
  );

  // BLoC - Registered as factory for fresh instances per screen
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      refreshTokenUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // BiometricCubit — manages availability state and preference toggle.
  // Registered as factory so each screen gets an independent instance.
  sl.registerFactory(() => BiometricCubit(biometricService: sl()));

  //! ============================================================================
  //! Features - Dashboard Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(database: sl(), logger: sl()),
  );

  // Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), logger: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetDashboardSummaryUseCase(sl()));

  // BLoC — registered in task 6.3
  sl.registerFactory(() => DashboardBloc(getDashboardSummary: sl()));

  //! ============================================================================
  //! Features - QR Scanner Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<ScannerRemoteDataSource>(
    () => ScannerRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ScannerLocalDataSource>(
    () => ScannerLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<ScannerRepository>(
    () => ScannerRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => ScanQRCodeUseCase(sl()));
  sl.registerLazySingleton(() => ScanQRQuickResultUseCase(sl()));
  sl.registerLazySingleton(() => const ValidateQRCodeUseCase());

  // BLoC
  sl.registerFactory(
    () => ScannerBloc(
      scanQRQuickResultUseCase: sl(),
      scannerRepository: sl(),
    ),
  );

  //! ============================================================================
  //! Features - Box Management Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<BoxRemoteDataSource>(
    () => BoxRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<BoxLocalDataSource>(() => BoxLocalDataSourceImpl(db: sl()));

  // Repository
  sl.registerLazySingleton<BoxRepository>(
    () => BoxRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetBoxDetailsUseCase(sl()));

  // BLoC — registered as factory for fresh instances per screen
  sl.registerFactory(() => BoxBloc(getBoxDetails: sl()));

  //! ============================================================================
  //! Features - Video Capture & AI Analysis Module
  //! ============================================================================
  //
  // Requirements: 5.4-5.6, 5.9, 22.7

  // Video compression service (video_compress package, FFmpeg-based)
  // Targets <10 MB output and 70% file size reduction (Req 5.4, 22.7).
  sl.registerLazySingleton<VideoCompressionService>(() => VideoCompressionService(logger: sl()));

  // Storage service — checks available disk space and offline queue usage
  // before a recording starts. Fail-open: if detection fails, recording
  // proceeds. Requirements: 5.9
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(logger: sl()));

  // Remote data source — Dio multipart upload with onSendProgress (Req 5.5)
  sl.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  // Local data source — Drift SQLite, queue / offline storage (Req 5.6)
  sl.registerLazySingleton<VideoLocalDataSource>(() => VideoLocalDataSourceImpl(db: sl()));

  // Repository — orchestrates compression, upload, offline queue,
  // and exponential back-off (delays: 1 s, 2 s, 4 s, 8 s, 16 s).
  // Requirements: 5.4-5.6, 5.9, 22.7
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      compressionService: sl(),
      logger: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CaptureVideoUseCase(sl()));
  sl.registerLazySingleton(() => GetAIResultsUseCase(sl()));

  // BLoC — factory so each screen gets a fresh instance.
  // capturedBy is resolved at runtime via AuthLocalDataSource / current user.
  // For now we register with a factory that accepts capturedBy as empty
  // string; screens that push VideoCaptureScreen should create their own
  // instance via BlocProvider with the authenticated user id.
  sl.registerFactory(
    () => VideoCaptureBloc(
      captureVideoUseCase: sl(),
      videoRepository: sl(),
      capturedBy: '',
      storageService: sl(),
    ),
  );

  // AI Results BLoC — factory for fresh instances per screen.
  sl.registerFactory(
    () => AiResultsBloc(getAIResultsUseCase: sl(), videoRepository: sl(), logger: sl()),
  );

  //! ============================================================================
  //! Features - Manual Inspection Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<InspectionRemoteDataSource>(
    () => InspectionRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<InspectionLocalDataSource>(
    () => InspectionLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<InspectionRepository>(
    () => InspectionRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SubmitInspectionUseCase(sl()));
  sl.registerLazySingleton(() => SubmitFeedbackUseCase(sl()));

  // BLoC — factory for fresh instance per screen
  sl.registerFactory(
    () => InspectionBloc(
      submitInspection: sl(),
      submitFeedback: sl(),
      repository: sl(),
      getAiResults: sl(),
      logger: sl(),
    ),
  );

  //! ============================================================================
  //! Features - Water Quality Module
  //! ============================================================================

  // Data Sources
  // Requirements: 8.1-8.10
  sl.registerLazySingleton<WaterQualityRemoteDataSource>(
    () => WaterQualityRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  // Local cache with 7-day retention (Requirement 8.5, 23.6)
  sl.registerLazySingleton<WaterQualityLocalDataSource>(
    () => WaterQualityLocalDataSourceImpl(database: sl()),
  );

  // Repository — offline-first, maps exceptions to Failures
  sl.registerLazySingleton<WaterQualityRepository>(
    () => WaterQualityRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCurrentReadingsUseCase(sl()));
  sl.registerLazySingleton(() => GetHistoricalDataUseCase(sl()));

  // BLoC — registered in task 13.3
  sl.registerFactory(
    () => WaterQualityBloc(
      getCurrentReadings: sl(),
      getHistoricalData: sl(),
      repository: sl(),
    ),
  );

  //! ============================================================================
  //! Features - Alerts Module
  //! ============================================================================

  // Data Sources
  // Requirements: 9.1-9.10
  sl.registerLazySingleton<AlertRemoteDataSource>(
    () => AlertRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<AlertLocalDataSource>(() => AlertLocalDataSourceImpl(database: sl()));

  // Repository — offline-first, maps exceptions to Failures
  sl.registerLazySingleton<AlertRepository>(
    () => AlertRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAlertsUseCase(sl()));
  sl.registerLazySingleton(() => AcknowledgeAlertUseCase(sl()));
  sl.registerLazySingleton(() => DismissAlertUseCase(sl()));

  // BLoC — factory for fresh instances per screen
  sl.registerFactory(
    () => AlertBloc(getAlerts: sl(), acknowledgeAlert: sl(), dismissAlert: sl(), repository: sl()),
  );

  //! ============================================================================
  //! Features - Operation Logs Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<OperationRemoteDataSource>(
    () => OperationRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<OperationLocalDataSource>(
    () => OperationLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<OperationRepository>(
    () => OperationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateOperationLogUseCase(sl()));
  sl.registerLazySingleton(() => GetOperationHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAllOperationLogsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOperationLogUseCase(sl()));

  // BLoC
  sl.registerFactory(() => OperationBloc(createOperationLog: sl(), updateOperationLog: sl()));

  //! ============================================================================
  //! Features - Harvest Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<HarvestRemoteDataSource>(
    () => HarvestRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<HarvestLocalDataSource>(
    () => HarvestLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<HarvestRepository>(
    () => HarvestRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => RecordHarvestUseCase(sl()));
  sl.registerLazySingleton(() => GetHarvestHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetHarvestSummaryUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => HarvestBloc(
      recordHarvest: sl(),
    ),
  );
  sl.registerFactory(
    () => HarvestHistoryBloc(
      getHarvestHistory: sl(),
      getHarvestSummary: sl(),
    ),
  );


  //! ============================================================================
  //! Features - Sales Module
  //! ============================================================================

  // Data Sources
  sl.registerLazySingleton<SalesRemoteDataSource>(
    () => SalesRemoteDataSourceImpl(apiClient: sl(), logger: sl()),
  );

  sl.registerLazySingleton<SalesLocalDataSource>(
    () => SalesLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<SalesRepository>(
    () => SalesRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateSaleUseCase(sl()));
  sl.registerLazySingleton(() => GetSalesHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetSalesSummaryUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => SalesBloc(
      createSale: sl(),
    ),
  );
  sl.registerFactory(
    () => SalesHistoryBloc(
      getSalesHistory: sl(),
      getSalesSummary: sl(),
    ),
  );

  //! ============================================================================
  //! Features - Offline Sync Module
  //! ============================================================================

  // Data Sources
  // Uncomment when implementation is ready
  // sl.registerLazySingleton<SyncLocalDataSource>(
  //   () => SyncLocalDataSourceImpl(hive: sl()),
  // );

  // Repository
  // Uncomment when implementation is ready
  // sl.registerLazySingleton<SyncRepository>(
  //   () => SyncRepositoryImpl(
  //     localDataSource: sl(),
  //     networkInfo: sl(),
  //   ),
  // );

  // Use Cases
  // Uncomment when implementation is ready
  // sl.registerLazySingleton(() => SyncPendingOperationsUseCase(sl()));

  // BLoC - Sync & Offline Indicator (Req 13.2, 13.8)
  sl.registerFactory<SyncBloc>(
    () => SyncBloc(
      networkInfo: sl(),
      syncManager: sl(),
      syncService: sl(),
    ),
  );


  //! ============================================================================
  //! Features - Profile / Notification Preferences Module
  //! ============================================================================

  // Local data source — Hive-backed key-value storage for prefs.
  // The box must be opened before init() is called (see main.dart).
  // Requirements: 14.9-14.10
  sl.registerLazySingleton<NotificationPreferencesLocalDataSource>(
    () => NotificationPreferencesLocalDataSourceImpl(box: Hive.box(kNotifPrefsBoxName)),
  );

  sl.registerLazySingleton<NotificationPreferencesRepository>(
    () => NotificationPreferencesRepositoryImpl(localDataSource: sl()),
  );

  //! ============================================================================
  //! Features - Notification History Module
  //! ============================================================================
  //
  // IMPORTANT: The 'notification_history' Hive box must be opened in main.dart
  // before init() is called:
  //   await Hive.openBox(kNotifHistoryBoxName);
  //
  // Requirements: 14.6

  sl.registerLazySingleton<NotificationHistoryLocalDataSource>(
    () => NotificationHistoryLocalDataSourceImpl(box: Hive.box(kNotifHistoryBoxName)),
  );

  sl.registerLazySingleton<NotificationHistoryRepository>(
    () => NotificationHistoryRepositoryImpl(localDataSource: sl(), logger: sl()),
  );

  sl.registerLazySingleton(() => GetNotificationHistoryUseCase(sl()));
  sl.registerLazySingleton(() => ClearNotificationHistoryUseCase(sl()));

  sl.registerFactory(
    () => NotificationHistoryBloc(getHistory: sl(), clearHistory: sl(), repository: sl()),
  );

  //! ============================================================================
  //! Additional Features
  //! ============================================================================

  // As you implement more features (Notifications, Traceability, Profile, etc.),
  // add their dependency registrations here following the same pattern:
  // 1. Data Sources (Remote & Local)
  // 2. Repository Implementation
  // 3. Use Cases
  // 4. BLoC (as factory)

  sl<Logger>().i('✅ Dependency injection initialized successfully');
}

/// Reset all dependencies
///
/// This function unregisters all dependencies from the service locator.
/// Useful for testing purposes or when you need to reinitialize the app.
///
/// WARNING: This should NOT be called during normal app operation.
/// Only use this in tests or very specific scenarios.
Future<void> reset() async {
  await sl.reset();
  sl<Logger>().w('⚠️ All dependencies have been reset');
}
