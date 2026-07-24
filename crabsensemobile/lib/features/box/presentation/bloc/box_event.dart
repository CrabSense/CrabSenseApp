import 'package:equatable/equatable.dart';

import '../../../../core/errors/example_usage.dart' show BoxBloc, BoxLoading, BoxLoaded, BoxError;

/// Base class for all box events.
///
/// Events trigger actions in [BoxBloc]. Each event represents an
/// action the user or system wants to perform on the box details screen.
///
/// Requirements: 4.1-4.10
abstract class BoxEvent extends Equatable {
  const BoxEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to load the details of a specific box.
///
/// Emits [BoxLoading] while fetching, then [BoxLoaded] or [BoxError].
///
/// Requirements: 4.1, 4.2, 4.7, 4.10
class BoxDetailsLoadRequested extends BoxEvent {
  const BoxDetailsLoadRequested(this.boxId);

  /// The unique identifier of the box to load.
  final String boxId;

  @override
  List<Object?> get props => [boxId];
}

/// Event triggered when the user performs pull-to-refresh.
///
/// Keeps the current [BoxLoaded] data visible while refreshing.
/// Emits [BoxLoaded] on success or [BoxError] on failure.
///
/// Requirements: 4.7
class BoxDetailsRefreshRequested extends BoxEvent {
  const BoxDetailsRefreshRequested(this.boxId);

  /// The unique identifier of the box to refresh.
  final String boxId;

  @override
  List<Object?> get props => [boxId];
}
