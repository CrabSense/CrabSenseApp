import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Skeleton loaders matching Alerts Command Center layout.
class AlertsSkeleton extends StatelessWidget {
  const AlertsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlertsHeaderSkeleton(),
          SizedBox(height: 12),
          AlertSummarySkeleton(),
          SizedBox(height: 12),
          PriorityAlertSkeleton(),
          SizedBox(height: 12),
          AlertFilterSkeleton(),
          SizedBox(height: 16),
          AlertListSkeleton(),
        ],
      ),
    );
  }
}

class AlertsHeaderSkeleton extends StatelessWidget {
  const AlertsHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBlock(width: 100, height: 22, radius: 8),
              SizedBox(height: 8),
              _ShimmerBlock(width: 140, height: 12, radius: 6),
              SizedBox(height: 6),
              _ShimmerBlock(width: 160, height: 10, radius: 6),
            ],
          ),
        ),
        _ShimmerBlock(width: 40, height: 40, radius: 12),
        SizedBox(width: 8),
        _ShimmerBlock(width: 40, height: 40, radius: 12),
        SizedBox(width: 8),
        _ShimmerBlock(width: 40, height: 40, radius: 12),
      ],
    );
  }
}

class AlertSummarySkeleton extends StatelessWidget {
  const AlertSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) =>
            const _ShimmerBlock(width: 88, height: 64, radius: 14),
      ),
    );
  }
}

class PriorityAlertSkeleton extends StatelessWidget {
  const PriorityAlertSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kHomeNavyLift,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kHomeBorderBlue),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(width: 90, height: 18, radius: 8),
              Spacer(),
              _ShimmerBlock(width: 48, height: 18, radius: 8),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 18, radius: 8),
          SizedBox(height: 8),
          _ShimmerBlock(width: 200, height: 12, radius: 6),
          SizedBox(height: 14),
          _ShimmerBlock(width: double.infinity, height: 56, radius: 12),
          SizedBox(height: 12),
          Row(
            children: [
              _ShimmerBlock(width: 96, height: 36, radius: 10),
              SizedBox(width: 8),
              _ShimmerBlock(width: 80, height: 36, radius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class AlertFilterSkeleton extends StatelessWidget {
  const AlertFilterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) =>
            const _ShimmerBlock(width: 84, height: 32, radius: 20),
      ),
    );
  }
}

class AlertCardSkeleton extends StatelessWidget {
  const AlertCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kHomeNavyLift,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHomeBorderBlue),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(width: 36, height: 36, radius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBlock(width: 160, height: 14, radius: 6),
                    SizedBox(height: 6),
                    _ShimmerBlock(width: 100, height: 10, radius: 6),
                  ],
                ),
              ),
              _ShimmerBlock(width: 44, height: 20, radius: 8),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 12, radius: 6),
          SizedBox(height: 8),
          _ShimmerBlock(width: 180, height: 12, radius: 6),
        ],
      ),
    );
  }
}

class AlertListSkeleton extends StatelessWidget {
  const AlertListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const AlertCardSkeleton()),
    );
  }
}

class AlertDetailSkeleton extends StatelessWidget {
  const AlertDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _ShimmerBlock(width: 140, height: 18, radius: 8),
          SizedBox(height: 16),
          _ShimmerBlock(width: double.infinity, height: 80, radius: 14),
          SizedBox(height: 12),
          AlertTimelineSkeleton(),
          SizedBox(height: 12),
          AssignmentSkeleton(),
        ],
      ),
    );
  }
}

class AlertTimelineSkeleton extends StatelessWidget {
  const AlertTimelineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ShimmerBlock(width: double.infinity, height: 40, radius: 10),
        SizedBox(height: 8),
        _ShimmerBlock(width: double.infinity, height: 40, radius: 10),
        SizedBox(height: 8),
        _ShimmerBlock(width: double.infinity, height: 40, radius: 10),
      ],
    );
  }
}

class AssignmentSkeleton extends StatelessWidget {
  const AssignmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBlock(width: double.infinity, height: 72, radius: 14);
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          constraints: widget.width == double.infinity
              ? const BoxConstraints(minWidth: double.infinity)
              : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                kHomeNavy,
                kHomeNavyDeep,
                kHomeNavy,
              ],
            ),
          ),
        );
      },
    );
  }
}
