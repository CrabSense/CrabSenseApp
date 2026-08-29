import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';
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
  final delta = healthScore.deltaVsYesterday;
  final deltaPositive = delta >= 0;
  final deltaColor = deltaPositive ? kHomeGreen : CrabSenseColors.danger;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kHomeSurface, kHomeBg, kHomeBg],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: kHomeBorderBlue.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: kHomeBlue.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Họa tiết lưới khay nuôi + cua (đồng bộ trang home)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CrabHologramPainter(
                    color: kHomeBlueLight.withValues(alpha: 0.07),
                    trayExtent: 28,
                  ),
                ),
              ),
            ),
            // Vệt sáng cạnh trên
            Positioned(
              top: 0,
              left: 32,
              right: 32,
              height: 1,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        kHomeBlueLight.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh kéo phát sáng
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kHomeBorderBlue.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: kHomeBlue.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header: icon phát sáng + tiêu đề + nút đóng
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kHomeBlue.withValues(alpha: 0.14),
                            border: Border.all(
                              color: kHomeBlue.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kHomeBlue.withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.insights_rounded,
                            color: kHomeBlueLight,
                            size: 20,
                            shadows: [
                              Shadow(
                                color: kHomeBlue.withValues(alpha: 0.9),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PHÂN TÍCH FARM HEALTH',
                                style: TextStyle(
                                  color: kHomePrimaryDark,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (farmName != null && farmName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  farmName,
                                  style: const TextStyle(
                                    color: CrabSenseColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        _SheetCloseButton(onTap: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Điểm số + trạng thái
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: homeTileDecoration(radius: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: statusColor,
                                        width: 4,
                                      ),
                                      color:
                                          statusColor.withValues(alpha: 0.12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${healthScore.score}',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                        shadows: [
                                          Shadow(
                                            color: statusColor.withValues(
                                              alpha: 0.7,
                                            ),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: statusColor.withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: statusColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ],
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
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              deltaPositive
                                                  ? Icons.trending_up_rounded
                                                  : Icons
                                                      .trending_down_rounded,
                                              size: 16,
                                              color: deltaColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${deltaPositive ? '+' : ''}'
                                              '${delta.toStringAsFixed(0)}% '
                                              'so với hôm qua',
                                              style: TextStyle(
                                                color: deltaColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cập nhật AI: '
                                          '${_formatTime(healthScore.lastAiUpdated)}',
                                          style: const TextStyle(
                                            color: CrabSenseColors.hintText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Giải thích từ AI
                            const _SectionLabel(
                              icon: Icons.auto_awesome_rounded,
                              label: 'GIẢI THÍCH TỪ AI',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: homeTileDecoration(radius: 12),
                              child: Text(
                                healthScore.explanation.isNotEmpty
                                    ? healthScore.explanation
                                    : 'Chưa có giải thích từ hệ thống.',
                                style: const TextStyle(
                                  color: kHomeTextMain,
                                  height: 1.45,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Chỉ số thành phần
                            const _SectionLabel(
                              icon: Icons.stacked_bar_chart_rounded,
                              label: 'CHỈ SỐ THÀNH PHẦN',
                            ),
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.go(RoutePaths.waterQuality);
                                    },
                                    icon: const Icon(
                                      Icons.water_drop_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Xem nước'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kHomeBlueLight,
                                      side: BorderSide(
                                        color: kHomeBorderBlue.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      minimumSize: const Size(48, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.go(RoutePaths.alerts);
                                    },
                                    icon: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Cảnh báo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kHomeBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      shadowColor:
                                          kHomeBlue.withValues(alpha: 0.6),
                                      minimumSize: const Size(48, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

/// Nhãn section in hoa xanh sáng với icon phát sáng.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: kHomeBlueLight,
          shadows: [
            Shadow(
              color: kHomeBlueLight.withValues(alpha: 0.8),
              blurRadius: 10,
            ),
          ],
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: kHomePrimaryDark,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Nút đóng tròn nhỏ trong bottom sheet.
class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kHomeBg.withValues(alpha: 0.9),
            border: Border.all(
              color: kHomeBorderBlue.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: CrabSenseColors.hintText,
            size: 18,
          ),
        ),
      ),
    );
  }
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
        : (score >= 70
            ? CrabSenseColors.info
            : (score >= 50 ? CrabSenseColors.warning : CrabSenseColors.danger));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: homeTileDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: kHomeTextMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.clamp(0, 100)) / 100.0,
              minHeight: 6,
              backgroundColor: kHomeSurface,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
