import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Menu tile hologram cho tab Tài khoản.
/// Layout dọc cho value/subtitle để hiện đủ chữ, không tràn ngang.
class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? valueText;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isDestructive;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueText,
    this.trailing,
    this.iconColor,
    this.titleColor,
    this.onTap,
    this.showDivider = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDestructive
        ? const Color(0xFFFF6B6B)
        : (iconColor ?? Colors.white70);

    final effectiveTitleColor = isDestructive
        ? const Color(0xFFFF6B6B)
        : (titleColor ?? Colors.white);

    return Column(
      children: [
        Semantics(
          label: '$title ${subtitle ?? ''} ${valueText ?? ''}',
          button: onTap != null,
          enabled: onTap != null,
          child: InkWell(
            onTap: onTap,
            splashColor: kHomeCyan.withValues(alpha: 0.12),
            highlightColor: kHomeNavyLift.withValues(alpha: 0.4),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 20, color: effectiveIconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: effectiveTitleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (valueText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            valueText!,
                            style: const TextStyle(
                              color: kHomeCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ] else if (onTap != null && !isDestructive) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Divider(
              color: kHomeBorderBlue.withValues(alpha: 0.2),
              height: 1,
            ),
          ),
      ],
    );
  }
}
