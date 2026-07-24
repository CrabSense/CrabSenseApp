import 'package:flutter/material.dart';

import 'crab_hologram_painter.dart';

/// Palette + thành phần dùng chung cho các section trang home,
/// đồng bộ với header và card Tổng quan vận hành.
const Color kHomeBlue = Color(0xFF2F80FF);
const Color kHomeBlueLight = Color(0xFF6FB0FF);
const Color kHomeCyan = Color(0xFF3DDCFF);
const Color kHomeNavyDeep = Color(0xFF081A36);
const Color kHomeNavy = Color(0xFF0C2348);
const Color kHomeNavyLift = Color(0xFF123061);
const Color kHomeBorderBlue = Color(0xFF3E6FB8);
const Color kHomeGreen = Color(0xFF2ECC71);
const Color kHomePurple = Color(0xFF8B5CF6);
const Color kHomeOrange = Color(0xFFFFA53E);

/// Khung card navy gradient chuẩn của trang home.
/// [accent] đổi màu viền/glow (mặc định xanh dương).
BoxDecoration homeCardDecoration({
  Color? accent,
  double radius = 20,
  double glowAlpha = 0.18,
}) {
  final a = accent ?? kHomeBorderBlue;
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: a.withValues(alpha: 0.5)),
    boxShadow: [
      BoxShadow(
        color: kHomeBlue.withValues(alpha: glowAlpha),
        blurRadius: 18,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Nền phẳng hơn cho các ô/danh sách con nằm trong card.
BoxDecoration homeTileDecoration({
  Color? accent,
  double radius = 14,
}) {
  final a = accent ?? kHomeBorderBlue;
  return BoxDecoration(
    color: kHomeNavyDeep.withValues(alpha: 0.75),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: a.withValues(alpha: 0.4)),
  );
}

/// Watermark cua hologram — đặt trong [Stack] (tự [Positioned.fill]).
class HomeCrabWatermark extends StatelessWidget {
  const HomeCrabWatermark({
    super.key,
    this.alpha = 0.06,
    this.trayExtent = 26,
  });

  final double alpha;
  final double? trayExtent;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: CrabHologramPainter(
            color: kHomeBlueLight.withValues(alpha: alpha),
            trayExtent: trayExtent,
          ),
        ),
      ),
    );
  }
}

/// Vệt sáng mảnh ở cạnh trên card (đặt trong Stack với Positioned).
class HomeTopEdgeGlow extends StatelessWidget {
  const HomeTopEdgeGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 24,
      right: 24,
      height: 1,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  kHomeBlueLight.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
          ),
        ),
      ),
    );
  }
}

/// Header section thống nhất: icon phát sáng + tiêu đề in hoa xanh sáng
/// + nút hành động bên phải.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.icon,
    required this.title,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? kHomeBlueLight;
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: ic,
          shadows: [
            Shadow(color: ic.withValues(alpha: 0.8), blurRadius: 10),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: kHomeBlueLight,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 12.5,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: kHomeBlueLight,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 17),
              ],
            ),
          ),
      ],
    );
  }
}
