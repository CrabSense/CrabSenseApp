import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';

/// Header tab Cảnh báo — đồng bộ phong cách hologram trang home / Boxes.
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
              colors: [kHomeSurface, kHomeBg, kHomeBg],
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
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kHomeCyan.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CHỌN TRANG TRẠI',
                        style: TextStyle(
                          color: kHomePrimaryDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...data.availableFarms.map((f) {
                        final selected = f.id == data.selectedFarmId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                onFarmSwitched(f.id);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? kHomeBlue.withValues(alpha: 0.22)
                                      : kHomeBg.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? kHomeCyan.withValues(alpha: 0.7)
                                        : kHomeBorderBlue.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 18,
                                      color: selected ? kHomeCyan : Colors.white54,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        f.name,
                                        style: TextStyle(
                                          color: kHomeTextMain,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: kHomeCyan,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
  Widget build(BuildContext context) {
    final open = data.summary.open;
    final online = data.isOnline && !data.isOfflineCached;

    return Container(
      decoration: homeCardDecoration(radius: 22, glowAlpha: 0.16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeBlueLight.withValues(alpha: 0.06),
                  trayExtent: 26,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
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
                          'CẢNH BÁO',
                          style: TextStyle(
                            color: kHomePrimaryDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OnlineChip(online: online),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$open cảnh báo chưa xử lý',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF5A7184),
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
                      tooltip: 'Sắp xếp & nhóm',
                      onPressed: onFilterPressed,
                    ),
                    _HeaderIconButton(
                      icon: data.showingHistory
                          ? Icons.notifications_active_rounded
                          : Icons.history_rounded,
                      tooltip: 'Lịch sử',
                      onPressed: onHistoryPressed,
                      active: data.showingHistory,
                    ),
                    if (onMarkAllRead != null || onNotificationSettings != null)
                      PopupMenuButton<_OverflowAction>(
                        tooltip: 'Thêm',
                        color: kHomeSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: kHomeBorderBlue.withValues(alpha: 0.45),
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
                                style: TextStyle(color: kHomeTextMain),
                              ),
                            ),
                          if (onNotificationSettings != null)
                            const PopupMenuItem(
                              value: _OverflowAction.notificationSettings,
                              child: Text(
                                'Cài đặt thông báo',
                                style: TextStyle(color: kHomeTextMain),
                              ),
                            ),
                        ],
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: kHomeBg.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kHomeBorderBlue.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: kHomeBlueLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _OverflowAction { markAllRead, notificationSettings }

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
              colors: [kHomeSurface, kHomeBg, kHomeBg],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: kHomeBlueLight.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: kHomeBlue.withValues(alpha: 0.28),
                blurRadius: 10,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kHomeBlue.withValues(alpha: 0.18),
                          boxShadow: [
                            BoxShadow(
                              color: kHomeBlue.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: kHomeCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          farmName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kHomeTextMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: const Color(0xFF5A7184),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active
                    ? kHomeBlue.withValues(alpha: 0.28)
                    : kHomeBg.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? kHomeCyan.withValues(alpha: 0.7)
                      : kHomeBorderBlue.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: active ? kHomeCyan : kHomeBlueLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? kHomeGreen : kHomeOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
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
            online ? 'Trực tuyến' : 'Ngoại tuyến',
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
