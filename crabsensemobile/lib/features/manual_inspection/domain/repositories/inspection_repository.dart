import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/inspection.dart';

/// Repository interface for manual inspection operations.
///
/// Defines the contract between the domain layer and any concrete data-layer
/// implementation.  Implementations handle:
///   - Remote persistence via the REST API
///   - Local caching via SQLite (drift) for offline support
///   - Offline-first: store records locally when network is unavailable and
///     synchronise them when connectivity is restored (Requirements 7.7, 13.3)
///   - Mapping transport/storage errors to typed [Failure] values
///
/// All methods return `Either<Failure, T>`:
///   - Left([Failure]) — operation failed with a typed reason
///   - Right(T)        — operation succeeded with the result value
///
/// Requirements: 7.1-7.10
abstract class InspectionRepository {
  /// Saves an inspection locally and queues it for remote synchronisation.
  ///
  /// The record is written to local storage immediately so the UI can
  /// confirm the submission even when offline (Requirement 7.7).
  /// Once connectivity is restored the [syncPendingInspections] method
  /// uploads queued records.
  ///
  /// Returns:
  /// - `Right(Inspection)` — record persisted (syncStatus may be [SyncStatus.pending]
  ///   when offline)
  /// - `Left(ValidationFailure)` — provided data failed business-rule validation
  /// - `Left(CacheFailure)` — unable to persist to local storage
  ///
  /// Requirements: 7.4, 7.6, 7.7
  Future<Either<Failure, Inspection>> submitInspection(Inspection inspection);

  /// Sends AI-feedback to the remote AI service for model retraining.
  ///
  /// When offline the feedback is queued locally and sent with the next
  /// sync cycle (Requirement 7.7).
  ///
  /// Returns:
  /// - `Right(void)` — feedback delivered (or queued successfully)
  /// - `Left(ValidationFailure)` — [feedback] data failed validation
  /// - `Left(NetworkFailure)` — no internet and queuing failed
  /// - `Left(ServerFailure)` — remote AI service returned an error
  ///
  /// Requirements: 7.5
  Future<Either<Failure, void>> submitFeedback(InspectionFeedback feedback);

  /// Returns all inspection records for the given box in reverse-chronological
  /// order (newest first).
  ///
  /// Serves cached records when offline (Requirement 7.7).
  ///
  /// Returns:
  /// - `Right(List<Inspection>)` — list of inspections (may be empty)
  /// - `Left(NetworkFailure)` — no internet and no cached data available
  /// - `Left(CacheFailure)` — unable to read from local storage
  ///
  /// Requirements: 7.10
  Future<Either<Failure, List<Inspection>>> getInspectionHistory(String boxId);

  /// Calculates the agreement rate between AI and manual inspections for a box.
  ///
  /// The agreement rate is the proportion of inspections where
  /// [Inspection.aiAgreement] is `true` out of all inspections that had a
  /// non-null [Inspection.aiAgreement] value (Requirement 7.8).
  ///
  /// Returns a value in the range `[0.0, 1.0]`, or `0.0` when no inspections
  /// with AI comparison data exist.
  ///
  /// Returns:
  /// - `Right(double)` — agreement rate in the range `[0.0, 1.0]`
  /// - `Left(CacheFailure)` — unable to read from local storage
  ///
  /// Requirements: 7.8
  Future<Either<Failure, double>> getAgreementRate(String boxId);

  /// Uploads all locally-queued inspection and feedback records to the server.
  ///
  /// This method is typically called by a background sync service after
  /// connectivity is restored (Requirement 13.5-13.6).
  ///
  /// Processing order is chronological (oldest first).  Failed items are
  /// left in the queue with [SyncStatus.failed] so they can be retried later
  /// using exponential backoff (Requirement 13.7).
  ///
  /// Returns:
  /// - `Right(void)` — all pending records uploaded successfully
  /// - `Left(NetworkFailure)` — no internet connection; sync deferred
  /// - `Left(SyncFailure)` — one or more items failed to upload
  ///
  /// Requirements: 7.7, 13.5, 13.6, 13.7
  Future<Either<Failure, void>> syncPendingInspections();

  /// Uploads all locally-queued AI feedback records to the AI service.
  ///
  /// Feedback queued offline (via the SyncQueue) is sent when connectivity
  /// is restored (Requirement 7.7, 13.5-13.6).
  ///
  /// Returns:
  /// - `Right(void)` — all queued feedback uploaded successfully
  /// - `Left(NetworkFailure)` — no internet connection; sync deferred
  /// - `Left(SyncFailure)` — one or more feedbacks failed to upload
  ///
  /// Requirements: 7.5, 7.7
  Future<Either<Failure, void>> syncPendingFeedback();
}
