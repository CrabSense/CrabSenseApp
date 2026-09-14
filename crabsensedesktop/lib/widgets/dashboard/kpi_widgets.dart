import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/dashboard_ui.dart';
import '../../theme/dashboard_theme.dart';
import 'glass_card.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({
    super.key,
    required this.userName,
    required this.healthScore,
    this.statusMessage = 'Hôm nay hệ thống đang vận hành ổn định',
  });

  final String userName;
  final int healthScore;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào $userName',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DashboardColors.healthy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Health Score trung bình: $healthScore/100',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        HealthScoreRing(score: healthScore),
      ],
    );
  }
}

class HealthScoreRing extends StatelessWidget {
  const HealthScoreRing({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final progress = score / 100;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        width: 160,
        child: Column(
          children: [
            Text(
              'ĐIỂM SỨC KHỎE HỆ THỐNG',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: DashboardColors.cardBorder,
                      valueColor: const AlwaysStoppedAnimation(
                        DashboardColors.cyan,
                      ),
                    ),
                  ),
                  Text(
                    '$score',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.cyan,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '/100',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.item});

  final KpiItem item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label.toUpperCase(),
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (item.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DashboardColors.healthy.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.healthy,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: GoogleFonts.notoSans(
              color: item.color ?? DashboardColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.items, this.columns = 4});

  final List<KpiItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 1200
            ? columns
            : constraints.maxWidth > 800
                ? 3
                : 2;
        final spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: KpiCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class StatusDistributionCard extends StatelessWidget {
  const StatusDistributionCard({super.key, required this.segments});

  final List<StatusSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.map((e) => e.count).fold<int>(0, (a, b) => a + b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân Bổ Tình Trạng',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              if (wide) {
                return Row(
                  children: segments
                      .map((s) => Expanded(child: _StatusColumn(s, total)))
                      .toList(),
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: segments
                    .map(
                      (s) => SizedBox(
                        width: (constraints.maxWidth - 32) / 2,
                        child: _StatusColumn(s, total),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn(this.segment, this.total);

  final StatusSegment segment;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = segment.count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment.label,
          style: GoogleFonts.notoSans(
            color: segment.color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatCount(segment.count),
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: DashboardColors.cardBorder,
            valueColor: AlwaysStoppedAnimation(segment.color),
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
