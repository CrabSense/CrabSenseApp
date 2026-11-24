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
      expect(CrabSenseColors.success, const Color(0xFF2ECC71));
      expect(CrabSenseColors.warning, const Color(0xFFF39C12));
      expect(CrabSenseColors.error, const Color(0xFFE74C3C));
      expect(CrabSenseColors.info, const Color(0xFF3498DB));
    });

    test('Brand colors are correctly defined', () {
      expect(CrabSenseColors.primary, const Color(0xFF6DC22E));
      expect(CrabSenseColors.background, const Color(0xFFF3F6EC));
      expect(CrabSenseColors.surface, const Color(0xFFFFFFFF));
    });
  });

  group('CrabSenseTypography', () {
    testWidgets('uses the current Nunito typography scale', (tester) async {
      final theme = CrabSenseTheme.lightTheme;
      await _pumpTheme(tester, theme);
      final text = theme.textTheme;
      expect(text.headlineLarge?.fontSize, 24);
      expect(text.headlineMedium?.fontSize, 20);
      expect(text.headlineSmall?.fontSize, 18);
      expect(text.titleLarge?.fontSize, 16);
      expect(text.titleMedium?.fontSize, 15);
      expect(text.titleSmall?.fontSize, 14);
      expect(text.bodyLarge?.fontSize, 15);
      expect(text.bodyMedium?.fontSize, 14);
      expect(text.bodySmall?.fontSize, 12);
      expect(text.labelLarge?.fontSize, 14);
      expect(text.labelMedium?.fontSize, 12);
      expect(text.labelSmall?.fontSize, 11);
      expect(text.bodyLarge?.fontFamily, contains('Nunito'));
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

    testWidgets('primary color is #6DC22E (Req 20.2)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.colorScheme.primary, const Color(0xFF6DC22E));
    });

    testWidgets('scaffold background color is #F3F6EC (Req 20.2)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF3F6EC));
    });

    testWidgets('surface color is #FFFFFF', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    });

    testWidgets('legacy dark theme resolves to light', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('card border radius is 20dp (Req 20.5)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
      final borderRadius = cardShape.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, 20);
      expect(borderRadius.bottomRight.x, 20);
    });

    testWidgets('text theme uses Nunito font family (Req 20.6)', (tester) async {
      final theme = CrabSenseTheme.darkTheme;
      await _pumpTheme(tester, theme);
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('Nunito'));
      expect(theme.textTheme.headlineLarge?.fontFamily, contains('Nunito'));
      expect(theme.textTheme.titleLarge?.fontFamily, contains('Nunito'));
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
      expect(theme.colorScheme.primary, const Color(0xFF6DC22E));
    });
  });
}

/// Pumps a minimal [MaterialApp] with [theme] and settles all async tasks
/// (including google_fonts font loading) so tests don't leak async work.
Future<void> _pumpTheme(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(MaterialApp(theme: theme, home: const SizedBox()));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
