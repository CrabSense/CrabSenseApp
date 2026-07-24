import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_history_item.dart';
import '../../domain/repositories/notification_history_repository.dart';
import '../../domain/usecases/clear_notification_history_usecase.dart';
import '../../domain/usecases/get_notification_history_usecase.dart';
import 'notification_history_event.dart';
import 'notification_history_state.dart';

/// BLoC for the notification history feature.
///
/// Event → State transitions:
/// - [NotificationHistoryLoadRequested] → [NotificationHistoryLoading]
///   → [NotificationHistoryLoaded] / [NotificationHistoryError]
/// - [NotificationHistoryItemAdded]    → optimistic prepend to list,
///   then persists via repository
/// - [NotificationHistoryClearRequested] → clears store, emits empty list
///
/// Requirements: 14.6
class NotificationHistoryBloc extends Bloc<NotificationHistoryEvent, NotificationHistoryState> {
  NotificationHistoryBloc({
    required this._getHistory,
    required this._clearHistory,
    required this._repository,
  }) : super(const NotificationHistoryInitial()) {
    on<NotificationHistoryLoadRequested>(_onLoadRequested);
    on<NotificationHistoryItemAdded>(_onItemAdded);
    on<NotificationHistoryClearRequested>(_onClearRequested);
  }

  final GetNotificationHistoryUseCase _getHistory;
  final ClearNotificationHistoryUseCase _clearHistory;
  final NotificationHistoryRepository _repository;

  // ── Handlers ───────────────────────────────────────────────────────────────

  /// Loads notification history from local storage.
  Future<void> _onLoadRequested(
    NotificationHistoryLoadRequested event,
    Emitter<NotificationHistoryState> emit,
  ) async {
    emit(const NotificationHistoryLoading());
    await _fetchAndEmit(emit);
  }

  /// Adds a new item to history — optimistically updates the in-memory
  /// list for instant UI feedback, then persists to local storage.
  Future<void> _onItemAdded(
    NotificationHistoryItemAdded event,
    Emitter<NotificationHistoryState> emit,
  ) async {
    // Optimistically prepend the new item to the visible list.
    if (state is NotificationHistoryLoaded) {
      final current = state as NotificationHistoryLoaded;
      final updated = [event.item, ...current.items];
      emit(NotificationHistoryLoaded(items: updated));
    }

    // Persist to local storage.
    await _repository.addItem(event.item);
  }

  /// Clears all history items and emits an empty loaded state.
  Future<void> _onClearRequested(
    NotificationHistoryClearRequested event,
    Emitter<NotificationHistoryState> emit,
  ) async {
    final result = await _clearHistory();
    await result.fold(
      (failure) async => emit(NotificationHistoryError(message: failure.message)),
      (_) async => emit(const NotificationHistoryLoaded(items: [])),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Calls the use case and emits [NotificationHistoryLoaded] or
  /// [NotificationHistoryError].
  Future<void> _fetchAndEmit(Emitter<NotificationHistoryState> emit) async {
    final result = await _getHistory();
    result.fold(
      (failure) => emit(NotificationHistoryError(message: failure.message)),
      (items) => emit(NotificationHistoryLoaded(items: items)),
    );
  }

  // ── Public helper ─────────────────────────────────────────────────────────

  /// Convenience method called by the notification service to add a new
  /// item without requiring direct BLoC access from outside the feature.
  ///
  /// Usage:
  /// ```dart
  /// notificationHistoryBloc.onNotificationReceived(item);
  /// ```
  void onNotificationReceived(NotificationHistoryItem item) {
    add(NotificationHistoryItemAdded(item));
  }
}
