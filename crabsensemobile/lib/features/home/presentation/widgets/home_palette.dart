import 'package:flutter/material.dart';

// ── Color tokens — Light, thân thiện với nông dân ─────────────────
const Color kHomePrimary     = Color(0xFF1E8449);
const Color kHomePrimaryDark = Color(0xFF1E8449);
const Color kHomePrimaryBg   = Color(0xFFD5F5E3);
const Color kHomeSecondary   = Color(0xFF1A7FC1);
const Color kHomeSecondaryBg = Color(0xFFD6EFF9);
const Color kHomeSurface     = Color(0xFFFFFFFF);
const Color kHomeBg          = Color(0xFFF0F3F7);
const Color kHomeBorder      = Color(0xFFDDE4EB);
const Color kHomeTextMain    = Color(0xFF1A2E3B);
const Color kHomeTextSub     = Color(0xFF5A7184);
const Color kHomeTextHint    = Color(0xFF9DB3C2);
const Color kHomeWarning     = Color(0xFFF39C12);
const Color kHomeWarningBg   = Color(0xFFFEF5E7);
const Color kHomeDanger      = Color(0xFFE74C3C);
const Color kHomeDangerBg    = Color(0xFFFDECEC);
const Color kHomeInfo        = Color(0xFF3498DB);
const Color kHomeInfoBg      = Color(0xFFD6EFF9);
const Color kHomeShadow      = Color(0x14000000);

// Legacy aliases — tương thích với code cũ
const Color kHomeBlue        = Color(0xFF1A7FC1);
const Color kHomeBlueLight   = Color(0xFF3498DB);
const Color kHomeCyan        = Color(0xFF00B4A0);
const Color kHomeBorderBlue  = Color(0xFFDDE4EB);
const Color kHomeGreen       = Color(0xFF1E8449);
const Color kHomePurple      = Color(0xFF9B59B6);
const Color kHomeOrange      = Color(0xFFF39C12);
// Old dark aliases mapped to light equivalents
const Color kHomeNavyDeep    = Color(0xFFF0F3F7);
const Color kHomeNavy        = Color(0xFFF0F3F7);
const Color kHomeNavyLift    = Color(0xFFF0F3F7);

/// Card decoration — trắng, viền nhạt, shadow mềm
BoxDecoration homeCardDecoration({Color? accent, double radius = 12, double glowAlpha = 0.06}) {
  return BoxDecoration(
    color: kHomeSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kHomeBorder),
    boxShadow: [BoxShadow(color: kHomeShadow, blurRadius: 8, offset: const Offset(0, 2))],
  );
}

BoxDecoration homeTileDecoration({Color? accent, double radius = 8}) {
  return BoxDecoration(
    color: const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kHomeBorder),
  );
}

class HomeCrabWatermark extends StatelessWidget {
  const HomeCrabWatermark({super.key, this.alpha = 0.04, this.trayExtent});
  final double alpha;
  final double? trayExtent;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class HomeTopEdgeGlow extends StatelessWidget {
  const HomeTopEdgeGlow({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.icon, required this.title,
    this.iconColor, this.actionLabel, this.onAction, super.key,
  });
  final IconData icon;
  final String title;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? kHomePrimaryDark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: kHomePrimaryBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: ic),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kHomeTextMain))),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: kHomePrimaryDark, padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right_rounded, size: 16),
            ]),
          ),
      ],
    );
  }
}
