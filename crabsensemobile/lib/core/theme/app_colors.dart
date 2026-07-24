import 'package:flutter/material.dart';

/// CrabSense Design System - Smart Aquaculture & High-Tech Color Tokens
class CrabSenseColors {
  CrabSenseColors._();

  // Primary Tech Cyan Palette
  static const Color primary = Color(0xFF00C8FF);
  static const Color primaryDark = Color(0xFF0097D8);
  static const Color secondary = Color(0xFF0077B6);
  static const Color accent = Color(0xFF3DDCFF);

  // Dark Mode Surface & Background Palette
  static const Color background = Color(0xFF081528);
  static const Color surface = Color(0xFF10233A);
  static const Color card = Color(0xFF132C45);
  static const Color container = Color(0xFF173552);

  // Borders & Dividers
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color divider = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)

  // Typography Palette
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC6D9F2);
  static const Color hintText = Color(0xFF8AA9C9);

  // Semantic Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF2C94C);
  static const Color danger = Color(0xFFEB5757);
  static const Color info = Color(0xFF56CCF2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      secondary,
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F3254),
      Color(0xFF071F36),
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2B00C8FF),
      Color(0x0D0077B6),
    ],
  );
}
