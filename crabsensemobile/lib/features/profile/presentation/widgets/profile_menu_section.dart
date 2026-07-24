import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable Section Card Container for Profile Categories
class ProfileMenuSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailingBadge;
  final List<Widget> children;

  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailingBadge,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.border, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: CrabSenseColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: CrabSenseColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: CrabSenseColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
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
                if (trailingBadge != null) trailingBadge!,
              ],
            ),
          ),
          const Divider(color: CrabSenseColors.divider, height: 1),
          // List of Tiles
          ...children,
        ],
      ),
    );
  }
}
