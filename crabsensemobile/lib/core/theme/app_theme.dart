import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CrabSense Material Design 3 Theme Configuration
class CrabSenseTheme {
  CrabSenseTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CrabSenseColors.background,
        colorScheme: const ColorScheme.dark(
          primary: CrabSenseColors.primary,
          secondary: CrabSenseColors.secondary,
          surface: CrabSenseColors.surface,
          error: CrabSenseColors.danger,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: CrabSenseColors.textPrimary,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.bold),
            headlineLarge: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.w700),
            headlineMedium: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.w700),
            headlineSmall: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.w600),
            titleLarge: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(color: CrabSenseColors.textSecondary, fontWeight: FontWeight.w500),
            bodyLarge: TextStyle(color: CrabSenseColors.textPrimary),
            bodyMedium: TextStyle(color: CrabSenseColors.textSecondary),
            bodySmall: TextStyle(color: CrabSenseColors.hintText),
            labelLarge: TextStyle(color: CrabSenseColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: CrabSenseColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CrabSenseColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: CrabSenseColors.divider,
          thickness: 1,
          space: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CrabSenseColors.primary,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            minimumSize: const Size(48, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: CrabSenseColors.primary,
            side: const BorderSide(color: CrabSenseColors.primary, width: 1.5),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(48, 48),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: CrabSenseColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CrabSenseColors.container,
          hintStyle: GoogleFonts.inter(color: CrabSenseColors.hintText),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CrabSenseColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CrabSenseColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CrabSenseColors.primary, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: CrabSenseColors.surface,
          indicatorColor: CrabSenseColors.primary.withValues(alpha: 0.15),
          elevation: 8,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                color: CrabSenseColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return GoogleFonts.inter(
              color: CrabSenseColors.hintText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: CrabSenseColors.primary, size: 24);
            }
            return const IconThemeData(color: CrabSenseColors.hintText, size: 24);
          }),
        ),
      );
}
