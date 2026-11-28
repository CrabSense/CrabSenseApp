import 'package:flutter/material.dart';

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

  final String? crabId;
  final VoidCallback? onBack;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final state = HealthMonitoringState.unavailable(crabId: crabId);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onBack != null)
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
              Text(
                'Chưa có nguồn đánh giá xác minh',
                style: TextStyle(color: DashboardColors.textMuted),
              ),
              if (state.hasSelection && onOpenHistory != null)
                OutlinedButton(
                  onPressed: onOpenHistory,
                  child: const Text('Hồ sơ cua'),
                ),
              // No verified profile, no report construction or clipboard action.
              FilledButton.icon(
                key: const ValueKey('health-export'),
                onPressed: null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Xuất báo cáo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Giám sát sức khỏe',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.hasSelection
                ? 'Cua đang chọn: ${state.crabId}'
                : 'Chưa chọn cua',
            style: TextStyle(color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 16),
          HealthUnavailablePanel(state: state),
          if (state.hasSelection) ...[
            const SizedBox(height: 16),
            const HealthUnavailableDetails(),
          ],
        ],
      ),
    );
  }
}
