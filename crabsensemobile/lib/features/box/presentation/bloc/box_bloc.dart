import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_box_details_usecase.dart';
import 'box_event.dart';
import 'box_state.dart';

/// BLoC for the box details feature.
///
/// Handles [BoxEvent]s and emits [BoxState]s for the box details screen.
///
/// Event → State transitions:
/// - [BoxDetailsLoadRequested]   → [BoxLoading] → [BoxLoaded] or [BoxError]
/// - [BoxDetailsRefreshRequested] → keeps current [BoxLoaded] with
///   isRefreshing:true → [BoxLoaded] (fresh) or [BoxError]
///
/// Requirements: 4.1, 4.7, 4.10
class BoxBloc extends Bloc<BoxEvent, BoxState> {
  BoxBloc({required this._getBoxDetails}) : super(const BoxInitial()) {
    on<BoxDetailsLoadRequested>(_onLoadRequested);
    on<BoxDetailsRefreshRequested>(_onRefreshRequested);
  }

  final GetBoxDetailsUseCase _getBoxDetails;

  // ── BoxDetailsLoadRequested ──────────────────────────────────────────────

  /// Handles initial load.
  ///
  /// Emits [BoxLoading] first so the UI shows skeleton placeholders
  /// (Requirement 4.10), then calls the use case and emits either
  /// [BoxLoaded] or [BoxError].
  ///
  /// Requirements: 4.1, 4.7, 4.10
  Future<void> _onLoadRequested(BoxDetailsLoadRequested event, Emitter<BoxState> emit) async {
    emit(const BoxLoading());

    final result = await _getBoxDetails(GetBoxDetailsParams(boxId: event.boxId));

    result.fold(
      (failure) => emit(BoxError(message: failure.message, isOffline: failure is NetworkFailure)),
      (box) => emit(BoxLoaded(box: box)),
    );
  }

  // ── BoxDetailsRefreshRequested ───────────────────────────────────────────

  /// Handles pull-to-refresh.
  ///
  /// Marks the current [BoxLoaded] state as refreshing so the UI keeps
  /// showing the previous data while fetching fresh data.
  ///
  /// If the current state is not [BoxLoaded] (e.g., still loading),
  /// the refresh is treated the same as an initial load.
  ///
  /// Requirements: 4.7
  Future<void> _onRefreshRequested(BoxDetailsRefreshRequested event, Emitter<BoxState> emit) async {
    // Keep previous data visible while refreshing.
    if (state is BoxLoaded) {
      emit((state as BoxLoaded).copyWith(isRefreshing: true));
    }

    final result = await _getBoxDetails(GetBoxDetailsParams(boxId: event.boxId));

    result.fold(
      (failure) => emit(BoxError(message: failure.message, isOffline: failure is NetworkFailure)),
      (box) => emit(BoxLoaded(box: box)),
    );
  }
}
