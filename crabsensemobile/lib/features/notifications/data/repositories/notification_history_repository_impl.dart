import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_history_item.dart';
import '../../domain/repositories/notification_history_repository.dart';
import '../datasources/notification_history_local_data_source.dart';
import '../models/notification_history_item_model.dart';

/// Concrete implementation of [NotificationHistoryRepository].
///
/// Notification history is local-only — no remote sync is needed since
/// FCM already handles delivery via the server push infrastructure.
///
/// Requirements: 14.6
class NotificationHistoryRepositoryImpl implements NotificationHistoryRepository {
  NotificationHistoryRepositoryImpl({
    required NotificationHistoryLocalDataSource localDataSource,
    required this._logger,
  }) : _local = localDataSource;

  final NotificationHistoryLocalDataSource _local;
  final Logger _logger;

  @override
  Future<Either<Failure, List<NotificationHistoryItem>>> getHistory() async {
    try {
      final models = await _local.getHistory();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on Exception catch (e, st) {
      _logger.e('NotificationHistoryRepository: getHistory failed', error: e, stackTrace: st);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addItem(NotificationHistoryItem item) async {
    try {
      final model = NotificationHistoryItemModel.fromEntity(item);
      await _local.addItem(model);
      return const Right(null);
    } on Exception catch (e, st) {
      _logger.e('NotificationHistoryRepository: addItem failed', error: e, stackTrace: st);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _local.clearAll();
      return const Right(null);
    } on Exception catch (e, st) {
      _logger.e('NotificationHistoryRepository: clearAll failed', error: e, stackTrace: st);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await _local.markAllRead();
      return const Right(null);
    } on Exception catch (e, st) {
      _logger.e('NotificationHistoryRepository: markAllRead failed', error: e, stackTrace: st);
      return const Left(CacheFailure());
    }
  }
}
