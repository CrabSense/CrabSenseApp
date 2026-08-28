import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../features/alert/presentation/providers/alerts_provider.dart';
import 'routes.dart';

/// Bottom Navigation Bar — trắng, icon xanh lá khi active, shadow nhẹ
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.child, super.key});
  final Widget child;

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(RoutePaths.dashboard)) return 0;
    if (path.startsWith(RoutePaths.boxes) || path.startsWith('/box')) return 1;
    if (path.startsWith(RoutePaths.scanner)) return 2;
    if (path.startsWith(RoutePaths.alerts)) return 3;
    if (path.startsWith(RoutePaths.profile)) return 4;
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0: context.go(RoutePaths.dashboard);
      case 1: context.go(RoutePaths.boxes);
      case 2: context.go(RoutePaths.scanner);
      case 3: context.go(RoutePaths.alerts);
      case 4: context.go(RoutePaths.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _selectedIndex(context);
    final badgeCount = ref.watch(alertsBadgeCountProvider);

    return Scaffold(
      backgroundColor: CrabSenseColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CrabSenseColors.navBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Trang chủ', index: 0, selectedIndex: idx, onTap: (i) => _onTap(i, context)),
                _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Hộp nuôi', index: 1, selectedIndex: idx, onTap: (i) => _onTap(i, context)),
                _QrNavItem(index: 2, selectedIndex: idx, onTap: (i) => _onTap(i, context)),
                _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Cảnh báo', index: 3, selectedIndex: idx, onTap: (i) => _onTap(i, context), badge: badgeCount > 0 ? (badgeCount > 99 ? '99+' : '$badgeCount') : ''),
                _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Thêm', index: 4, selectedIndex: idx, onTap: (i) => _onTap(i, context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.badge = '',
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    final color = isActive ? CrabSenseColors.navActive : CrabSenseColors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, size: 24, color: color),
                if (badge.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: CrabSenseColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab quét QR — nút tròn nổi bật ở giữa
class _QrNavItem extends StatelessWidget {
  const _QrNavItem({required this.index, required this.selectedIndex, required this.onTap});
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive ? CrabSenseColors.primary : CrabSenseColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CrabSenseColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.qr_code_scanner_rounded, size: 22, color: isActive ? Colors.white : CrabSenseColors.primaryDark),
            ),
            const SizedBox(height: 1),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Quét QR',
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? CrabSenseColors.navActive : CrabSenseColors.navInactive,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
