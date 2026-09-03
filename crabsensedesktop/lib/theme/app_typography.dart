import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Noto Sans supports Vietnamese + Latin (web/desktop).
abstract final class AppTypography {
  static TextStyle text({
    double fontSize = 14,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.notoSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme darkTheme() => GoogleFonts.notoSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      );

  static TextTheme lightTheme() => GoogleFonts.notoSansTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      );
}

/// Drop-in replacement for previous Inter usage.
TextStyle appText({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    AppTypography.text(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
