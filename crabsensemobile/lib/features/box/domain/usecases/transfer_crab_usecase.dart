import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/box_repository.dart';

/// Parameters for [TransferCrabUseCase].
class TransferCrabParams {
  const TransferCrabParams({
    required this.crabId,
    required this.sourceBoxId,
    required this.destinationBoxId,
  });

  /// The unique identifier of the crab to transfer.
  final String crabId;

  /// The identifier of the box from which the crab is being moved.
  final String sourceBoxId;

  /// The identifier of the box to which the crab is being moved.
  final String destinationBoxId;
}

/// Use case for transferring a crab from one box to another.
///
/// Business rules enforced by this use case:
/// 1. Source and destination boxes must be different (Requirement 16.4)
/// 2. The transfer atomically decrements the source box count and increments
///    the destination box count (Requirement 16.5)
/// 3. All IDs must be non-empty
///
/// The atomic guarantee (Requirement 16.5) is implemented by the repository;
/// this use case validates inputs before delegating.
///
/// Requirements: 16.4, 16.5
class TransferCrabUseCase {
  const TransferCrabUseCase(this._repository);

  final BoxRepository _repository;

  /// Executes the crab transfer.
  ///
  /// Returns:
  /// - Right(void): Transfer completed successfully
  /// - Left(ValidationFailure): Source equals destination, or IDs are empty
  /// - Left(ServerFailure.notFound): Crab or either box not found
  /// - Left(NetworkFailure): No internet connection
  Future<Either<Failure, void>> call(TransferCrabParams params) async {
    // Validate crabId
    if (params.crabId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Crab ID'));
    }

    // Validate sourceBoxId
    if (params.sourceBoxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Source Box ID'));
    }

    // Validate destinationBoxId
    if (params.destinationBoxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Destination Box ID'));
    }

    // Source and destination must be different (Requirement 16.4)
    if (params.sourceBoxId == params.destinationBoxId) {
      return const Left(
        ValidationFailure(
          'Source and destination boxes must be different.',
          code: 'SAME_BOX_TRANSFER',
        ),
      );
    }

    return _repository.transferCrab(params.crabId, params.sourceBoxId, params.destinationBoxId);
  }
}
