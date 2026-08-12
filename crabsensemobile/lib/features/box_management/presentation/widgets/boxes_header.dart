import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../../notifications/presentation/providers/unread_notifications_provider.dart';
import '../../domain/models/boxes_models.dart';

/// Header tab Boxes — đồng bộ phong cách hologram trang home.
class BoxesHeader extends ConsumerWidget {
  const BoxesHeader({
    required this.data,
    required this.onFarmSwitched,
    required this.onSearchPressed,
    required this.onFilterPressed,
    required this.onViewModePressed,
    this.onNotificationPressed,
    super.key,
  });

  final BoxesStateData data;
  final ValueChanged<String> onFarmSwitched;
  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onViewModePressed;
  final VoidCallback? onNotificationPressed;

  void _showFarmSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: kHomeBlue.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CrabHologramPainter(
                      color: kHomeBlueLight.withValues(alpha: 0.08),
                      trayExtent: 28,
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
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kHomeBorderBlue.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: kHomeBlue.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kHomeBlue.withValues(alpha: 0.14),
                              border: Border.all(
                                color: kHomeBlue.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kHomeBlue.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: kHomeBlue,
                              size: 20,
                              shadows: [
                                Shadow(
                                  color: kHomeBlue.withValues(alpha: 0.9),
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
                                  'CHỌN KHU NUÔI',
                                  style: TextStyle(
                                    color: kHomeBlueLight,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${data.availableFarms.length} khu vực khả dụng',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(18),
                              child: Ink(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kHomeNavy.withValues(alpha: 0.9),
                                  border: Border.all(
                                    color: kHomeBorderBlue.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: data.availableFarms.length,
                          itemBuilder: (_, i) {
                            final farm = data.availableFarms[i];
                            final selected = farm.id == data.selectedFarmId;
                            return _FarmOptionTile(
                              name: farm.name,
                              isSelected: selected,
                              onTap: () {
                                Navigator.pop(ctx);
                                if (!selected) onFarmSwitched(farm.id);
                              },
                            );
                          },
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
    final unread =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 20,
              color: kHomeBlueLight,
              shadows: [
                Shadow(
                  color: kHomeBlueLight.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'BOXES',
                  style: TextStyle(
                    color: kHomeBlueLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _OnlineChip(isOnline: data.isOnline && !data.isOfflineCached),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${data.overview.total} hộp nuôi · Digital Twin',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FarmSelectorBar(
                farmName: data.selectedFarmName,
                onTap: () => _showFarmSelector(context),
              ),
            ),
            const SizedBox(width: 8),
            _HeaderIconButton(
              icon: Icons.search_rounded,
              tooltip: 'Tìm kiếm',
              onPressed: onSearchPressed,
            ),
            _HeaderIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Bộ lọc nâng cao',
              onPressed: onFilterPressed,
              badge: data.advancedFilter.hasActiveAdvancedFilters,
            ),
            _HeaderIconButton(
              icon: data.viewMode == BoxesViewMode.grid
                  ? Icons.grid_view_rounded
                  : data.viewMode == BoxesViewMode.list
                      ? Icons.view_list_rounded
                      : Icons.map_rounded,
              tooltip: 'Chế độ hiển thị',
              onPressed: onViewModePressed,
            ),
            if (onNotificationPressed != null)
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Thông báo',
                onPressed: onNotificationPressed!,
                countBadge: unread > 0
                    ? (unread > 99 ? '99+' : '$unread')
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

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
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: kHomeBlueLight.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: kHomeBlue.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CrabHologramPainter(
                        color: kHomeBlueLight.withValues(alpha: 0.07),
                        trayExtent: 22,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kHomeBlue.withValues(alpha: 0.18),
                          boxShadow: [
                            BoxShadow(
                              color: kHomeBlue.withValues(alpha: 0.55),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: kHomeBlue,
                          shadows: [
                            Shadow(
                              color: kHomeBlue.withValues(alpha: 0.95),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          farmName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: kHomeBlueLight.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        kHomeBlue.withValues(alpha: 0.22),
                        kHomeBlue.withValues(alpha: 0.08),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kHomeNavyLift, kHomeNavyDeep],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? kHomeBlue.withValues(alpha: 0.9)
                    : kHomeBorderBlue.withValues(alpha: 0.4),
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: kHomeBlue.withValues(alpha: 0.35),
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
                        ? kHomeBlue.withValues(alpha: 0.18)
                        : kHomeNavy.withValues(alpha: 0.8),
                    border: Border.all(
                      color: isSelected
                          ? kHomeBlue.withValues(alpha: 0.6)
                          : kHomeBorderBlue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isSelected
                        ? kHomeBlue
                        : Colors.white.withValues(alpha: 0.45),
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
                          color: Colors.white,
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
                            color: kHomeBlueLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: isSelected
                      ? kHomeBlue
                      : Colors.white.withValues(alpha: 0.4),
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

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? kHomeGreen : kHomeOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = false,
    this.countBadge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool badge;
  final String? countBadge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: kHomeBlueLight, size: 20),
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              backgroundColor: kHomeNavyDeep.withValues(alpha: 0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: kHomeBorderBlue.withValues(alpha: 0.55),
                ),
              ),
              shadowColor: kHomeBlue.withValues(alpha: 0.22),
              elevation: 2,
            ),
          ),
          if (countBadge != null)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.55),
                      blurRadius: 6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  countBadge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            )
          else if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kHomeBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kHomeBlue.withValues(alpha: 0.7),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
