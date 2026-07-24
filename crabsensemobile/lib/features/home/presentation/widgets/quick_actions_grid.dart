import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_palette.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onScanQrPressed;
  final VoidCallback onRecordVideoPressed;
  final VoidCallback onWaterTestPressed;
  final VoidCallback onHarvestPressed;

  const QuickActionsGrid({
    super.key,
    required this.onScanQrPressed,
    required this.onRecordVideoPressed,
    required this.onWaterTestPressed,
    required this.onHarvestPressed,
  });

  List<_QuickAction> get _actions => [
        _QuickAction(
          title: 'Quét Mã QR',
          subtitle: 'Quét box & chuyển cua',
          icon: Icons.qr_code_scanner_rounded,
          color: kHomeBlue,
          onTap: onScanQrPressed,
          isHighlighted: true,
        ),
        _QuickAction(
          title: 'Quay Video AI',
          subtitle: 'Nhận diện cua lột',
          icon: Icons.videocam_rounded,
          color: kHomePurple,
          onTap: onRecordVideoPressed,
        ),
        _QuickAction(
          title: 'Kiểm Tra Nước',
          subtitle: 'Ghi nhận chỉ số nước',
          icon: Icons.water_drop_rounded,
          color: kHomeCyan,
          onTap: onWaterTestPressed,
        ),
        _QuickAction(
          title: 'Thu Hoạch Cua',
          subtitle: 'Tạo phiếu thu hoạch',
          icon: Icons.inventory_2_rounded,
          color: kHomeOrange,
          onTap: onHarvestPressed,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final actions = _actions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          icon: Icons.bolt_rounded,
          title: 'THAO TÁC NHANH',
        ),
        const SizedBox(height: 12),
        if (isTablet)
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _ActionCard(action: actions[i])),
              ],
            ],
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.30,
            children: [
              for (final action in actions) _ActionCard(action: action),
            ],
          ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isHighlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isHighlighted;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: action.isHighlighted
                  ? color.withValues(alpha: 0.75)
                  : kHomeBorderBlue.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: (action.isHighlighted ? color : kHomeBlue)
                    .withValues(alpha: action.isHighlighted ? 0.3 : 0.15),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(action.icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CrabSenseColors.textSecondary,
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
