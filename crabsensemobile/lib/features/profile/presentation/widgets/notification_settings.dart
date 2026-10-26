import 'package:crabsensemobile/core/platform/io_export.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../../../shared/widgets/errors/error_state_widget.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../bloc/notification_settings_bloc.dart';
import '../bloc/notification_settings_event.dart';
import '../bloc/notification_settings_state.dart';

/// Cài đặt thông báo cá nhân (Hive + API).
class NotificationSettingsWidget extends StatelessWidget {
  const NotificationSettingsWidget({required this.repository, super.key});

  final NotificationPreferencesRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider<NotificationSettingsBloc>(
        create: (_) => NotificationSettingsBloc(repository: repository)
          ..add(const NotificationSettingsLoadRequested()),
        child: const _NotificationSettingsView(),
      );
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
        builder: (context, state) {
          if (state is NotificationSettingsLoading ||
              state is NotificationSettingsInitial) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: kHomePrimary),
              ),
            );
          }

          if (state is NotificationSettingsError) {
            return ErrorStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'Không tải được cài đặt',
              message: state.message,
              onRetry: () => context.read<NotificationSettingsBloc>().add(
                    const NotificationSettingsLoadRequested(),
                  ),
            );
          }

          if (state is NotificationSettingsLoaded) {
            return _SettingsBody(state: state);
          }

          return const Center(
            child: CircularProgressIndicator(color: kHomePrimary),
          );
        },
      );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.state});

  final NotificationSettingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final prefs = state.preferences;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _SectionHeader(
          title: 'Loại thông báo',
          subtitle: 'Chọn loại cảnh báo bạn muốn nhận',
          isSaving: state.isSaving,
        ),
        const _CategoryTile(
          title: 'Cảnh báo nghiêm trọng',
          subtitle:
              'Khẩn cấp chất lượng nước / thiết bị. Không thể tắt.',
          icon: Icons.warning_amber_rounded,
          iconColor: kHomeDanger,
          value: true,
          enabled: false,
          onChanged: null,
        ),
        _CategoryTile(
          title: 'Cảnh báo thường',
          subtitle: 'Thông số gần ngưỡng, bảo trì đến hạn',
          icon: Icons.info_outline_rounded,
          iconColor: kHomeWarning,
          value: prefs.warningsEnabled,
          enabled: true,
          onChanged: (value) =>
              _toggle(context, (p) => p.copyWith(warningsEnabled: value)),
        ),
        _CategoryTile(
          title: 'Nhắc việc',
          subtitle: 'Lịch giám sát và kiểm tra',
          icon: Icons.task_alt_rounded,
          iconColor: kHomePrimaryDark,
          value: prefs.taskRemindersEnabled,
          enabled: true,
          onChanged: (value) =>
              _toggle(context, (p) => p.copyWith(taskRemindersEnabled: value)),
        ),
        _CategoryTile(
          title: 'Cập nhật hệ thống',
          subtitle: 'Thông báo nền tảng và firmware',
          icon: Icons.system_update_alt_rounded,
          iconColor: kHomeSecondary,
          value: prefs.systemUpdatesEnabled,
          enabled: true,
          onChanged: (value) =>
              _toggle(context, (p) => p.copyWith(systemUpdatesEnabled: value)),
        ),
        const Divider(
          height: 24,
          indent: 16,
          endIndent: 16,
          color: kHomeBorder,
        ),
        const _SectionHeader(
          title: 'Hiển thị',
          subtitle: 'Tùy chỉnh cách thông báo xuất hiện',
        ),
        _DisplayOptionTile(
          title: 'Âm thanh',
          subtitle: 'Phát âm khi có thông báo',
          icon: Icons.volume_up_rounded,
          value: prefs.soundEnabled,
          onChanged: (value) =>
              _toggle(context, (p) => p.copyWith(soundEnabled: value)),
        ),
        _DisplayOptionTile(
          title: 'Rung',
          subtitle: 'Rung khi có thông báo',
          icon: Icons.vibration_rounded,
          value: prefs.vibrationEnabled,
          onChanged: (value) =>
              _toggle(context, (p) => p.copyWith(vibrationEnabled: value)),
        ),
        _DisplayOptionTile(
          title: 'Đèn LED',
          subtitle: Platform.isAndroid
              ? 'Nhấp nháy LED khi có thông báo mới'
              : 'Chỉ hỗ trợ trên Android',
          icon: Icons.lightbulb_outline_rounded,
          value: prefs.ledIndicatorEnabled,
          enabled: Platform.isAndroid,
          onChanged: Platform.isAndroid
              ? (value) =>
                  _toggle(context, (p) => p.copyWith(ledIndicatorEnabled: value))
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
    context
        .read<NotificationSettingsBloc>()
        .add(NotificationSettingToggled(updater));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.isSaving = false,
  });

  final String title;
  final String subtitle;
  final bool isSaving;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: kHomeTextHint,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kHomeTextSub,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSaving) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kHomePrimary,
                ),
              ),
            ],
          ],
        ),
      );
}

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
    final effectiveColor = enabled ? iconColor : kHomeTextHint;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Icon(icon, color: effectiveColor, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? kHomeTextMain : kHomeTextHint,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: kHomeTextSub,
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: kHomePrimaryDark,
      activeTrackColor: kHomePrimary,
    );
  }
}

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
    final effectiveIconColor = enabled ? kHomePrimaryDark : kHomeTextHint;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Icon(icon, color: effectiveIconColor, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? kHomeTextMain : kHomeTextHint,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: kHomeTextSub,
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: kHomePrimaryDark,
      activeTrackColor: kHomePrimary,
    );
  }
}
