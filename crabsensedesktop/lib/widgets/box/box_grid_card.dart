import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../theme/dashboard_theme.dart';

class BoxGridCard extends StatelessWidget {
  const BoxGridCard({
    super.key,
    required this.box,
    this.onTap,
  });

  final BoxRecord box;
  final VoidCallback? onTap;

  static int _healthScore(BoxRecord box) {
    final h = box.boxCode.hashCode.abs() % 35;
    return 65 + h;
  }

  @override
  Widget build(BuildContext context) {
    final status = box.status.toLowerCase();
    final empty = status == 'empty' || status == 'deceased' || !box.hasCrab;
    final attention = box.alertCount > 0 ||
        status == 'maintenance' ||
        status == 'alert' ||
        status == 'warning' ||
        status == 'quarantine';

    final Color accent;
    final String statusLabel;
    final IconData statusIcon;
    final int? health;

    if (empty) {
      accent = const Color(0xFF64748B);
      statusLabel = 'Trống';
      statusIcon = Icons.inventory_2_outlined;
      health = null;
    } else if (attention) {
      accent = DashboardColors.monitoring;
      statusLabel = 'Chú ý';
      statusIcon = Icons.warning_amber_rounded;
      health = _healthScore(box).clamp(40, 70);
    } else {
      accent = DashboardColors.cyan;
      statusLabel = 'Nuôi';
      statusIcon = Icons.water_drop;
      health = _healthScore(box).clamp(75, 99);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: DashboardColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: empty ? 0.2 : 0.45),
            ),
            boxShadow: empty
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(statusIcon, size: 16, color: accent),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              box.boxCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSans(
                                color: empty
                                    ? DashboardColors.textMuted
                                    : DashboardColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.notoSans(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (health != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$health',
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '%',
                                style: GoogleFonts.notoSans(
                                  color: DashboardColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (box.volume != null && box.volume! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${box.volume!.toStringAsFixed(0)}L',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: health != null ? health / 100 : 0,
                          minHeight: 3,
                          backgroundColor:
                              DashboardColors.cardBorder.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
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
