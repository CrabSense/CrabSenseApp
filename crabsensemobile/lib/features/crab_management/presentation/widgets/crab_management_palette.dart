import 'package:flutter/material.dart';

// ── CrabSense Crab Management — Design Tokens ─────────────────────────────────
// Sync'd with: Dashboard, Quản lý khu, Quản lý dãy, Quản lý hộp, Quản lý nhập hàng
// Primary: Emerald #087F5B / CrabSense Green #12A87A

const Color kCmPrimary = Color(0xFF12A87A); // CrabSense Green
const Color kCmPrimaryDark = Color(0xFF087F5B); // Emerald
const Color kCmPrimaryLight = Color(0xFFDDF7EE); // Mint
const Color kCmMintBg = Color(0xFFF3FBF8); // Light Mint
const Color kCmBackground = Color(0xFFF7FCFA); // Background
const Color kCmSurface = Color(0xFFFFFFFF);
const Color kCmBorder = Color(0xFFD8E9E4);
const Color kCmTextPrimary = Color(0xFF12332D); // Dark Text
const Color kCmTextSecondary = Color(0xFF66847C); // Secondary
const Color kCmTextHint = Color(0xFF94A3B8); // Slate

// Semantic colors
const Color kCmBlue = Color(0xFF2495E8); // Total / info
const Color kCmBlueLight = Color(0xFFDBEDFB);
const Color kCmAmber = Color(0xFFF5B700); // Theo dõi
const Color kCmAmberLight = Color(0xFFFFF8DC);
const Color kCmRed = Color(0xFFEF4444); // Chết
const Color kCmRedLight = Color(0xFFFEE2E2);
const Color kCmPurple = Color(0xFF7C3AED); // Đang lột xác
const Color kCmPurpleLight = Color(0xFFF3EEFF);
const Color kCmGreen = Color(0xFF22C55E); // Đang nuôi / Khỏe mạnh
const Color kCmGreenLight = Color(0xFFDCFCE7);
const Color kCmTeal = Color(0xFF0D9488); // Sắp thu hoạch
const Color kCmTealLight = Color(0xFFCCFBF1);
const Color kCmSlate = Color(0xFF64748B); // Đã thu hoạch / unknown
const Color kCmSlateBg = Color(0xFFEEF2F6);

const Color kCmShadow = Color(0x14000000);

BoxDecoration cmCardDecoration({double radius = 14}) => BoxDecoration(
  color: kCmSurface,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: kCmBorder),
  boxShadow: const [
    BoxShadow(color: kCmShadow, blurRadius: 10, offset: Offset(0, 3)),
  ],
);
