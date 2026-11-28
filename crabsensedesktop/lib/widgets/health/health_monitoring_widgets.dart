import 'package:flutter/material.dart';

import '../../models/health_monitoring.dart';
import '../../theme/dashboard_theme.dart';

/// Unavailable-state cards deliberately contain no inferred measurements,
/// diagnoses, thresholds, trend charts, or AI recommendations.
class HealthUnavailablePanel extends StatelessWidget {
  const HealthUnavailablePanel({super.key, required this.state});

  final HealthMonitoringState state;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: DashboardColors.textMuted),
          const SizedBox(height: 12),
          Text(
            state.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.explanation,
            style: TextStyle(color: DashboardColors.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            state.exportReason,
            style: TextStyle(color: DashboardColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class HealthUnavailableDetails extends StatelessWidget {
  const HealthUnavailableDetails({super.key});

  static const sections = <String>[
    'Điểm sức khỏe',
    'Nguy cơ bệnh',
    'Tình trạng lột xác',
    'Hoạt động',
    'Cho ăn',
    'Tăng trưởng',
    'Chất lượng nước RAS',
    'Đánh giá và đề xuất AI',
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final title in sections)
        Card(
          child: ListTile(
            title: Text(title),
            subtitle: const Text('Chưa có dữ liệu xác minh'),
            trailing: Text(
              '—',
              style: TextStyle(
                color: DashboardColors.textMuted,
                fontSize: 18,
              ),
            ),
          ),
        ),
    ],
  );
}
