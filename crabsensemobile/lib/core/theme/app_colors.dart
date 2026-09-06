import 'package:flutter/material.dart';

/// CrabSense Design System — Neofarm-inspired (lime + forest), same screens
class CrabSenseColors {
  CrabSenseColors._();

  // ── Primary — Lime (accent) + Forest (ink) ────────────────────────
  static const Color primary       = Color(0xFF6DC22E);
  static const Color primaryDark   = Color(0xFF0A3323);
  static const Color primaryLight  = Color(0xFFC8E86A);
  static const Color primaryMuted  = Color(0xFFF3F8E8);

  // ── Secondary — Sage (nước / IoT), không dùng xanh dương marketing ─
  static const Color secondary      = Color(0xFF4F7A62);
  static const Color secondaryLight = Color(0xFFDCE8DF);
  static const Color teal           = Color(0xFF3D8B6E);

  // ── Background & Surface ─────────────────────────────────────────────
  static const Color background     = Color(0xFFF3F6EC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFEEF3E6);
  static const Color headerBg       = Color(0xFF0A3323);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF0F1F18);
  static const Color textSecondary  = Color(0xFF5A6B60);
  static const Color textHint       = Color(0xFF8A9A8E);
  static const Color textOnPrimary  = Color(0xFF0A3323); // Chữ đậm trên nút lime
  static const Color textOnDark     = Color(0xFFFFFFFF);

  // ── Borders & Dividers ─────────────────────────────────────────────
  static const Color border         = Color(0xFFD5E0D0);
  static const Color divider        = Color(0xFFE6EEE0);

  // ── Status Colors ──────────────────────────────────────────────────
  static const Color success        = Color(0xFF2ECC71); // Xanh lá = OK
  static const Color successLight   = Color(0xFFD5F5E3);
  static const Color warning        = Color(0xFFF39C12); // Cam vàng = Cần chú ý
  static const Color warningLight   = Color(0xFFFEF5E7);
  static const Color danger         = Color(0xFFE74C3C); // Đỏ = Nguy hiểm
  static const Color dangerLight    = Color(0xFFFDECEC);
  static const Color info           = Color(0xFF3498DB); // Xanh = Thông tin
  static const Color infoLight      = Color(0xFFD6EFF9);
  static const Color normal         = Color(0xFF2ECC71); // Bình thường

  // ── Crab Health Status Colors ──────────────────────────────────────
  static const Color healthNormal   = Color(0xFF2ECC71); // Bình thường
  static const Color healthMolting  = Color(0xFFF39C12); // Sắp lột xác
  static const Color healthAlert    = Color(0xFFE74C3C); // Cảnh báo

  // ── Box Status Colors (sơ đồ trang trại) ─────────────────────────
  static const Color boxNormal      = Color(0xFF2ECC71); // Xanh lá = bình thường
  static const Color boxMolting     = Color(0xFFF39C12); // Cam = sắp lột
  static const Color boxAlert       = Color(0xFFE74C3C); // Đỏ = cảnh báo
  static const Color boxEmpty       = Color(0xFFBDC3C7); // Xám = trống

  // ── Water Quality Indicator Colors ────────────────────────────────
  static const Color wqGood         = Color(0xFF2ECC71);
  static const Color wqWarning      = Color(0xFFF39C12);
  static const Color wqBad          = Color(0xFFE74C3C);

  // ── Bottom Navigation ─────────────────────────────────────────────
  static const Color navActive      = Color(0xFF0A3323);
  static const Color navInactive    = Color(0xFF8A9A8E);
  static const Color navBackground  = Color(0xFFFFFFFF);

  // ── Shadow ────────────────────────────────────────────────────────
  static const Color shadow         = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color shadowMedium   = Color(0x1F000000); // rgba(0,0,0,0.12)

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8ED63A), Color(0xFF6DC22E)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7ED321), Color(0xFF6DC22E), Color(0xFF4FA81E)],
  );

  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D8B6E), Color(0xFF0A3323)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC8E86A), Color(0xFFF3F6EC)],
  );
  // ── Legacy aliases — tương thích với code cũ ─────────────────────
  static const Color container      = Color(0xFFF0F4F8);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color textDisabled   = Color(0xFF9DB3C2);
  static const Color error          = Color(0xFFE74C3C);
  static const Color accent         = Color(0xFF6DC22E);
  static const Color outline        = Color(0xFFDDE4EB);
  static const Color outlineVariant = Color(0xFFEBEFF3);
  static const Color hintText       = Color(0xFF9DB3C2);
  static const Color card           = Color(0xFFFFFFFF);
}



