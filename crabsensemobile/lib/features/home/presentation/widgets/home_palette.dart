import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ── Color tokens — Neofarm lime/forest, cùng layout Home cũ ─────────
const Color kHomePrimary     = CrabSenseColors.primary;
const Color kHomePrimaryDark = CrabSenseColors.primaryDark;
const Color kHomePrimaryBg   = CrabSenseColors.primaryLight;
const Color kHomeSecondary   = CrabSenseColors.secondary;
const Color kHomeSecondaryBg = CrabSenseColors.secondaryLight;
const Color kHomeSurface     = CrabSenseColors.surface;
const Color kHomeBg          = CrabSenseColors.background;
const Color kHomeBorder      = CrabSenseColors.border;
const Color kHomeTextMain    = CrabSenseColors.textPrimary;
const Color kHomeTextSub     = CrabSenseColors.textSecondary;
const Color kHomeTextHint    = CrabSenseColors.textHint;
const Color kHomeWarning     = CrabSenseColors.warning;
const Color kHomeWarningBg   = CrabSenseColors.warningLight;
const Color kHomeDanger      = CrabSenseColors.danger;
const Color kHomeDangerBg    = CrabSenseColors.dangerLight;

/// Tím cho cua đang lột (quy ước: lột = tím) — dùng chung thẻ hộp và chi tiết cua.
const Color kHomeMolt        = CrabSenseColors.molt;
const Color kHomeMoltBg      = CrabSenseColors.moltLight;
const Color kHomeInfo        = CrabSenseColors.teal;
const Color kHomeInfoBg      = CrabSenseColors.secondaryLight;
const Color kHomeShadow      = CrabSenseColors.shadow;

const Color kHomeBlue        = CrabSenseColors.secondary;
const Color kHomeBlueLight   = CrabSenseColors.teal;
const Color kHomeCyan        = CrabSenseColors.teal;
const Color kHomeBorderBlue  = CrabSenseColors.border;
const Color kHomeGreen       = CrabSenseColors.primaryDark;
const Color kHomePurple      = Color(0xFF9B59B6);
const Color kHomeOrange      = CrabSenseColors.warning;
const Color kHomeNavyDeep    = CrabSenseColors.background;
const Color kHomeNavy        = CrabSenseColors.background;
const Color kHomeNavyLift    = CrabSenseColors.primaryLight;

BoxDecoration homeCardDecoration({Color? accent, double radius = 20, double glowAlpha = 0.06}) {
  return BoxDecoration(
    color: kHomeSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kHomeBorder),
    boxShadow: [BoxShadow(color: kHomeShadow, blurRadius: 12, offset: const Offset(0, 4))],
  );
}

BoxDecoration homeTileDecoration({Color? accent, double radius = 14}) {
  return BoxDecoration(
    color: CrabSenseColors.surfaceAlt,
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
          decoration: BoxDecoration(color: kHomePrimaryBg, borderRadius: BorderRadius.circular(12)),
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
