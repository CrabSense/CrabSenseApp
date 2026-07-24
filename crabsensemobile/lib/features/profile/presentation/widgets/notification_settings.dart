import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/errors/error_state_widget.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../bloc/notification_settings_bloc.dart';
import '../bloc/notification_settings_event.dart';
import '../bloc/notification_settings_state.dart';

/// Notification settings widget.
///
/// Allows the user to enable/disable notifications by category and
/// configure display options (sound, vibration, LED indicator).
///
/// Usage — provide a [NotificationPreferencesRepository] and the widget
/// creates its own [NotificationSettingsBloc] internally:
///
/// ```dart
/// NotificationSettingsWidget(repository: sl())
/// ```
///
/// Requirements: 14.9-14.10
class NotificationSettingsWidget extends StatelessWidget {
  const NotificationSettingsWidget({required this.repository, super.key});

  /// Repository injected from outside; no get_it calls in the widget.
  final NotificationPreferencesRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider<NotificationSettingsBloc>(
    create: (_) =>
        NotificationSettingsBloc(repository: repository)
          ..add(const NotificationSettingsLoadRequested()),
    child: const _NotificationSettingsView(),
  );
}

// ── Internal view ─────────────────────────────────────────────────────────────

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
        builder: (context, state) {
          if (state is NotificationSettingsLoading || state is NotificationSettingsInitial) {
            return const _LoadingBody();
          }

          if (state is NotificationSettingsError) {
            return ErrorStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'Could not load settings',
              message: state.message,
              onRetry: () => context.read<NotificationSettingsBloc>().add(
                const NotificationSettingsLoadRequested(),
              ),
            );
          }

          if (state is NotificationSettingsLoaded) {
            return _SettingsBody(state: state);
          }

          return const _LoadingBody();
        },
      );
}

// ── Loading body ──────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: CrabSenseColors.primary));
}

// ── Settings body ─────────────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.state});

  final NotificationSettingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final prefs = state.preferences;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── Categories section ──────────────────────────────────────
        _SectionHeader(
          title: 'Notification Categories',
          subtitle: 'Choose which alerts you receive',
          isSaving: state.isSaving,
        ),

        // Critical Alerts — always on, toggle is locked
        const _CategoryTile(
          title: 'Critical Alerts',
          subtitle:
              'Water quality emergencies and equipment failures. '
              'Cannot be disabled.',
          icon: Icons.warning_amber_rounded,
          iconColor: CrabSenseColors.error,
          value: true,
          enabled: false,
          onChanged: null,
        ),

        _CategoryTile(
          title: 'Warnings',
          subtitle: 'Parameters approaching thresholds, maintenance due',
          icon: Icons.info_outline_rounded,
          iconColor: CrabSenseColors.warning,
          value: prefs.warningsEnabled,
          enabled: true,
          onChanged: (value) => _toggle(context, (p) => p.copyWith(warningsEnabled: value)),
        ),

        _CategoryTile(
          title: 'Task Reminders',
          subtitle: 'Scheduled monitoring and inspection reminders',
          icon: Icons.task_alt_rounded,
          iconColor: CrabSenseColors.primary,
          value: prefs.taskRemindersEnabled,
          enabled: true,
          onChanged: (value) => _toggle(context, (p) => p.copyWith(taskRemindersEnabled: value)),
        ),

        _CategoryTile(
          title: 'System Updates',
          subtitle: 'Platform and firmware update notifications',
          icon: Icons.system_update_alt_rounded,
          iconColor: CrabSenseColors.textSecondary,
          value: prefs.systemUpdatesEnabled,
          enabled: true,
          onChanged: (value) => _toggle(context, (p) => p.copyWith(systemUpdatesEnabled: value)),
        ),

        const Divider(height: 32, indent: 16, endIndent: 16),

        // ── Display options section ─────────────────────────────────
        const _SectionHeader(
          title: 'Display Options',
          subtitle: 'Customise how notifications appear',
        ),

        _DisplayOptionTile(
          title: 'Sound',
          subtitle: 'Play a sound when a notification arrives',
          icon: Icons.volume_up_rounded,
          value: prefs.soundEnabled,
          onChanged: (value) => _toggle(context, (p) => p.copyWith(soundEnabled: value)),
        ),

        _DisplayOptionTile(
          title: 'Vibration',
          subtitle: 'Vibrate when a notification arrives',
          icon: Icons.vibration_rounded,
          value: prefs.vibrationEnabled,
          onChanged: (value) => _toggle(context, (p) => p.copyWith(vibrationEnabled: value)),
        ),

        _DisplayOptionTile(
          title: 'LED Indicator',
          subtitle: Platform.isAndroid
              ? 'Blink the device LED for new notifications'
              : 'LED indicator (Android only)',
          icon: Icons.lightbulb_outline_rounded,
          value: prefs.ledIndicatorEnabled,
          // On iOS the toggle is shown but greyed out — the preference is
          // stored so it takes effect if the user later uses an Android
          // device with the same account.
          enabled: Platform.isAndroid,
          onChanged: Platform.isAndroid
              ? (value) => _toggle(context, (p) => p.copyWith(ledIndicatorEnabled: value))
              : null,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  void _toggle(
    BuildContext context,
    NotificationPreferences Function(NotificationPreferences) updater,
  ) {
    context.read<NotificationSettingsBloc>().add(NotificationSettingToggled(updater));
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, this.isSaving = false});

  final String title;
  final String subtitle;
  final bool isSaving;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: CrabSenseColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
              ),
            ],
          ),
        ),
        if (isSaving) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: CrabSenseColors.primary),
          ),
        ],
      ],
    ),
  );
}

// ── Category tile ─────────────────────────────────────────────────────────────

/// A [SwitchListTile] representing a per-category notification toggle.
///
/// When [enabled] is false the tile is greyed out and the switch cannot
/// be interacted with (used for Critical Alerts).
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? iconColor : CrabSenseColors.textDisabled;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Icon(icon, color: effectiveColor, size: 24),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: enabled ? CrabSenseColors.textPrimary : CrabSenseColors.textDisabled,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: CrabSenseColors.textSecondary),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeTrackColor: CrabSenseColors.primary,
    );
  }
}

// ── Display-option tile ───────────────────────────────────────────────────────

/// A [SwitchListTile] for a display option (sound, vibration, LED).
class _DisplayOptionTile extends StatelessWidget {
  const _DisplayOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = enabled ? CrabSenseColors.primary : CrabSenseColors.textDisabled;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Icon(icon, color: effectiveIconColor, size: 24),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: enabled ? CrabSenseColors.textPrimary : CrabSenseColors.textDisabled,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: enabled ? CrabSenseColors.textSecondary : CrabSenseColors.textDisabled,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeTrackColor: CrabSenseColors.primary,
    );
  }
}
