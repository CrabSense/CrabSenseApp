import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// CrabSense Material Design 3 Theme Configuration
/// Implements brand colors, typography, and component themes
/// Requirements: 20.1-20.10

/// Brand color palette for CrabSense
class CrabSenseColors {
  // Primary brand color
  static const primary = Color(0xFF00C8FF); // Cyan blue
  static const secondary = Color(0xFF00A8E8); // Accent blue/cyan

  // Background and surfaces
  static const background = Color(0xFF081528); // Dark blue
  static const surface = Color(0xFF0F1F3D);
  static const surfaceVariant = Color(0xFF1A2F4D);

  // Status colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFEF5350);
  static const info = Color(0xFF29B6F6);

  // Text colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0BEC5);
  static const textDisabled = Color(0xFF607D8B);

  // Border and outline colors
  static const outline = Color(0xFF37474F);
  static const outlineVariant = Color(0xFF263238);
}

/// Typography configuration using Inter font family
class CrabSenseTypography {
  static const String fontFamily = 'Inter';

  // Display styles
  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
    fontFamily: fontFamily,
  );

  static const displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
    fontFamily: fontFamily,
  );

  static const displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.22,
    fontFamily: fontFamily,
  );

  // Headline styles
  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    fontFamily: fontFamily,
  );

  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    fontFamily: fontFamily,
  );

  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    fontFamily: fontFamily,
  );

  // Title styles
  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
    fontFamily: fontFamily,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
    fontFamily: fontFamily,
  );

  static const titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    fontFamily: fontFamily,
  );

  // Body styles
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
    fontFamily: fontFamily,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    fontFamily: fontFamily,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    fontFamily: fontFamily,
  );

  // Label styles
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    fontFamily: fontFamily,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    fontFamily: fontFamily,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    fontFamily: fontFamily,
  );
}

/// CrabSense Dark Theme Configuration (Default)
class CrabSenseTheme {
  /// Dark theme implementation (default)
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: CrabSenseColors.primary,
      secondary: CrabSenseColors.primary.withValues(alpha: 0.7),
      error: CrabSenseColors.error,
      onError: Colors.white,
      surface: CrabSenseColors.surface,
      surfaceContainerHighest: CrabSenseColors.surfaceVariant,
      outline: CrabSenseColors.outline,
      outlineVariant: CrabSenseColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CrabSenseColors.background,

      // Typography theme with Inter font family from Google Fonts
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: CrabSenseTypography.displayLarge.copyWith(
            color: CrabSenseColors.textPrimary,
          ),
          displayMedium: CrabSenseTypography.displayMedium.copyWith(
            color: CrabSenseColors.textPrimary,
          ),
          displaySmall: CrabSenseTypography.displaySmall.copyWith(
            color: CrabSenseColors.textPrimary,
          ),
          headlineLarge: CrabSenseTypography.headlineLarge.copyWith(
            color: CrabSenseColors.textPrimary,
          ),
          headlineMedium: CrabSenseTypography.headlineMedium.copyWith(
            color: CrabSenseColors.textPrimary,
          ),
          headlineSmall: CrabSenseTypography.headlineSmall.copyWith(
            color: CrabSenseColors.textPrimary,
          ),
          titleLarge: CrabSenseTypography.titleLarge.copyWith(color: CrabSenseColors.textPrimary),
          titleMedium: CrabSenseTypography.titleMedium.copyWith(color: CrabSenseColors.textPrimary),
          titleSmall: CrabSenseTypography.titleSmall.copyWith(color: CrabSenseColors.textSecondary),
          bodyLarge: CrabSenseTypography.bodyLarge.copyWith(color: CrabSenseColors.textPrimary),
          bodyMedium: CrabSenseTypography.bodyMedium.copyWith(color: CrabSenseColors.textSecondary),
          bodySmall: CrabSenseTypography.bodySmall.copyWith(color: CrabSenseColors.textSecondary),
          labelLarge: CrabSenseTypography.labelLarge.copyWith(color: CrabSenseColors.textPrimary),
          labelMedium: CrabSenseTypography.labelMedium.copyWith(
            color: CrabSenseColors.textSecondary,
          ),
          labelSmall: CrabSenseTypography.labelSmall.copyWith(color: CrabSenseColors.textDisabled),
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: CrabSenseColors.surface,
        foregroundColor: CrabSenseColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: CrabSenseTypography.titleLarge.copyWith(color: CrabSenseColors.textPrimary),
        iconTheme: const IconThemeData(color: CrabSenseColors.textPrimary, size: 24),
      ),

      // Card theme - 16dp border radius
      cardTheme: CardThemeData(
        elevation: 2,
        color: CrabSenseColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CrabSenseColors.primary.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
      ),

      // Elevated button theme - 14dp border radius
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CrabSenseColors.primary,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: CrabSenseTypography.labelLarge.copyWith(color: Colors.black),
        ),
      ),

      // Outlined button theme - 14dp border radius
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CrabSenseColors.primary,
          side: const BorderSide(color: CrabSenseColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: CrabSenseTypography.labelLarge.copyWith(color: CrabSenseColors.primary),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CrabSenseColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: CrabSenseTypography.labelLarge.copyWith(color: CrabSenseColors.primary),
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: CrabSenseColors.textPrimary, iconSize: 24),
      ),

      // Floating action button theme - 16dp border radius
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CrabSenseColors.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input decoration theme - outlined style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CrabSenseColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CrabSenseColors.error, width: 2),
        ),
        labelStyle: CrabSenseTypography.bodyMedium.copyWith(color: CrabSenseColors.textSecondary),
        hintStyle: CrabSenseTypography.bodyMedium.copyWith(color: CrabSenseColors.textDisabled),
        errorStyle: CrabSenseTypography.bodySmall.copyWith(color: CrabSenseColors.error),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CrabSenseColors.surface,
        selectedItemColor: CrabSenseColors.primary,
        unselectedItemColor: CrabSenseColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: CrabSenseTypography.labelSmall.copyWith(color: CrabSenseColors.primary),
        unselectedLabelStyle: CrabSenseTypography.labelSmall.copyWith(
          color: CrabSenseColors.textSecondary,
        ),
      ),

      // Dialog theme - 16dp border radius
      dialogTheme: DialogThemeData(
        backgroundColor: CrabSenseColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: CrabSenseTypography.headlineSmall.copyWith(
          color: CrabSenseColors.textPrimary,
        ),
        contentTextStyle: CrabSenseTypography.bodyMedium.copyWith(
          color: CrabSenseColors.textSecondary,
        ),
      ),

      // Bottom sheet theme - 16dp border radius (top corners)
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CrabSenseColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Chip theme - 14dp border radius
      chipTheme: ChipThemeData(
        backgroundColor: CrabSenseColors.surfaceVariant,
        deleteIconColor: CrabSenseColors.textPrimary,
        disabledColor: CrabSenseColors.surfaceVariant.withValues(alpha: 0.5),
        selectedColor: CrabSenseColors.primary.withValues(alpha: 0.3),
        secondarySelectedColor: CrabSenseColors.primary.withValues(alpha: 0.3),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: CrabSenseColors.outline),
        ),
        labelStyle: CrabSenseTypography.labelMedium.copyWith(color: CrabSenseColors.textPrimary),
        secondaryLabelStyle: CrabSenseTypography.labelMedium.copyWith(
          color: CrabSenseColors.textPrimary,
        ),
        brightness: Brightness.dark,
      ),

      // Snackbar theme - 14dp border radius
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CrabSenseColors.surfaceVariant,
        contentTextStyle: CrabSenseTypography.bodyMedium.copyWith(
          color: CrabSenseColors.textPrimary,
        ),
        actionTextColor: CrabSenseColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(color: CrabSenseColors.outline, thickness: 1, space: 1),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CrabSenseColors.primary,
        circularTrackColor: CrabSenseColors.surfaceVariant,
        linearTrackColor: CrabSenseColors.surfaceVariant,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return CrabSenseColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CrabSenseColors.primary;
          }
          return CrabSenseColors.outline;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CrabSenseColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.black),
        side: const BorderSide(color: CrabSenseColors.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio button theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CrabSenseColors.primary;
          }
          return CrabSenseColors.outline;
        }),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: CrabSenseColors.primary,
        inactiveTrackColor: CrabSenseColors.outline,
        thumbColor: CrabSenseColors.primary,
        overlayColor: CrabSenseColors.primary.withValues(alpha: 0.2),
        valueIndicatorColor: CrabSenseColors.primary,
        valueIndicatorTextStyle: CrabSenseTypography.labelSmall.copyWith(color: Colors.black),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: CrabSenseColors.primary.withValues(alpha: 0.1),
        iconColor: CrabSenseColors.textSecondary,
        textColor: CrabSenseColors.textPrimary,
        titleTextStyle: CrabSenseTypography.bodyLarge.copyWith(color: CrabSenseColors.textPrimary),
        subtitleTextStyle: CrabSenseTypography.bodyMedium.copyWith(
          color: CrabSenseColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: CrabSenseColors.primary,
        unselectedLabelColor: CrabSenseColors.textSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: CrabSenseColors.primary, width: 2),
        ),
        labelStyle: CrabSenseTypography.labelLarge.copyWith(color: CrabSenseColors.primary),
        unselectedLabelStyle: CrabSenseTypography.labelLarge.copyWith(
          color: CrabSenseColors.textSecondary,
        ),
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CrabSenseColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: CrabSenseTypography.bodySmall.copyWith(color: CrabSenseColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Light theme implementation (optional fallback)
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: CrabSenseColors.primary,
      secondary: CrabSenseColors.primary.withValues(alpha: 0.7),
      onSecondary: Colors.white,
      error: CrabSenseColors.error,
      onSurface: Colors.black87,
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      outline: const Color(0xFFE0E0E0),
      outlineVariant: const Color(0xFFF5F5F5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      // Light theme uses similar structure to dark theme
      // with adjusted colors for light mode
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: CrabSenseTypography.displayLarge.copyWith(color: Colors.black87),
          displayMedium: CrabSenseTypography.displayMedium.copyWith(color: Colors.black87),
          displaySmall: CrabSenseTypography.displaySmall.copyWith(color: Colors.black87),
          headlineLarge: CrabSenseTypography.headlineLarge.copyWith(color: Colors.black87),
          headlineMedium: CrabSenseTypography.headlineMedium.copyWith(color: Colors.black87),
          headlineSmall: CrabSenseTypography.headlineSmall.copyWith(color: Colors.black87),
          titleLarge: CrabSenseTypography.titleLarge.copyWith(color: Colors.black87),
          titleMedium: CrabSenseTypography.titleMedium.copyWith(color: Colors.black87),
          titleSmall: CrabSenseTypography.titleSmall.copyWith(color: Colors.black54),
          bodyLarge: CrabSenseTypography.bodyLarge.copyWith(color: Colors.black87),
          bodyMedium: CrabSenseTypography.bodyMedium.copyWith(color: Colors.black54),
          bodySmall: CrabSenseTypography.bodySmall.copyWith(color: Colors.black54),
          labelLarge: CrabSenseTypography.labelLarge.copyWith(color: Colors.black87),
          labelMedium: CrabSenseTypography.labelMedium.copyWith(color: Colors.black54),
          labelSmall: CrabSenseTypography.labelSmall.copyWith(color: Colors.black38),
        ),
      ),
    );
  }
}
