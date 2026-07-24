import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/notification_history_repository.dart';

/// Clears all notification history items from local storage.
///
/// Requirements: 14.6
class ClearNotificationHistoryUseCase {
  const ClearNotificationHistoryUseCase(this._repository);

  final NotificationHistoryRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.clearAll();
  }
}
