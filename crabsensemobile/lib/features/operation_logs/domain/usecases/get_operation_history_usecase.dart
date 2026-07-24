import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/operation_log.dart';
import '../entities/operation_type.dart';
import '../repositories/operation_repository.dart';

/// Parameters for [GetOperationHistoryUseCase].
class GetOperationHistoryParams {
  const GetOperationHistoryParams({
    required this.boxId,
    this.startDate,
    this.endDate,
    this.type,
    this.page = 1,
    this.pageSize = 50,
  });

  /// The box whose operation history to retrieve (required).
  final String boxId;

  /// Optional lower bound on the operation timestamp.
  /// Only logs with [OperationLog.timestamp] >= [startDate] are returned.
  final DateTime? startDate;

  /// Optional upper bound on the operation timestamp.
  /// Only logs with [OperationLog.timestamp] <= [endDate] are returned.
  final DateTime? endDate;

  /// Optional filter to retrieve only one operation type.
  final OperationType? type;

  /// 1-based page number for pagination. Defaults to 1.
  final int page;

  /// Number of records per page. Defaults to 50 (Requirement 10.8).
  final int pageSize;
}

/// Use case for retrieving the operation history of a box.
///
/// Returns a paginated, optionally filtered list of [OperationLog] entries
/// for the given box, sorted by timestamp descending (newest first).
/// Returns cached data when offline (Requirement 10.7).
///
/// Following Clean Architecture, this use case represents a single
/// read operation and delegates to [OperationRepository].
///
/// Requirements: 10.4, 10.7, 10.8
class GetOperationHistoryUseCase {
  const GetOperationHistoryUseCase(this._repository);

  final OperationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - `Right(List<OperationLog>)`: Matching logs (may be empty)
  /// - `Left(ValidationFailure)`: [params.boxId] is empty, page < 1,
  ///   or pageSize < 1, or [startDate] is after [endDate]
  /// - `Left(NetworkFailure)`: No internet and no cached data
  /// - `Left(CacheFailure)`: Error reading from local storage
  /// - `Left(ServerFailure)`: Server error
  Future<Either<Failure, List<OperationLog>>> call(GetOperationHistoryParams params) async {
    if (params.boxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    if (params.page < 1) {
      return const Left(ValidationFailure('Page number must be at least 1.'));
    }

    if (params.pageSize < 1) {
      return const Left(ValidationFailure('Page size must be at least 1.'));
    }

    if (params.startDate != null &&
        params.endDate != null &&
        params.startDate!.isAfter(params.endDate!)) {
      return const Left(ValidationFailure('Start date must be before end date.'));
    }

    return _repository.getOperationHistory(
      boxId: params.boxId,
      startDate: params.startDate,
      endDate: params.endDate,
      type: params.type,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
