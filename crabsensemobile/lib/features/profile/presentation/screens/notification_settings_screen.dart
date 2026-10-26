import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../widgets/notification_settings.dart';
import '../widgets/profile_hub_scaffold.dart';

/// Cài đặt thông báo cá nhân — sync Hive + PUT /auth/me/notification-preferences.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileHubScaffold(
      title: 'Cài đặt thông báo',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: HubCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: NotificationSettingsWidget(
            repository: sl<NotificationPreferencesRepository>(),
          ),
        ),
      ),
    );
  }
}
