import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/notification_preferences_repository.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

/// BLoC for the notification settings widget.
///
/// Event → State transitions:
/// - [NotificationSettingsLoadRequested]
///     → [NotificationSettingsLoading]
///     → [NotificationSettingsLoaded] / [NotificationSettingsError]
/// - [NotificationSettingToggled]
///     → [NotificationSettingsLoaded](isSaving: true)
///     → [NotificationSettingsLoaded](isSaving: false) / error
///
/// Requirements: 14.9-14.10
class NotificationSettingsBloc extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  NotificationSettingsBloc({required this._repository})
    : super(const NotificationSettingsInitial()) {
    on<NotificationSettingsLoadRequested>(_onLoadRequested);
    on<NotificationSettingToggled>(_onToggled);
  }

  final NotificationPreferencesRepository _repository;

  // ── NotificationSettingsLoadRequested ────────────────────────────────────

  /// Loads preferences from local storage and emits [NotificationSettingsLoaded].
  ///
  /// Requirements: 14.9
  Future<void> _onLoadRequested(
    NotificationSettingsLoadRequested event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(const NotificationSettingsLoading());
    try {
      final prefs = await _repository.getPreferences();
      emit(NotificationSettingsLoaded(preferences: prefs));
    } on Exception catch (e) {
      emit(NotificationSettingsError(message: 'Could not load notification settings: $e'));
    }
  }

  // ── NotificationSettingToggled ───────────────────────────────────────────

  /// Applies the updater, persists the result, and emits new state.
  ///
  /// While saving, isSaving is true so the UI can show a subtle
  /// indicator without blocking further interaction.
  ///
  /// Requirements: 14.9
  Future<void> _onToggled(
    NotificationSettingToggled event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationSettingsLoaded) return;

    final updated = event.updater(current.preferences);

    // Optimistically apply the change so the toggle responds immediately.
    emit(current.copyWith(preferences: updated, isSaving: true));

    try {
      await _repository.savePreferences(updated);
      emit(current.copyWith(preferences: updated, isSaving: false));
    } on Exception catch (e) {
      // Revert to previous preferences on failure.
      emit(current.copyWith(isSaving: false));
      emit(NotificationSettingsError(message: 'Could not save notification settings: $e'));
    }
  }
}
