import 'package:crabsensemobile/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Theme tests use testWidgets to ensure the WidgetsFlutterBinding is
// initialised before google_fonts attempts async font loading.
// Pure typography/color tests that do NOT construct a ThemeData are kept
// as regular synchronous tests for speed.

void main() {
  group('CrabSenseColors', () {
    test('Status colors are correctly defined', () {
      expect(CrabSenseColors.success, const Color(0xFF4CAF50));
      expect(CrabSenseColors.warning, const Color(0xFFFFA726));
      expect(CrabSenseColors.error, const Color(0xFFEF5350));
      expect(CrabSenseColors.info, const Color(0xFF29B6F6));
    });

    test('Brand colors are correctly defined', () {
      expect(CrabSenseColors.primary, const Color(0xFF00C8FF));
      expect(CrabSenseColors.background, const Color(0xFF081528));
      expect(CrabSenseColors.surface, const Color(0xFF0F1F3D));
    });
  });

  group('CrabSenseTypography', () {
    test('Typography should have correct font sizes', () {
      // Display styles
      expect(CrabSenseTypography.displayLarge.fontSize, 57);
      expect(CrabSenseTypography.displayMedium.fontSize, 45);
      expect(CrabSenseTypography.displaySmall.fontSize, 36);

      // Headline styles
      expect(CrabSenseTypography.headlineLarge.fontSize, 32);
      expect(CrabSenseTypography.headlineMedium.fontSize, 28);
      expect(CrabSenseTypography.headlineSmall.fontSize, 24);

      // Title styles
      expect(CrabSenseTypography.titleLarge.fontSize, 22);
      expect(CrabSenseTypography.titleMedium.fontSize, 16);
      expect(CrabSenseTypography.titleSmall.fontSize, 14);

      // Body styles
      expect(CrabSenseTypography.bodyLarge.fontSize, 16);
      expect(CrabSenseTypography.bodyMedium.fontSize, 14);
      expect(CrabSenseTypography.bodySmall.fontSize, 12);

      // Label styles
      expect(CrabSenseTypography.labelLarge.fontSize, 14);
      expect(CrabSenseTypography.labelMedium.fontSize, 12);
      expect(CrabSenseTypography.labelSmall.fontSize, 11);
    });

    test('Typography uses Inter font family', () {
      expect(CrabSenseTypography.fontFamily, 'Inter');
      expect(CrabSenseTypography.displayLarge.fontFamily, 'Inter');
      expect(CrabSenseTypography.bodyLarge.fontFamily, 'Inter');
      expect(CrabSenseTypography.labelLarge.fontFamily, 'Inter');
    });
  });

  group('CrabSenseTheme — dark theme', () {
    // Use testWidgets so that the WidgetsBinding is initialised before
    // google_fonts starts async font-loading. pumpWidget + pumpAndSettle
    // drains the async queue so no "failed after completing" errors occur.

    testWidgets('uses Material Design 3 (Req 20.1)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.useMaterial3, true);
    });

    testWidgets('primary color is #00C8FF (Req 20.2)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.colorScheme.primary, const Color(0xFF00C8FF));
    });

    testWidgets('scaffold background color is #081528 (Req 20.2)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF081528));
    });

    testWidgets('surface color is #0F1F3D', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.colorScheme.surface, const Color(0xFF0F1F3D));
    });

    testWidgets('brightness is dark (Req 20.3)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('card border radius is 16dp (Req 20.5)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
      final borderRadius = cardShape.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, 16);
      expect(borderRadius.bottomRight.x, 16);
    });

    testWidgets('text theme uses Inter font family (Req 20.6)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('Inter'));
      expect(theme.textTheme.headlineLarge?.fontFamily, contains('Inter'));
      expect(theme.textTheme.titleLarge?.fontFamily, contains('Inter'));
    });

    testWidgets('has all required component themes', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.appBarTheme, isNotNull);
      expect(theme.cardTheme, isNotNull);
      expect(theme.elevatedButtonTheme, isNotNull);
      expect(theme.outlinedButtonTheme, isNotNull);
      expect(theme.textButtonTheme, isNotNull);
      expect(theme.floatingActionButtonTheme, isNotNull);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.bottomNavigationBarTheme, isNotNull);
      expect(theme.dialogTheme, isNotNull);
      expect(theme.snackBarTheme, isNotNull);
    });
  });

  group('CrabSenseTheme — light theme', () {
    testWidgets('light theme is available and uses Material 3', (tester) async {
      final theme = CrabSenseTheme.lightTheme;
      await _pumpTheme(tester, theme);
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF00C8FF));
    });
  });
}

/// Pumps a minimal [MaterialApp] with [theme] and settles all async tasks
/// (including google_fonts font loading) so tests don't leak async work.
Future<void> _pumpTheme(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(MaterialApp(theme: theme, home: const SizedBox()));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
