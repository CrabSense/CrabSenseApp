import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Be Vietnam Pro — font chuẩn CrabSense (hỗ trợ tiếng Việt).
abstract final class AppTypography {
  static TextStyle text({
    double fontSize = 14,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.beVietnamPro(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme darkTheme() => GoogleFonts.beVietnamProTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      );

  static TextTheme lightTheme() => GoogleFonts.beVietnamProTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      );
}

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
