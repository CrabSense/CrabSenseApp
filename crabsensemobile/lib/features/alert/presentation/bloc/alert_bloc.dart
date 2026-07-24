import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/usecases/acknowledge_alert_usecase.dart';
import '../../domain/usecases/dismiss_alert_usecase.dart';
import '../../domain/usecases/get_alerts_usecase.dart';
import 'alert_event.dart';
import 'alert_state.dart';

/// BLoC for the alert management feature.
///
/// Handles [AlertEvent]s and emits [AlertState]s for the alert screen.
///
/// Event → State transitions:
/// - [AlertLoadRequested]        → [AlertLoading] → [AlertLoaded]/[AlertError]
/// - [AlertRefreshRequested]     → [AlertLoaded](isRefreshing:true)
///                                 → [AlertLoaded] / [AlertError]
/// - [AlertFiltersChanged]       → re-fetch with new filters
/// - [AlertAcknowledgeRequested] → [AlertActionInProgress]
///                                 → [AlertLoaded] (updated list)
/// - [AlertDismissRequested]     → [AlertActionInProgress]
///                                 → [AlertLoaded] (updated list)
/// - [AlertUnreadCountUpdated]   → [AlertLoaded](unreadCount updated)
///
/// Requirements: 9.2, 9.4, 9.6, 9.7, 9.8, 9.9, 9.10
class AlertBloc extends Bloc<AlertEvent, AlertState> {
  AlertBloc({
    required this._getAlerts,
    required this._acknowledgeAlert,
    required this._dismissAlert,
    required AlertRepository repository,
  }) : _repository = repository,
       super(const AlertInitial()) {
    on<AlertLoadRequested>(_onLoadRequested);
    on<AlertRefreshRequested>(_onRefreshRequested);
    on<AlertFiltersChanged>(_onFiltersChanged);
    on<AlertAcknowledgeRequested>(_onAcknowledgeRequested);
    on<AlertDismissRequested>(_onDismissRequested);
    on<AlertUnreadCountUpdated>(_onUnreadCountUpdated);

    // Subscribe to the unread-count stream. The listener dispatches
    // [AlertUnreadCountUpdated] as a proper event so state is updated
    // through the normal event handler path (Req 9.2).
    _unreadCountSubscription = repository.watchUnreadCount().listen(
      (count) => add(AlertUnreadCountUpdated(count)),
    );
  }

  final GetAlertsUseCase _getAlerts;
  final AcknowledgeAlertUseCase _acknowledgeAlert;
  final DismissAlertUseCase _dismissAlert;
  final AlertRepository _repository;
  late final StreamSubscription<int> _unreadCountSubscription;

  // Tracks the currently active filters between events.
  AlertActiveFilters _activeFilters = const AlertActiveFilters();

  @override
  Future<void> close() {
    _unreadCountSubscription.cancel();
    return super.close();
  }

  // ── AlertLoadRequested ───────────────────────────────────────────────────

  /// Handles initial load.
  ///
  /// Emits [AlertLoading] first (skeleton UI), calls the use case, then
  /// emits [AlertLoaded] or [AlertError].
  ///
  /// Requirements: 9.4, 9.9, 9.10
  Future<void> _onLoadRequested(
    AlertLoadRequested event,
    Emitter<AlertState> emit,
  ) async {
    emit(const AlertLoading());
    await _fetchAndEmit(emit, filters: _activeFilters);
  }

  // ── AlertRefreshRequested ────────────────────────────────────────────────

  /// Handles pull-to-refresh.
  ///
  /// Marks the current [AlertLoaded] state as refreshing so the UI keeps
  /// showing previous data while the indicator spins.
  ///
  /// Requirements: 9.4, 9.10
  Future<void> _onRefreshRequested(
    AlertRefreshRequested event,
    Emitter<AlertState> emit,
  ) async {
    if (state is AlertLoaded) {
      emit((state as AlertLoaded).copyWith(isRefreshing: true));
    }
    await _fetchAndEmit(emit, filters: _activeFilters);
  }

  // ── AlertFiltersChanged ──────────────────────────────────────────────────

  /// Handles filter changes and re-fetches with new parameters.
  ///
  /// Requirements: 9.8
  Future<void> _onFiltersChanged(
    AlertFiltersChanged event,
    Emitter<AlertState> emit,
  ) async {
    _activeFilters = AlertActiveFilters(
      severity: event.severity,
      type: event.type,
      status: event.status,
    );

    // Keep current data visible if already loaded.
    if (state is! AlertLoaded) {
      emit(const AlertLoading());
    }

    await _fetchAndEmit(emit, filters: _activeFilters);
  }

  // ── AlertAcknowledgeRequested ────────────────────────────────────────────

  /// Handles acknowledge action.
  ///
  /// Emits [AlertActionInProgress] while the request is in flight, then
  /// reloads the full list (Req 9.7).
  ///
  /// Requirements: 9.6, 9.7, 9.10
  Future<void> _onAcknowledgeRequested(
    AlertAcknowledgeRequested event,
    Emitter<AlertState> emit,
  ) async {
    final current = _asLoaded;
    if (current != null) {
      emit(
        AlertActionInProgress(
          alerts: current.alerts,
          unreadCount: current.unreadCount,
          activeFilters: current.activeFilters,
          processingAlertId: event.alertId,
        ),
      );
    }

    final result = await _acknowledgeAlert(
      AcknowledgeAlertParams(
        alertId: event.alertId,
        acknowledgedBy: event.acknowledgedBy,
      ),
    );

    await result.fold(
      (failure) async => emit(
        AlertError(
          message: failure.message,
          isOffline: failure is NetworkFailure,
        ),
      ),
      (_) async => _fetchAndEmit(emit, filters: _activeFilters),
    );
  }

  // ── AlertDismissRequested ────────────────────────────────────────────────

  /// Handles dismiss action.
  ///
  /// Requirements: 9.6, 9.10
  Future<void> _onDismissRequested(
    AlertDismissRequested event,
    Emitter<AlertState> emit,
  ) async {
    final current = _asLoaded;
    if (current != null) {
      emit(
        AlertActionInProgress(
          alerts: current.alerts,
          unreadCount: current.unreadCount,
          activeFilters: current.activeFilters,
          processingAlertId: event.alertId,
        ),
      );
    }

    final result = await _dismissAlert(
      DismissAlertParams(alertId: event.alertId),
    );

    await result.fold(
      (failure) async => emit(
        AlertError(
          message: failure.message,
          isOffline: failure is NetworkFailure,
        ),
      ),
      (_) async => _fetchAndEmit(emit, filters: _activeFilters),
    );
  }

  // ── AlertUnreadCountUpdated ──────────────────────────────────────────────

  /// Updates the unread badge count in the current [AlertLoaded] state.
  ///
  /// Fired automatically by the live stream from the local database.
  /// Does nothing if the current state is not [AlertLoaded] (e.g., loading).
  ///
  /// Requirements: 9.2
  Future<void> _onUnreadCountUpdated(
    AlertUnreadCountUpdated event,
    Emitter<AlertState> emit,
  ) async {
    if (state is AlertLoaded) {
      emit((state as AlertLoaded).copyWith(unreadCount: event.count));
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Fetches the alert list and emits [AlertLoaded] or [AlertError].
  ///
  /// Also independently fetches the unread count so the badge reflects
  /// the true total regardless of which filters are active.
  Future<void> _fetchAndEmit(
    Emitter<AlertState> emit, {
    required AlertActiveFilters filters,
  }) async {
    final alertsResult = await _getAlerts(
      GetAlertsParams(
        severity: filters.severity,
        type: filters.type,
        status: filters.status,
      ),
    );

    // Fetch unread count independently so the badge always shows the
    // true total (not just the count within the current filter set).
    final unreadResult = await _repository.getUnreadCount();
    final unreadCount = unreadResult.fold((_) => 0, (n) => n);

    alertsResult.fold(
      (failure) => emit(
        AlertError(
          message: failure.message,
          isOffline: failure is NetworkFailure,
        ),
      ),
      (alerts) {
        // Infer offline when both network+unread have a NetworkFailure.
        final isOffline =
            unreadResult.isLeft() &&
            unreadResult.fold((f) => f is NetworkFailure, (_) => false);

        emit(
          AlertLoaded(
            alerts: alerts,
            unreadCount: unreadCount,
            activeFilters: filters,
            isOffline: isOffline,
          ),
        );
      },
    );
  }

  /// Returns the current state cast to [AlertLoaded], or null.
  AlertLoaded? get _asLoaded =>
      state is AlertLoaded ? state as AlertLoaded : null;
}
