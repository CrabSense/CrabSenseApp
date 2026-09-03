import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/dashboard_theme.dart';

/// Logo / mascot Crab Assistant (ảnh chibi trong suốt).
class AiAssistantAvatar extends StatelessWidget {
  const AiAssistantAvatar({
    super.key,
    this.size = 48,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.background,
    this.borderRadius,
  });

  static const asset = 'assets/images/ai_assistant_mascot.png';

  final double size;
  final BoxFit fit;
  final EdgeInsets padding;
  final Color? background;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.2);

    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.smart_toy_outlined,
          size: size * 0.55,
          color: DashboardColors.purple,
        ),
      ),
    );
  }
}

/// Hàng tiêu đề chuẩn: logo + tên + phụ đề (tùy chọn).
class AiAssistantHeader extends StatelessWidget {
  const AiAssistantHeader({
    super.key,
    this.title = 'Crab Assistant',
    this.subtitle,
    this.avatarSize = 52,
    this.titleStyle,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final double avatarSize;
  final TextStyle? titleStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AiAssistantAvatar(
          size: avatarSize,
          padding: const EdgeInsets.all(2),
          background: DashboardColors.purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null && subtitle!.toUpperCase() == subtitle)
                Text(
                  subtitle!,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              if (subtitle != null && subtitle!.toUpperCase() == subtitle)
                const SizedBox(height: 2),
              Text(
                title,
                style: titleStyle ??
                    GoogleFonts.notoSans(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : 14,
                    ),
              ),
              if (subtitle != null && subtitle!.toUpperCase() != subtitle) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
