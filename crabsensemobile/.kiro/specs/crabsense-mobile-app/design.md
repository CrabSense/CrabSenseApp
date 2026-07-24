# Design Document: CrabSense Mobile Application

## 1. System Overview

CrabSense Mobile is an enterprise-grade Flutter application for smart crab farming operations. The application enables real-time monitoring, AI-powered health detection, offline-first operations, and comprehensive farm management capabilities.

### 1.1 Architecture Style

- **Pattern**: Clean Architecture with BLoC state management
- **Layers**: Presentation → Domain → Data
- **Offline-First**: Local database as source of truth with background sync
- **Platform**: Flutter 3.x with Dart 3.x

### 1.2 Key Design Principles

1. **Separation of Concerns**: Clear boundaries between UI, business logic, and data
2. **Dependency Inversion**: Domain layer independent of external frameworks
3. **Single Responsibility**: Each class/module serves one purpose
4. **Offline-First**: All operations work without network, sync when available
5. **Security by Design**: Encryption, secure storage, certificate pinning
6. **Material Design 3**: Consistent, modern UI following platform guidelines

## 2. Architecture Layers

### 2.1 Presentation Layer

**Responsibility**: UI components, state management, user interaction

**Structure**:
```
lib/features/[feature]/presentation/
  ├── screens/          # Screen widgets
  ├── widgets/          # Feature-specific widgets
  ├── bloc/             # BLoC/Cubit for state management
  └── models/           # Presentation models (view models)
```

**Key Components**:
- **Screens**: Full-page widgets (Dashboard, QR Scanner, Box Details)
- **Widgets**: Reusable UI components (WaterQualityCard, AlertBadge)
- **BLoC/Cubit**: State management following BLoC pattern
- **Navigation**: GoRouter with type-safe routes and deep linking


### 2.2 Domain Layer

**Responsibility**: Business logic, use cases, domain entities

**Structure**:
```
lib/features/[feature]/domain/
  ├── entities/         # Core business objects
  ├── repositories/     # Repository interfaces
  └── usecases/         # Business operations
```

**Key Components**:
- **Entities**: Pure Dart objects (Box, Crab, WaterQuality, Alert)
- **Repository Interfaces**: Abstract contracts for data access
- **Use Cases**: Single-purpose business operations (ScanQRCode, CaptureVideo)
- **Business Rules**: Validation, calculations, domain constraints

### 2.3 Data Layer

**Responsibility**: Data sources, API clients, local storage, caching

**Structure**:
```
lib/features/[feature]/data/
  ├── models/           # Data transfer objects (DTOs)
  ├── repositories/     # Repository implementations
  ├── datasources/      # Remote and local data sources
  └── mappers/          # DTO ↔ Entity conversion
```

**Key Components**:
- **Models**: JSON-serializable DTOs with freezed/json_serializable
- **Remote Data Source**: HTTP client for API communication
- **Local Data Source**: Drift database for offline storage
- **Repository Implementation**: Combines remote + local, handles sync logic


## 3. Feature Modules

### 3.1 Authentication Module

**Purpose**: Secure user login, session management, role-based access

**Components**:
- **AuthBloc**: Manages authentication state (unauthenticated, authenticated, loading, error)
- **LoginScreen**: Credential input with validation
- **BiometricAuthService**: Fingerprint/Face ID integration
- **TokenRepository**: JWT storage in FlutterSecureStorage
- **AuthGuard**: Route protection middleware

**Data Flow**:
1. User enters credentials → AuthBloc emits loading state
2. AuthRepository validates via API → receives JWT token
3. Token stored in secure storage → AuthBloc emits authenticated state
4. Permission Manager loads user roles and permissions
5. Navigation redirects to dashboard

**Security Considerations**:
- Passwords hashed with bcrypt on server (not client)
- JWT stored in FlutterSecureStorage (Keychain/Keystore)
- Certificate pinning for API requests
- Account lockout after 3 failed attempts
- Auto-refresh token 5 minutes before expiry


### 3.2 Dashboard Module

**Purpose**: Overview of farm operations, metrics, quick actions

**Components**:
- **DashboardBloc**: Aggregates data from multiple sources
- **DashboardScreen**: Main layout with sections
- **MetricCard**: Reusable metric display widget
- **QuickActionButton**: Scan QR, Capture Video, Operation Log
- **AlertSummary**: Count and severity indicators

**Data Sources**:
- Active alerts from AlertRepository
- Today's video schedule from VideoRepository
- Water quality summary from WaterQualityRepository
- Weekly harvest summary from HarvestRepository

**Refresh Strategy**:
- Auto-refresh every 60 seconds when online
- Pull-to-refresh gesture
- Display cached data with offline indicator when network unavailable
- Skeleton loading during initial fetch

**Performance**:
- Parallel data fetching with Future.wait
- Cached responses for 30 seconds to reduce API calls
- Pagination for alert list (50 items per page)


### 3.3 QR Scanner Module

**Purpose**: QR code scanning for box identification

**Components**:
- **QRScannerBloc**: Manages scanner state and decoded data
- **QRScannerScreen**: Camera view with overlay and controls
- **QRProcessor**: Decodes and validates QR data
- **ScanningGuide**: Visual overlay for first-time users

**Libraries**:
- **mobile_scanner**: Native barcode scanning (iOS/Android)
- **permission_handler**: Camera permission management

**Scanning Flow**:
1. Request camera permission → Show rationale if denied
2. Initialize camera stream → Display preview
3. Detect QR code → Decode box identifier
4. Validate format → Fetch box data from repository
5. Navigate to Box Details screen → Pass box ID

**Features**:
- Continuous scan mode for bulk operations
- Flashlight toggle for low-light environments
- Haptic feedback and audio cue on successful scan
- Error handling for invalid QR codes with retry
- Offline queue for scans when network unavailable

**Performance**:
- Decode QR within 500ms
- Throttle scan events to prevent duplicate processing
- Release camera resources when screen is not active


### 3.4 Box Management Module

**Purpose**: Display box details, crab inventory, operations

**Components**:
- **BoxDetailsBloc**: Manages box data and operations
- **BoxDetailsScreen**: Comprehensive box information view
- **CrabListWidget**: Display crab records with filtering
- **BoxTimelineWidget**: Recent operations and events
- **ActionPanel**: Quick action buttons (Video, Inspect, Harvest, Sale)

**Data Display**:
- Box identifier, location, farm/pond
- Current crab count, species, average weight
- Latest water quality readings with visual indicators
- AI detection history with health status
- Active alerts associated with box
- Operation timeline with filters

**Operations**:
- Add new crab → Increment count, record metadata
- Transfer crab → Atomic decrement source, increment destination
- Update box info → Edit location, capacity
- View history → Timeline with pagination

**Offline Behavior**:
- Display cached box data with last sync timestamp
- Queue operations locally when offline
- Show staleness warning if data older than 30 minutes


### 3.5 Video Capture & AI Analysis Module

**Purpose**: Record videos for AI-powered crab health detection

**Components**:
- **VideoCaptureBloc**: Manages recording state and upload
- **VideoCaptureScreen**: Camera interface with guidelines
- **AIResultsBloc**: Displays and manages AI detection results
- **AIResultsScreen**: Shows molting status, health, recommendations
- **VideoCompressor**: Reduces file size before upload

**Recording Flow**:
1. Access camera → Display recording guidelines overlay
2. Start recording → Show timer (5-10 seconds)
3. Stop automatically at 10 seconds → Compress video
4. Associate with box ID → Upload to AI service
5. If offline → Store in local queue for later sync

**Libraries**:
- **camera**: Native camera access and recording
- **video_compress**: FFmpeg-based video compression
- **path_provider**: Local file storage

**AI Detection Display**:
- Molting status: Pre-Molt, Molting, Post-Molt, Hard Shell
- Health indicators: Normal, Disease, Stress
- Confidence score: Percentage per detection
- Visual overlays: Highlighted crabs in video frames
- Recommendations: Continue Monitoring, Harvest Ready, Treat Disease

**Performance**:
- Compress video to under 10MB (target 70% reduction)
- Upload with progress indicator
- Retry with exponential backoff on failure
- Queue unlimited videos offline with storage limit warning


### 3.6 Manual Inspection Module

**Purpose**: Manual verification of AI results and feedback collection

**Components**:
- **InspectionBloc**: Manages inspection form state
- **InspectionScreen**: Form with AI comparison view
- **FeedbackWidget**: Correct/Incorrect buttons for AI results
- **PhotoCaptureWidget**: Additional photo documentation

**Form Fields**:
- Molting status (dropdown): Pre-Molt, Molting, Post-Molt, Hard Shell
- Health condition (dropdown): Normal, Disease, Stress
- Weight (numeric input): Decimal with validation
- Notes (text area): Optional observations
- Photos (gallery): Multiple image capture

**Data Flow**:
1. Display AI results for comparison
2. Operator fills manual inspection form
3. Validate required fields → Submit to repository
4. Send feedback to AI service for model improvement
5. Update box records with manual data
6. If offline → Queue in local storage

**Tracking**:
- Agreement rate: AI vs manual inspections
- Inspection history: Timestamp, operator, results
- Feedback analytics: Accuracy trends over time


### 3.7 Water Quality Monitoring Module

**Purpose**: Real-time IoT sensor data display and alerting

**Components**:
- **WaterQualityBloc**: Manages sensor data and refresh
- **WaterQualityScreen**: Current readings and historical charts
- **SensorCard**: Individual parameter display with thresholds
- **HistoricalChart**: Time-series visualization (24h, 7d, 30d)

**Parameters**:
- Temperature (°C): Range 26-30, alert if outside
- pH: Range 7.5-8.5, alert if outside
- Dissolved Oxygen (mg/L): Minimum 5, alert if below
- Salinity (ppt): Range 15-25, alert if outside

**Libraries**:
- **fl_chart**: Line charts for historical data
- **intl**: Number formatting and localization

**Data Flow**:
1. Fetch current readings from API → Display with timestamp
2. Auto-refresh every 30 seconds when screen active
3. Highlight out-of-range values with warning colors
4. Display historical charts with zoom/pan gestures
5. Show device offline status if IoT sensor disconnected

**Alerting**:
- Threshold exceeded → Send push notification
- Show alert banner in app → Navigate to Water Quality screen
- Historical alert markers on charts

**Offline Behavior**:
- Display last cached readings with staleness indicator
- No auto-refresh when offline
- Cache historical data for 7 days


### 3.8 Alert Management Module

**Purpose**: Receive, view, and manage critical notifications

**Components**:
- **AlertBloc**: Manages alert list and filtering
- **AlertScreen**: List view with categorization
- **AlertCard**: Individual alert display with actions
- **NotificationService**: Push notification handling

**Alert Types**:
- Critical: Water quality emergency, equipment failure
- Warning: Parameter approaching threshold, maintenance due
- Info: Task reminder, system update

**Features**:
- Unread count badge on navigation tab
- Sort by timestamp (newest first)
- Filter by severity, type, status (unread/read/dismissed)
- Acknowledge or dismiss alerts
- Navigate to related screen (e.g., alert → water quality)
- Alert history for last 30 days

**Push Notifications**:
- FCM (Firebase Cloud Messaging) for cross-platform
- Register device token on app install
- Foreground: In-app banner notification
- Background/Terminated: System tray notification
- Tap notification → Deep link to alert details

**Offline Behavior**:
- Queue alert acknowledgements when offline
- Sync status changes when connection restored
- Local notifications for app-generated alerts


### 3.9 Operation Logging Module

**Purpose**: Record farm operations and maintenance activities

**Components**:
- **OperationLogBloc**: Manages operation creation and history
- **OperationLogScreen**: Form and timeline view
- **OperationTypeSelector**: Feeding, Water Change, Mineral, Cleaning, Medication
- **PhotoAttachment**: Image documentation support

**Form Fields**:
- Operation type (required): Dropdown selection
- Box selection (required): Single or multiple boxes
- Timestamp (required): Auto-filled, editable
- Quantity/Amount (optional): Numeric input
- Notes (optional): Text observations
- Photos (optional): Multiple image attachments

**Data Flow**:
1. Select operation type → Display relevant form fields
2. Select target boxes → Validate selection
3. Fill details → Capture photos if needed
4. Submit → Validate required fields
5. If online → Sync immediately, else queue locally
6. Display in timeline with filters (date, type, box)

**Permissions**:
- Field Operator or higher can create logs
- Edit within 24 hours of creation
- View history accessible to all authenticated users

**Timeline View**:
- Chronological list with grouping by date
- Filter by operation type, box, date range
- Search by keywords in notes
- Export to CSV for reporting


### 3.10 Harvest & Sales Module

**Purpose**: Record harvest data and quick sales transactions

**Components**:
- **HarvestBloc**: Manages harvest recording
- **SalesBloc**: Manages sales transactions
- **HarvestScreen**: Form with weight, count, quality
- **SalesScreen**: Buyer info, pricing, payment method
- **InventoryTracker**: Automatic stock management

**Harvest Flow**:
1. Select box for harvest → Display current crab count
2. Enter total weight, crab count → Validate positive numbers
3. Select quality grade (A, B, C) → Optional notes
4. Capture harvest photos → Associate with operator
5. Submit → Decrement box inventory atomically
6. If online → Sync immediately, else queue

**Sales Flow**:
1. Select harvest batch or manual entry → Display available stock
2. Enter buyer information → Name, contact
3. Enter quantity, unit price → Auto-calculate total
4. Select payment method → Cash, Bank Transfer, Credit
5. Generate transaction ID → Submit to repository
6. If online → Sync immediately, else queue

**Reporting**:
- Daily sales summary: Total revenue, quantity
- Weekly harvest summary: Total weight, boxes harvested
- Inventory status: Available harvested stock
- Historical trends: Charts for 30/90 days

**Permissions**:
- Field Operator can record harvests
- Sales role required for sales transactions
- Admin and Farm Manager have full access


### 3.11 Product Traceability Module

**Purpose**: Scan product QR codes to view complete origin and quality history

**Components**:
- **TraceabilityBloc**: Fetches and displays product journey
- **TraceabilityScreen**: Timeline of product lifecycle
- **TraceabilityQRScanner**: Public access QR scanning
- **ShareWidget**: QR code sharing to social media

**Data Display**:
- Farm origin with location map
- Box history and transfer records
- Water quality during growth period
- AI detection records and health assessments
- Operation logs: Feeding, treatments, water changes
- Harvest date and operator identity
- Quality certifications and grades

**Features**:
- Anonymous access (no login required)
- QR code generation for sharing
- Social media sharing integration
- Multi-language support (English, Vietnamese)
- Offline viewing of cached traceability data

**Data Flow**:
1. Scan product QR code → Decode traceability ID
2. Fetch complete product journey from API
3. Display timeline with expandable sections
4. Show farm location on embedded map
5. Cache data locally for offline viewing

**Security**:
- Public data only, no sensitive information
- Rate limiting to prevent abuse
- Verify QR authenticity with digital signature


## 4. Cross-Cutting Concerns

### 4.1 Offline Synchronization Strategy

**Architecture**:
- **Local Database**: Drift (SQLite wrapper) as single source of truth
- **Sync Service**: Background worker for bi-directional sync
- **Conflict Resolution**: Last-write-wins with timestamp comparison
- **Queue Management**: FIFO queue with priority levels

**Sync Process**:
1. Detect network availability → ConnectivityPlus package
2. Check for pending operations → Query local queue table
3. Process items in chronological order → Batch upload
4. Retry failed items with exponential backoff (1s, 2s, 4s, 8s, 16s)
5. Download server changes → Merge with local data
6. Update sync status → Display progress to user

**Conflict Handling**:
- Timestamp comparison: Server timestamp > local timestamp → server wins
- User prompt for manual conflicts (simultaneous edits)
- Preserve both versions with conflict flag for review

**Data Priority**:
1. Critical: Alerts, water quality thresholds
2. High: Harvests, sales, AI results
3. Medium: Operation logs, inspections
4. Low: Analytics, historical data

**Storage Management**:
- Auto-delete synced items older than 30 days
- Warn user when storage exceeds 80% capacity
- Provide manual cache clear option in settings


### 4.2 Security Architecture

**Authentication**:
- JWT tokens with RS256 signature algorithm
- Access token: 60 minutes expiry
- Refresh token: 7 days expiry, stored in FlutterSecureStorage
- Biometric authentication: Local verification, then token exchange

**Data Protection**:
- At rest: AES-256 encryption for sensitive local data
- In transit: TLS 1.3 with certificate pinning
- Secure storage: Platform-specific (Keychain/Keystore)
- Memory: Clear sensitive data after use (dispose controllers)

**Certificate Pinning**:
```dart
class PinnedHttpClient {
  // Pin SHA-256 hash of server certificate
  static const String certHash = "sha256/...";
  
  // Validate certificate in HTTP client
  // Reject connection if hash doesn't match
}
```

**Input Validation**:
- Client-side validation for UX (instant feedback)
- Server-side validation for security (trust nothing from client)
- Sanitize all text inputs (SQL injection, XSS prevention)
- File upload validation: Type, size, malware scan

**Permission Model**:
- Minimum required permissions requested
- Runtime permission checks before protected operations
- Graceful degradation if optional permissions denied
- Clear rationale displayed before each permission request


### 4.3 State Management with BLoC

**Pattern**: Business Logic Component (BLoC) with Cubit for simpler cases

**Structure**:
```dart
// Event: User actions
abstract class BoxEvent {}
class LoadBoxDetails extends BoxEvent { final String boxId; }

// State: UI states
abstract class BoxState {}
class BoxLoading extends BoxState {}
class BoxLoaded extends BoxState { final Box box; }
class BoxError extends BoxState { final String message; }

// BLoC: Business logic
class BoxBloc extends Bloc<BoxEvent, BoxState> {
  final BoxRepository repository;
  
  BoxBloc(this.repository) : super(BoxInitial()) {
    on<LoadBoxDetails>(_onLoadBoxDetails);
  }
  
  Future<void> _onLoadBoxDetails(
    LoadBoxDetails event,
    Emitter<BoxState> emit,
  ) async {
    emit(BoxLoading());
    try {
      final box = await repository.getBox(event.boxId);
      emit(BoxLoaded(box));
    } catch (e) {
      emit(BoxError(e.toString()));
    }
  }
}
```

**Benefits**:
- Clear separation: UI doesn't contain business logic
- Testable: BLoCs are pure Dart, easy to unit test
- Predictable: Single source of truth for state
- Reactive: UI rebuilds automatically on state changes

**BLoC vs Cubit Decision**:
- Use BLoC when: Complex state transitions, event history needed
- Use Cubit when: Simple state management, direct state updates


### 4.4 Navigation Architecture

**Pattern**: Declarative routing with GoRouter

**Route Structure**:
```
/                          → Splash/Loading
/login                     → Login screen
/dashboard                 → Dashboard (authenticated)
/scanner                   → QR Scanner
/box/:id                   → Box details
/box/:id/video             → Video capture
/box/:id/inspect           → Manual inspection
/water-quality             → Water quality monitoring
/alerts                    → Alert list
/operations                → Operation logs
/harvest                   → Harvest recording
/sales                     → Sales management
/profile                   → User profile and settings
/traceability/:productId   → Product traceability (public)
```

**Deep Linking**:
- Custom scheme: `crabsense://box/12345`
- Universal links: `https://crabsense.app/traceability/abc123`
- Handle incoming links when app is cold-started or warm-started
- Parse parameters and navigate to appropriate screen

**Navigation Guards**:
```dart
redirect: (context, state) {
  final isAuthenticated = authService.isAuthenticated;
  final isPublicRoute = state.path.startsWith('/traceability');
  
  if (!isAuthenticated && !isPublicRoute) {
    return '/login';
  }
  return null; // No redirect needed
}
```


### 4.5 Error Handling Strategy

**Error Types**:
```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection');
}

class ServerFailure extends Failure {
  final int statusCode;
  const ServerFailure(this.statusCode, String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure() : super('Failed to load cached data');
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;
  const ValidationFailure(this.fieldErrors) : super('Validation failed');
}
```

**Error Presentation**:
- **SnackBar**: Temporary errors (network timeout, save success)
- **Dialog**: Critical errors requiring acknowledgment
- **Error State Widget**: Full-screen errors with retry button
- **Inline Validation**: Real-time form field errors

**Logging**:
- Firebase Crashlytics for crash reports
- Sentry for error tracking with context
- Custom logger for debug builds with log levels
- Never log sensitive data (passwords, tokens, PII)

**Retry Mechanism**:
```dart
Future<T> retryWithExponentialBackoff<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  // Exponential backoff: 1s, 2s, 4s, 8s, 16s
}
```


### 4.6 Caching Strategy

**Multi-Level Cache**:

1. **Memory Cache**: In-memory for frequently accessed data (user profile, permissions)
   - LRU eviction policy
   - Max size: 50 items
   - TTL: 5 minutes

2. **Disk Cache**: Persistent storage for offline access
   - Drift database with cache tables
   - TTL stored per record
   - Auto-cleanup on app startup

3. **Image Cache**: Optimized for photos and videos
   - cached_network_image package
   - Max cache size: 200 MB
   - Auto-eviction when limit reached

**Cache Invalidation**:
- Time-based: Expire after TTL (configurable per data type)
- Event-based: Invalidate on data mutation
- Manual: Pull-to-refresh gesture, retry button
- Version-based: Invalidate on app update if schema changes

**Cache Keys**:
```dart
// Hierarchical key structure
"box:123"                    // Box details
"box:123:water_quality"      // Water quality for box
"alerts:farm:456"            // Alerts for specific farm
"user:profile:789"           // User profile
```

**Staleness Indicators**:
- Fresh (< 5 minutes): No indicator
- Stale (5-30 minutes): "Updated X minutes ago"
- Very stale (> 30 minutes): Warning icon with timestamp


### 4.7 Performance Optimization

**App Launch**:
- Splash screen displayed within 1 second
- Pre-load critical data during splash (user profile, permissions)
- Lazy load feature modules on first access
- Initialize heavy services in background isolates

**Rendering Performance**:
- Maintain 60 FPS for smooth animations
- Use const constructors wherever possible
- Implement RepaintBoundary for complex widgets
- Profile with Flutter DevTools to identify jank

**List Performance**:
- ListView.builder for dynamic lists (only builds visible items)
- Pagination: Load 50 items per page
- Infinite scroll with scroll listener
- Cached item heights for smooth scrolling

**Image Optimization**:
- Compress images before upload (target 80% quality)
- Use WebP format for better compression
- Resize images to display size (no unnecessary large images)
- Lazy load images outside viewport

**Database Performance**:
- Index frequently queried fields (box_id, user_id, timestamp)
- Use transactions for batch operations
- Run complex queries in background isolates
- Implement pagination for large datasets

**Network Optimization**:
- Batch API requests when possible
- Implement request debouncing (300ms delay)
- Use HTTP/2 for multiplexing
- Compress request/response bodies (gzip)


## 5. Data Models

### 5.1 Core Entities

**User Entity**:
```dart
class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final List<String> assignedFarmIds;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}

enum UserRole { admin, farmManager, fieldOperator, sales, viewer }
```

**Box Entity**:
```dart
class Box {
  final String id;
  final String qrCode;
  final String farmId;
  final String? pondId;
  final Location location;
  final int currentCrabCount;
  final int capacity;
  final CrabSpecies species;
  final double averageWeight;
  final BoxStatus status;
  final DateTime createdAt;
  final DateTime? lastVideoAt;
}

enum BoxStatus { active, inactive, maintenance, harvested }
enum CrabSpecies { blueCrab, mudCrab, softShell }
```

**Crab Entity**:
```dart
class Crab {
  final String id;
  final String boxId;
  final CrabSpecies species;
  final double weight;
  final MoltingStatus moltingStatus;
  final HealthStatus healthStatus;
  final String source; // "farm", "purchase", "transfer"
  final DateTime addedAt;
  final String addedBy;
}

enum MoltingStatus { preMolt, molting, postMolt, hardShell }
enum HealthStatus { normal, disease, stress, unknown }
```


**WaterQuality Entity**:
```dart
class WaterQuality {
  final String id;
  final String sensorId;
  final String farmId;
  final String? pondId;
  final double temperature; // Celsius
  final double ph;
  final double dissolvedOxygen; // mg/L
  final double salinity; // ppt
  final DateTime timestamp;
  final bool isAlertTriggered;
}

class WaterQualityThresholds {
  final double minTemperature = 26.0;
  final double maxTemperature = 30.0;
  final double minPh = 7.5;
  final double maxPh = 8.5;
  final double minDissolvedOxygen = 5.0;
  final double minSalinity = 15.0;
  final double maxSalinity = 25.0;
}
```

**AIDetection Entity**:
```dart
class AIDetection {
  final String id;
  final String videoId;
  final String boxId;
  final MoltingStatus moltingStatus;
  final HealthStatus healthStatus;
  final double confidenceScore; // 0.0 to 1.0
  final List<DetectionBox> detectedCrabs;
  final List<String> recommendations;
  final DateTime analyzedAt;
  final String? feedbackStatus; // "correct", "incorrect", null
}

class DetectionBox {
  final double x, y, width, height; // Normalized coordinates
  final String label;
  final double confidence;
}
```


**Alert Entity**:
```dart
class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? sourceId; // box_id, sensor_id, etc.
  final String? sourceType; // "box", "sensor", "system"
  final List<String> recommendedActions;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final AlertStatus status;
}

enum AlertType { 
  waterQuality, equipment, crabHealth, 
  maintenance, task, system 
}

enum AlertSeverity { critical, warning, info }

enum AlertStatus { unread, read, acknowledged, dismissed }
```

**OperationLog Entity**:
```dart
class OperationLog {
  final String id;
  final OperationType type;
  final List<String> boxIds;
  final double? quantity;
  final String? unit;
  final String notes;
  final List<String> photoUrls;
  final DateTime timestamp;
  final String operatorId;
  final String operatorName;
}

enum OperationType { 
  feeding, waterChange, mineralAddition, 
  cleaning, medication, inspection 
}
```


**Harvest Entity**:
```dart
class Harvest {
  final String id;
  final String boxId;
  final double totalWeight; // kg
  final int crabCount;
  final QualityGrade qualityGrade;
  final DateTime harvestDate;
  final String harvestedBy;
  final String? destination;
  final List<String> photoUrls;
  final String notes;
}

enum QualityGrade { gradeA, gradeB, gradeC }
```

**Sale Entity**:
```dart
class Sale {
  final String id;
  final String transactionId;
  final String buyerName;
  final String? buyerContact;
  final double quantity; // kg
  final double unitPrice;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime saleDate;
  final String soldBy;
  final String? harvestId; // Link to harvest record
}

enum PaymentMethod { cash, bankTransfer, credit }
enum PaymentStatus { pending, completed, cancelled }
```

**SyncQueueItem Entity**:
```dart
class SyncQueueItem {
  final String id;
  final SyncOperation operation;
  final String entityType; // "harvest", "sale", "operation_log"
  final Map<String, dynamic> data;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final SyncStatus status;
  final String? errorMessage;
}

enum SyncOperation { create, update, delete }
enum SyncStatus { pending, inProgress, completed, failed }
```


## 6. API Integration

### 6.1 REST API Client

**Base Configuration**:
```dart
class ApiClient {
  static const String baseUrl = 'https://api.crabsense.app/v1';
  static const Duration timeout = Duration(seconds: 30);
  
  final Dio _dio;
  final TokenRepository _tokenRepository;
  
  ApiClient(this._tokenRepository) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
    ));
    
    _setupInterceptors();
    _setupCertificatePinning();
  }
  
  void _setupInterceptors() {
    // Add authorization header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenRepository.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 by refreshing token
        if (error.response?.statusCode == 401) {
          await _refreshTokenAndRetry(error, handler);
        }
        return handler.next(error);
      },
    ));
  }
}
```


### 6.2 API Endpoints

**Authentication**:
- `POST /auth/login` - User login, returns JWT tokens
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Invalidate tokens
- `POST /auth/biometric/register` - Register device for biometric auth
- `POST /auth/biometric/authenticate` - Biometric login

**User Management**:
- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update user profile
- `PUT /users/me/password` - Change password
- `GET /users/me/permissions` - Get user permissions

**Box Management**:
- `GET /boxes` - List boxes (with pagination, filters)
- `GET /boxes/:id` - Get box details
- `PUT /boxes/:id` - Update box information
- `POST /boxes/:id/crabs` - Add crab to box
- `PUT /boxes/:id/crabs/:crabId` - Update crab record
- `POST /boxes/:id/transfer` - Transfer crabs between boxes

**Water Quality**:
- `GET /water-quality/current` - Current readings for all sensors
- `GET /water-quality/sensor/:id` - Specific sensor readings
- `GET /water-quality/history` - Historical data (with date range)
- `GET /water-quality/alerts` - Water quality alerts

**Video & AI**:
- `POST /videos/upload` - Upload video for AI analysis
- `GET /videos/:id` - Get video metadata
- `GET /videos/:id/detection` - Get AI detection results
- `POST /videos/:id/feedback` - Submit feedback on AI results


**Alerts**:
- `GET /alerts` - List alerts (with filters)
- `GET /alerts/:id` - Get alert details
- `PUT /alerts/:id/acknowledge` - Acknowledge alert
- `PUT /alerts/:id/dismiss` - Dismiss alert

**Operations**:
- `POST /operations` - Create operation log
- `GET /operations` - List operation logs (with filters)
- `GET /operations/:id` - Get operation details
- `PUT /operations/:id` - Update operation log (within 24h)

**Harvest & Sales**:
- `POST /harvests` - Record harvest
- `GET /harvests` - List harvests (with filters)
- `GET /harvests/summary` - Weekly/monthly summary
- `POST /sales` - Create sale transaction
- `GET /sales` - List sales (with filters)
- `GET /sales/summary` - Daily/weekly revenue summary

**Traceability**:
- `GET /traceability/:productId` - Get product journey (public)
- `GET /traceability/:productId/qr` - Generate QR code for sharing

**Sync**:
- `POST /sync/upload` - Batch upload queued operations
- `GET /sync/changes` - Get server changes since last sync
- `PUT /sync/resolve-conflict` - Submit conflict resolution


### 6.3 Response Format

**Success Response**:
```json
{
  "success": true,
  "data": {
    "id": "box_123",
    "qrCode": "BOX-001",
    "currentCrabCount": 45
  },
  "meta": {
    "page": 1,
    "pageSize": 50,
    "total": 150
  }
}
```

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "weight": "Must be a positive number",
      "boxId": "Box not found"
    }
  }
}
```

**Error Codes**:
- `AUTHENTICATION_ERROR` - Invalid credentials, expired token
- `AUTHORIZATION_ERROR` - Insufficient permissions
- `VALIDATION_ERROR` - Invalid input data
- `NOT_FOUND` - Resource not found
- `CONFLICT` - Duplicate record, concurrent modification
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `SERVER_ERROR` - Internal server error


## 7. UI/UX Design

### 7.1 Material Design 3 Theme

**Color Palette**:
```dart
class CrabSenseColors {
  // Primary brand color
  static const primary = Color(0xFF00C8FF); // Cyan blue
  
  // Background and surfaces
  static const background = Color(0xFF081528); // Dark blue
  static const surface = Color(0xFF0F1F3D);
  static const surfaceVariant = Color(0xFF1A2F4D);
  
  // Status colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFEF5350);
  static const info = Color(0xFF29B6F6);
  
  // Text colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0BEC5);
  static const textDisabled = Color(0xFF607D8B);
}
```

**Typography**:
```dart
class CrabSenseTypography {
  static const fontFamily = 'Inter';
  
  static const displayLarge = TextStyle(
    fontSize: 57, fontWeight: FontWeight.w700,
  );
  static const headlineLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w600,
  );
  static const titleLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600,
  );
  static const bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
  );
  static const labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500,
  );
}
```


### 7.2 Component Library

**Card Component**:
```dart
class CrabSenseCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool useGlassmorphism;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: useGlassmorphism
            ? CrabSenseColors.surface.withOpacity(0.7)
            : CrabSenseColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CrabSenseColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

**Button Components**:
- Primary Button: Filled with primary color
- Secondary Button: Outlined with primary color
- Text Button: No background, primary color text
- Icon Button: Circular with icon only
- FAB (Floating Action Button): Primary color with icon

**Input Components**:
- Text Field: Outlined with rounded corners
- Dropdown: Material dropdown with custom styling
- Date Picker: Material date picker
- Camera Picker: Custom bottom sheet with camera/gallery options


### 7.3 Screen Layouts

**Dashboard Screen**:
```
┌─────────────────────────────────┐
│ CrabSense Logo    [🔔 3] [👤]  │ ← App bar
├─────────────────────────────────┤
│ Good morning, John!             │ ← Greeting
│ Farm: Ocean Blue Farm           │
├─────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │📦 45│ │🎥 8 │ │⚠️ 3│        │ ← Quick metrics
│ │Boxes│ │Video│ │Alert│        │
│ └─────┘ └─────┘ └─────┘        │
├─────────────────────────────────┤
│ Quick Actions                   │
│ [Scan QR] [Capture Video]      │ ← Action buttons
│ [Operation Log] [More...]       │
├─────────────────────────────────┤
│ Active Alerts (3)               │
│ 🔴 High pH Level - Pond A       │ ← Alert cards
│ 🟡 Video Overdue - Box 023     │
│ 🔵 Maintenance Due - Pump 1    │
└─────────────────────────────────┘
│ [Dashboard] [Tasks] [Alerts]   │ ← Bottom nav
└─────────────────────────────────┘
```

**Box Details Screen**:
```
┌─────────────────────────────────┐
│ ← Box BOX-001          [⋮]     │ ← App bar
├─────────────────────────────────┤
│ Pond A - Ocean Blue Farm        │
│ Last updated: 2 minutes ago     │
├─────────────────────────────────┤
│ Current Inventory               │
│ 🦀 45 crabs | 📦 Capacity: 50  │
│ ⚖️ Avg Weight: 250g            │
├─────────────────────────────────┤
│ Water Quality                   │
│ 🌡️ 28.5°C  pH 8.1  💧 6.2mg/L │
│ [View Details →]                │
├─────────────────────────────────┤
│ AI Health Status                │
│ 🟢 Normal (87% confidence)     │
│ Last scan: 2 hours ago          │
├─────────────────────────────────┤
│ Quick Actions                   │
│ [📹 Video] [🔍 Inspect]        │
│ [🎣 Harvest] [💰 Quick Sale]   │
└─────────────────────────────────┘
```


### 7.4 Loading States and Animations

**Skeleton Loading**:
- Display content-shaped placeholders during data fetch
- Shimmer animation for visual feedback
- Use Skeletonizer package for automatic skeleton generation

**Empty States**:
- Illustrative images with helpful messages
- Clear call-to-action buttons
- Examples: "No alerts yet", "No boxes scanned", "No videos recorded"

**Animations**:
- Page transitions: Slide animation (300ms)
- List item animations: Fade in with stagger (50ms delay per item)
- Success feedback: Scale animation with checkmark
- Error shake: Horizontal shake animation for invalid input

### 7.5 Accessibility

**Screen Reader Support**:
- Semantic labels for all interactive elements
- Announce state changes (loading, success, error)
- Logical focus order for keyboard navigation

**Visual Accessibility**:
- Minimum 4.5:1 contrast ratio for text
- Touch targets minimum 48x48 dp
- Support dynamic font sizes
- Color is not the only indicator (use icons + text)

**Platform Conventions**:
- Follow iOS Human Interface Guidelines on iOS
- Follow Material Design guidelines on Android
- Respect system accessibility settings


## 8. Technology Stack

### 8.1 Core Framework

**Flutter 3.x**:
- Cross-platform development (iOS, Android)
- Hot reload for rapid development
- Native performance with ahead-of-time compilation
- Rich widget library with Material Design 3

**Dart 3.x**:
- Null safety for fewer runtime errors
- Strong type system for maintainability
- Async/await for clean asynchronous code
- Pattern matching for concise logic

### 8.2 State Management

**flutter_bloc** (^8.1.0):
- Predictable state management
- Clear separation of business logic
- Easy testing with bloc_test
- Time-travel debugging support

### 8.3 Navigation

**go_router** (^13.0.0):
- Declarative routing
- Deep linking support
- Type-safe navigation
- Authentication guards
- Nested navigation for tab bars

### 8.4 Local Storage

**drift** (^2.14.0):
- Type-safe SQL queries
- Reactive database with streams
- Migration support
- Cross-platform (iOS, Android, Web)

**flutter_secure_storage** (^9.0.0):
- Secure token storage
- Platform-specific encryption (Keychain/Keystore)
- Biometric authentication integration

**hive** (^2.2.3):
- Fast key-value storage
- No native dependencies
- Use for simple caching and settings


### 8.5 Networking

**dio** (^5.4.0):
- HTTP client with interceptors
- Request/response transformation
- Timeout configuration
- Certificate pinning support
- File upload/download with progress

**connectivity_plus** (^5.0.0):
- Network connectivity monitoring
- WiFi, mobile, ethernet detection
- Stream-based connectivity updates

### 8.6 Media Handling

**camera** (^0.10.5):
- Native camera access
- Video recording with duration control
- Front/rear camera switching
- Flash control

**mobile_scanner** (^3.5.0):
- Fast QR/barcode scanning
- No external dependencies
- Torch (flashlight) support
- Continuous scanning mode

**video_compress** (^3.1.2):
- FFmpeg-based video compression
- Progress callbacks
- Configurable quality settings
- Async processing

**cached_network_image** (^3.3.1):
- Image caching with disk/memory storage
- Placeholder and error widgets
- Automatic cache invalidation

**image_picker** (^1.0.7):
- Gallery and camera image selection
- Multiple image selection
- Compression options


### 8.7 Push Notifications

**firebase_messaging** (^14.7.0):
- Cross-platform push notifications
- Foreground/background/terminated handling
- Topic subscription support
- Data and notification messages

**flutter_local_notifications** (^16.3.0):
- Local notifications scheduling
- Custom notification channels
- Action buttons on notifications
- Notification tapping handling

### 8.8 Charts and Visualization

**fl_chart** (^0.66.0):
- Line charts for water quality trends
- Bar charts for harvest statistics
- Pie charts for distribution analysis
- Interactive touch feedback
- Custom styling support

### 8.9 Utilities

**freezed** (^2.4.6) + **json_serializable** (^6.7.1):
- Immutable data classes
- JSON serialization/deserialization
- Union types for state management
- Code generation for boilerplate reduction

**intl** (^0.18.1):
- Internationalization support
- Date/time formatting
- Number formatting
- Multi-language support (English, Vietnamese)

**permission_handler** (^11.2.0):
- Runtime permission requests
- Permission status checking
- Settings navigation

**path_provider** (^2.1.2):
- Platform-specific directory paths
- Document, cache, temporary directories
- Cross-platform file storage


### 8.10 Testing and Quality

**Testing Libraries**:
- **flutter_test**: Unit and widget testing
- **bloc_test**: BLoC testing utilities
- **mocktail**: Mocking for tests
- **integration_test**: End-to-end testing
- **golden_toolkit**: Visual regression testing

**Code Quality**:
- **flutter_lints**: Recommended linting rules
- **very_good_analysis**: Stricter linting rules
- **dart_code_metrics**: Code quality metrics

**Monitoring**:
- **firebase_crashlytics**: Crash reporting
- **sentry_flutter**: Error tracking with context
- **firebase_analytics**: Usage analytics

## 9. Project Structure

```
lib/
├── app/
│   ├── app.dart                    # App widget
│   ├── router.dart                 # GoRouter configuration
│   └── theme.dart                  # Material theme definition
├── core/
│   ├── constants/
│   │   ├── api_constants.dart      # API endpoints
│   │   └── app_constants.dart      # App-wide constants
│   ├── di/
│   │   └── injection.dart          # Dependency injection setup
│   ├── error/
│   │   ├── failures.dart           # Failure classes
│   │   └── exceptions.dart         # Exception classes
│   ├── network/
│   │   ├── api_client.dart         # Dio HTTP client
│   │   └── network_info.dart       # Connectivity checker
│   ├── security/
│   │   ├── certificate_pinning.dart
│   │   └── secure_storage.dart
│   └── utils/
│       ├── extensions.dart         # Dart extensions
│       ├── validators.dart         # Input validators
│       └── logger.dart             # Logging utility
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── screens/
│   │       └── widgets/
│   ├── dashboard/
│   ├── scanner/
│   ├── box/
│   ├── video/
│   ├── water_quality/
│   ├── alerts/
│   ├── operations/
│   ├── harvest/
│   ├── sales/
│   └── traceability/
├── shared/
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── cards/
│   │   ├── inputs/
│   │   ├── loading/
│   │   └── errors/
│   └── services/
│       ├── sync_service.dart
│       └── notification_service.dart
└── main.dart                       # App entry point
```


## 10. Database Schema

### 10.1 Drift Tables

**Users Table**:
```dart
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get assignedFarmIds => text()(); // JSON array
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Boxes Table**:
```dart
class Boxes extends Table {
  TextColumn get id => text()();
  TextColumn get qrCode => text()();
  TextColumn get farmId => text()();
  TextColumn get pondId => text().nullable()();
  IntColumn get currentCrabCount => integer()();
  IntColumn get capacity => integer()();
  TextColumn get species => text()();
  RealColumn get averageWeight => real()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastVideoAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Crabs Table**:
```dart
class Crabs extends Table {
  TextColumn get id => text()();
  TextColumn get boxId => text()();
  TextColumn get species => text()();
  RealColumn get weight => real()();
  TextColumn get moltingStatus => text()();
  TextColumn get healthStatus => text()();
  TextColumn get source => text()();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get addedBy => text()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```


**WaterQuality Table**:
```dart
class WaterQualityReadings extends Table {
  TextColumn get id => text()();
  TextColumn get sensorId => text()();
  TextColumn get farmId => text()();
  TextColumn get pondId => text().nullable()();
  RealColumn get temperature => real()();
  RealColumn get ph => real()();
  RealColumn get dissolvedOxygen => real()();
  RealColumn get salinity => real()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isAlertTriggered => boolean()();
  DateTimeColumn get cachedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Alerts Table**:
```dart
class Alerts extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get severity => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get sourceType => text().nullable()();
  TextColumn get recommendedActions => text()(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();
  TextColumn get acknowledgedBy => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**SyncQueue Table**:
```dart
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get entityType => text()();
  TextColumn get data => text()(); // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```


## 11. Testing Strategy

### 11.1 Unit Tests

**Target Coverage**: 80% minimum

**Test Scope**:
- Domain layer: Entities, use cases, business logic
- Data layer: Repositories, data sources, models
- Utilities: Validators, formatters, extensions
- BLoCs: State transitions, event handling

**Example Unit Test**:
```dart
void main() {
  group('LoginBloc', () {
    late LoginBloc loginBloc;
    late MockAuthRepository mockAuthRepository;
    
    setUp(() {
      mockAuthRepository = MockAuthRepository();
      loginBloc = LoginBloc(mockAuthRepository);
    });
    
    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginSuccess] when login succeeds',
      build: () => loginBloc,
      act: (bloc) {
        when(() => mockAuthRepository.login(any(), any()))
            .thenAnswer((_) async => Right(mockUser));
        bloc.add(LoginSubmitted('test@example.com', 'password123'));
      },
      expect: () => [
        LoginLoading(),
        LoginSuccess(mockUser),
      ],
    );
  });
}
```

### 11.2 Widget Tests

**Test Scope**:
- Screen widgets: Layout, user interactions
- Custom widgets: Props, callbacks, edge cases
- Form validation: Error states, submission

**Example Widget Test**:
```dart
void main() {
  testWidgets('LoginScreen shows error on invalid credentials', 
    (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    
    // Enter invalid credentials
    await tester.enterText(find.byKey(Key('email')), 'invalid');
    await tester.enterText(find.byKey(Key('password')), 'short');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    // Verify error messages displayed
    expect(find.text('Invalid email format'), findsOneWidget);
    expect(find.text('Password too short'), findsOneWidget);
  });
}
```


### 11.3 Integration Tests

**Test Scope**:
- Complete user flows: Login → Dashboard → Scan → Box Details
- Offline sync: Create data offline → Go online → Verify sync
- Error handling: Network errors, API errors, validation errors
- State persistence: App restart, background/foreground

**Example Integration Test**:
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete harvest flow', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Login
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    
    // Navigate to scanner
    await tester.tap(find.text('Scan QR'));
    await tester.pumpAndSettle();
    
    // Scan box (mock QR scanner result)
    // ... scan simulation ...
    
    // Open harvest form
    await tester.tap(find.text('Harvest'));
    await tester.pumpAndSettle();
    
    // Fill harvest data
    await tester.enterText(find.byKey(Key('weight')), '25.5');
    await tester.enterText(find.byKey(Key('count')), '45');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    
    // Verify success
    expect(find.text('Harvest recorded'), findsOneWidget);
  });
}
```

### 11.4 Golden Tests

**Test Scope**:
- Visual regression testing for key screens
- Theme consistency across widgets
- Responsive layout verification

**Example Golden Test**:
```dart
void main() {
  testGoldens('Dashboard screen matches golden', (tester) async {
    await tester.pumpWidgetBuilder(
      DashboardScreen(),
      surfaceSize: Size(375, 812), // iPhone X size
    );
    
    await screenMatchesGolden(tester, 'dashboard_screen');
  });
}
```


## 12. Deployment Strategy

### 12.1 Build Configurations

**Development**:
- Debug build with verbose logging
- Mock API endpoints for testing
- Firebase Test project
- No code obfuscation

**Staging**:
- Profile build for performance testing
- Staging API endpoints
- Firebase Staging project
- Limited code obfuscation

**Production**:
- Release build with optimizations
- Production API endpoints
- Firebase Production project
- Full code obfuscation
- ProGuard/R8 for Android
- BitCode for iOS

### 12.2 CI/CD Pipeline

**GitHub Actions Workflow**:
```yaml
name: Build and Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
      
  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build appbundle --release
      
  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release --no-codesign
```


### 12.3 App Store Deployment

**Android (Google Play)**:
- Build signed AAB (Android App Bundle)
- Upload to Play Console
- Internal testing → Closed testing → Open testing → Production
- Configure release notes and screenshots
- Set up staged rollout (10% → 50% → 100%)

**iOS (App Store)**:
- Build signed IPA with distribution certificate
- Upload to App Store Connect via Xcode or Transporter
- TestFlight beta testing
- Submit for App Store review
- Configure App Store listing with screenshots

**Version Management**:
- Semantic versioning: MAJOR.MINOR.PATCH
- Build number auto-increment in CI/CD
- Changelog maintained in CHANGELOG.md
- Release notes generated from git commits

### 12.4 Feature Flags

**Remote Config (Firebase)**:
```dart
class FeatureFlags {
  final RemoteConfig _remoteConfig;
  
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: Duration(seconds: 10),
      minimumFetchInterval: Duration(hours: 1),
    ));
    await _remoteConfig.fetchAndActivate();
  }
  
  bool get enableBiometricAuth => 
      _remoteConfig.getBool('enable_biometric_auth');
  
  bool get enableVideoCompression => 
      _remoteConfig.getBool('enable_video_compression');
  
  int get maxOfflineVideos => 
      _remoteConfig.getInt('max_offline_videos');
}
```

**Use Cases**:
- Enable/disable features remotely
- A/B testing for new features
- Gradual rollout of experimental features
- Emergency kill switch for problematic features


## 13. Monitoring and Analytics

### 13.1 Crash Reporting

**Firebase Crashlytics**:
- Automatic crash detection and reporting
- Custom crash keys for context
- User identification for impact analysis
- Stack trace symbolication

```dart
void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    
    runApp(MyApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}
```

### 13.2 Analytics Events

**Key Events to Track**:
- User authentication: login, logout, registration
- Feature usage: scan_qr, capture_video, create_harvest
- Errors: api_error, validation_error, sync_failure
- Performance: screen_load_time, api_response_time
- Business metrics: harvest_created, sale_completed

```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  
  Future<void> logQRScan(String boxId) async {
    await _analytics.logEvent(
      name: 'qr_scan',
      parameters: {
        'box_id': boxId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  Future<void> logHarvestCreated(double weight, int count) async {
    await _analytics.logEvent(
      name: 'harvest_created',
      parameters: {
        'weight_kg': weight,
        'crab_count': count,
      },
    );
  }
}
```


### 13.3 Performance Monitoring

**Firebase Performance Monitoring**:
- Automatic traces for app start, screen rendering
- Custom traces for critical operations
- Network request monitoring

```dart
class PerformanceService {
  final FirebasePerformance _performance;
  
  Future<T> traceOperation<T>({
    required String name,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(name);
    
    if (attributes != null) {
      attributes.forEach((key, value) {
        trace.putAttribute(key, value);
      });
    }
    
    await trace.start();
    try {
      final result = await operation();
      trace.incrementMetric('success', 1);
      return result;
    } catch (e) {
      trace.incrementMetric('failure', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

**Performance Targets**:
- App startup: < 3 seconds to first meaningful paint
- Screen transitions: < 300ms animation duration
- API calls: < 2 seconds for standard requests
- Database queries: < 100ms for indexed queries
- Frame rate: 60 FPS maintained during scrolling


## 14. Security Considerations

### 14.1 Authentication Security

**Token Management**:
- Access tokens: Short-lived (60 minutes)
- Refresh tokens: Long-lived (7 days), rotated on use
- Secure storage: FlutterSecureStorage with platform encryption
- Auto-refresh: Transparent token renewal before expiry

**Session Security**:
- HTTPS only communication (TLS 1.3)
- Certificate pinning to prevent MITM attacks
- Biometric authentication for local verification
- Account lockout after 3 failed login attempts

### 14.2 Data Security

**Encryption**:
```dart
class EncryptionService {
  final FlutterSecureStorage _secureStorage;
  final Encrypter _encrypter;
  
  Future<String> encrypt(String plaintext) async {
    final key = await _getEncryptionKey();
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
  
  Future<String> decrypt(String ciphertext) async {
    final parts = ciphertext.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final key = await _getEncryptionKey();
    return _encrypter.decrypt(encrypted, iv: iv);
  }
}
```

**Sensitive Data**:
- Passwords: Never stored locally, hashed on server
- Tokens: Encrypted in secure storage
- Biometric data: Handled by platform, never accessed directly
- PII: Encrypted in database, masked in logs


### 14.3 Input Validation

**Client-Side Validation**:
```dart
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    return null;
  }
  
  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return 'Must be a positive number';
    }
    return null;
  }
}
```

**SQL Injection Prevention**:
- Use parameterized queries exclusively
- Drift automatically handles parameter binding
- Never concatenate user input into SQL

**XSS Prevention**:
- Sanitize user input before display
- Escape HTML characters in text fields
- Use TextFormField which handles sanitization


### 14.4 Certificate Pinning

**Implementation**:
```dart
class CertificatePinning {
  static const String certificateHash = 
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  
  static SecurityContext getSecurityContext() {
    final context = SecurityContext.defaultContext;
    // Load certificate from assets
    final cert = File('assets/certificates/api_cert.pem')
        .readAsBytesSync();
    context.setTrustedCertificatesBytes(cert);
    return context;
  }
  
  static HttpClient createHttpClient() {
    final client = HttpClient(context: getSecurityContext());
    client.badCertificateCallback = 
        (X509Certificate cert, String host, int port) {
      // Verify certificate hash matches pinned hash
      final certHash = sha256.convert(cert.der).toString();
      return certHash == certificateHash;
    };
    return client;
  }
}
```

### 14.5 Secure Coding Practices

**Memory Management**:
- Clear sensitive data from memory after use
- Dispose controllers and streams properly
- Use final variables where possible
- Avoid storing sensitive data in global variables

**Logging**:
```dart
class SecureLogger {
  static void log(String message, {dynamic data}) {
    if (kDebugMode) {
      // In debug mode, log full data
      print('[$message] $data');
    } else {
      // In release mode, sanitize sensitive data
      final sanitized = _sanitizeData(data);
      print('[$message] $sanitized');
    }
  }
  
  static dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (_isSensitiveKey(key)) {
          return MapEntry(key, '***REDACTED***');
        }
        return MapEntry(key, value);
      });
    }
    return data;
  }
  
  static bool _isSensitiveKey(String key) {
    return ['password', 'token', 'secret', 'api_key']
        .any((sensitive) => key.toLowerCase().contains(sensitive));
  }
}
```


## 15. Internationalization (i18n)

### 15.1 Supported Languages

- English (en): Default language
- Vietnamese (vi): Primary target market

### 15.2 Implementation

**ARB Files Structure**:
```
lib/l10n/
├── app_en.arb          # English translations
├── app_vi.arb          # Vietnamese translations
└── l10n.yaml           # Configuration
```

**app_en.arb**:
```json
{
  "@@locale": "en",
  "appTitle": "CrabSense",
  "loginTitle": "Login",
  "emailLabel": "Email",
  "passwordLabel": "Password",
  "loginButton": "Login",
  "dashboardTitle": "Dashboard",
  "scanQRButton": "Scan QR Code",
  "captureVideoButton": "Capture Video",
  "waterQualityTitle": "Water Quality",
  "temperature": "Temperature",
  "phLevel": "pH Level",
  "dissolvedOxygen": "Dissolved Oxygen",
  "salinity": "Salinity",
  "harvestTitle": "Harvest",
  "weightLabel": "Weight (kg)",
  "countLabel": "Crab Count",
  "submitButton": "Submit",
  "successMessage": "Operation successful",
  "errorMessage": "An error occurred"
}
```

**app_vi.arb**:
```json
{
  "@@locale": "vi",
  "appTitle": "CrabSense",
  "loginTitle": "Đăng nhập",
  "emailLabel": "Email",
  "passwordLabel": "Mật khẩu",
  "loginButton": "Đăng nhập",
  "dashboardTitle": "Bảng điều khiển",
  "scanQRButton": "Quét mã QR",
  "captureVideoButton": "Ghi hình",
  "waterQualityTitle": "Chất lượng nước",
  "temperature": "Nhiệt độ",
  "phLevel": "Độ pH",
  "dissolvedOxygen": "Oxy hòa tan",
  "salinity": "Độ mặn",
  "harvestTitle": "Thu hoạch",
  "weightLabel": "Khối lượng (kg)",
  "countLabel": "Số lượng cua",
  "submitButton": "Gửi",
  "successMessage": "Thao tác thành công",
  "errorMessage": "Đã xảy ra lỗi"
}
```


### 15.3 Usage in Code

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
      ),
      body: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
            ),
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.loginButton),
          ),
        ],
      ),
    );
  }
}
```

### 15.4 Locale Selection

**User Preference**:
```dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = Locale('en');
  
  Locale get locale => _locale;
  
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }
  
  Future<void> loadLocale() async {
    final languageCode = _prefs.getString('locale') ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
```

**App Configuration**:
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: localeProvider.locale,
  // ...
)
```


## 16. Accessibility Implementation

### 16.1 Screen Reader Support

**Semantic Labels**:
```dart
Semantics(
  label: 'Scan QR Code button',
  hint: 'Opens camera to scan box QR code',
  button: true,
  child: ElevatedButton(
    onPressed: _onScanQR,
    child: Text('Scan QR'),
  ),
)
```

**Live Regions**:
```dart
Semantics(
  liveRegion: true,
  child: Text(_statusMessage),
)
```

### 16.2 Visual Accessibility

**Color Contrast**:
- All text meets WCAG AA standard (4.5:1 contrast ratio)
- Important actions meet AAA standard (7:1 contrast ratio)
- Use contrast checker during design phase

**Touch Targets**:
```dart
class AccessibleButton extends StatelessWidget {
  static const double minTouchTarget = 48.0;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: minTouchTarget,
        minHeight: minTouchTarget,
      ),
      child: TextButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
```

**Focus Management**:
```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          focusNode: _emailFocus,
          onFieldSubmitted: (_) {
            _passwordFocus.requestFocus();
          },
        ),
        TextFormField(
          focusNode: _passwordFocus,
          onFieldSubmitted: (_) {
            _submitLogin();
          },
        ),
      ],
    );
  }
}
```


## 17. Development Guidelines

### 17.1 Code Style

**Follow Effective Dart**:
- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for classes and types
- Use `lowercase_with_underscores` for file names
- Prefer `final` over `var` when possible
- Use trailing commas for better formatting

**Naming Conventions**:
```dart
// Good
class BoxRepository {}
final userName = 'John';
void fetchBoxDetails() {}

// Bad
class box_repository {}
var UserName = 'John';
void FetchBoxDetails() {}
```

### 17.2 File Organization

**Feature-First Structure**:
- Group files by feature, not by type
- Each feature is self-contained
- Shared code goes in `shared/` or `core/`

**Imports**:
```dart
// Dart SDK imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';

// Relative imports
import '../domain/entities/box.dart';
import 'box_card.dart';
```

### 17.3 Documentation

**Class Documentation**:
```dart
/// Repository for managing box data.
///
/// Handles both local database operations and remote API calls,
/// implementing offline-first architecture with automatic sync.
class BoxRepository {
  /// Fetches box details by ID.
  ///
  /// First attempts to load from local cache, then falls back to API.
  /// Updates cache with fresh data from API when available.
  ///
  /// Returns [Box] if found, throws [BoxNotFoundException] otherwise.
  Future<Box> getBoxById(String id) async {
    // Implementation
  }
}
```


### 17.4 Git Workflow

**Branch Strategy**:
- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: New features (e.g., `feature/qr-scanner`)
- `bugfix/*`: Bug fixes (e.g., `bugfix/login-validation`)
- `hotfix/*`: Emergency production fixes

**Commit Messages**:
```
type(scope): subject

body (optional)

footer (optional)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (no logic change)
- `refactor`: Code restructuring (no behavior change)
- `test`: Adding or updating tests
- `chore`: Build process, dependencies

**Examples**:
```
feat(auth): add biometric login support

Implement fingerprint and face ID authentication for iOS and Android.
Uses local_auth package with fallback to password login.

Closes #123
```

```
fix(sync): resolve duplicate entries on offline sync

Fixed issue where offline queue was creating duplicate records
when sync retry occurred. Added unique constraint check.

Fixes #456
```

### 17.5 Code Review Checklist

**Functionality**:
- [ ] Code implements requirements correctly
- [ ] Edge cases are handled
- [ ] Error handling is appropriate
- [ ] No hardcoded values (use constants)

**Code Quality**:
- [ ] Follows project conventions
- [ ] No code duplication
- [ ] Clear variable and function names
- [ ] Appropriate comments for complex logic

**Testing**:
- [ ] Unit tests added/updated
- [ ] Tests pass locally
- [ ] Coverage meets minimum threshold

**Performance**:
- [ ] No unnecessary rebuilds
- [ ] Efficient algorithms used
- [ ] No memory leaks (streams disposed)

**Security**:
- [ ] No sensitive data in logs
- [ ] Input validation implemented
- [ ] API keys not hardcoded


## 18. Dependency Injection

### 18.1 GetIt Setup

**Service Locator**:
```dart
final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // External dependencies
  final sharedPrefs = await SharedPreferences.getInstance();
  final database = await _initDatabase();
  
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  getIt.registerSingleton<AppDatabase>(database);
  
  // Core services
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<TokenRepository>()),
  );
  
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(Connectivity()),
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<BoxRepository>(
    () => BoxRepositoryImpl(
      remoteDataSource: getIt<BoxRemoteDataSource>(),
      localDataSource: getIt<BoxLocalDataSource>(),
    ),
  );
  
  // BLoCs (registered as factories for new instance per screen)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );
  
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      boxRepository: getIt<BoxRepository>(),
      alertRepository: getIt<AlertRepository>(),
    ),
  );
}
```

### 18.2 Usage in Widgets

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: LoginView(),
    );
  }
}
```


## 19. Performance Optimization Techniques

### 19.1 Widget Optimization

**Use const Constructors**:
```dart
// Good: Constant widget won't rebuild
const Text('Hello World');
const SizedBox(height: 16);

// Bad: Non-const widget rebuilds unnecessarily
Text('Hello World');
SizedBox(height: 16);
```

**Extract Widgets**:
```dart
// Bad: Entire widget rebuilds on state change
build(context) {
  return Column(
    children: [
      // This complex widget rebuilds even if unchanged
      Container(
        decoration: BoxDecoration(...),
        child: Column(...),
      ),
      Text(counter.toString()), // Only this needs to update
    ],
  );
}

// Good: Extract static widget
build(context) {
  return Column(
    children: [
      const _HeaderWidget(), // Won't rebuild
      Text(counter.toString()),
    ],
  );
}
```

**RepaintBoundary**:
```dart
RepaintBoundary(
  child: ComplexChart(data: chartData),
)
```

### 19.2 List Performance

**ListView.builder**:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return BoxCard(box: items[index]);
  },
)
```

**Pagination**:
```dart
class InfiniteListView extends StatefulWidget {
  @override
  _InfiniteListViewState createState() => _InfiniteListViewState();
}

class _InfiniteListViewState extends State<InfiniteListView> {
  final _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_isBottom) {
      context.read<BoxBloc>().add(LoadMoreBoxes());
    }
  }
  
  bool get _isBottom {
    return _scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent;
  }
}
```


### 19.3 Image Optimization

**Cached Network Images**:
```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(color: Colors.white),
  ),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 400, // Resize for display
  memCacheHeight: 400,
)
```

**Image Compression**:
```dart
Future<File> compressImage(File file) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    '${file.path}_compressed.jpg',
    quality: 80,
    minWidth: 1024,
    minHeight: 1024,
  );
  return File(result!.path);
}
```

### 19.4 Database Optimization

**Indexes**:
```dart
class Boxes extends Table {
  TextColumn get id => text()();
  TextColumn get qrCode => text()();
  TextColumn get farmId => text()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  List<Index> get indexes => [
    Index('box_qr_code_idx', [qrCode]),
    Index('box_farm_id_idx', [farmId]),
    Index('box_created_at_idx', [createdAt]),
  ];
}
```

**Batch Operations**:
```dart
Future<void> insertMultipleBoxes(List<Box> boxes) async {
  await database.batch((batch) {
    for (final box in boxes) {
      batch.insert(database.boxes, box);
    }
  });
}
```

### 19.5 Memory Management

**Dispose Resources**:
```dart
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  _subscription.cancel();
  super.dispose();
}
```

**Limit Cache Size**:
```dart
class ImageCacheManager {
  static void configureCache() {
    imageCache.maximumSize = 100; // Maximum number of images
    imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200 MB
  }
}
```


## 20. Conclusion

This design document provides a comprehensive blueprint for building the CrabSense Mobile Application. The architecture emphasizes:

### Key Strengths

1. **Offline-First Architecture**: Local database as source of truth with robust background sync ensures operations continue seamlessly in areas with poor network coverage.

2. **Clean Architecture**: Clear separation of concerns with Presentation, Domain, and Data layers ensures maintainability and testability.

3. **Security by Design**: Multiple layers of security including encryption, certificate pinning, secure storage, and input validation protect sensitive farm data.

4. **Material Design 3**: Modern, consistent UI following platform guidelines with emphasis on usability and accessibility.

5. **BLoC State Management**: Predictable state management with clear separation of business logic from UI.

6. **Scalability**: Modular feature-based structure allows easy addition of new capabilities without affecting existing code.

### Development Phases

**Phase 1: Foundation (Weeks 1-4)**
- Project setup and dependencies
- Core architecture implementation
- Authentication module
- Basic navigation

**Phase 2: Core Features (Weeks 5-10)**
- Dashboard and metrics
- QR scanning and box management
- Video capture and AI integration
- Water quality monitoring

**Phase 3: Advanced Features (Weeks 11-14)**
- Offline sync implementation
- Operation logging
- Harvest and sales management
- Alert management

**Phase 4: Polish (Weeks 15-16)**
- Performance optimization
- Accessibility improvements
- Internationalization
- Testing and bug fixes

**Phase 5: Deployment (Week 17)**
- Beta testing
- App store submission
- Production deployment
- Monitoring setup

### Success Metrics

- **Performance**: < 3 second app launch, 60 FPS maintained
- **Reliability**: 99.9% crash-free sessions
- **Offline Capability**: 100% of operations work offline
- **User Satisfaction**: 4.5+ star rating on app stores
- **Code Quality**: 80%+ test coverage

This design serves as the technical foundation for implementing a production-grade mobile application that empowers crab farmers with real-time monitoring, AI-powered insights, and comprehensive farm management capabilities.

