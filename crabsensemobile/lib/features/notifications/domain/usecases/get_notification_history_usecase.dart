import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification_history_item.dart';
import '../repositories/notification_history_repository.dart';

/// Returns notification history items sorted newest first.
///
/// Requirements: 14.6
class GetNotificationHistoryUseCase {
  const GetNotificationHistoryUseCase(this._repository);

  final NotificationHistoryRepository _repository;

  Future<Either<Failure, List<NotificationHistoryItem>>> call() {
    return _repository.getHistory();
  }
}
