import 'package:flutter/material.dart';
import 'home_palette.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onScanQrPressed;
  final VoidCallback onRecordVideoPressed;
  final VoidCallback onWaterTestPressed;
  final VoidCallback onHarvestPressed;
  final VoidCallback? onTrackingPressed;
  final VoidCallback? onMineralDosingPressed;

  const QuickActionsGrid({
    super.key,
    required this.onScanQrPressed,
    required this.onRecordVideoPressed,
    required this.onWaterTestPressed,
    required this.onHarvestPressed,
    this.onTrackingPressed,
    this.onMineralDosingPressed,
  });

  static const List<_ActionDef> _extraActions = [
    _ActionDef(
      label: 'Vận hành',
      icon: Icons.edit_note_rounded,
      bgColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFF39C12),
    ),
    _ActionDef(
      label: 'AI Center',
      icon: Icons.psychology_rounded,
      bgColor: Color(0xFFF3E8FF),
      iconColor: Color(0xFF9B59B6),
    ),
    _ActionDef(
      label: 'Báo cáo',
      icon: Icons.trending_up_rounded,
      bgColor: Color(0xFFFFE8EF),
      iconColor: Color(0xFFE91E8C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          icon: Icons.bolt_rounded,
          title: 'Thao tác nhanh',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            _QuickBtn(
              label: 'Quét QR',
              icon: Icons.qr_code_scanner_rounded,
              bgColor: kHomePrimaryBg,
              iconColor: kHomePrimary,
              onTap: onScanQrPressed,
            ),
            _QuickBtn(
              label: 'Hộp nuôi',
              icon: Icons.grid_view_rounded,
              bgColor: kHomeSecondaryBg,
              iconColor: kHomeSecondary,
              onTap: onRecordVideoPressed,
            ),
            _QuickBtn(
              label: 'Chất lượng',
              icon: Icons.water_drop_rounded,
              bgColor: const Color(0xFFE0F7FA),
              iconColor: kHomeCyan,
              onTap: onWaterTestPressed,
            ),
            _QuickBtn(
              label: 'Liều khoáng',
              icon: Icons.scale_rounded,
              bgColor: const Color(0xFFE0F2F1),
              iconColor: kHomeInfo,
              onTap: onMineralDosingPressed ?? () {},
            ),
            _QuickBtn(
              label: 'Thu hoạch',
              icon: Icons.agriculture_rounded,
              bgColor: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFF9A825),
              onTap: onHarvestPressed,
            ),
            _QuickBtn(
              label: 'Theo dõi',
              icon: Icons.track_changes_rounded,
              bgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF1E8449),
              onTap: onTrackingPressed ?? () {},
            ),
            for (final a in _extraActions)
              _QuickBtn(
                label: a.label,
                icon: a.icon,
                bgColor: a.bgColor,
                iconColor: a.iconColor,
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionDef {
  const _ActionDef({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kHomeTextMain,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
