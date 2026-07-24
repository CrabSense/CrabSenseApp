import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/box.dart';
import '../repositories/box_repository.dart';

/// Parameters for [UpdateBoxUseCase].
class UpdateBoxParams {
  const UpdateBoxParams({required this.box});

  /// The updated box entity.
  ///
  /// The [Box.id] and [Box.farmId] must not be empty.
  /// The [Box.capacity] must be a positive integer.
  /// The [Box.currentCrabCount] must not exceed [Box.capacity].
  final Box box;
}

/// Use case for updating an existing box record.
///
/// Business rules enforced by this use case:
/// 1. Box ID must not be empty (identity of the record to update)
/// 2. Farm ID must not be empty (a box must always belong to a farm)
/// 3. Capacity must be a positive integer
/// 4. Current crab count must not exceed capacity
///
/// Requirements: 4.1
class UpdateBoxUseCase {
  const UpdateBoxUseCase(this._repository);

  final BoxRepository _repository;

  /// Executes the box update.
  ///
  /// Returns:
  /// - Right(Box): Updated box record
  /// - Left(ValidationFailure): Box data failed validation
  /// - Left(ServerFailure.notFound): Box does not exist
  /// - Left(NetworkFailure): No internet connection
  Future<Either<Failure, Box>> call(UpdateBoxParams params) async {
    final box = params.box;

    // ID is required to identify the record
    if (box.id.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    // A box must always belong to a farm
    if (box.farmId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Farm ID'));
    }

    // Capacity must be a positive integer
    if (box.capacity <= 0) {
      return const Left(
        ValidationFailure('Box capacity must be a positive number.', code: 'INVALID_BOX_CAPACITY'),
      );
    }

    // Crab count must not exceed capacity
    if (box.currentCrabCount > box.capacity) {
      return const Left(
        ValidationFailure(
          'Current crab count cannot exceed box capacity.',
          code: 'CRAB_COUNT_EXCEEDS_CAPACITY',
        ),
      );
    }

    // Crab count must not be negative
    if (box.currentCrabCount < 0) {
      return const Left(
        ValidationFailure('Current crab count cannot be negative.', code: 'NEGATIVE_CRAB_COUNT'),
      );
    }

    return _repository.updateBox(box);
  }
}
