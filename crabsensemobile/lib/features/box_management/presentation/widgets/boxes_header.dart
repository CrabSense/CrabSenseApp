import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/boxes_models.dart';

class BoxesHeader extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Boxes',
                    style: TextStyle(
                      color: CrabSenseColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    onSelected: onFarmSwitched,
                    color: CrabSenseColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: CrabSenseColors.border),
                    ),
                    itemBuilder: (context) => data.availableFarms
                        .map(
                          (f) => PopupMenuItem(
                            value: f.id,
                            child: Text(
                              f.name,
                              style: TextStyle(
                                color: f.id == data.selectedFarmId
                                    ? CrabSenseColors.primary
                                    : CrabSenseColors.textPrimary,
                                fontWeight: f.id == data.selectedFarmId
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            data.selectedFarmName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CrabSenseColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: CrabSenseColors.hintText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.overview.total} Boxes',
                    style: const TextStyle(
                      color: CrabSenseColors.hintText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _OnlineChip(isOnline: data.isOnline && !data.isOfflineCached),
            const SizedBox(width: 6),
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
              ),
          ],
        ),
      ],
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? CrabSenseColors.success : CrabSenseColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: CrabSenseColors.textSecondary),
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: CrabSenseColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CrabSenseColors.border),
              ),
            ),
          ),
          if (badge)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: CrabSenseColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
