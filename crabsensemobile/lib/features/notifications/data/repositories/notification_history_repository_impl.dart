import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_history_item.dart';
import '../../domain/repositories/notification_history_repository.dart';
import '../datasources/notification_history_local_data_source.dart';
import '../models/notification_history_item_model.dart';

/// Concrete implementation of [NotificationHistoryRepository].
///
/// The in-app notification centre reads from CrabSenseBE
/// (`GET /api/notifications/me`). The local Hive store is kept only as a
/// cache for notifications delivered through FCM while the app is open.
class NotificationHistoryRepositoryImpl
    implements NotificationHistoryRepository {
  NotificationHistoryRepositoryImpl({
    required NotificationHistoryLocalDataSource localDataSource,
    required ApiClient api,
    required this._logger,
  }) : _local = localDataSource,
       _api = api;

  final NotificationHistoryLocalDataSource _local;
  final ApiClient _api;
  final Logger _logger;

  @override
  Future<Either<Failure, List<NotificationHistoryItem>>> getHistory() async {
    final result = await _api.safeGet<dynamic>(ApiConstants.myNotifications);
    if (result.failure != null) {
      _logger.e(
        'NotificationHistoryRepository: getHistory failed',
        error: result.failure,
      );
      return Left(result.failure!);
    }
    try {
      final models =
          _listOf(result.data.data)
              .whereType<Map>()
              .map(
                (e) => NotificationHistoryItemModel.fromApi(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
            ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return Right(models.map((m) => m.toEntity()).toList());
    } on Exception catch (e, st) {
      _logger.e(
        'NotificationHistoryRepository: parse failed',
        error: e,
        stackTrace: st,
      );
      return const Left(ParseFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addItem(NotificationHistoryItem item) async {
    try {
      final model = NotificationHistoryItemModel.fromEntity(item);
      await _local.addItem(model);
      return const Right(null);
    } on Exception catch (e, st) {
      _logger.e(
        'NotificationHistoryRepository: addItem failed',
        error: e,
        stackTrace: st,
      );
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _local.clearAll();
      return const Right(null);
    } on Exception catch (e, st) {
      _logger.e(
        'NotificationHistoryRepository: clearAll failed',
        error: e,
        stackTrace: st,
      );
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    final result = await _api.safePatch<dynamic>(
      ApiConstants.markNotificationRead(id),
    );
    if (result.failure != null) {
      _logger.w(
        'NotificationHistoryRepository: markRead failed',
        error: result.failure,
      );
      return Left(result.failure!);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    final result = await _api.safePatch<dynamic>(
      ApiConstants.markAllNotificationsRead,
    );
    if (result.failure != null) {
      _logger.w(
        'NotificationHistoryRepository: markAllRead failed',
        error: result.failure,
      );
      return Left(result.failure!);
    }
    return const Right(null);
  }

  /// BE wraps payloads as `{ success, message, data: [...] }`.
  static List<dynamic> _listOf(dynamic raw) {
    dynamic body = raw;
    if (raw is Map && raw['data'] != null) body = raw['data'];
    if (body is List) return body;
    if (body is Map && body['items'] is List) return body['items'] as List;
    return const [];
  }
}
