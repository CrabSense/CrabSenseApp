import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';

class FarmOverviewSummary extends StatelessWidget {
  const FarmOverviewSummary({
    required this.overview,
    this.onStatusTap,
    super.key,
  });

  final FarmBoxesOverview overview;
  final ValueChanged<BoxQuickFilter>? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final total = overview.total == 0 ? 1 : overview.total;
    return Container(
      width: double.infinity,
      decoration: homeCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CrabHologramPainter(
                    color: kHomeBlueLight.withValues(alpha: 0.08),
                    trayExtent: 24,
                  ),
                ),
              ),
            ),
            const HomeTopEdgeGlow(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Stat(
                        label: 'Tổng',
                        value: overview.total,
                        color: kHomeBlueLight,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.all),
                      ),
                      _Stat(
                        label: 'Ổn định',
                        value: overview.healthy,
                        color: kHomeGreen,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.healthy),
                      ),
                      _Stat(
                        label: 'Cảnh báo',
                        value: overview.warning,
                        color: kHomeOrange,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.warning),
                      ),
                      _Stat(
                        label: 'Nghiêm trọng',
                        value: overview.critical,
                        color: Colors.redAccent,
                        onTap: () =>
                            onStatusTap?.call(BoxQuickFilter.critical),
                      ),
                      _Stat(
                        label: 'Offline',
                        value: overview.offline,
                        color: Colors.white54,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.offline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          Expanded(
                            flex: overview.healthy,
                            child: Container(color: kHomeGreen),
                          ),
                          Expanded(
                            flex: overview.warning,
                            child: Container(color: kHomeOrange),
                          ),
                          Expanded(
                            flex: overview.critical,
                            child: Container(color: Colors.redAccent),
                          ),
                          Expanded(
                            flex: overview.offline,
                            child: Container(color: Colors.white38),
                          ),
                          if (overview.total == 0)
                            Expanded(
                              child: Container(
                                color: kHomeSurface,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (overview.withAiRecommendation > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: kHomePurple,
                          shadows: [
                            Shadow(
                              color: kHomePurple.withValues(alpha: 0.7),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${overview.withAiRecommendation} Box có đề xuất AI',
                          style: TextStyle(
                            color: const Color(0xFF5A7184),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${((overview.healthy / total) * 100).round()}% ổn định',
                          style: TextStyle(
                            color: const Color(0xFF5A7184),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5A7184),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
