import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_health_monitoring_data.dart';
import '../../models/health_monitoring.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/health/health_monitoring_widgets.dart';

class HealthMonitoringPage extends StatelessWidget {
  const HealthMonitoringPage({
    super.key,
    required this.crabId,
    this.onBack,
    this.onOpenHistory,
  });

  final String crabId;
  final VoidCallback? onBack;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final profile = MockHealthMonitoringData.profileFor(crabId);
    final alerts = MockHealthMonitoringData.autoAlerts(profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(
            profile: profile,
            onBack: onBack,
            onExport: () => _exportReport(context, profile),
            onHistory: onOpenHistory,
          ),
          const SizedBox(height: 24),
          HealthKpiStrip(profile: profile),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 1000;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HealthScoreBreakdownCard(profile: profile),
                          if (alerts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _AlertsCard(alerts: alerts),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IndexContributionChart(profile: profile),
                          const SizedBox(height: 16),
                          HealthTrendChart(profile: profile),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 300,
                      child: CrabAssistantPanel(profile: profile),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HealthScoreBreakdownCard(profile: profile),
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _AlertsCard(alerts: alerts),
                  ],
                  const SizedBox(height: 16),
                  IndexContributionChart(profile: profile),
                  const SizedBox(height: 16),
                  HealthTrendChart(profile: profile),
                  const SizedBox(height: 16),
                  CrabAssistantPanel(profile: profile),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          MonitorDetailCards(profile: profile),
          const SizedBox(height: 16),
          _FormulaCard(components: profile.components),
        ],
      ),
    );
  }

  void _exportReport(BuildContext context, HealthMonitoringProfile profile) {
    final c = profile.components;
    final report = '''
BÁO CÁO HEALTH MONITORING — ${profile.crabId}
Hộp ${profile.boxId} | Lứa ${profile.batchId}

Health Score: ${profile.healthScore.toStringAsFixed(1)}/100 (${profile.level.label})

Thành phần:
- Activity: ${c.activity} → ${c.activityContribution.toStringAsFixed(1)} điểm (30%)
- Feeding: ${c.feeding} → ${c.feedingContribution.toStringAsFixed(1)} điểm (25%)
- Growth: ${c.growth} → ${c.growthContribution.toStringAsFixed(1)} điểm (20%)
- Water: ${c.waterQuality} → ${c.waterContribution.toStringAsFixed(1)} điểm (15%)
- Disease: ${c.diseaseStatus} → ${c.diseaseContribution.toStringAsFixed(1)} điểm (10%)

AI: ${profile.aiRecommendation}
''';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardColors.card,
        title: const Text('Xuất báo cáo'),
        content: SelectableText(report, style: GoogleFonts.notoSans(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sao chép'),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.profile,
    this.onBack,
    required this.onExport,
    this.onHistory,
  });

  final HealthMonitoringProfile profile;
  final VoidCallback? onBack;
  final VoidCallback onExport;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DashboardColors.risk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: DashboardColors.risk.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: DashboardColors.risk,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE MONITOR',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.risk,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (onHistory != null)
              OutlinedButton(
                onPressed: onHistory,
                child: const Text('Lịch sử'),
              ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Xuất báo cáo'),
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Giám sát Sức khỏe AI',
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Theo dõi sức khỏe cua theo thời gian thực · ${profile.crabId}',
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 14),
        ),
      ],
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.risk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.risk.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cảnh báo tự động',
            style: GoogleFonts.notoSans(
              color: DashboardColors.risk,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $a', style: GoogleFonts.notoSans(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.components});

  final HealthScoreComponents components;

  @override
  Widget build(BuildContext context) {
    final total = components.total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.cardBorder),
      ),
      child: Text(
        'Health Score = ${components.activity}×30% + ${components.feeding}×25% + '
        '${components.growth}×20% + ${components.waterQuality}×15% + '
        '${components.diseaseStatus}×10% = ${total.toStringAsFixed(1)}',
        style: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 11,
        ),
      ),
    );
  }
}
