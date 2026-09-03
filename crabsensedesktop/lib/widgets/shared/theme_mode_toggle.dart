import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/theme_mode_service.dart';
import '../../theme/dashboard_theme.dart';

/// Nút chọn chế độ sáng / tối / tự động trên header.
class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key, this.service});

  final ThemeModeService? service;

  ThemeModeService get _service => service ?? appThemeMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final icon = switch (_service.mode) {
          AppAppearanceMode.dark => Icons.dark_mode_outlined,
          AppAppearanceMode.light => Icons.light_mode_outlined,
          AppAppearanceMode.autoTime => Icons.brightness_auto_outlined,
        };

        return Tooltip(
          message: _service.modeLabel,
          child: PopupMenuButton<AppAppearanceMode>(
            tooltip: 'Giao diện',
            offset: const Offset(0, 40),
            color: DashboardColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: DashboardColors.cardBorder),
            ),
            onSelected: _service.setMode,
            itemBuilder: (context) => [
              _item(
                AppAppearanceMode.light,
                Icons.light_mode_outlined,
                'Sáng',
                '6:00 – 18:00 (khi Tự động)',
              ),
              _item(
                AppAppearanceMode.dark,
                Icons.dark_mode_outlined,
                'Tối',
                'Luôn dùng giao diện tối',
              ),
              _item(
                AppAppearanceMode.autoTime,
                Icons.brightness_auto_outlined,
                'Tự động',
                'Đổi theo giờ hệ thống',
              ),
            ],
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: DashboardColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DashboardColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: DashboardColors.cyan),
                  const SizedBox(width: 6),
                  Text(
                    _shortLabel(_service.mode),
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: DashboardColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _shortLabel(AppAppearanceMode mode) => switch (mode) {
        AppAppearanceMode.dark => 'Tối',
        AppAppearanceMode.light => 'Sáng',
        AppAppearanceMode.autoTime => 'Tự động',
      };

  PopupMenuEntry<AppAppearanceMode> _item(
    AppAppearanceMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _service.mode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? DashboardColors.cyan : DashboardColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: DashboardColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check, size: 18, color: DashboardColors.cyan),
        ],
      ),
    );
  }
}
