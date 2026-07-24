import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart' as tokens;
import '../features/alert/presentation/providers/alerts_provider.dart';
import 'routes.dart';
import 'theme.dart';

/// Shell scaffold providing persistent Bottom Navigation Bar across main app tabs.
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RoutePaths.dashboard)) {
      return 0;
    }
    if (location.startsWith(RoutePaths.boxes)) {
      return 1;
    }
    if (location.startsWith(RoutePaths.scanner)) {
      return 2;
    }
    if (location.startsWith(RoutePaths.alerts)) {
      return 3;
    }
    if (location.startsWith(RoutePaths.profile)) {
      return 4;
    }
    if (location.startsWith('/box')) {
      return 1;
    }
    if (location.startsWith(RoutePaths.waterQuality) ||
        location.startsWith(RoutePaths.operations) ||
        location.startsWith(RoutePaths.harvest) ||
        location.startsWith(RoutePaths.sales)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RoutePaths.dashboard);
      case 1:
        context.go(RoutePaths.boxes);
      case 2:
        context.go(RoutePaths.scanner);
      case 3:
        context.go(RoutePaths.alerts);
      case 4:
        context.go(RoutePaths.profile);
    }
  }

  String _badgeLabel(int count) {
    if (count <= 0) {
      return '';
    }
    if (count > 99) {
      return '99+';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final badgeCount = ref.watch(alertsBadgeCountProvider);
    final badge = _badgeLabel(badgeCount);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: CrabSenseColors.background,
      body: child,
      bottomNavigationBar: _CyberNavBar(
        selectedIndex: selectedIndex,
        badge: badge,
        bottomInset: bottomInset,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}

/// Cyber glass bottom nav — active glow tile + neon QR orb (matches design).
class _CyberNavBar extends StatelessWidget {
  const _CyberNavBar({
    required this.selectedIndex,
    required this.badge,
    required this.bottomInset,
    required this.onTap,
  });

  final int selectedIndex;
  final String badge;
  final double bottomInset;
  final ValueChanged<int> onTap;

  static const double _barHeight = 72;
  static const double _orbSize = 48;

  static const _inactive = Color(0xFF8AA3C4);
  static const _active = Color(0xFF4D9AFF);

  static const _items = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Boxes',
    ),
    _NavItem(
      icon: Icons.qr_code_scanner_rounded,
      activeIcon: Icons.qr_code_scanner_rounded,
      label: 'Quét QR',
      isCenter: true,
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Tài khoản',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF061224),
        border: Border(
          top: BorderSide(color: _active.withValues(alpha: 0.25)),
        ),
        boxShadow: [
          BoxShadow(
            color: _active.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(6, 8, 6, 8 + bottomInset),
      child: SizedBox(
        height: _barHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0C2348).withValues(alpha: 0.95),
                    const Color(0xFF081A36).withValues(alpha: 0.98),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF3E6FB8).withValues(alpha: 0.32),
                ),
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  if (item.isCenter) {
                    return Expanded(
                      child: _QrTab(
                        size: _orbSize,
                        label: item.label,
                        selected: selectedIndex == 2,
                        activeColor: _active,
                        inactiveColor: _inactive,
                        onTap: () => onTap(2),
                      ),
                    );
                  }
                  return Expanded(
                    child: _NavTab(
                      item: item,
                      selected: selectedIndex == index,
                      badge: index == 3 ? badge : '',
                      activeColor: _active,
                      inactiveColor: _inactive,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.badge,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final String badge;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: activeColor.withValues(alpha: 0.12),
        child: SizedBox(
          height: _CyberNavBar._barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Active glow tile (like design ref)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? activeColor.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.45),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                      border: selected
                          ? Border.all(
                              color: activeColor.withValues(alpha: 0.35),
                            )
                          : null,
                    ),
                  ),
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: tokens.CrabSenseColors.danger,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF061224),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          badge,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrTab extends StatelessWidget {
  const _QrTab({
    required this.size,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final double size;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: _CyberNavBar._barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.25, -0.35),
                    radius: 0.95,
                    colors: [
                      Color(0xFF7FB8FF),
                      Color(0xFF2F80FF),
                      Color(0xFF1B4FA8),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F80FF).withValues(
                        alpha: selected ? 0.75 : 0.55,
                      ),
                      blurRadius: selected ? 22 : 16,
                      spreadRadius: selected ? 1 : 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF2F80FF).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
