import 'package:flutter/material.dart';

import 'home_palette.dart';

/// Animated Shimmer Skeleton Loader for Farm Command Center
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 12,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          margin: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                kHomeNavy,
                kHomeNavyLift,
                kHomeNavy,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton Header
          Row(
            children: [
              _buildShimmerBox(width: 44, height: 44, borderRadius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 140, height: 16),
                    const SizedBox(height: 6),
                    _buildShimmerBox(width: 200, height: 12),
                  ],
                ),
              ),
              _buildShimmerBox(width: 40, height: 40, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 20),

          // Skeleton Hero Overview Card
          _buildShimmerBox(width: double.infinity, height: 110, borderRadius: 16),
          const SizedBox(height: 16),

          // Skeleton Farm Health Score Card (Highlight 1)
          _buildShimmerBox(width: double.infinity, height: 180, borderRadius: 16),
          const SizedBox(height: 16),

          // Skeleton AI Recommendation Card (Highlight 2)
          _buildShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
          const SizedBox(height: 16),

          // Skeleton Quick Actions Grid (Highlight 3)
          Row(
            children: [
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 90, borderRadius: 14)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 90, borderRadius: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 90, borderRadius: 14)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 90, borderRadius: 14)),
            ],
          ),
          const SizedBox(height: 24),

          // Skeleton Water Quality Cards
          _buildShimmerBox(width: 160, height: 20),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _buildShimmerBox(width: 120, height: 90, borderRadius: 14),
            ),
          ),
        ],
      ),
    );
  }
}
