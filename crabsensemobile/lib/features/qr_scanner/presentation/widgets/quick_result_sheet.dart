import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
                color: CrabSenseColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
        if (result.isOffline)
          OfflineBanner(onSync: onSync),
        Text(
          result.code,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              result.farmName,
              style: const TextStyle(color: CrabSenseColors.textSecondary),
            ),
            const SizedBox(width: 10),
            _StatusPill(label: result.statusLabel),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Health',
                value: '${result.healthScore}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'AI Score',
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
        Row(
          children: [
            if (result.temperature != null)
              _ChipStat(
                icon: Icons.thermostat,
                text: '${result.temperature!.toStringAsFixed(0)}°C',
              ),
            if (result.ph != null) ...[
              const SizedBox(width: 8),
              _ChipStat(
                icon: Icons.water_drop_outlined,
                text: 'pH ${result.ph!.toStringAsFixed(1)}',
              ),
            ],
            const Spacer(),
            Text(
              'Updated ${result.relativeUpdatedLabel}',
              style: const TextStyle(
                color: CrabSenseColors.hintText,
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
      return ColoredBox(
        color: CrabSenseColors.surface.withValues(alpha: 0.96),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: content,
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
            color: CrabSenseColors.surface.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: CrabSenseColors.border),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: content,
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
    final color = label.toLowerCase().contains('health')
        ? CrabSenseColors.success
        : label.toLowerCase().contains('warn')
            ? CrabSenseColors.warning
            : label.toLowerCase().contains('critical')
                ? CrabSenseColors.danger
                : CrabSenseColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: CrabSenseColors.container.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CrabSenseColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: CrabSenseColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: CrabSenseColors.hintText,
              fontSize: 11,
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
        Icon(icon, size: 14, color: CrabSenseColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: CrabSenseColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
