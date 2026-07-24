import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan QR',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: CrabSenseColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        farmLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CrabSenseColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _IconBtn(
                  icon: isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  tooltip: 'Flash',
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
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                selected: continuousScan,
                onSelected: (_) => onToggleContinuous(),
                label: Text(
                  continuousScan ? 'Continuous Scan' : 'Single Scan',
                  style: TextStyle(
                    color: continuousScan
                        ? CrabSenseColors.background
                        : CrabSenseColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor: CrabSenseColors.primary,
                backgroundColor: CrabSenseColors.container.withValues(alpha: 0.72),
                side: BorderSide(color: CrabSenseColors.border),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
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
        style: IconButton.styleFrom(
          backgroundColor: active
              ? CrabSenseColors.primary.withValues(alpha: 0.22)
              : CrabSenseColors.surface.withValues(alpha: 0.55),
          foregroundColor:
              active ? CrabSenseColors.primary : CrabSenseColors.textPrimary,
        ),
        icon: Icon(icon, size: 22),
      ),
    );
  }
}
