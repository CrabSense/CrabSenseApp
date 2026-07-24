import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_history_item.dart';

/// Abstract contract for the notification history data layer.
///
/// All operations return [Either] so callers can handle failures
/// without exceptions leaking into the presentation layer.
///
/// Requirements: 14.6
abstract class NotificationHistoryRepository {
  /// Returns all stored notification history items, newest first.
  ///
  /// Items older than 30 days are excluded automatically.
  Future<Either<Failure, List<NotificationHistoryItem>>> getHistory();

  /// Persists a new item to the local history store.
  Future<Either<Failure, void>> addItem(NotificationHistoryItem item);

  /// Deletes all stored notification history items.
  Future<Either<Failure, void>> clearAll();

  /// Marks every stored item as read.
  Future<Either<Failure, void>> markAllRead();
}
