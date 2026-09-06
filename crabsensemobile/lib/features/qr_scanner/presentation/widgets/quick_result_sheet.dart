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
                color: kHomeBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Green header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kHomePrimary, kHomePrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.code,
                    style: const TextStyle(
                      color: kHomeTextMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusPill(label: result.statusLabel),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            result.code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kHomeTextMain,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          _StatusPill(label: result.statusLabel),
          const SizedBox(height: 12),
        ],
        if (result.isOffline) OfflineBanner(onSync: onSync),
        // Farm + data rows
        _DataRow(label: 'Trang trại', value: result.farmName),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _MetricTile(label: 'Sức khỏe', value: '${result.healthScore}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(label: 'Điểm AI', value: '${result.aiScore}'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(label: 'Số cua', value: '${result.crabCount}'),
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
              style: const TextStyle(
                color: kHomeTextHint,
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
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onAction(ScanQuickAction.scanAgain),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kHomePrimary,
                  side: const BorderSide(color: kHomePrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size.zero,
                ),
                child: const Text('Đóng',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onAction(ScanQuickAction.details),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHomePrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size.zero,
                ),
                child: const Text('Chi tiết',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );

    if (embedded) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: kHomeShadow, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: content,
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
        ? kHomePrimary
        : lower.contains('warn') || lower.contains('cảnh')
            ? kHomeWarning
            : lower.contains('critical') || lower.contains('nghiêm')
                ? kHomeDanger
                : kHomePrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: kHomeTextSub),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kHomeTextMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: kHomePrimaryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kHomeBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kHomePrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kHomeTextSub,
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
        Icon(icon, size: 14, color: kHomeSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: kHomeTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
