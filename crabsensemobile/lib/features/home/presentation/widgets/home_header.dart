import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';

// Palette theo ảnh thiết kế: xanh dương (azure) trên nền navy đậm.
const Color _kBlue = Color(0xFF2F80FF);
const Color _kBlueLight = Color(0xFF6FB0FF);
const Color _kNavyDeep = Color(0xFF081A36);
const Color _kNavy = Color(0xFF0C2348);
const Color _kNavyLift = Color(0xFF123061);
const Color _kBorderBlue = Color(0xFF3E6FB8);

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
      return 'Chào buổi sáng!';
    }
    if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều!';
    }
    return 'Chào buổi tối!';
  }

  void _showFarmSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kNavyLift, _kNavy, _kNavyDeep],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: _kBorderBlue.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Họa tiết lưới khay nuôi + cua (đồng bộ trang home)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CrabHologramPainter(
                      color: _kBlueLight.withValues(alpha: 0.08),
                      trayExtent: 28,
                    ),
                  ),
                ),
              ),
              // Vệt sáng cạnh trên
              Positioned(
                top: 0,
                left: 32,
                right: 32,
                height: 1,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _kBlueLight.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                            color: _kBorderBlue.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Pin phát sáng như thanh chọn trại
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kBlue.withValues(alpha: 0.14),
                              border: Border.all(
                                color: _kBlue.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kBlue.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: _kBlue,
                              size: 20,
                              shadows: [
                                Shadow(
                                  color: _kBlue.withValues(alpha: 0.9),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHỌN TRANG TRẠI ĐIỀU HÀNH',
                                  style: TextStyle(
                                    color: _kBlueLight,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${data.availableFarms.length} khu vực khả dụng',
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
        Stack(
          children: [
            // Họa tiết khay nuôi + cua mờ phía sau hàng chào/avatar
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CrabHologramPainter(
                    color: _kBlueLight.withValues(alpha: 0.09),
                  ),
                ),
              ),
            ),
            _buildTopRow(context, unreadCount: unread),
          ],
        ),
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
                      color: _kBlue,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: _kNavy,
                    child: Text(
                      'OP',
                      style: TextStyle(
                        color: _kBlueLight,
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
                              : 'Chủ trại',
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
                          content: Text('Tìm kiếm sẽ sớm có mặt'),
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

/// Item chọn trại trong bottom sheet: pin phát sáng + tên trại,
/// item đang chọn có viền + glow xanh và nhãn "Đang điều hành".
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
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _kBlue.withValues(alpha: 0.22),
                        _kBlue.withValues(alpha: 0.08),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kNavyLift, _kNavyDeep],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _kBlue.withValues(alpha: 0.9)
                    : _kBorderBlue.withValues(alpha: 0.4),
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kBlue.withValues(alpha: 0.35),
                        blurRadius: 14,
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
                        ? _kBlue.withValues(alpha: 0.18)
                        : _kNavy.withValues(alpha: 0.8),
                    border: Border.all(
                      color: isSelected
                          ? _kBlue.withValues(alpha: 0.6)
                          : _kBorderBlue.withValues(alpha: 0.4),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _kBlue.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isSelected ? _kBlue : CrabSenseColors.hintText,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: _kBlue.withValues(alpha: 0.9),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
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
                              ? Colors.white
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
                          'Đang điều hành',
                          style: TextStyle(
                            color: _kBlueLight,
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
                    color: _kBlue,
                    size: 22,
                    shadows: [
                      Shadow(
                        color: _kBlue.withValues(alpha: 0.8),
                        blurRadius: 10,
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: CrabSenseColors.hintText.withValues(alpha: 0.7),
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

/// Nút đóng tròn nhỏ trong bottom sheet.
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
            color: _kNavy.withValues(alpha: 0.9),
            border: Border.all(
              color: _kBorderBlue.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: CrabSenseColors.hintText,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Pill chọn trại theo ảnh: nền navy gradient, viền xanh dương sáng nhẹ,
/// pin định vị xanh phát sáng + watermark cua mờ bên phải.
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
              colors: [_kNavy, _kNavyDeep, Color(0xFF0B2144)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _kBorderBlue.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Vầng sáng xanh lan ra từ khu vực pin (bên trái, như ảnh)
              Positioned(
                left: -18,
                top: -18,
                bottom: -18,
                width: 110,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _kBlue.withValues(alpha: 0.28),
                          _kBlue.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Nền: lưới khay nuôi isometric, mỗi khay một con cua,
              // cua lớn phát sáng ở giữa-phải (mờ dần về trái để lộ chữ)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CrabHologramPainter(
                      color: _kBlueLight.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
              // Highlight nhẹ ở cạnh trên (ánh sáng như ảnh)
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                height: 1,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _kBlueLight.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Pin + tên trại + chevron
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Quầng glow phía sau pin
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _kBlue.withValues(alpha: 0.45),
                                    _kBlue.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                              child: const SizedBox.expand(),
                            ),
                            // Lõi sáng hiện qua lỗ tròn của pin
                            Transform.translate(
                              offset: const Offset(0, -2.5),
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kBlueLight,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.location_on_rounded,
                              color: _kBlue,
                              size: 26,
                              shadows: [
                                Shadow(
                                  color: _kBlue.withValues(alpha: 0.95),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          farmName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.1,
                            height: 1.0,
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
            color: _kNavy.withValues(alpha: 0.9),
            border: Border.all(
              color: _kBorderBlue.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.22),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: CrabSenseColors.textPrimary, size: 20),
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
        ),
      ),
    );
  }
}
