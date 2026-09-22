// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import '../../features/video_capture/domain/entities/ai_detection.dart'
    show AIDetection;
import 'database_connection.dart';
import 'migrations/database_migration_manager.dart';

// Table definitions
part 'database.g.dart';

/// Database schema version — increment when making migrations.
const int kDatabaseVersion = 3;

// ============================================================================
// TABLE DEFINITIONS
// ============================================================================

/// Users table.
///
/// Stores authenticated user profiles cached locally.
/// Tokens are NOT stored here — they live in FlutterSecureStorage.
/// Requirement: 1.6, 23.4
class Users extends Table {
  @override
  String get tableName => 'users';

  /// UUID primary key.
  TextColumn get id => text().named('id')();

  TextColumn get email => text().named('email').withLength(max: 255)();

  TextColumn get name => text().named('name').withLength(max: 255)();

  /// Role string: admin | farmManager | fieldOperator | sales | viewer
  TextColumn get role => text().named('role').withLength(max: 50)();

  /// JSON-encoded list of assigned farm IDs.
  TextColumn get assignedFarmIds =>
      text().named('assigned_farm_ids').withDefault(const Constant('[]'))();

  /// URL to the user's profile photo (nullable).
  TextColumn get photoUrl => text().named('photo_url').nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get lastLoginAt =>
      dateTime().named('last_login_at').nullable()();

  /// Cached at timestamp for 30-day retention policy (req 23.6).
  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Boxes table.
///
/// Physical crab containers identified by QR code.
/// Requirements: 4.1-4.10, 13.3
class Boxes extends Table {
  @override
  String get tableName => 'boxes';

  TextColumn get id => text().named('id')();

  TextColumn get qrCode => text().named('qr_code').withLength(max: 100)();

  TextColumn get farmId => text().named('farm_id')();

  TextColumn get pondId => text().named('pond_id').nullable()();

  /// JSON-encoded location object (latitude, longitude, label).
  TextColumn get location => text().named('location').nullable()();

  IntColumn get currentCrabCount =>
      integer().named('current_crab_count').withDefault(const Constant(0))();

  IntColumn get capacity =>
      integer().named('capacity').withDefault(const Constant(0))();

  /// Species string: blueCrab | mudCrab | softShell
  TextColumn get species => text().named('species').withLength(max: 50)();

  RealColumn get averageWeight =>
      real().named('average_weight').withDefault(const Constant(0))();

  /// Status string: active | inactive | maintenance | harvested
  TextColumn get status => text()
      .named('status')
      .withLength(max: 50)
      .withDefault(const Constant('active'))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get lastVideoAt =>
      dateTime().named('last_video_at').nullable()();

  // Sync tracking columns (req 13.3-13.10)
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Crabs table.
///
/// Individual crab records associated with a box.
/// Requirements: 16.1-16.10, 13.3
class Crabs extends Table {
  @override
  String get tableName => 'crabs';

  TextColumn get id => text().named('id')();

  /// Foreign key → boxes.id
  TextColumn get boxId => text().named('box_id').references(Boxes, #id)();

  /// Species: blueCrab | mudCrab | softShell
  TextColumn get species => text().named('species').withLength(max: 50)();

  RealColumn get weight =>
      real().named('weight').withDefault(const Constant(0))();

  /// Molting status: preMolt | molting | postMolt | hardShell
  TextColumn get moltingStatus =>
      text().named('molting_status').withLength(max: 50)();

  /// Health status: normal | disease | stress | unknown
  TextColumn get healthStatus => text()
      .named('health_status')
      .withLength(max: 50)
      .withDefault(const Constant('unknown'))();

  /// Source of the crab: farm | purchase | transfer
  TextColumn get source => text().named('source').withLength(max: 50)();

  DateTimeColumn get addedAt => dateTime().named('added_at')();

  /// Operator user ID who added this crab record.
  TextColumn get addedBy => text().named('added_by')();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// WaterQualityReadings table.
///
/// IoT sensor readings cached locally for offline viewing.
/// Requirements: 8.1-8.10, 13.3
class WaterQualityReadings extends Table {
  @override
  String get tableName => 'water_quality_readings';

  TextColumn get id => text().named('id')();

  TextColumn get sensorId => text().named('sensor_id')();

  TextColumn get farmId => text().named('farm_id')();

  TextColumn get pondId => text().named('pond_id').nullable()();

  /// Temperature in Celsius (26–30 optimal range).
  RealColumn get temperature =>
      real().named('temperature').withDefault(const Constant(0))();

  /// pH level (7.5–8.5 optimal range).
  RealColumn get ph => real().named('ph').withDefault(const Constant(0))();

  /// Dissolved oxygen in mg/L (minimum 5.0).
  RealColumn get dissolvedOxygen =>
      real().named('dissolved_oxygen').withDefault(const Constant(0))();

  /// Salinity in ppt (15–25 optimal range).
  RealColumn get salinity =>
      real().named('salinity').withDefault(const Constant(0))();

  DateTimeColumn get timestamp => dateTime().named('timestamp')();

  BoolColumn get isAlertTriggered => boolean()
      .named('is_alert_triggered')
      .withDefault(const Constant(false))();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Alerts table.
///
/// Critical, warning, and info notifications cached locally.
/// Supports offline acknowledgement queuing (req 9.10, 13.4).
/// Requirements: 9.1-9.10, 13.3
class Alerts extends Table {
  @override
  String get tableName => 'alerts';

  TextColumn get id => text().named('id')();

  /// Alert type: waterQuality | equipment | crabHealth | maintenance | task | system
  TextColumn get type => text().named('type').withLength(max: 50)();

  /// Severity: critical | warning | info
  TextColumn get severity => text().named('severity').withLength(max: 20)();

  TextColumn get title => text().named('title').withLength(max: 255)();

  TextColumn get message => text().named('message')();

  /// Optional ID of the source entity (box_id, sensor_id, etc.).
  TextColumn get sourceId => text().named('source_id').nullable()();

  /// Type of the source entity: box | sensor | system
  TextColumn get sourceType =>
      text().named('source_type').withLength(max: 50).nullable()();

  /// JSON-encoded list of recommended action strings.
  TextColumn get recommendedActions =>
      text().named('recommended_actions').withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get acknowledgedAt =>
      dateTime().named('acknowledged_at').nullable()();

  TextColumn get acknowledgedBy => text().named('acknowledged_by').nullable()();

  /// Status: unread | read | acknowledged | dismissed
  TextColumn get status => text()
      .named('status')
      .withLength(max: 20)
      .withDefault(const Constant('unread'))();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// OperationLogs table.
///
/// Farm operation records (feeding, water change, etc.) with offline queuing.
/// Requirements: 10.1-10.10, 13.4
class OperationLogs extends Table {
  @override
  String get tableName => 'operation_logs';

  TextColumn get id => text().named('id')();

  /// Operation type: feeding | waterChange | mineralAddition |
  ///                  cleaning | medication | inspection
  TextColumn get type => text().named('type').withLength(max: 50)();

  /// JSON-encoded list of box IDs this operation applies to.
  TextColumn get boxIds =>
      text().named('box_ids').withDefault(const Constant('[]'))();

  RealColumn get quantity => real().named('quantity').nullable()();

  TextColumn get unit => text().named('unit').withLength(max: 50).nullable()();

  TextColumn get notes =>
      text().named('notes').withDefault(const Constant(''))();

  /// JSON-encoded list of photo URL strings.
  TextColumn get photoUrls =>
      text().named('photo_urls').withDefault(const Constant('[]'))();

  DateTimeColumn get timestamp => dateTime().named('timestamp')();

  TextColumn get operatorId => text().named('operator_id')();

  TextColumn get operatorName =>
      text().named('operator_name').withLength(max: 255)();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Harvests table.
///
/// Harvest records with inventory update tracking.
/// Requirements: 11.1-11.10, 13.4
class Harvests extends Table {
  @override
  String get tableName => 'harvests';

  TextColumn get id => text().named('id')();

  /// Foreign key → boxes.id
  TextColumn get boxId => text().named('box_id').references(Boxes, #id)();

  /// Total weight in kg.
  RealColumn get totalWeight =>
      real().named('total_weight').withDefault(const Constant(0))();

  IntColumn get crabCount =>
      integer().named('crab_count').withDefault(const Constant(0))();

  /// Quality grade: gradeA | gradeB | gradeC
  TextColumn get qualityGrade =>
      text().named('quality_grade').withLength(max: 20)();

  DateTimeColumn get harvestDate => dateTime().named('harvest_date')();

  TextColumn get harvestedBy => text().named('harvested_by')();

  TextColumn get destination => text().named('destination').nullable()();

  /// JSON-encoded list of photo URL strings.
  TextColumn get photoUrls =>
      text().named('photo_urls').withDefault(const Constant('[]'))();

  TextColumn get notes =>
      text().named('notes').withDefault(const Constant(''))();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Sales table.
///
/// Sales transaction records.
/// Requirements: 12.1-12.10, 13.4
class Sales extends Table {
  @override
  String get tableName => 'sales';

  TextColumn get id => text().named('id')();

  /// Unique transaction identifier generated at creation.
  TextColumn get transactionId =>
      text().named('transaction_id').withLength(max: 100)();

  TextColumn get buyerName => text().named('buyer_name').withLength(max: 255)();

  TextColumn get buyerContact =>
      text().named('buyer_contact').withLength(max: 255).nullable()();

  /// Quantity in kg.
  RealColumn get quantity =>
      real().named('quantity').withDefault(const Constant(0))();

  RealColumn get unitPrice =>
      real().named('unit_price').withDefault(const Constant(0))();

  RealColumn get totalAmount =>
      real().named('total_amount').withDefault(const Constant(0))();

  /// Payment method: cash | bankTransfer | credit
  TextColumn get paymentMethod =>
      text().named('payment_method').withLength(max: 50)();

  /// Payment status: pending | completed | cancelled
  TextColumn get paymentStatus => text()
      .named('payment_status')
      .withLength(max: 50)
      .withDefault(const Constant('pending'))();

  DateTimeColumn get saleDate => dateTime().named('sale_date')();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// SyncQueue table.
///
/// Offline operation queue. Stores pending mutations that need to be
/// replayed to the server when connectivity is restored.
///
/// Processing order is chronological (createdAt ASC, priority DESC).
/// Requirements: 13.3-13.10
class SyncQueue extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get id => text().named('id')();

  /// Operation type string, e.g. "create_harvest", "acknowledge_alert".
  TextColumn get operationType =>
      text().named('operation_type').withLength(max: 100)();

  /// ID of the entity this operation targets.
  TextColumn get entityId => text().named('entity_id')();

  /// Entity type: box | crab | alert | operationLog | harvest | sale | inspection
  TextColumn get entityType =>
      text().named('entity_type').withLength(max: 50)();

  /// JSON-encoded payload of the operation.
  TextColumn get payload => text().named('payload')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  /// Number of failed sync attempts so far.
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  /// Queue item status: pending | processing | failed | completed
  TextColumn get status => text()
      .named('status')
      .withLength(max: 20)
      .withDefault(const Constant('pending'))();

  /// Priority level — higher numbers are processed first within
  /// the same batch. Maps to data priorities in design section 4.1:
  ///   3 = critical (alerts, water quality thresholds)
  ///   2 = high     (harvests, sales, AI results)
  ///   1 = medium   (operation logs, inspections)
  ///   0 = low      (analytics, historical data)
  IntColumn get priority =>
      integer().named('priority').withDefault(const Constant(1))();

  DateTimeColumn get lastAttemptAt =>
      dateTime().named('last_attempt_at').nullable()();

  TextColumn get errorMessage => text().named('error_message').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Version metadata for entities whose domain tables are shared with older
/// clients. The table keeps optimistic-concurrency state without changing
/// every existing domain model at once.
class EntitySyncMetadata extends Table {
  @override
  String get tableName => 'entity_sync_metadata';

  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  IntColumn get serverVersion =>
      integer().named('server_version').withDefault(const Constant(0))();
  DateTimeColumn get localUpdatedAt => dateTime().named('local_updated_at')();
  DateTimeColumn get serverUpdatedAt =>
      dateTime().named('server_updated_at').nullable()();
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('synced'))();
  TextColumn get lastSyncError => text().named('last_sync_error').nullable()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

// ----------------------------------------------------------------------------

/// Metadata for photos kept in app-private storage while waiting for upload.
class PhotoAssets extends Table {
  @override
  String get tableName => 'photo_assets';

  TextColumn get id => text().named('id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get feedingId => text().named('feeding_id').nullable()();
  TextColumn get boxId => text().named('box_id').nullable()();
  TextColumn get crabId => text().named('crab_id').nullable()();
  TextColumn get photoType => text().named('photo_type')();
  TextColumn get localPath => text().named('local_path')();
  TextColumn get serverId => text().named('server_id').nullable()();
  TextColumn get serverUrl => text().named('server_url').nullable()();
  TextColumn get uploadStatus =>
      text().named('upload_status').withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get uploadedAt => dateTime().named('uploaded_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Persisted local/server versions requiring an explicit user decision.
class SyncConflicts extends Table {
  @override
  String get tableName => 'sync_conflicts';

  TextColumn get id => text().named('id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get localPayload => text().named('local_payload')();
  TextColumn get serverPayload => text().named('server_payload')();
  IntColumn get localVersion =>
      integer().named('local_version').withDefault(const Constant(0))();
  IntColumn get serverVersion =>
      integer().named('server_version').withDefault(const Constant(0))();
  TextColumn get status =>
      text().named('status').withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get resolvedAt => dateTime().named('resolved_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Inspections table.
///
/// Manual crab inspection records with offline-first support.
/// Persisted locally immediately; synced to remote when online.
/// Requirements: 7.1-7.10, 13.3-13.4
class Inspections extends Table {
  @override
  String get tableName => 'inspections';

  TextColumn get id => text().named('id')();

  /// Foreign key → boxes.id
  TextColumn get boxId => text().named('box_id').references(Boxes, #id)();

  /// Optional video / AI detection ID this inspection is linked to.
  TextColumn get relatedVideoId =>
      text().named('related_video_id').nullable()();

  /// Molting status: preMolt | molting | postMolt | hardShell
  TextColumn get moltingStatus =>
      text().named('molting_status').withLength(max: 50)();

  /// Health status: normal | disease | stress | unknown
  TextColumn get healthStatus => text()
      .named('health_status')
      .withLength(max: 50)
      .withDefault(const Constant('unknown'))();

  /// Weight recorded in grams (must be > 0).
  RealColumn get weight =>
      real().named('weight').withDefault(const Constant(0))();

  TextColumn get notes =>
      text().named('notes').withDefault(const Constant(''))();

  /// JSON-encoded list of photo URL strings.
  TextColumn get photoUrls =>
      text().named('photo_urls').withDefault(const Constant('[]'))();

  DateTimeColumn get timestamp => dateTime().named('timestamp')();

  TextColumn get operatorId => text().named('operator_id')();

  TextColumn get operatorName =>
      text().named('operator_name').withLength(max: 255)();

  /// Whether the operator agreed with the AI result: true / false / null.
  BoolColumn get aiAgreement => boolean().named('ai_agreement').nullable()();

  /// Sync status: pending | synced | failed
  TextColumn get syncStatus => text()
      .named('sync_status')
      .withLength(max: 20)
      .withDefault(const Constant('pending'))();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// Videos table.
///
/// Records of captured videos for AI crab health analysis.
/// Supports offline-first queuing — status progresses from
/// pending → uploading → uploaded (or failed with retry).
/// Requirements: 5.1-5.10, 13.3
class Videos extends Table {
  @override
  String get tableName => 'videos';

  TextColumn get id => text().named('id')();

  /// Foreign key → boxes.id
  TextColumn get boxId => text().named('box_id').references(Boxes, #id)();

  /// Absolute path to the video file on device storage.
  TextColumn get localPath => text().named('local_path')();

  /// Duration of the recording in seconds (5–10 valid range).
  IntColumn get durationSeconds =>
      integer().named('duration_seconds').withDefault(const Constant(0))();

  /// Compressed file size in bytes; null until compression completes.
  IntColumn get fileSizeBytes =>
      integer().named('file_size_bytes').nullable()();

  /// Upload status: pending | uploading | uploaded | failed
  TextColumn get status => text()
      .named('status')
      .withLength(max: 50)
      .withDefault(const Constant('pending'))();

  DateTimeColumn get capturedAt => dateTime().named('captured_at')();

  /// Identifier of the field operator who recorded this video.
  TextColumn get capturedBy => text().named('captured_by')();

  /// Timestamp when the upload completed; null until uploaded.
  DateTimeColumn get uploadedAt => dateTime().named('uploaded_at').nullable()();

  /// ID of the [AIDetection] result; null until analysis is complete.
  TextColumn get aiDetectionId => text().named('ai_detection_id').nullable()();

  /// Number of failed upload attempts for exponential back-off (Req 6.10).
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------------------------

/// AiDetections table.
///
/// AI detection results returned by the analysis service for a video.
/// detectedCrabs and recommendations are stored as JSON-encoded strings.
/// Requirements: 6.1-6.10, 13.3
class AiDetections extends Table {
  @override
  String get tableName => 'ai_detections';

  TextColumn get id => text().named('id')();

  /// Foreign key → videos.id
  TextColumn get videoId => text().named('video_id').references(Videos, #id)();

  /// The box this detection is associated with.
  TextColumn get boxId => text().named('box_id')();

  /// Molting stage: preMolt | molting | postMolt | hardShell
  TextColumn get moltingStatus =>
      text().named('molting_status').withLength(max: 50)();

  /// Health status: normal | disease | stress | unknown
  TextColumn get healthStatus => text()
      .named('health_status')
      .withLength(max: 50)
      .withDefault(const Constant('unknown'))();

  /// Overall confidence score in [0.0, 1.0].
  RealColumn get confidenceScore =>
      real().named('confidence_score').withDefault(const Constant(0))();

  /// JSON-encoded list of DetectionBox objects.
  TextColumn get detectedCrabs =>
      text().named('detected_crabs').withDefault(const Constant('[]'))();

  /// JSON-encoded list of recommendation strings.
  TextColumn get recommendations =>
      text().named('recommendations').withDefault(const Constant('[]'))();

  DateTimeColumn get analyzedAt => dateTime().named('analyzed_at')();

  /// Operator feedback: correct | incorrect | null (no feedback yet).
  TextColumn get feedbackStatus =>
      text().named('feedback_status').withLength(max: 20).nullable()();

  // Sync tracking
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  DateTimeColumn get cachedAt =>
      dateTime().named('cached_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// DATABASE CLASS
// ============================================================================

/// CrabSense local Drift database.
///
/// This is the single source of truth for all local data. Every write goes
/// here first; the SyncService replicates mutations to the remote API.
///
/// Schema version history:
///   v1 — initial schema with all 9 core tables.
///   v2 — added Videos and AiDetections tables (requirements 5.1-5.10, 6.1-6.10).
///
/// Requirements: 13.3-13.10, 23.6
@DriftDatabase(
  tables: [
    Users,
    Boxes,
    Crabs,
    WaterQualityReadings,
    Alerts,
    OperationLogs,
    Harvests,
    Sales,
    SyncQueue,
    EntitySyncMetadata,
    PhotoAssets,
    SyncConflicts,
    Videos,
    AiDetections,
    Inspections,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openAppConnection());

  /// Constructor that accepts a [QueryExecutor] — used in tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => kDatabaseVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => DatabaseMigrationManager.onCreate(m, this),
    onUpgrade: (m, from, to) =>
        DatabaseMigrationManager.onUpgrade(m, from, to, this),
    beforeOpen: (db) async {
      // Enable foreign-key enforcement on every connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
