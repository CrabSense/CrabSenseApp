import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Section card hologram cho tab Tài khoản.
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
      decoration: homeCardDecoration(radius: 16, glowAlpha: 0.1),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HomeCrabWatermark(alpha: 0.04, trayExtent: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: kHomeBlue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kHomeBorderBlue.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(icon, size: 18, color: kHomeBlueLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: kHomeBlueLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null || trailingBadge != null) ...[
                      const SizedBox(height: 8),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      if (trailingBadge != null) ...[
                        if (subtitle != null) const SizedBox(height: 6),
                        trailingBadge!,
                      ],
                    ],
                  ],
                ),
              ),
              Divider(
                color: kHomeBorderBlue.withValues(alpha: 0.25),
                height: 1,
              ),
              ...children,
            ],
          ),
        ],
      ),
    );
  }
}
