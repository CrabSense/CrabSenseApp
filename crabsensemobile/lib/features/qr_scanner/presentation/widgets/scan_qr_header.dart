import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Top bar for Scan QR: title, farm, torch, flip, album, help.
class ScanQRHeader extends StatelessWidget {
  const ScanQRHeader({
    required this.farmLabel,
    required this.isTorchOn,
    required this.continuousScan,
    required this.onToggleTorch,
    required this.onToggleFacing,
    required this.onOpenAlbum,
    required this.onHelp,
    required this.onToggleContinuous,
    super.key,
  });

  final String farmLabel;
  final bool isTorchOn;
  final bool continuousScan;
  final VoidCallback onToggleTorch;
  final VoidCallback onToggleFacing;
  final VoidCallback onOpenAlbum;
  final VoidCallback onHelp;
  final VoidCallback onToggleContinuous;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'QUÉT QR',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kHomeBlueLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: kHomeCyan.withValues(alpha: 0.55),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                  ),
                ),
                _IconBtn(
                  icon: isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  tooltip: 'Đèn flash',
                  active: isTorchOn,
                  onTap: onToggleTorch,
                ),
                _IconBtn(
                  icon: Icons.cameraswitch_rounded,
                  tooltip: 'Đổi camera',
                  onTap: onToggleFacing,
                ),
                _IconBtn(
                  icon: Icons.photo_library_outlined,
                  tooltip: 'Album',
                  onTap: onOpenAlbum,
                ),
                _IconBtn(
                  icon: Icons.help_outline_rounded,
                  tooltip: 'Trợ giúp',
                  onTap: onHelp,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: _FarmChip(label: farmLabel),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  continuousScan: continuousScan,
                  onTap: onToggleContinuous,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmChip extends StatelessWidget {
  const _FarmChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kHomeNavyDeep.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kHomeBorderBlue.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: kHomeBlue.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HomeCrabWatermark(alpha: 0.08, trayExtent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: kHomeCyan,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.continuousScan,
    required this.onTap,
  });

  final bool continuousScan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: continuousScan
                ? kHomeBlue.withValues(alpha: 0.45)
                : kHomeNavyDeep.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: continuousScan
                  ? kHomeCyan.withValues(alpha: 0.8)
                  : kHomeBorderBlue.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              continuousScan ? 'Quét liên tục' : 'Quét một lần',
              style: TextStyle(
                color: continuousScan ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: active
              ? kHomeBlue.withValues(alpha: 0.28)
              : kHomeNavyDeep.withValues(alpha: 0.65),
          foregroundColor: active ? kHomeCyan : kHomeBlueLight,
          side: BorderSide(
            color: active
                ? kHomeCyan.withValues(alpha: 0.7)
                : kHomeBorderBlue.withValues(alpha: 0.45),
          ),
          shadowColor: active ? kHomeCyan.withValues(alpha: 0.45) : null,
          elevation: active ? 4 : 0,
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
