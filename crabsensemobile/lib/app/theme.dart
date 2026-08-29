import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

export '../core/theme/app_colors.dart';

/// CrabSense Theme — Thân thiện với nông dân, sáng sủa, dễ dùng
/// Light mode là mặc định theo thiết kế mới
class CrabSenseTheme {
  static ThemeData get darkTheme => lightTheme; // redirect về light

  static ThemeData get lightTheme {
    final base = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CrabSenseColors.background,

      colorScheme: const ColorScheme.light(
        primary: CrabSenseColors.primary,
        onPrimary: CrabSenseColors.textOnPrimary,
        secondary: CrabSenseColors.secondary,
        onSecondary: Colors.white,
        error: CrabSenseColors.danger,
        onError: Colors.white,
        surface: CrabSenseColors.surface,
        onSurface: CrabSenseColors.textPrimary,
        outline: CrabSenseColors.border,
        outlineVariant: CrabSenseColors.divider,
      ),

      // ── Typography — Nunito: tròn, thân thiện, dễ đọc ───────────────
      textTheme: base.copyWith(
        // Tiêu đề lớn
        headlineLarge: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: CrabSenseColors.textPrimary),
        headlineMedium: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: CrabSenseColors.textPrimary),
        headlineSmall: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: CrabSenseColors.textPrimary),
        // Tiêu đề section
        titleLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: CrabSenseColors.textPrimary),
        titleMedium: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: CrabSenseColors.textPrimary),
        titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: CrabSenseColors.textSecondary),
        // Nội dung
        bodyLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: CrabSenseColors.textPrimary),
        bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: CrabSenseColors.textSecondary),
        bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: CrabSenseColors.textHint),
        // Label
        labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: CrabSenseColors.textPrimary),
        labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: CrabSenseColors.textSecondary),
        labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: CrabSenseColors.textHint),
      ),

      // ── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: CrabSenseColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      // ── Cards ────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: CrabSenseColors.surface,
        elevation: 0,
        shadowColor: CrabSenseColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CrabSenseColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ── Buttons ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CrabSenseColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CrabSenseColors.primary,
          side: const BorderSide(color: CrabSenseColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CrabSenseColors.primary,
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CrabSenseColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Input Fields ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CrabSenseColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CrabSenseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CrabSenseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CrabSenseColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CrabSenseColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CrabSenseColors.danger, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(fontSize: 14, color: CrabSenseColors.textHint),
        labelStyle: GoogleFonts.nunito(fontSize: 14, color: CrabSenseColors.textSecondary),
        prefixIconColor: CrabSenseColors.textHint,
        suffixIconColor: CrabSenseColors.textHint,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CrabSenseColors.navBackground,
        selectedItemColor: CrabSenseColors.navActive,
        unselectedItemColor: CrabSenseColors.navInactive,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500),
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
      ),

      // ── Chips ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: CrabSenseColors.surfaceAlt,
        selectedColor: CrabSenseColors.primaryLight,
        labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CrabSenseColors.border),
        ),
        side: const BorderSide(color: CrabSenseColors.border),
      ),

      // ── Divider ──────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: CrabSenseColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ───────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: CrabSenseColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: CrabSenseColors.textPrimary),
        contentTextStyle: GoogleFonts.nunito(fontSize: 14, color: CrabSenseColors.textSecondary),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CrabSenseColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Snackbar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CrabSenseColors.textPrimary,
        contentTextStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.white),
        actionTextColor: CrabSenseColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),

      // ── List Tile ────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: CrabSenseColors.primaryLight,
        iconColor: CrabSenseColors.textSecondary,
        textColor: CrabSenseColors.textPrimary,
        titleTextStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: CrabSenseColors.textPrimary),
        subtitleTextStyle: GoogleFonts.nunito(fontSize: 13, color: CrabSenseColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Tab Bar ──────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: CrabSenseColors.primary,
        unselectedLabelColor: CrabSenseColors.textHint,
        indicatorColor: CrabSenseColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: CrabSenseColors.divider,
        labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500),
      ),

      // ── Switch ───────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? CrabSenseColors.primary : CrabSenseColors.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ── Checkbox ─────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? CrabSenseColors.primary : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: CrabSenseColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Progress Indicator ───────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CrabSenseColors.primary,
        circularTrackColor: CrabSenseColors.primaryLight,
        linearTrackColor: CrabSenseColors.primaryLight,
      ),
    );
  }
}
