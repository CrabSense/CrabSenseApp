import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_preferences.dart';

/// Base class for all notification settings states.
///
/// Requirements: 14.9-14.10
abstract class NotificationSettingsState extends Equatable {
  const NotificationSettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been requested.
class NotificationSettingsInitial extends NotificationSettingsState {
  const NotificationSettingsInitial();
}

/// State emitted while preferences are being loaded or saved.
///
/// The UI shows a progress indicator and disables all toggles.
class NotificationSettingsLoading extends NotificationSettingsState {
  const NotificationSettingsLoading();
}

/// State emitted when preferences are available and ready to display.
///
/// - [preferences]: the current saved preferences.
/// - [isSaving]: true while a toggle write is in flight (show spinner
///   on the affected row without blocking the whole widget).
///
/// Requirements: 14.9
class NotificationSettingsLoaded extends NotificationSettingsState {
  const NotificationSettingsLoaded({required this.preferences, this.isSaving = false});

  /// Current notification preferences.
  final NotificationPreferences preferences;

  /// True while an updated value is being written to local storage.
  final bool isSaving;

  NotificationSettingsLoaded copyWith({NotificationPreferences? preferences, bool? isSaving}) =>
      NotificationSettingsLoaded(
        preferences: preferences ?? this.preferences,
        isSaving: isSaving ?? this.isSaving,
      );

  @override
  List<Object?> get props => [preferences, isSaving];
}

/// State emitted when loading or saving preferences fails.
///
/// - [message]: user-facing description of the error.
///
/// Requirements: 14.9
class NotificationSettingsError extends NotificationSettingsState {
  const NotificationSettingsError({required this.message});

  /// User-facing error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
