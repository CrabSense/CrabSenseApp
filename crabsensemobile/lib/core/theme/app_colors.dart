import 'package:flutter/material.dart';

/// CrabSense Design System — Nông nghiệp thân thiện, sáng sủa
/// Màu sắc lấy cảm hứng từ thiên nhiên: xanh lá cây tươi + trắng sạch
class CrabSenseColors {
  CrabSenseColors._();

  // ── Primary — Xanh lá cây tươi (màu chủ đạo) ──────────────────────
  static const Color primary       = Color(0xFF27AE60); // Xanh lá đậm vừa (bớt neon)
  static const Color primaryDark   = Color(0xFF1E8449); // Xanh lá đậm
  static const Color primaryLight  = Color(0xFFD5F5E3); // Xanh lá nhạt
  static const Color primaryMuted  = Color(0xFFEAF7EF); // Xanh lá cực nhạt

  // ── Secondary — Xanh dương biển (IoT/nước) ─────────────────────────
  static const Color secondary      = Color(0xFF1A7FC1); // Xanh dương đậm hơn
  static const Color secondaryLight = Color(0xFFD6EFF9);
  static const Color teal           = Color(0xFF17A589);

  // ── Background & Surface ─────────────────────────────────────────────
  static const Color background     = Color(0xFFF0F3F7); // Xám nhạt tự nhiên hơn
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFEEF2F6);
  static const Color headerBg       = Color(0xFF1A5276); // Xanh đậm header

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A2E3B); // Đen xanh đậm
  static const Color textSecondary  = Color(0xFF5A7184); // Xám xanh phụ
  static const Color textHint       = Color(0xFF9DB3C2); // Xám nhạt placeholder
  static const Color textOnPrimary  = Color(0xFFFFFFFF); // Trắng trên nền xanh
  static const Color textOnDark     = Color(0xFFFFFFFF); // Trắng trên dark bg

  // ── Borders & Dividers ─────────────────────────────────────────────
  static const Color border         = Color(0xFFDDE4EB); // Viền nhạt
  static const Color divider        = Color(0xFFEBEFF3); // Đường kẻ

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
  static const Color navActive      = Color(0xFF27AE60);
  static const Color navInactive    = Color(0xFF9DB3C2);
  static const Color navBackground  = Color(0xFFFFFFFF);

  // ── Shadow ────────────────────────────────────────────────────────
  static const Color shadow         = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color shadowMedium   = Color(0x1F000000); // rgba(0,0,0,0.12)

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6CA8), Color(0xFF1A9CD8)],
  );

  static const LinearGradient waterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A9CD8), Color(0xFF00B4A0)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F8F0), Color(0xFFFFFFFF)],
  );
  // ── Legacy aliases — tương thích với code cũ ─────────────────────
  static const Color container      = Color(0xFFF0F4F8);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color textDisabled   = Color(0xFF9DB3C2);
  static const Color error          = Color(0xFFE74C3C);
  static const Color accent         = Color(0xFF1A9CD8);
  static const Color outline        = Color(0xFFDDE4EB);
  static const Color outlineVariant = Color(0xFFEBEFF3);
  static const Color hintText       = Color(0xFF9DB3C2);
  static const Color card           = Color(0xFFFFFFFF);
}



