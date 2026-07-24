import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/box.dart';
import '../repositories/box_repository.dart';

/// Parameters for [GetBoxDetailsUseCase].
class GetBoxDetailsParams {
  const GetBoxDetailsParams({required this.boxId});

  /// The unique identifier of the box to retrieve.
  final String boxId;
}

/// Use case for retrieving the details of a single box.
///
/// Fetches box information including crab count, species, average weight,
/// and status. Returns cached data when offline (Requirement 4.7).
///
/// Following Clean Architecture, this use case represents a single
/// read operation and delegates to [BoxRepository].
///
/// Requirements: 4.1, 4.2, 4.7, 4.10
class GetBoxDetailsUseCase {
  const GetBoxDetailsUseCase(this._repository);

  final BoxRepository _repository;

  /// Executes the use case.
  ///
  /// Returns:
  /// - Right(Box): Box details found
  /// - Left(ValidationFailure): [params.boxId] is empty
  /// - Left(ServerFailure.notFound): Box does not exist
  /// - Left(NetworkFailure): No internet and no cached data
  /// - Left(CacheFailure): Error reading from local storage
  Future<Either<Failure, Box>> call(GetBoxDetailsParams params) async {
    if (params.boxId.trim().isEmpty) {
      return const Left(ValidationFailure.required('Box ID'));
    }

    return _repository.getBoxDetails(params.boxId);
  }
}
