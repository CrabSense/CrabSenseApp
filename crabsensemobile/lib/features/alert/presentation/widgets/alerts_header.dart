import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/alerts_models.dart';

/// Glassmorphism Alerts header — neon cyan tabs matching CrabSense cyber UI.
class AlertsHeader extends StatelessWidget {
  const AlertsHeader({
    required this.data,
    required this.onFarmSwitched,
    required this.onSearchPressed,
    required this.onFilterPressed,
    required this.onHistoryPressed,
    this.onMarkAllRead,
    this.onNotificationSettings,
    super.key,
  });

  final AlertsStateData data;
  final ValueChanged<String> onFarmSwitched;
  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onNotificationSettings;

  @override
  Widget build(BuildContext context) {
    final open = data.summary.open;
    final online = data.isOnline && !data.isOfflineCached;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: CrabSenseColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CrabSenseColors.card.withValues(alpha: 0.94),
                  CrabSenseColors.surface.withValues(alpha: 0.82),
                  CrabSenseColors.container.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: CrabSenseColors.primary.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: CrabSenseColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CrabSenseColors.primary
                                          .withValues(alpha: 0.7),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Alerts',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: CrabSenseColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          PopupMenuButton<String>(
                            onSelected: onFarmSwitched,
                            color: CrabSenseColors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: CrabSenseColors.primary
                                    .withValues(alpha: 0.25),
                              ),
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
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    data.selectedFarmName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CrabSenseColors.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: CrabSenseColors.accent,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$open cảnh báo chưa xử lý',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CrabSenseColors.hintText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _OnlineChip(online: online),
                  ],
                ),
                const SizedBox(height: 14),
                // Neon glass action tabs (tiled cyber style)
                Row(
                  children: [
                    Expanded(
                      child: _NeonActionTile(
                        icon: Icons.search_rounded,
                        label: 'Tìm',
                        onPressed: onSearchPressed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NeonActionTile(
                        icon: Icons.tune_rounded,
                        label: 'Lọc',
                        onPressed: onFilterPressed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NeonActionTile(
                        icon: data.showingHistory
                            ? Icons.notifications_active_rounded
                            : Icons.history_rounded,
                        label: 'Lịch sử',
                        highlighted: data.showingHistory,
                        onPressed: onHistoryPressed,
                      ),
                    ),
                    if (onMarkAllRead != null ||
                        onNotificationSettings != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: PopupMenuButton<_OverflowAction>(
                          tooltip: 'Thêm',
                          color: CrabSenseColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: CrabSenseColors.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case _OverflowAction.markAllRead:
                                onMarkAllRead?.call();
                              case _OverflowAction.notificationSettings:
                                onNotificationSettings?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            if (onMarkAllRead != null)
                              const PopupMenuItem(
                                value: _OverflowAction.markAllRead,
                                child: Text(
                                  'Đánh dấu tất cả đã xem',
                                  style: TextStyle(
                                    color: CrabSenseColors.textPrimary,
                                  ),
                                ),
                              ),
                            if (onNotificationSettings != null)
                              const PopupMenuItem(
                                value: _OverflowAction.notificationSettings,
                                child: Text(
                                  'Cài đặt thông báo',
                                  style: TextStyle(
                                    color: CrabSenseColors.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                          child: const _NeonActionTile(
                            icon: Icons.more_horiz_rounded,
                            label: 'Thêm',
                            onPressed: null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _OverflowAction { markAllRead, notificationSettings }

/// Individual glowing tile — active fills neon blue; inactive glass + corner dot.
class _NeonActionTile extends StatelessWidget {
  const _NeonActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3DDCFF),
                  CrabSenseColors.primary,
                  CrabSenseColors.primaryDark,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CrabSenseColors.container.withValues(alpha: 0.9),
                  CrabSenseColors.surface.withValues(alpha: 0.72),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? Colors.white.withValues(alpha: 0.35)
              : CrabSenseColors.primary.withValues(alpha: 0.4),
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CrabSenseColors.primary
                .withValues(alpha: highlighted ? 0.55 : 0.18),
            blurRadius: highlighted ? 16 : 8,
            spreadRadius: highlighted ? 1 : 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!highlighted)
            Positioned(
              top: 0,
              right: 2,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: CrabSenseColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CrabSenseColors.accent.withValues(alpha: 0.9),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          if (highlighted)
            Positioned(
              top: 2,
              left: 8,
              right: 8,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: highlighted
                      ? Colors.white
                      : CrabSenseColors.textSecondary,
                  shadows: highlighted
                      ? [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlighted
                        ? Colors.white
                        : CrabSenseColors.hintText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    shadows: highlighted
                        ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: CrabSenseColors.primary.withValues(alpha: 0.2),
        highlightColor: CrabSenseColors.primary.withValues(alpha: 0.1),
        child: tile,
      ),
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? CrabSenseColors.success : CrabSenseColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'Online' : 'Offline',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
