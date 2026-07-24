/// Core error handling components for the CrabSense mobile application.
///
/// This library provides a comprehensive error handling framework following
/// Clean Architecture principles. It includes:
///
/// - **Failures**: Domain-level error objects representing business logic failures
/// - **Exceptions**: Data-level technical errors from external sources
/// - **Error Mapper**: Utilities for converting exceptions to failures
///
/// ## Usage
///
/// ### In Data Layer (Repositories)
///
/// ```dart
/// @override
/// Future<Either<Failure, Box>> getBox(String id) async {
///   try {
///     final boxDto = await remoteDataSource.getBox(id);
///     return Right(boxDto.toEntity());
///   } on ServerException catch (e) {
///     return Left(ErrorMapper.mapExceptionToFailure(e));
///   } on NetworkException catch (e) {
///     return Left(ErrorMapper.mapExceptionToFailure(e));
///   } catch (e, stackTrace) {
///     return Left(ErrorMapper.mapExceptionToFailure(e, stackTrace));
///   }
/// }
/// ```
///
/// ### In Domain Layer (Use Cases)
///
/// ```dart
/// @override
/// Future<Either<Failure, Box>> call(String id) async {
///   return await repository.getBox(id);
/// }
/// ```
///
/// ### In Presentation Layer (BLoC)
///
/// ```dart
/// final result = await getBoxUseCase(event.boxId);
/// result.fold(
///   (failure) => emit(BoxError(ErrorMapper.getFailureMessage(failure))),
///   (box) => emit(BoxLoaded(box)),
/// );
/// ```
///
library;

export 'error_mapper.dart';
export 'exceptions.dart';
export 'failures.dart';
