import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cloud_edge_connectivity.dart';
import '../../services/connectivity_link_service.dart';
import '../../theme/dashboard_theme.dart';

/// Badge Cloud / Edge trên header — trạng thái kết nối realtime.
class CloudEdgeHeaderBadges extends StatelessWidget {
  const CloudEdgeHeaderBadges({
    super.key,
    required this.service,
    this.compact = false,
    this.onTapCloud,
    this.onTapEdge,
    this.showEdge = false,
  });

  final ConnectivityLinkService service;
  final bool compact;
  final VoidCallback? onTapCloud;
  final VoidCallback? onTapEdge;

  /// Desktop cloud-only: mặc định chỉ hiện badge Cloud.
  final bool showEdge;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Badge(
          status: service.cloud,
          compact: compact,
          onTap: onTapCloud,
        ),
        if (showEdge && !service.cloudOnly) ...[
          SizedBox(width: compact ? 6 : 8),
          _Badge(
            status: service.edge,
            compact: compact,
            onTap: onTapEdge,
          ),
        ],
      ],
    ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.status,
    required this.compact,
    this.onTap,
  });

  final ConnectivityLinkStatus status;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.state) {
      ConnectivityLinkState.connected => DashboardColors.healthy,
      ConnectivityLinkState.disconnected => DashboardColors.risk,
      ConnectivityLinkState.checking => DashboardColors.monitoring,
      ConnectivityLinkState.unknown => DashboardColors.textMuted,
    };

    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: DashboardColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.kind.icon, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.kind.label,
            style: GoogleFonts.notoSans(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          _StatusDot(color: color, pulsing: status.state == ConnectivityLinkState.checking),
          if (!compact && status.latencyMs != null && status.isConnected) ...[
            const SizedBox(width: 6),
            Text(
              '${status.latencyMs}ms',
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );

    final tooltip = StringBuffer()
      ..writeln('${status.kind.label}: ${status.endpoint}');
    if (status.lastChecked != null) {
      tooltip.writeln('Kiểm tra: ${status.lastChecked}');
    }
    if (status.message != null && status.message!.isNotEmpty) {
      tooltip.write(status.message);
    }

    if (onTap == null) return child;
    return Tooltip(
      message: tooltip.toString().trim(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, this.pulsing = false});

  final Color color;
  final bool pulsing;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.pulsing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulsing) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.pulsing ? 0.85 + _pulse.value * 0.3 : 1.0;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
