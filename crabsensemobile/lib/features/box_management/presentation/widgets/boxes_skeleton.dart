import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shimmer skeleton matching Boxes tab layout.
class BoxesSkeleton extends StatelessWidget {
  const BoxesSkeleton({super.key, this.gridColumns = 2});

  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BoxesHeaderSkeleton(),
          const SizedBox(height: 12),
          const SearchBarSkeleton(),
          const SizedBox(height: 12),
          const FarmSummarySkeleton(),
          const SizedBox(height: 12),
          const FilterChipSkeleton(),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridColumns * 2,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (_, __) => const GridBoxCardSkeleton(),
          ),
        ],
      ),
    );
  }
}

class BoxesHeaderSkeleton extends StatelessWidget {
  const BoxesHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShimmerRow(
      children: [
        _ShimmerBlock(width: 120, height: 22, radius: 8),
        Spacer(),
        _ShimmerBlock(width: 40, height: 40, radius: 12),
        SizedBox(width: 8),
        _ShimmerBlock(width: 40, height: 40, radius: 12),
        SizedBox(width: 8),
        _ShimmerBlock(width: 40, height: 40, radius: 12),
      ],
    );
  }
}

class SearchBarSkeleton extends StatelessWidget {
  const SearchBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBlock(width: double.infinity, height: 48, radius: 14);
  }
}

class FarmSummarySkeleton extends StatelessWidget {
  const FarmSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBlock(width: double.infinity, height: 72, radius: 16);
  }
}

class FilterChipSkeleton extends StatelessWidget {
  const FilterChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) =>
            const _ShimmerBlock(width: 88, height: 32, radius: 20),
      ),
    );
  }
}

class GridBoxCardSkeleton extends StatelessWidget {
  const GridBoxCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBlock(width: 72, height: 16, radius: 6),
              Spacer(),
              _ShimmerBlock(width: 56, height: 20, radius: 20),
            ],
          ),
          SizedBox(height: 8),
          _ShimmerBlock(width: 90, height: 12, radius: 6),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 48, radius: 12),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 12, radius: 6),
          SizedBox(height: 8),
          _ShimmerBlock(width: double.infinity, height: 12, radius: 6),
          Spacer(),
          _ShimmerBlock(width: 100, height: 10, radius: 6),
        ],
      ),
    );
  }
}

class ListBoxRowSkeleton extends StatelessWidget {
  const ListBoxRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrabSenseColors.border),
      ),
      child: const Row(
        children: [
          _ShimmerBlock(width: 40, height: 40, radius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBlock(width: 100, height: 14, radius: 6),
                SizedBox(height: 6),
                _ShimmerBlock(width: 160, height: 10, radius: 6),
              ],
            ),
          ),
          _ShimmerBlock(width: 36, height: 36, radius: 18),
        ],
      ),
    );
  }
}

class FarmMapSkeleton extends StatelessWidget {
  const FarmMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShimmerBlock(width: double.infinity, height: 360, radius: 16);
  }
}

class FilterBottomSheetSkeleton extends StatelessWidget {
  const FilterBottomSheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _ShimmerBlock(width: 120, height: 18, radius: 8),
          SizedBox(height: 16),
          _ShimmerBlock(width: double.infinity, height: 48, radius: 14),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 48, radius: 14),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 80, radius: 14),
        ],
      ),
    );
  }
}

class BoxQuickViewSkeleton extends StatelessWidget {
  const BoxQuickViewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _ShimmerBlock(width: 140, height: 18, radius: 8),
          SizedBox(height: 16),
          _ShimmerBlock(width: double.infinity, height: 64, radius: 14),
          SizedBox(height: 12),
          _ShimmerBlock(width: double.infinity, height: 48, radius: 14),
        ],
      ),
    );
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
                CrabSenseColors.surface,
                CrabSenseColors.container,
                CrabSenseColors.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(children: children);
  }
}
