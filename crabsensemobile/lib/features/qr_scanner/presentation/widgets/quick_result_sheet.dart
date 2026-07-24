import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/entities/scan_quick_result.dart';
import 'ai_recommendation_card.dart';
import 'alert_summary_card.dart';
import 'offline_banner.dart';
import 'quick_actions_grid.dart';
import 'scan_history_list.dart';

/// Glassmorphism quick-result sheet after a successful QR scan.
class QuickResultSheet extends StatelessWidget {
  const QuickResultSheet({
    required this.result,
    required this.history,
    required this.onAction,
    required this.onViewAnalysis,
    required this.onRescanHistory,
    required this.onSync,
    super.key,
    this.embedded = false,
  });

  final ScanQuickResult result;
  final List<ScanHistoryEntry> history;
  final void Function(ScanQuickAction action) onAction;
  final VoidCallback onViewAnalysis;
  final void Function(ScanHistoryEntry entry) onRescanHistory;
  final VoidCallback onSync;

  /// When true, used as side panel (tablet) without modal chrome.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embedded) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: kHomeCyan.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: kHomeCyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (result.isOffline) OfflineBanner(onSync: onSync),
        Text(
          result.code,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.55,
              ),
              child: Text(
                result.farmName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
            _StatusPill(label: result.statusLabel),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Sức khỏe',
                value: '${result.healthScore}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Điểm AI',
                value: '${result.aiScore}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Cua',
                value: '${result.crabCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (result.temperature != null)
              _ChipStat(
                icon: Icons.thermostat,
                text: '${result.temperature!.toStringAsFixed(0)}°C',
              ),
            if (result.ph != null)
              _ChipStat(
                icon: Icons.water_drop_outlined,
                text: 'pH ${result.ph!.toStringAsFixed(1)}',
              ),
            Text(
              'Cập nhật ${result.relativeUpdatedLabel}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AIRecommendationCard(
          result: result,
          onViewAnalysis: onViewAnalysis,
        ),
        if (result.hasAlerts) ...[
          const SizedBox(height: 12),
          AlertSummaryCard(alerts: result.alerts),
        ],
        const SizedBox(height: 16),
        QuickActionsGrid(onAction: onAction),
        const SizedBox(height: 12),
        ScanHistoryList(entries: history, onRescan: onRescanHistory),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );

    if (embedded) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
          ),
        ),
        child: Stack(
          children: [
            const HomeCrabWatermark(alpha: 0.05, trayExtent: 28),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: content,
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kHomeNavyLift.withValues(alpha: 0.94),
                kHomeNavy.withValues(alpha: 0.96),
                kHomeNavyDeep.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: kHomeBlue.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            children: [
              const HomeCrabWatermark(alpha: 0.05, trayExtent: 28),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = lower.contains('health') ||
            lower.contains('ổn') ||
            lower.contains('healthy')
        ? kHomeGreen
        : lower.contains('warn') || lower.contains('cảnh')
            ? kHomeOrange
            : lower.contains('critical') || lower.contains('nghiêm')
                ? Colors.redAccent
                : kHomeCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: homeTileDecoration(radius: 14),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kHomeCyan,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kHomeBlueLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
