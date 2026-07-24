import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';

/// Skeleton bottom sheet while box quick-result loads.
class ScanSkeleton extends StatelessWidget {
  const ScanSkeleton({super.key});

  static const _base = Color(0xFF0A1F42);
  static const _highlight = Color(0xFF163A6E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: kHomeBlue.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kHomeCyan.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: kHomeCyan.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(
            width: 140,
            height: 22,
            baseColor: _base,
            highlightColor: _highlight,
            duration: Duration(milliseconds: 1200),
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(
            width: 90,
            height: 14,
            baseColor: _base,
            highlightColor: _highlight,
            duration: Duration(milliseconds: 1200),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  height: 56,
                  baseColor: _base,
                  highlightColor: _highlight,
                  duration: Duration(milliseconds: 1200),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonLoader(
                  height: 56,
                  baseColor: _base,
                  highlightColor: _highlight,
                  duration: Duration(milliseconds: 1200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonLoader(
            height: 72,
            baseColor: _base,
            highlightColor: _highlight,
            duration: Duration(milliseconds: 1200),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: List.generate(
              6,
              (_) => const SkeletonLoader(
                height: 72,
                borderRadius: 16,
                baseColor: _base,
                highlightColor: _highlight,
                duration: Duration(milliseconds: 1200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
