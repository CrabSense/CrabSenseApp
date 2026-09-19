import 'package:flutter/material.dart';

import '../../theme/dashboard_theme.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.borderColor,
    this.highlight = false,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool highlight;
  final Color? color;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final elevated = _hovered && widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, elevated ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color ?? DashboardColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.highlight
                ? DashboardColors.monitoring.withValues(alpha: 0.55)
                : (widget.borderColor ?? DashboardColors.cardBorder),
            width: widget.highlight ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.brand.withValues(alpha: 0.06),
              blurRadius: elevated ? 18 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
