import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable Profile Menu Tile Item
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
        ? CrabSenseColors.danger
        : (iconColor ?? CrabSenseColors.textSecondary);

    final effectiveTitleColor = isDestructive
        ? CrabSenseColors.danger
        : (titleColor ?? CrabSenseColors.textPrimary);

    return Column(
      children: [
        Semantics(
          label: '$title ${subtitle ?? ''} ${valueText ?? ''}',
          button: onTap != null,
          enabled: onTap != null,
          child: InkWell(
            onTap: onTap,
            splashColor: CrabSenseColors.primary.withValues(alpha: 0.1),
            highlightColor: CrabSenseColors.surface,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: effectiveIconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: effectiveTitleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: CrabSenseColors.hintText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (valueText != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      valueText!,
                      style: const TextStyle(
                        color: CrabSenseColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ] else if (onTap != null && !isDestructive) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: CrabSenseColors.hintText,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 50),
            child: Divider(color: CrabSenseColors.divider, height: 1),
          ),
      ],
    );
  }
}
