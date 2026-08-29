import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../domain/models/home_models.dart';

// Light theme palette — xanh lá tuoi, n?n tr?ng/xám nh?t
const Color _kPrimary    = Color(0xFF2ECC71);
const Color _kPrimaryDk  = Color(0xFF27AE60);
const Color _kPrimaryBg  = Color(0xFFE8F8F0);
const Color _kSecondary  = Color(0xFF1A9CD8);
const Color _kBorder     = Color(0xFFDDE4EB);
const Color _kSurface    = Color(0xFFFFFFFF);
const Color _kBg         = Color(0xFFF5F7FA);
const Color _kShadow     = Color(0x14000000);
// Keep old names as aliases to avoid any missed references
const Color _kBlue       = Color(0xFF1A9CD8);
const Color _kBlueLight  = Color(0xFF1A9CD8);
const Color _kNavyDeep   = Color(0xFF1A2E3B);
const Color _kNavy       = Color(0xFF1A2E3B);
const Color _kNavyLift   = Color(0xFF2ECC71);
const Color _kBorderBlue = Color(0xFFDDE4EB);

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    required this.data,
    required this.onFarmSwitched,
    required this.onNotificationPressed,
    this.onSearchPressed,
    this.onMenuPressed,
    super.key,
  });

  final HomeStateData data;
  final Function(String farmId) onFarmSwitched;
  final VoidCallback onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onMenuPressed;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Chào bu?i sáng!';
    }
    if (hour >= 12 && hour < 18) {
      return 'Chào bu?i chi?u!';
    }
    return 'Chào bu?i t?i!';
  }

  void _showFarmSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: _kBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: _kShadow,
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thanh kéo
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _kBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Pin icon for farm selector
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kPrimaryBg,
                              border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: _kPrimaryDk,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CH?N TRANG TR?I ÐI?U HÀNH',
                                  style: TextStyle(
                                    color: _kPrimaryDk,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${data.availableFarms.length} khu v?c kh? d?ng',
                                  style: const TextStyle(
                                    color: CrabSenseColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _SheetCloseButton(onTap: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: data.availableFarms.map((farm) {
                              final isSelected =
                                  farm.id == data.selectedFarmId ||
                                      (data.selectedFarmId == null &&
                                          farm.name == data.selectedFarmName);
                              return _FarmOptionTile(
                                name: farm.name,
                                isSelected: isSelected,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onFarmSwitched(farm.id);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiUnread = ref.watch(unreadNotificationsCountProvider).valueOrNull;
    final unread = apiUnread ?? data.unreadNotificationsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(context, unreadCount: unread),
        const SizedBox(height: 14),
        // Farm selector — neon left-edge + wireframe (matches design ref)
        _FarmSelectorBar(
          farmName: data.selectedFarmName,
          onTap: () => _showFarmSelector(context),
        ),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context, {required int unreadCount}) {
    final greeting = _getGreeting();
    final isOnline = data.isOnline && !data.isOfflineCached;
    final onlineColor =
        isOnline ? CrabSenseColors.success : CrabSenseColors.warning;

    return Row(
          children: [
            // Avatar with cyan glow ring + online dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _kPrimary,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: _kPrimaryBg,
                    child: Text(
                      'OP',
                      style: TextStyle(
                        color: _kPrimaryDk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: onlineColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CrabSenseColors.background,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: onlineColor.withValues(alpha: 0.7),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: CrabSenseColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.operatorName.isNotEmpty
                              ? data.operatorName
                              : 'Ch? tr?i',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CrabSenseColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: onlineColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: onlineColor.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: onlineColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _HeaderActionButton(
              icon: Icons.search_rounded,
              onPressed: onSearchPressed ??
                  () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tìm ki?m s? s?m có m?t'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
            ),
            const SizedBox(width: 8),
            _HeaderActionButton(
              icon: Icons.notifications_outlined,
              badge: unreadCount > 0
                  ? '${unreadCount > 99 ? '99+' : unreadCount}'
                  : null,
              onPressed: onNotificationPressed,
            ),
            const SizedBox(width: 8),
            _HeaderActionButton(
              icon: Icons.menu_rounded,
              onPressed: onMenuPressed ??
                  () => context.push(RoutePaths.profile),
            ),
          ],
        );
  }
}

/// Item ch?n tr?i trong bottom sheet: pin phát sáng + tên tr?i,
/// item dang ch?n có vi?n + glow xanh và nhãn "Ðang di?u hành".
class _FarmOptionTile extends StatelessWidget {
  const _FarmOptionTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kPrimary.withValues(alpha: 0.10)
                  : _kBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _kPrimary.withValues(alpha: 0.8)
                    : _kBorder,
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? _kPrimary.withValues(alpha: 0.15)
                        : _kBg,
                    border: Border.all(
                      color: isSelected
                          ? _kPrimary.withValues(alpha: 0.6)
                          : _kBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isSelected ? _kPrimaryDk : CrabSenseColors.textHint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                              ? _kPrimaryDk
                              : CrabSenseColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Ðang di?u hành',
                          style: TextStyle(
                            color: _kPrimaryDk,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: _kPrimary,
                    size: 22,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: CrabSenseColors.textHint,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút dóng tròn nh? trong bottom sheet.
class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBg,
            border: Border.all(
              color: _kBorder,
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: CrabSenseColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Pill ch?n tr?i theo ?nh: n?n navy gradient, vi?n xanh duong sáng nh?,
/// pin d?nh v? xanh phát sáng + watermark cua m? bên ph?i.
class _FarmSelectorBar extends StatelessWidget {
  const _FarmSelectorBar({
    required this.farmName,
    required this.onTap,
  });

  final String farmName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Color(0xFF27AE60),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x282ECC71),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Pin + tên tr?i + chevron
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          farmName,
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.1, height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFDDE4EB),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x142ECC71),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1A2E3B), size: 20),
              if (badge != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: CrabSenseColors.danger,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: CrabSenseColors.danger.withValues(alpha: 0.55),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      badge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, height: 1.35,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
