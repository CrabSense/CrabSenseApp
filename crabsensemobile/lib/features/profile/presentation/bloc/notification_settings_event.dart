import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_preferences.dart';

/// Base class for all notification settings events.
///
/// Requirements: 14.9-14.10
abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers an initial load of the stored notification preferences.
///
/// Dispatched once when [NotificationSettingsWidget] first mounts.
///
/// Requirements: 14.9
class NotificationSettingsLoadRequested extends NotificationSettingsEvent {
  const NotificationSettingsLoadRequested();
}

/// Applies a single preference update and persists the result.
///
/// The caller provides an [updater] function that receives the current
/// [NotificationPreferences] and returns a modified copy via `copyWith`.
/// This keeps each toggle self-contained without a separate event class
/// per field.
///
/// Example:
/// ```dart
/// context.read<NotificationSettingsBloc>().add(
///   NotificationSettingToggled(
///     (prefs) => prefs.copyWith(soundEnabled: !prefs.soundEnabled),
///   ),
/// );
/// ```
///
/// Requirements: 14.9
class NotificationSettingToggled extends NotificationSettingsEvent {
  const NotificationSettingToggled(this.updater);

  /// Pure function: current preferences → updated preferences.
  final NotificationPreferences Function(NotificationPreferences) updater;

  // Functions are not equatable, so props stays empty.
  // Equatable identity is intentionally not used for toggle events.
  @override
  List<Object?> get props => [];
}
