import 'package:flutter/material.dart';

/// Bảng màu theo chế độ sáng/tối.
class DashboardPalette {
  const DashboardPalette({
    required this.darkNavy,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.sidebarBg,
    required this.pageGradient,
    required this.glowAlpha,
  });

  final Color darkNavy;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color sidebarBg;
  final LinearGradient pageGradient;
  final double glowAlpha;

  factory DashboardPalette.dark() => const DashboardPalette(
        darkNavy: Color(0xFF101827),
        card: Color(0xFF1B2438),
        cardBorder: Color(0xFF2A3548),
        textPrimary: Color(0xFFF8FAFC),
        textMuted: Color(0xFF94A3B8),
        sidebarBg: Color(0xFF0D1424),
        pageGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1040),
            Color(0xFF101827),
            Color(0xFF0C1F3D),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        glowAlpha: 0.18,
      );

  factory DashboardPalette.light() => const DashboardPalette(
        darkNavy: Color(0xFFF3FBF8),
        card: Color(0xFFFFFFFF),
        cardBorder: Color(0xFFD7EBE3),
        textPrimary: Color(0xFF12332D),
        textMuted: Color(0xFF66847C),
        sidebarBg: Color(0xFFEAF8F3),
        pageGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7FFFC),
            Color(0xFFF3FBF8),
            Color(0xFFEAF8F3),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        glowAlpha: 0.12,
      );
}

abstract final class DashboardColors {
  static DashboardPalette _palette = DashboardPalette.light();

  static void applyPalette(DashboardPalette palette) {
    _palette = palette;
  }

  static const purple = Color(0xFF7C5CFF);
  static const blue = Color(0xFF25A7E8);
  static const cyan = Color(0xFF12A87A);
  /// Brand emerald — thay accent tím trên UI chính.
  static const brand = Color(0xFF087F5B);
  static const brandGreen = Color(0xFF12A87A);
  static const mint = Color(0xFFDDF7EE);
  static const mintActive = Color(0xFFCFF4E5);
  static const lightMint = Color(0xFFF3FBF8);
  static Color get darkNavy => _palette.darkNavy;
  static Color get card => _palette.card;
  static Color get cardBorder => _palette.cardBorder;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textMuted => _palette.textMuted;
  static Color get sidebarBg => _palette.sidebarBg;

  static const seaGreen = Color(0xFF14B8A6);
  static const oceanBlue = Color(0xFF0EA5E9);
  static const healthy = Color(0xFF22C55E);
  static const monitoring = Color(0xFFEAB308);
  static const molting = Color(0xFFF97316);

  /// Tím cho hộp cua đang lột xác (quy ước: lột = tím).
  static const moltPurple = Color(0xFFA78BFA);
  static const risk = Color(0xFFEF4444);
  static const dead = Color(0xFF64748B);

  static const excellent = Color(0xFF22C55E);
  static const good = Color(0xFF57E6FF);
  static const warning = Color(0xFFEAB308);
  static const danger = Color(0xFFEF4444);

  static LinearGradient get pageGradient => _palette.pageGradient;

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [brand, brandGreen, Color(0xFF35C997)],
      );

  static BoxShadow get glowShadow => BoxShadow(
        color: brand.withValues(alpha: _palette.glowAlpha),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );
}

enum ParamStatus { excellent, good, warning, danger }

extension ParamStatusX on ParamStatus {
  Color get color => switch (this) {
        ParamStatus.excellent => DashboardColors.excellent,
        ParamStatus.good => DashboardColors.good,
        ParamStatus.warning => DashboardColors.warning,
        ParamStatus.danger => DashboardColors.danger,
      };

  String get label => switch (this) {
        ParamStatus.excellent => 'Excellent',
        ParamStatus.good => 'Good',
        ParamStatus.warning => 'Warning',
        ParamStatus.danger => 'Danger',
      };
}

enum MascotMood { happy, calm, alert, critical }

MascotMood mascotMoodFromHealth(int score) {
  if (score >= 90) return MascotMood.happy;
  if (score >= 75) return MascotMood.calm;
  if (score >= 60) return MascotMood.alert;
  return MascotMood.critical;
}
