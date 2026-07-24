import 'package:equatable/equatable.dart';

import '../../domain/entities/box.dart';

/// Base class for all box states.
///
/// States represent the current condition of the box details feature.
/// All states use [Equatable] for value equality.
///
/// Requirements: 4.1-4.10
abstract class BoxState extends Equatable {
  const BoxState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been requested.
class BoxInitial extends BoxState {
  const BoxInitial();
}

/// State emitted while the initial box data is being loaded.
///
/// The UI should show skeleton / shimmer placeholders (Requirement 4.10).
class BoxLoading extends BoxState {
  const BoxLoading();
}

/// State emitted when box data has been successfully loaded.
///
/// When [isRefreshing] is true the UI keeps the previous data visible
/// while the pull-to-refresh indicator is shown.
///
/// Requirements: 4.1, 4.2, 4.7
class BoxLoaded extends BoxState {
  const BoxLoaded({required this.box, this.isRefreshing = false});

  /// The loaded box entity.
  final Box box;

  /// True while a background refresh is in flight.
  final bool isRefreshing;

  /// Returns a copy of this state with selected fields replaced.
  BoxLoaded copyWith({Box? box, bool? isRefreshing}) =>
      BoxLoaded(box: box ?? this.box, isRefreshing: isRefreshing ?? this.isRefreshing);

  @override
  List<Object?> get props => [box, isRefreshing];
}

/// State emitted when loading the box data fails.
///
/// - [message]: human-readable error description shown to the user.
/// - [isOffline]: true when the failure is due to no connectivity.
///
/// Requirements: 4.7, 4.10
class BoxError extends BoxState {
  const BoxError({required this.message, this.isOffline = false});

  /// User-facing error message.
  final String message;

  /// Whether the failure is a connectivity error.
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}
