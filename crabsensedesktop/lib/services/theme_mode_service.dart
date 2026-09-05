import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_typography.dart';
import '../theme/dashboard_theme.dart';

final appThemeMode = ThemeModeService();

/// Giao diện cố định chế độ sáng.
class ThemeModeService {
  ThemeModeService() {
    DashboardColors.applyPalette(DashboardPalette.light());
  }

  bool get isDark => false;

  ThemeData get materialTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: DashboardColors.darkNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DashboardColors.purple,
        brightness: Brightness.light,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      textTheme: AppTypography.lightTheme(),
      useMaterial3: true,
    );
  }
}
