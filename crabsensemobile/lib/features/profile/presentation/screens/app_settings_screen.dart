import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../data/models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_hub_scaffold.dart';

/// Cài đặt ứng dụng — prefs local + route thông báo.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(profileStateProvider).valueOrNull;
    final s = data?.settings ?? SettingsSummary.sample;

    void toast(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    Future<void> pickLanguage() async {
      final next = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: kHomeSurface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tiếng Việt', style: TextStyle(color: kHomeTextMain)),
                onTap: () => Navigator.pop(ctx, 'Tiếng Việt'),
              ),
              ListTile(
                title: const Text('English', style: TextStyle(color: kHomeTextMain)),
                onTap: () => Navigator.pop(ctx, 'English'),
              ),
            ],
          ),
        ),
      );
      if (next != null) {
        ref.read(profileStateProvider.notifier).updateSettings(
              s.copyWith(language: next),
            );
        toast('Ngôn ngữ: $next');
      }
    }

    Future<void> pickUnits() async {
      final next = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: kHomeSurface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('°C, mg/L, ppt, pH',
                    style: TextStyle(color: kHomeTextMain)),
                onTap: () => Navigator.pop(ctx, '°C, mg/L, ppt, pH'),
              ),
              ListTile(
                title: const Text('°F, ppm, ppt, pH',
                    style: TextStyle(color: kHomeTextMain)),
                onTap: () => Navigator.pop(ctx, '°F, ppm, ppt, pH'),
              ),
            ],
          ),
        ),
      );
      if (next != null) {
        ref.read(profileStateProvider.notifier).updateSettings(
              s.copyWith(measurementUnit: next),
            );
        toast('Đơn vị đo: $next');
      }
    }

    Future<void> pickCamera() async {
      final next = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: kHomeSurface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in ['HD 720p', 'HD 1080p', '2K'])
                ListTile(
                  title: Text(r, style: const TextStyle(color: kHomeTextMain)),
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      );
      if (next != null) {
        ref.read(profileStateProvider.notifier).updateSettings(
              s.copyWith(cameraResolution: next),
            );
        toast('Camera AI: $next');
      }
    }

    Future<void> pickRefresh() async {
      final next = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: kHomeSurface,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final sec in [15, 30, 60, 120])
                ListTile(
                  title: Text('$sec giây',
                      style: const TextStyle(color: kHomeTextMain)),
                  onTap: () => Navigator.pop(ctx, sec),
                ),
            ],
          ),
        ),
      );
      if (next != null) {
        ref.read(profileStateProvider.notifier).updateSettings(
              s.copyWith(refreshRateSeconds: next),
            );
        toast('Làm mới mỗi $next giây');
      }
    }

    return ProfileHubScaffold(
      title: 'CÀI ĐẶT ỨNG DỤNG',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HubCard(
            child: Column(
              children: [
                HubTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Giao diện',
                  value: s.isDarkMode ? 'Tối (Dark Mode)' : 'Sáng',
                  trailing: Switch(
                    value: s.isDarkMode,
                    activeColor: kHomeCyan,
                    onChanged: (v) {
                      ref.read(profileStateProvider.notifier).updateSettings(
                            s.copyWith(isDarkMode: v),
                          );
                      toast(v ? 'Đã bật Dark Mode' : 'Đã tắt Dark Mode');
                    },
                  ),
                  showDivider: true,
                ),
                HubTile(
                  icon: Icons.language_rounded,
                  title: 'Ngôn ngữ',
                  value: s.language,
                  onTap: pickLanguage,
                ),
                HubTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Cài đặt thông báo',
                  subtitle: 'Cảnh báo, nhắc việc, âm thanh',
                  onTap: () => context.push(RoutePaths.notificationSettings),
                ),
                HubTile(
                  icon: Icons.straighten_rounded,
                  title: 'Đơn vị đo lường',
                  value: s.measurementUnit,
                  onTap: pickUnits,
                ),
                HubTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Cấu hình Camera AI',
                  value: s.cameraResolution,
                  onTap: pickCamera,
                ),
                HubTile(
                  icon: Icons.storage_rounded,
                  title: 'Bộ nhớ đệm',
                  value: s.cacheSize,
                  onTap: () {
                    ref.read(profileStateProvider.notifier).updateSettings(
                          s.copyWith(cacheSize: '0 MB'),
                        );
                    toast('Đã xóa bộ nhớ đệm (mô phỏng)');
                  },
                ),
                HubTile(
                  icon: Icons.autorenew_rounded,
                  title: 'Tự động đồng bộ',
                  trailing: Switch(
                    value: s.autoSync,
                    activeColor: kHomeCyan,
                    onChanged: (v) {
                      ref.read(profileStateProvider.notifier).updateSettings(
                            s.copyWith(autoSync: v),
                          );
                      toast(v ? 'Bật tự động đồng bộ' : 'Tắt tự động đồng bộ');
                    },
                  ),
                ),
                HubTile(
                  icon: Icons.timer_outlined,
                  title: 'Tần suất làm mới dữ liệu',
                  value: '${s.refreshRateSeconds} giây',
                  onTap: pickRefresh,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
