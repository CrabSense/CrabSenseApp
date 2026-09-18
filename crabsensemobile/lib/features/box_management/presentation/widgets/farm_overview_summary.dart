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
                      // Nhãn + màu lấy thẳng từ [BoxStatus] để thanh tổng quan
                      // không lệch với chip lọc, lưới hộp và app desktop.
                      _Stat(
                        label: BoxStatus.normal.label,
                        value: overview.normal,
                        color: BoxStatus.normal.color,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.normal),
                      ),
                      _Stat(
                        label: BoxStatus.watch.label,
                        value: overview.watch,
                        color: BoxStatus.watch.color,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.watch),
                      ),
                      _Stat(
                        label: BoxStatus.molting.label,
                        value: overview.molting,
                        color: BoxStatus.molting.color,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.molting),
                      ),
                      _Stat(
                        label: BoxStatus.alert.label,
                        value: overview.alert,
                        color: BoxStatus.alert.color,
                        onTap: () => onStatusTap?.call(BoxQuickFilter.alert),
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
                            flex: overview.normal,
                            child: Container(color: BoxStatus.normal.color),
                          ),
                          Expanded(
                            flex: overview.watch,
                            child: Container(color: BoxStatus.watch.color),
                          ),
                          Expanded(
                            flex: overview.molting,
                            child: Container(color: BoxStatus.molting.color),
                          ),
                          Expanded(
                            flex: overview.alert,
                            child: Container(color: BoxStatus.alert.color),
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
                          '${((overview.normal / total) * 100).round()}% ổn định',
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
