import 'package:flutter/material.dart';

/// Skeleton Loader Component
/// Animated placeholder for loading states
/// Requirements: 20.1-20.10, 21.6
class SkeletonLoader extends StatefulWidget {
  /// Creates a skeleton loader
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Width of skeleton (null for infinite width)
  final double? width;

  /// Height of skeleton
  final double height;

  /// Border radius of skeleton
  final double borderRadius;

  /// Base color of skeleton
  final Color? baseColor;

  /// Highlight color for shimmer effect
  final Color? highlightColor;

  /// Shimmer animation duration
  final Duration duration;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBaseColor = widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveHighlightColor =
        widget.highlightColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            colors: [effectiveBaseColor, effectiveHighlightColor, effectiveBaseColor],
          ),
        ),
      ),
    );
  }
}

/// Skeleton Text Component
/// Pre-configured skeleton for text lines
class SkeletonText extends StatelessWidget {
  /// Creates a skeleton text
  const SkeletonText({
    super.key,
    this.lines = 1,
    this.lineHeight = 16,
    this.spacing = 8,
    this.lastLineWidth = 0.7,
  });

  /// Number of text lines
  final int lines;

  /// Height of each line
  final double lineHeight;

  /// Spacing between lines
  final double spacing;

  /// Width factor for last line (0.0-1.0)
  final double lastLineWidth;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        List.generate(lines, (index) {
          final isLastLine = index == lines - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLastLine ? 0 : spacing),
            child: SkeletonLoader(
              height: lineHeight,
              width: isLastLine ? null : null,
              borderRadius: 4,
            ),
          );
        }).map((widget) {
          // Apply width constraint to last line
          if (widget.key == null && lines > 1 && (widget.child! as SkeletonLoader).width == null) {
            return FractionallySizedBox(
              widthFactor: lastLineWidth,
              alignment: Alignment.centerLeft,
              child: widget,
            );
          }
          return widget;
        }).toList(),
  );
}

/// Skeleton Circle Component
/// Pre-configured skeleton for circular avatars
class SkeletonCircle extends StatelessWidget {
  /// Creates a skeleton circle
  const SkeletonCircle({super.key, this.size = 48});

  /// Diameter of circle
  final double size;

  @override
  Widget build(BuildContext context) =>
      SkeletonLoader(width: size, height: size, borderRadius: size / 2);
}
