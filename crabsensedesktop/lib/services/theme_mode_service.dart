import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_typography.dart';
import '../theme/dashboard_theme.dart';

/// Cách chọn giao diện: tối, sáng, hoặc tự động theo giờ trong ngày.
enum AppAppearanceMode {
  dark,
  light,
  autoTime,
}

/// Giờ bắt đầu / kết thúc chế độ sáng (theo giờ máy local).
const _lightStartHour = 6;
const _lightEndHour = 18;

final appThemeMode = ThemeModeService();

class ThemeModeService extends ChangeNotifier {
  ThemeModeService() {
    DashboardColors.applyPalette(_paletteFor(_resolveBrightness()));
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_mode != AppAppearanceMode.autoTime) return;
      _syncAutoIfNeeded();
    });
  }

  AppAppearanceMode _mode = AppAppearanceMode.dark;
  Timer? _timer;
  Brightness? _lastApplied;

  AppAppearanceMode get mode => _mode;

  bool get isDark => _resolveBrightness() == Brightness.dark;

  String get modeLabel => switch (_mode) {
        AppAppearanceMode.dark => 'Chế độ tối',
        AppAppearanceMode.light => 'Chế độ sáng',
        AppAppearanceMode.autoTime => 'Tự động theo giờ',
      };

  Brightness _resolveBrightness() {
    return switch (_mode) {
      AppAppearanceMode.dark => Brightness.dark,
      AppAppearanceMode.light => Brightness.light,
      AppAppearanceMode.autoTime => _brightnessFromTime(DateTime.now()),
    };
  }

  static Brightness _brightnessFromTime(DateTime now) {
    final h = now.hour;
    if (h >= _lightStartHour && h < _lightEndHour) {
      return Brightness.light;
    }
    return Brightness.dark;
  }

  void setMode(AppAppearanceMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _applyBrightness(_resolveBrightness());
  }

  void _syncAutoIfNeeded() {
    final next = _resolveBrightness();
    if (next != _lastApplied) {
      _applyBrightness(next);
    }
  }

  void _applyBrightness(Brightness brightness) {
    _lastApplied = brightness;
    DashboardColors.applyPalette(_paletteFor(brightness));
    notifyListeners();
  }

  DashboardPalette _paletteFor(Brightness brightness) {
    return brightness == Brightness.light
        ? DashboardPalette.light()
        : DashboardPalette.dark();
  }

  ThemeData get materialTheme {
    final dark = isDark;
    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: DashboardColors.darkNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DashboardColors.purple,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      textTheme: dark ? AppTypography.darkTheme() : AppTypography.lightTheme(),
      useMaterial3: true,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
