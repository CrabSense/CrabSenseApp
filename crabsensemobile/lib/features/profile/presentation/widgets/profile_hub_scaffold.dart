import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';

/// Shared hologram shell for Profile child hubs (settings, help, sync, …).
class ProfileHubScaffold extends StatelessWidget {
  const ProfileHubScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onRefresh,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = body;
    return Scaffold(
      backgroundColor: kHomeNavyDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.05),
                  trayExtent: 32,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: kHomeBlueLight,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: kHomeBlueLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...?actions,
                    ],
                  ),
                ),
                Expanded(
                  child: onRefresh == null
                      ? content
                      : RefreshIndicator(
                          color: kHomeCyan,
                          backgroundColor: kHomeNavyLift,
                          onRefresh: onRefresh!,
                          child: content,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card block used inside hub screens.
class HubCard extends StatelessWidget {
  const HubCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: homeCardDecoration(radius: 16, glowAlpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HomeCrabWatermark(alpha: 0.05, trayExtent: 18),
          Padding(
            padding: padding ?? const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: kHomeCyan, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (value != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            value!,
                            style: const TextStyle(
                              color: kHomeCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: kHomeBorderBlue.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}
