import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_status.dart';
import '../../models/farm_layout.dart';
import '../../theme/dashboard_theme.dart';

/// Ô hộp trên bản đồ: mã + số cua + icon trạng thái.
class FarmMapBoxTile extends StatelessWidget {
  const FarmMapBoxTile({
    super.key,
    required this.item,
    required this.onTap,
    this.highlighted = false,
  });

  final FarmMapBox item;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final status = item.display.status;
    final color = status.color;
    final empty = status == BoxStatus.empty;
    final crabs = item.crabCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 96,
          height: 102,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          decoration: BoxDecoration(
            color: empty
                ? DashboardColors.darkNavy.withValues(alpha: 0.55)
                : DashboardColors.card.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted
                  ? DashboardColors.purple
                  : color.withValues(alpha: empty ? 0.45 : 0.7),
              width: highlighted ? 2 : 1.4,
            ),
            boxShadow: empty
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                item.display.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Image.asset(
                  status.iconAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => Icon(
                    empty ? Icons.inventory_2_outlined : Icons.pets,
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (!empty)
                Text(
                  '$crabs cua',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
