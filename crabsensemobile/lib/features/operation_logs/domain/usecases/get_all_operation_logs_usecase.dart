import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/operation_log.dart';
import '../repositories/operation_repository.dart';

/// Parameters for [GetAllOperationLogsUseCase].
class GetAllOperationLogsParams {
  const GetAllOperationLogsParams({this.page = 1, this.pageSize = 50});

  /// 1-based page number for pagination. Defaults to 1.
  final int page;

  /// Number of records per page. Defaults to 50.
  final int pageSize;
}

/// Use case for retrieving all operation logs across every box.
///
/// Online: refreshes the local cache from `GET /operations` and returns
/// the merged result (server data + logs still pending sync).
/// Offline: returns cached data directly.
///
/// Results are sorted by timestamp descending (newest first).
/// This is the data source for the operation history screen.
class GetAllOperationLogsUseCase {
  const GetAllOperationLogsUseCase(this._repository);

  final OperationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(List<OperationLog>)`: Matching logs (may be empty)
  /// - `Left(ValidationFailure)`: page < 1 or pageSize < 1
  /// - `Left(CacheFailure)`: Error reading from local storage
  Future<Either<Failure, List<OperationLog>>> call(
    GetAllOperationLogsParams params,
  ) async {
    if (params.page < 1) {
      return const Left(ValidationFailure('Page number must be at least 1.'));
    }
    if (params.pageSize < 1) {
      return const Left(ValidationFailure('Page size must be at least 1.'));
    }

    return _repository.getAllOperationLogs(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
