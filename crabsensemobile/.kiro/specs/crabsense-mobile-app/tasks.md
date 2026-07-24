# Implementation Plan: CrabSense Mobile Application

## Overview

This implementation plan breaks down the CrabSense Mobile Application development into discrete, actionable coding tasks following Clean Architecture with BLoC state management. The application is built with Flutter 3.x and Dart 3.x, implementing offline-first architecture with comprehensive IoT integration for smart crab farming operations.

**Key Technologies:**
- **Framework:** Flutter 3.x with Material Design 3
- **State Management:** flutter_bloc (BLoC pattern)
- **Navigation:** go_router with deep linking
- **Local Storage:** drift (SQLite), flutter_secure_storage, hive
- **Networking:** dio with interceptors and certificate pinning
- **Media:** camera, mobile_scanner, video_compress
- **Push Notifications:** firebase_messaging, flutter_local_notifications

## Tasks

- [x] 1. Project Setup and Core Infrastructure
  - [x] 1.1 Initialize Flutter project with proper directory structure
    - Create Clean Architecture folder structure: features/, core/, shared/
    - Set up lib/ directories: app/, core/, features/, shared/
    - Configure pubspec.yaml with required dependencies
    - Set up assets folder with images and fonts
    - Configure analysis_options.yaml with strict linting rules
    - _Requirements: All requirements rely on proper project foundation_

  - [x] 1.2 Implement dependency injection with get_it
    - Create core/di/injection.dart for service locator setup
    - Register repositories, data sources, use cases, and BLoCs
    - Implement lazy singleton pattern for services
    - Set up init() function to be called at app startup
    - _Requirements: 1.8, 19.1-19.10_

  - [x] 1.3 Create core utilities and constants
    - Implement core/constants/api_constants.dart with endpoint URLs
    - Create core/constants/app_constants.dart with app-wide values
    - Implement core/utils/validators.dart for input validation
    - Create core/utils/extensions.dart for Dart extensions
    - Implement core/utils/logger.dart for structured logging
    - _Requirements: All requirements need utilities_

  - [x] 1.4 Implement error handling framework
    - Create core/error/failures.dart with Failure abstract class
    - Implement specific failure types: NetworkFailure, ServerFailure, CacheFailure, ValidationFailure
    - Create core/error/exceptions.dart with exception classes
    - Implement error-to-failure mapping utilities
    - _Requirements: 21.1-21.10_


- [x] 2. Theme and UI Foundation
  - [x] 2.1 Implement Material Design 3 theme
    - Create app/theme.dart with CrabSense brand colors
    - Define color scheme: primary #00C8FF, background #081528
    - Implement typography with Inter font family
    - Configure component themes: cards, buttons, inputs
    - Set up dark mode theme as default
    - _Requirements: 20.1-20.10_

  - [x] 2.2 Create reusable UI components library
    - Implement shared/widgets/cards/crabsense_card.dart with glassmorphism
    - Create shared/widgets/buttons/ (primary, secondary, text, icon, FAB)
    - Implement shared/widgets/inputs/ (text fields, dropdowns, date pickers)
    - Create shared/widgets/loading/skeleton_loader.dart
    - Implement shared/widgets/errors/error_state_widget.dart
    - _Requirements: 20.1-20.10, 21.6_

  - [x] 2.3 Write widget tests for reusable components
    - Test CrabSenseCard rendering and tap behavior
    - Test button variants and disabled states
    - Test input validation and error states
    - Test skeleton loader animations
    - _Requirements: 25.2, 25.4_

- [x] 3. Authentication Module
  - [x] 3.1 Create authentication domain layer
    - Implement features/auth/domain/entities/user.dart with User entity
    - Create features/auth/domain/repositories/auth_repository.dart interface
    - Implement use cases: LoginUseCase, LogoutUseCase, RefreshTokenUseCase
    - Define UserRole enum: admin, farmManager, fieldOperator, sales, viewer
    - _Requirements: 1.1-1.10, 19.1-19.10_

  - [x] 3.2 Implement authentication data layer
    - Create features/auth/data/models/user_model.dart with JSON serialization
    - Implement features/auth/data/datasources/auth_remote_data_source.dart
    - Create features/auth/data/datasources/auth_local_data_source.dart
    - Implement features/auth/data/repositories/auth_repository_impl.dart
    - Set up JWT token storage in FlutterSecureStorage
    - _Requirements: 1.1-1.10, 23.4_

  - [x] 3.3 Build authentication presentation layer
    - Implement features/auth/presentation/bloc/auth_bloc.dart with states: unauthenticated, authenticated, loading, error
    - Create features/auth/presentation/screens/login_screen.dart with credential inputs
    - Implement password validation and error display
    - Add loading indicator during authentication
    - _Requirements: 1.1-1.10_


  - [x] 3.4 Implement API client with authentication
    - Create core/network/api_client.dart using Dio
    - Add authorization header interceptor for JWT tokens
    - Implement token refresh on 401 response
    - Configure timeout settings (30 seconds)
    - Set up certificate pinning for security
    - _Requirements: 1.1-1.10, 23.1-23.3_

  - [x] 3.5 Write unit tests for authentication BLoC
    - Test login success emits [LoginLoading, LoginSuccess]
    - Test login failure emits [LoginLoading, LoginError]
    - Test account lockout after 3 failed attempts
    - Test token refresh logic
    - _Requirements: 1.5, 25.1_

  - [x] 3.6 Implement biometric authentication
    - Create features/auth/data/datasources/biometric_auth_service.dart
    - Implement fingerprint/face ID verification
    - Add biometric login flow to login screen
    - Store biometric preference in secure storage
    - Handle biometric availability check
    - _Requirements: 1.9_

- [x] 4. Navigation and Routing
  - [x] 4.1 Implement go_router configuration
    - Create app/router.dart with route definitions
    - Define routes: /, /login, /dashboard, /scanner, /box/:id, /water-quality, /alerts
    - Implement deep linking for traceability: /traceability/:productId
    - Set up route guards for authentication
    - Configure redirect logic for unauthenticated users
    - _Requirements: 1.3, 1.7, 17.1_

  - [x] 4.2 Create app root widget with router
    - Implement app/app.dart as MaterialApp with router configuration
    - Set up theme from app/theme.dart
    - Configure navigation observer for analytics
    - Add error page for invalid routes
    - _Requirements: 1.1-1.10_

- [x] 5. Local Database Setup
  - [x] 5.1 Define Drift database schema
    - Create core/database/database.dart with @DriftDatabase annotation
    - Define tables: Users, Boxes, Crabs, WaterQualityReadings, Alerts, OperationLogs, Harvests, Sales, SyncQueue
    - Implement primary keys and foreign key relationships
    - Add isDirty and syncedAt columns for sync tracking
    - _Requirements: 13.3-13.10, 23.6_


  - [x] 5.2 Implement database migrations
    - Create initial migration (version 1) with all tables
    - Implement core/database/migrations/ directory structure
    - Add migration logic in database.dart
    - Test migration on fresh install
    - _Requirements: 13.3-13.10_

  - [x] 5.3 Write tests for database operations
    - Test table creation and schema validation
    - Test CRUD operations for each table
    - Test query performance with indexed fields
    - Test transaction rollback behavior
    - _Requirements: 25.1_

- [x] 6. Dashboard Module
  - [x] 6.1 Create dashboard domain layer
    - Implement features/dashboard/domain/entities/dashboard_summary.dart
    - Create features/dashboard/domain/repositories/dashboard_repository.dart interface
    - Implement GetDashboardSummaryUseCase
    - _Requirements: 2.1-2.10_

  - [x] 6.2 Implement dashboard data layer
    - Create features/dashboard/data/models/dashboard_summary_model.dart
    - Implement features/dashboard/data/datasources/dashboard_remote_data_source.dart
    - Create features/dashboard/data/datasources/dashboard_local_data_source.dart
    - Implement features/dashboard/data/repositories/dashboard_repository_impl.dart
    - Add parallel data fetching with Future.wait for alerts, videos, water quality, harvests
    - _Requirements: 2.1-2.10_

  - [x] 6.3 Build dashboard presentation layer
    - Implement features/dashboard/presentation/bloc/dashboard_bloc.dart
    - Create features/dashboard/presentation/screens/dashboard_screen.dart
    - Implement greeting widget with user name and farm selection
    - Create quick metrics cards: active boxes, videos due, alerts count
    - Add quick action buttons: Scan QR, Capture Video, Operation Log
    - Display active alerts summary with navigation
    - _Requirements: 2.1-2.10_

  - [x] 6.4 Implement dashboard refresh and offline behavior
    - Add pull-to-refresh gesture on dashboard
    - Implement auto-refresh every 60 seconds when online
    - Display cached data with offline indicator when network unavailable
    - Show skeleton loading during initial fetch
    - _Requirements: 2.6-2.7, 2.9-2.10_


- [x] 7. Checkpoint - Verify Authentication and Dashboard
  - Ensure all tests pass, verify login flow works end-to-end
  - Test dashboard displays correctly with mock data
  - Verify offline mode shows cached data
  - Ask the user if questions arise

- [x] 8. QR Scanner Module
  - [x] 8.1 Create scanner domain layer
    - Implement features/scanner/domain/entities/scan_result.dart
    - Create features/scanner/domain/repositories/scanner_repository.dart interface
    - Implement ScanQRCodeUseCase and ValidateQRCodeUseCase
    - _Requirements: 3.1-3.10_

  - [x] 8.2 Implement scanner presentation layer
    - Create features/scanner/presentation/bloc/scanner_bloc.dart
    - Implement features/scanner/presentation/screens/qr_scanner_screen.dart
    - Add mobile_scanner widget with camera preview
    - Implement QR detection callback with haptic feedback
    - Add flashlight toggle button for low-light environments
    - Display scanning guide overlay for first-time users
    - _Requirements: 3.1-3.10, 24.1-24.2_

  - [x] 8.3 Implement camera permission handling
    - Request camera permission with rationale dialog
    - Handle permission denied state with settings navigation
    - Show appropriate error message if permission permanently denied
    - _Requirements: 3.4, 24.1-24.9_

  - [x] 8.4 Add QR validation and box data fetching
    - Decode QR code and validate format
    - Fetch box data from repository on successful scan
    - Navigate to box details screen with box ID
    - Handle invalid QR codes with error message and retry option
    - Queue scan for sync when offline
    - _Requirements: 3.2-3.3, 3.6-3.7_

- [x] 9. Box Management Module
  - [x] 9.1 Create box domain layer
    - Implement features/box/domain/entities/box.dart with Box entity
    - Create features/box/domain/entities/crab.dart with Crab entity
    - Define features/box/domain/repositories/box_repository.dart interface
    - Implement use cases: GetBoxDetailsUseCase, AddCrabUseCase, TransferCrabUseCase, UpdateBoxUseCase
    - Define enums: BoxStatus, CrabSpecies, MoltingStatus, HealthStatus
    - _Requirements: 4.1-4.10, 16.1-16.10_


  - [x] 9.2 Implement box data layer
    - Create features/box/data/models/box_model.dart with JSON serialization
    - Create features/box/data/models/crab_model.dart with JSON serialization
    - Implement features/box/data/datasources/box_remote_data_source.dart
    - Create features/box/data/datasources/box_local_data_source.dart
    - Implement features/box/data/repositories/box_repository_impl.dart
    - _Requirements: 4.1-4.10, 16.1-16.10_

  - [x] 9.3 Build box details presentation layer
    - Implement features/box/presentation/bloc/box_bloc.dart
    - Create features/box/presentation/screens/box_details_screen.dart
    - Display box identifier, location, farm/pond information
    - Show current crab count, capacity, average weight
    - Display latest water quality readings with visual indicators
    - Show AI health status with confidence score
    - List active alerts associated with box
    - _Requirements: 4.1-4.10_

  - [x] 9.4 Implement box action panel
    - Create features/box/presentation/widgets/action_panel.dart
    - Add action buttons: Capture Video, Manual Inspection, Harvest, Quick Sale
    - Implement navigation to respective feature screens
    - Show disabled state based on user permissions
    - _Requirements: 4.6, 19.1-19.10_

  - [x] 9.5 Create box timeline and history
    - Implement features/box/presentation/widgets/box_timeline_widget.dart
    - Display recent operations and events chronologically
    - Add filters: operation type, date range
    - Implement pagination for large datasets (50 items per page)
    - _Requirements: 4.8_

  - [x] 9.6 Write integration tests for box module
    - Test QR scan → box details navigation flow
    - Test box data loading and caching
    - Test offline mode displays stale data warning
    - _Requirements: 4.7, 4.10, 25.3_

- [x] 10. Video Capture and AI Analysis Module
  - [x] 10.1 Create video domain layer
    - Implement features/video/domain/entities/video.dart
    - Create features/video/domain/entities/ai_detection.dart with detection results
    - Define features/video/domain/repositories/video_repository.dart interface
    - Implement use cases: CaptureVideoUseCase, UploadVideoUseCase, GetAIResultsUseCase
    - _Requirements: 5.1-5.10, 6.1-6.10_


  - [x] 10.2 Implement video data layer
    - Create features/video/data/models/video_model.dart
    - Create features/video/data/models/ai_detection_model.dart
    - Implement features/video/data/datasources/video_remote_data_source.dart
    - Create features/video/data/datasources/video_local_data_source.dart
    - Implement video upload with progress tracking using Dio
    - _Requirements: 5.1-5.10, 6.1-6.10_

  - [x] 10.3 Build video capture presentation layer
    - Implement features/video/presentation/bloc/video_capture_bloc.dart
    - Create features/video/presentation/screens/video_capture_screen.dart
    - Initialize camera controller and display preview
    - Add recording timer display (5-10 seconds)
    - Implement auto-stop at 10 seconds
    - Display recording guidelines overlay (distance, lighting, movement)
    - Add front/rear camera toggle button
    - _Requirements: 5.1-5.10, 24.1-24.9_

  - [x] 10.4 Implement video compression and upload
    - Integrate video_compress package for file size reduction
    - Compress video to under 10MB (target 70% reduction)
    - Upload video when network available with progress indicator
    - Queue video in offline storage when network unavailable
    - Handle upload failure with exponential backoff retry
    - Associate video with scanned box identifier
    - _Requirements: 5.4-5.6, 5.9, 22.7_

  - [x] 10.5 Build AI results presentation layer
    - Implement features/video/presentation/bloc/ai_results_bloc.dart
    - Create features/video/presentation/screens/ai_results_screen.dart
    - Display molting status: Pre-Molt, Molting, Post-Molt, Hard Shell
    - Show health indicators: Normal, Disease, Stress
    - Display confidence score as percentage
    - Show visual overlays highlighting detected crabs
    - Present actionable recommendations: Continue Monitoring, Harvest Ready, Treat Disease
    - _Requirements: 6.1-6.10_

  - [x] 10.6 Implement storage space check
    - Check available storage before video recording
    - Display error message if insufficient space
    - Warn user when offline video storage exceeds 80% limit
    - _Requirements: 5.9_


- [x] 11. Manual Inspection Module
  - [x] 11.1 Create inspection domain layer
    - Implement features/inspection/domain/entities/inspection.dart
    - Create features/inspection/domain/repositories/inspection_repository.dart interface
    - Implement SubmitInspectionUseCase and SubmitFeedbackUseCase
    - _Requirements: 7.1-7.10_

  - [x] 11.2 Implement inspection data layer
    - Create features/inspection/data/models/inspection_model.dart
    - Implement features/inspection/data/datasources/inspection_remote_data_source.dart
    - Create features/inspection/data/datasources/inspection_local_data_source.dart
    - Implement features/inspection/data/repositories/inspection_repository_impl.dart
    - _Requirements: 7.1-7.10_

  - [x] 11.3 Build inspection presentation layer
    - Implement features/inspection/presentation/bloc/inspection_bloc.dart
    - Create features/inspection/presentation/screens/inspection_screen.dart
    - Display AI results for comparison at top of screen
    - Add form inputs: molting status dropdown, health condition dropdown, weight numeric input, notes text area
    - Implement photo capture widget for additional documentation
    - Add Correct/Incorrect feedback buttons for AI results
    - Validate required fields on submission
    - _Requirements: 7.1-7.10_

  - [x] 11.4 Implement inspection submission and feedback
    - Submit inspection data to repository
    - Send feedback to AI service for model improvement
    - Update box records with manual inspection data
    - Queue inspection data in offline storage when network unavailable
    - Track agreement rate between AI and manual inspections
    - _Requirements: 7.5-7.9_

- [x] 12. Checkpoint - Verify Core Features
  - Ensure QR scan → box details → video capture flow works
  - Test video compression and upload
  - Verify manual inspection form and submission
  - Test offline queuing for videos and inspections
  - Ask the user if questions arise

- [ ] 13. Water Quality Monitoring Module
  - [x] 13.1 Create water quality domain layer
    - Implement features/water_quality/domain/entities/water_quality.dart
    - Create features/water_quality/domain/entities/water_quality_thresholds.dart
    - Define features/water_quality/domain/repositories/water_quality_repository.dart interface
    - Implement use cases: GetCurrentReadingsUseCase, GetHistoricalDataUseCase
    - _Requirements: 8.1-8.10_


  - [x] 13.2 Implement water quality data layer
    - Create features/water_quality/data/models/water_quality_model.dart
    - Implement features/water_quality/data/datasources/water_quality_remote_data_source.dart
    - Create features/water_quality/data/datasources/water_quality_local_data_source.dart
    - Implement features/water_quality/data/repositories/water_quality_repository_impl.dart
    - Add caching with 7-day retention for historical data
    - _Requirements: 8.1-8.10_

  - [x] 13.3 Build water quality presentation layer
    - Implement features/water_quality/presentation/bloc/water_quality_bloc.dart
    - Create features/water_quality/presentation/screens/water_quality_screen.dart
    - Display current readings: temperature, pH, dissolved oxygen, salinity
    - Show sensor readings with timestamp and unit labels
    - Highlight out-of-range values with warning color indicators
    - Implement auto-refresh every 30 seconds when screen active
    - Display device offline status if IoT sensor disconnected
    - _Requirements: 8.1-8.10_

  - [x] 13.4 Create historical charts with fl_chart
    - Implement features/water_quality/presentation/widgets/historical_chart.dart
    - Add line charts for 24 hours, 7 days, 30 days time ranges
    - Implement zoom and pan gestures
    - Mark threshold lines on charts
    - Display alert markers on historical data
    - _Requirements: 8.5_

  - [x] 13.5 Implement farm and pond filtering
    - Add dropdown selectors for farm and pond
    - Filter sensor readings by selected location
    - Update charts when selection changes
    - _Requirements: 8.9_

- [x] 14. Alert Management Module
  - [x] 14.1 Create alert domain layer
    - Implement features/alert/domain/entities/alert.dart
    - Define AlertType enum: waterQuality, equipment, crabHealth, maintenance, task, system
    - Define AlertSeverity enum: critical, warning, info
    - Define AlertStatus enum: unread, read, acknowledged, dismissed
    - Create features/alert/domain/repositories/alert_repository.dart interface
    - Implement use cases: GetAlertsUseCase, AcknowledgeAlertUseCase, DismissAlertUseCase
    - _Requirements: 9.1-9.10_


  - [x] 14.2 Implement alert data layer
    - Create features/alert/data/models/alert_model.dart
    - Implement features/alert/data/datasources/alert_remote_data_source.dart
    - Create features/alert/data/datasources/alert_local_data_source.dart
    - Implement features/alert/data/repositories/alert_repository_impl.dart
    - Add 30-day history retention in local database
    - _Requirements: 9.1-9.10_

  - [x] 14.3 Build alert list presentation layer
    - Implement features/alert/presentation/bloc/alert_bloc.dart
    - Create features/alert/presentation/screens/alert_screen.dart
    - Display alerts sorted by timestamp descending
    - Show unread count badge on navigation tab
    - Implement categorization by severity with color indicators
    - Add filtering: by severity, type, status (unread/read/dismissed)
    - Display alert history for last 30 days
    - _Requirements: 9.1-9.10_

  - [x] 14.4 Create alert card widget
    - Implement features/alert/presentation/widgets/alert_card.dart
    - Display alert type icon, severity indicator, title, message
    - Show timestamp and recommended actions
    - Add acknowledge and dismiss action buttons
    - Implement navigation to related screen (e.g., alert → water quality)
    - _Requirements: 9.5-9.6_

  - [x] 14.5 Implement alert acknowledgement
    - Handle acknowledge and dismiss button taps
    - Update alert status within 2 seconds when online
    - Queue acknowledgements when offline for later sync
    - Refresh alert list after status change
    - _Requirements: 9.6-9.7, 9.10_

- [x] 15. Push Notifications
  - [x] 15.1 Implement notification service
    - Create shared/services/notification_service.dart
    - Integrate firebase_messaging for FCM
    - Request notification permissions on app install
    - Register device token with server when permission granted
    - _Requirements: 14.1-14.3_

  - [x] 15.2 Handle notification categories and display
    - Support categories: Critical Alert, Warning, Task Reminder, System Update
    - Display in-app banner notification when app in foreground
    - Show system tray notification when app in background/terminated
    - Implement notification tap handling with deep link navigation
    - _Requirements: 14.3-14.5, 14.8_


  - [x] 15.3 Create notification settings
    - Implement features/profile/presentation/widgets/notification_settings.dart
    - Allow user to enable/disable notifications by category
    - Store notification preferences in local storage
    - Add toggle for notification sound, vibration, LED indicator
    - _Requirements: 14.9-14.10_

  - [x] 15.4 Implement notification history
    - Display notification history in app notification center
    - Show notification title, message, timestamp
    - Group notifications by date
    - Implement clear all functionality
    - _Requirements: 14.6_

- [x] 16. Operation Logging Module
  - [x] 16.1 Create operation domain layer
    - Implement features/operation/domain/entities/operation_log.dart
    - Define OperationType enum: feeding, waterChange, mineralAddition, cleaning, medication, inspection
    - Create features/operation/domain/repositories/operation_repository.dart interface
    - Implement use cases: CreateOperationLogUseCase, GetOperationHistoryUseCase, UpdateOperationLogUseCase
    - _Requirements: 10.1-10.10_

  - [x] 16.2 Implement operation data layer
    - Create features/operation/data/models/operation_log_model.dart
    - Implement features/operation/data/datasources/operation_remote_data_source.dart
    - Create features/operation/data/datasources/operation_local_data_source.dart
    - Implement features/operation/data/repositories/operation_repository_impl.dart
    - _Requirements: 10.1-10.10_

  - [x] 16.3 Build operation logging presentation layer
    - Implement features/operation/presentation/bloc/operation_bloc.dart
    - Create features/operation/presentation/screens/operation_log_screen.dart
    - Display form with operation type dropdown
    - Add box selection (single or multiple)
    - Include timestamp input (auto-filled, editable)
    - Add quantity/amount numeric input (optional)
    - Include notes text area (optional)
    - Add photo attachment support with image_picker
    - _Requirements: 10.1-10.10_

  - [x] 16.4 Implement operation timeline view
    - Create features/operation/presentation/widgets/operation_timeline.dart
    - Display operations chronologically with date grouping
    - Add filters: operation type, box, date range
    - Implement search by keywords in notes
    - Support pagination (50 items per page)
    - _Requirements: 10.8_


  - [x] 16.5 Implement operation submission and editing
    - Validate required fields on submission
    - Submit to repository and sync immediately when online
    - Queue in offline storage when network unavailable
    - Allow editing within 24 hours of creation
    - Enforce Field_Operator role or higher permission
    - _Requirements: 10.2-10.7, 10.9-10.10_

- [ ] 17. Harvest Recording Module
  - [ ] 17.1 Create harvest domain layer
    - Implement features/harvest/domain/entities/harvest.dart
    - Define QualityGrade enum: gradeA, gradeB, gradeC
    - Create features/harvest/domain/repositories/harvest_repository.dart interface
    - Implement use cases: RecordHarvestUseCase, GetHarvestHistoryUseCase, GetHarvestSummaryUseCase
    - _Requirements: 11.1-11.10_

  - [ ] 17.2 Implement harvest data layer
    - Create features/harvest/data/models/harvest_model.dart
    - Implement features/harvest/data/datasources/harvest_remote_data_source.dart
    - Create features/harvest/data/datasources/harvest_local_data_source.dart
    - Implement features/harvest/data/repositories/harvest_repository_impl.dart
    - _Requirements: 11.1-11.10_

  - [ ] 17.3 Build harvest recording presentation layer
    - Implement features/harvest/presentation/bloc/harvest_bloc.dart
    - Create features/harvest/presentation/screens/harvest_screen.dart
    - Display harvest form with box selection
    - Add input fields: total weight, crab count, quality grade, harvest date
    - Include photo capture for harvested crabs
    - Add optional notes text area
    - _Requirements: 11.1-11.10_

  - [ ] 17.4 Implement harvest submission with inventory update
    - Validate weight is positive number
    - Submit harvest record to repository
    - Update box inventory by reducing crab count atomically
    - Associate harvest with Field_Operator identity
    - Sync immediately when online, queue when offline
    - _Requirements: 11.3-11.8_

  - [ ] 17.5 Create harvest history and summary views
    - Display harvest history with filterable date range
    - Calculate cumulative harvest weight per farm per week
    - Show weekly/monthly summary statistics
    - Implement export to CSV functionality
    - _Requirements: 11.9-11.10_


- [ ] 18. Sales Management Module
  - [ ] 18.1 Create sales domain layer
    - Implement features/sales/domain/entities/sale.dart
    - Define PaymentMethod enum: cash, bankTransfer, credit
    - Define PaymentStatus enum: pending, completed, cancelled
    - Create features/sales/domain/repositories/sales_repository.dart interface
    - Implement use cases: CreateSaleUseCase, GetSalesHistoryUseCase, GetSalesSummaryUseCase
    - _Requirements: 12.1-12.10_

  - [ ] 18.2 Implement sales data layer
    - Create features/sales/data/models/sale_model.dart
    - Implement features/sales/data/datasources/sales_remote_data_source.dart
    - Create features/sales/data/datasources/sales_local_data_source.dart
    - Implement features/sales/data/repositories/sales_repository_impl.dart
    - _Requirements: 12.1-12.10_

  - [ ] 18.3 Build sales recording presentation layer
    - Implement features/sales/presentation/bloc/sales_bloc.dart
    - Create features/sales/presentation/screens/sales_screen.dart
    - Display form with buyer information fields: name, contact
    - Add product details: quantity, unit price (auto-calculate total)
    - Include payment method dropdown
    - Add sale date picker
    - _Requirements: 12.1-12.10_

  - [ ] 18.4 Implement sales submission with validation
    - Validate quantity does not exceed available harvested inventory
    - Generate unique sale transaction identifier
    - Submit sale record to repository
    - Sync immediately when online, queue when offline
    - Enforce sales role permission check
    - _Requirements: 12.3-12.9_

  - [ ] 18.5 Create sales summary and reports
    - Display daily and weekly sales summary
    - Show total revenue and quantity sold
    - Implement filtering by date range
    - Add export to CSV functionality
    - _Requirements: 12.10_

- [ ] 19. Checkpoint - Verify Business Logic Modules
  - Test water quality monitoring with mock sensor data
  - Verify alert display and acknowledgement
  - Test operation logging with photo attachments
  - Verify harvest and sales flows with inventory updates
  - Ensure push notifications work in foreground and background
  - Ask the user if questions arise


- [ ] 20. Offline Synchronization
  - [ ] 20.1 Implement connectivity monitoring
    - Create core/network/network_info.dart using connectivity_plus
    - Implement stream-based connectivity updates
    - Detect WiFi, mobile, ethernet connection types
    - Notify app when network status changes
    - _Requirements: 13.1-13.2_

  - [ ] 20.2 Create sync queue management
    - Implement shared/services/sync_service.dart
    - Define sync queue table operations in database
    - Support entity types: harvest, sale, operation_log, inspection, video, alert_ack
    - Implement priority levels: critical (1), high (2), medium (3), low (4)
    - Add retry count and error message tracking
    - _Requirements: 13.3-13.4_

  - [ ] 20.3 Implement bidirectional sync logic
    - Detect network availability and trigger sync
    - Process queued items in chronological order
    - Batch upload operations to API
    - Download server changes since last sync
    - Implement exponential backoff for failed items (1s, 2s, 4s, 8s, 16s)
    - Update sync status and display progress to user
    - _Requirements: 13.5-13.8_

  - [ ] 20.4 Implement conflict resolution
    - Use last-write-wins with timestamp comparison
    - Server timestamp > local timestamp → server wins
    - Prompt user for manual resolution on simultaneous edits
    - Preserve both versions with conflict flag for review
    - _Requirements: 13.9_

  - [ ] 20.5 Create offline indicator UI
    - Display offline indicator in app bar when network unavailable
    - Show sync progress with item count and status
    - Add manual sync trigger button
    - Display last sync timestamp
    - _Requirements: 13.2, 13.8_

  - [ ] 20.6 Implement background sync
    - Use WorkManager for Android background sync
    - Use BGTaskScheduler for iOS background sync
    - Schedule periodic sync every 15 minutes when offline queue has items
    - Respect battery optimization settings
    - _Requirements: 13.10_

## Notes

- Tasks marked with `*` are optional test-related sub-tasks and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability to the requirements document
- Checkpoints (tasks 7, 12, 19) ensure incremental validation of completed features
- Property tests and unit tests are complementary — both validate correctness from different angles
- Core implementation tasks (not marked with `*`) must be completed for a functional application
- Testing tasks are grouped as sub-tasks under their parent implementation tasks for better organization
- Offline synchronization (task 20) is critical for field operations where network connectivity is unreliable
- All tasks assume Clean Architecture structure with clear separation between presentation, domain, and data layers
- BLoC pattern is used consistently for state management across all feature modules

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.3", "1.4", "2.1"] },
    { "id": 1, "tasks": ["1.2", "2.2", "5.1"] },
    { "id": 2, "tasks": ["2.3", "3.1", "4.1", "5.2"] },
    { "id": 3, "tasks": ["3.2", "4.2", "5.3"] },
    { "id": 4, "tasks": ["3.3", "3.4", "6.1", "8.1", "9.1", "10.1", "11.1", "13.1", "14.1", "15.1", "16.1", "17.1", "18.1"] },
    { "id": 5, "tasks": ["3.5", "3.6", "6.2", "8.2", "9.2", "10.2", "11.2", "13.2", "14.2", "15.2", "16.2", "17.2", "18.2", "20.1"] },
    { "id": 6, "tasks": ["6.3", "8.3", "9.3", "10.3", "11.3", "13.3", "14.3", "15.3", "16.3", "17.3", "18.3", "20.2"] },
    { "id": 7, "tasks": ["6.4", "8.4", "9.4", "10.4", "11.4", "13.4", "14.4", "15.4", "16.4", "17.4", "18.4", "20.3"] },
    { "id": 8, "tasks": ["9.5", "9.6", "10.5", "13.5", "14.5", "16.5", "17.5", "18.5", "20.4", "20.5"] },
    { "id": 9, "tasks": ["10.6", "20.6"] }
  ]
}
```

