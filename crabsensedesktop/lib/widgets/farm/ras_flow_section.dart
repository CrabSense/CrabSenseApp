import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_box.dart';
import '../../models/ras_flow.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

/// Sơ đồ RAS ngang — dùng chung Bản đồ trại (mock) và Quản lý khu (API).
class RasFlowSection extends StatefulWidget {
  const RasFlowSection({
    super.key,
    this.components,
    this.liveNodes,
    this.onRelayCommand,
    this.liveCirculation = true,
    this.liveUpdatedAt,
    this.liveRefreshing = false,
  }) : assert(
          (components != null && liveNodes == null) ||
              (components == null && liveNodes != null),
          'Chỉ truyền components (mock) hoặc liveNodes (API)',
        );

  final List<RasComponent>? components;
  final List<RasFlowNodeLive>? liveNodes;
  final Future<bool> Function(RasFlowNodeLive node, String command)? onRelayCommand;
  final bool liveCirculation;
  final DateTime? liveUpdatedAt;
  final bool liveRefreshing;

  @override
  State<RasFlowSection> createState() => _RasFlowSectionState();
}

class _RasFlowSectionState extends State<RasFlowSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  /// Không dùng `late` — hot reload giữ State cũ nhưng không chạy lại initState.
  Map<String, bool> _mockStates = {};

  bool get _isLive => widget.liveNodes != null;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initMockStates();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RasFlowSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isLive && oldWidget.components != widget.components) {
      _initMockStates();
    }
  }

  void _initMockStates() {
    final list = widget.components ?? const <RasComponent>[];
    _mockStates = {for (final c in list) c.name: c.isOn};
  }

  void _toggleMock(String name) {
    setState(() {
      _mockStates[name] = !(_mockStates[name] ?? true);
    });
  }

  Future<void> _toggleLive(RasFlowNodeLive node) async {
    final cmd = node.onRelayCommand(widget.onRelayCommand);
    if (cmd != null) await widget.onRelayCommand!(node, cmd);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.liveNodes;
    final mock = widget.components;
    if (!_isLive && mock != null && mock.isNotEmpty && _mockStates.isEmpty) {
      _initMockStates();
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sơ Đồ Hệ Thống RAS',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.liveCirculation) _buildLiveHeader(nodes),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (nodes != null)
                  for (var i = 0; i < nodes.length; i++) ...[
                    _RasNode(
                      key: ValueKey(
                        '${nodes[i].id}-'
                        '${nodes[i].powerW}-${nodes[i].currentA}-'
                        '${nodes[i].voltageV}-${nodes[i].isOn}',
                      ),
                      component: nodes[i].toRasComponent(),
                      isOn: nodes[i].isOn ?? false,
                      onToggle: nodes[i].hasRelay
                          ? () => _toggleLive(nodes[i])
                          : null,
                    ),
                    if (i < nodes.length - 1) _flowArrow(),
                  ]
                else if (mock != null)
                  for (var i = 0; i < mock.length; i++) ...[
                    _RasNode(
                      component: mock[i],
                      isOn: _mockStates[mock[i].name] ?? mock[i].isOn,
                      onToggle: mock[i].hasControl
                          ? () => _toggleMock(mock[i].name)
                          : null,
                    ),
                    if (i < mock.length - 1) _flowArrow(),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeader(List<RasFlowNodeLive>? nodes) {
    final online = nodes?.any((n) => n.isOnline == true) ?? false;
    final label = _isLive ? 'Live · 2s' : 'Live Circulation';
    return Row(
      children: [
        if (_isLive)
          FadeTransition(
            opacity: _pulseAnim,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: online ? DashboardColors.healthy : DashboardColors.textMuted,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DashboardColors.healthy.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: DashboardColors.healthy,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: DashboardColors.healthy,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.liveRefreshing) ...[
          const SizedBox(width: 6),
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              color: DashboardColors.healthy,
            ),
          ),
        ],
      ],
    );
  }

  Widget _flowArrow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          Icons.arrow_forward,
          color: DashboardColors.cyan.withValues(alpha: 0.6),
          size: 18,
        ),
      );
}

extension _RasFlowNodeLiveCommand on RasFlowNodeLive {
  String? onRelayCommand(
    Future<bool> Function(RasFlowNodeLive, String)? handler,
  ) {
    if (!hasRelay || handler == null) return null;
    return (isOn ?? false) ? 'off' : 'on';
  }
}

class _RasNode extends StatelessWidget {
  const _RasNode({
    super.key,
    required this.component,
    required this.isOn,
    this.onToggle,
  });

  final RasComponent component;
  final bool isOn;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final hasControl = component.hasControl;
    final powerWatts = component.powerWatts;
    final currentAmps = component.currentAmps;
    final voltageVolts = component.voltageVolts;
    final temperature = component.temperatureCelsius;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasControl && isOn
              ? DashboardColors.cyan.withValues(alpha: 0.4)
              : DashboardColors.cyan.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                component.icon,
                color: hasControl && isOn
                    ? DashboardColors.cyan
                    : DashboardColors.cyan.withValues(alpha: 0.6),
                size: 20,
              ),
              const Spacer(),
              if (powerWatts != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DashboardColors.molting.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: DashboardColors.molting,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        powerWatts >= 1000
                            ? '${(powerWatts / 1000).toStringAsFixed(1)} kW'
                            : '${powerWatts.round()} W',
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.molting,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            component.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (hasControl && isOn)
                      ? DashboardColors.healthy.withValues(alpha: 0.15)
                      : DashboardColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasControl ? (isOn ? 'Bật' : 'Tắt') : 'Trực tuyến',
                  style: GoogleFonts.notoSans(
                    color: (hasControl && isOn)
                        ? DashboardColors.healthy
                        : DashboardColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
              if (hasControl && onToggle != null) ...[
                const Spacer(),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOn
                          ? DashboardColors.risk.withValues(alpha: 0.2)
                          : DashboardColors.healthy.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isOn
                            ? DashboardColors.risk.withValues(alpha: 0.5)
                            : DashboardColors.healthy.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      isOn ? 'Tắt' : 'Bật',
                      style: GoogleFonts.notoSans(
                        color: isOn ? DashboardColors.risk : DashboardColors.healthy,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (temperature != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: DashboardColors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thermostat,
                    color: DashboardColors.blue,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${temperature.toStringAsFixed(1)}°C',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          if (component.hasElectrical &&
              (currentAmps != null || voltageVolts != null)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (currentAmps != null) ...[
                  const Icon(Icons.electric_bolt, size: 11, color: DashboardColors.molting),
                  const SizedBox(width: 3),
                  Text(
                    '${currentAmps.toStringAsFixed(2)} A',
                    style: GoogleFonts.robotoMono(
                      color: DashboardColors.molting,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
                if (currentAmps != null && voltageVolts != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '·',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ),
                if (voltageVolts != null)
                  Text(
                    '${voltageVolts.toStringAsFixed(0)} V',
                    style: GoogleFonts.robotoMono(
                      color: DashboardColors.cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
              ],
            ),
          ],
          if (component.metric.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              component.metric,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 9,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
