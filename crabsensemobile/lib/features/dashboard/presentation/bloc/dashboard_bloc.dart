import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// BLoC for the dashboard feature.
///
/// Handles [DashboardEvent]s and emits [DashboardState]s for the
/// dashboard screen to render.
///
/// Event → State transitions:
/// - [DashboardLoadRequested] → [DashboardLoading] → [DashboardLoaded]
///   or [DashboardError]
/// - [DashboardRefreshRequested] → keeps current [DashboardLoaded] with
///   isRefreshing:true → [DashboardLoaded] (fresh) or [DashboardError]
///
/// Requirements: 2.1, 2.6, 2.7, 2.9, 2.10
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required this._getDashboardSummary}) : super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  final GetDashboardSummaryUseCase _getDashboardSummary;

  // ── DashboardLoadRequested ───────────────────────────────────────────────

  /// Handles initial load.
  ///
  /// Emits [DashboardLoading] first so the UI shows skeleton placeholders
  /// (Requirement 2.10), then calls the use case and emits either
  /// [DashboardLoaded] or [DashboardError].
  ///
  /// Requirements: 2.1, 2.6, 2.9, 2.10
  Future<void> _onLoadRequested(DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());

    final result = await _getDashboardSummary();

    result.fold(
      (failure) =>
          emit(DashboardError(message: failure.message, isOffline: failure is NetworkFailure)),
      (summary) => emit(DashboardLoaded(summary: summary)),
    );
  }

  // ── DashboardRefreshRequested ────────────────────────────────────────────

  /// Handles pull-to-refresh.
  ///
  /// Marks the current [DashboardLoaded] state as refreshing so the UI
  /// can show a refresh indicator while keeping the previous data visible,
  /// then forces a fresh API call. Emits [DashboardLoaded] on success or
  /// [DashboardError] on failure.
  ///
  /// If the current state is not [DashboardLoaded] (e.g., still loading),
  /// the refresh is treated the same as an initial load.
  ///
  /// Requirements: 2.7
  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep previous data visible while refreshing.
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(isRefreshing: true));
    }

    final result = await _getDashboardSummary(forceRefresh: true);

    result.fold(
      (failure) =>
          emit(DashboardError(message: failure.message, isOffline: failure is NetworkFailure)),
      (summary) => emit(DashboardLoaded(summary: summary)),
    );
  }
}
