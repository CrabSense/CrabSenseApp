import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'home_palette.dart';

/// Bottom sheet chi tiết Farm Health Score (nút "Xem phân tích").
void showFarmHealthAnalysisSheet(
  BuildContext context, {
  required FarmHealthScore healthScore,
  String? farmName,
}) {
  final statusColor = switch (healthScore.statusLevel) {
    HealthStatusLevel.excellent => CrabSenseColors.success,
    HealthStatusLevel.good => CrabSenseColors.info,
    HealthStatusLevel.warning => CrabSenseColors.warning,
    HealthStatusLevel.danger => CrabSenseColors.danger,
  };

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kHomeNavy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CrabSenseColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Phân tích Farm Health',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CrabSenseColors.textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: CrabSenseColors.hintText),
                    ),
                  ],
                ),
                if (farmName != null && farmName.isNotEmpty) ...[
                  Text(
                    farmName,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: CrabSenseColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor, width: 4),
                        color: statusColor.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        '${healthScore.score}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              healthScore.statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'So với hôm qua: '
                            '${healthScore.deltaVsYesterday >= 0 ? '+' : ''}'
                            '${healthScore.deltaVsYesterday.toStringAsFixed(0)}%',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: CrabSenseColors.textSecondary,
                                ),
                          ),
                          Text(
                            'Cập nhật AI: ${_formatTime(healthScore.lastAiUpdated)}',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: CrabSenseColors.hintText,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Giải thích',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CrabSenseColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  healthScore.explanation.isNotEmpty
                      ? healthScore.explanation
                      : 'Chưa có giải thích từ hệ thống.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: CrabSenseColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chỉ số thành phần',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CrabSenseColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                _FactorBar(
                  label: 'Chất lượng nước',
                  score: healthScore.waterQualityScore,
                  icon: Icons.water_drop_rounded,
                ),
                const SizedBox(height: 10),
                _FactorBar(
                  label: 'Sức khỏe cua',
                  score: healthScore.crabHealthScore,
                  icon: Icons.favorite_rounded,
                ),
                const SizedBox(height: 10),
                _FactorBar(
                  label: 'Thiết bị IoT',
                  score: healthScore.deviceStatusScore,
                  icon: Icons.memory_rounded,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go(RoutePaths.waterQuality);
                        },
                        icon: const Icon(Icons.water_drop_outlined, size: 18),
                        label: const Text('Xem nước'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kHomeBlueLight,
                          side: BorderSide(
                            color: kHomeBorderBlue.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go(RoutePaths.alerts);
                        },
                        icon: const Icon(Icons.warning_amber_rounded, size: 18),
                        label: const Text('Cảnh báo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kHomeBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm · ${local.day}/${local.month}/${local.year}';
}

class _FactorBar extends StatelessWidget {
  const _FactorBar({
    required this.label,
    required this.score,
    required this.icon,
  });

  final String label;
  final int score;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? CrabSenseColors.success
        : (score >= 70 ? CrabSenseColors.info : (score >= 50 ? CrabSenseColors.warning : CrabSenseColors.danger));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: homeTileDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.clamp(0, 100)) / 100.0,
              minHeight: 6,
              backgroundColor: kHomeNavyLift,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
