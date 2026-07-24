import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/home_models.dart';
import 'crab_hologram_painter.dart';
import 'home_palette.dart';

/// Bottom sheet chi tiết khuyến nghị AI (nút "Xem chi tiết").
void showAiRecommendationDetailSheet(
  BuildContext context, {
  required AiRecommendation recommendation,
  required VoidCallback onExecutePressed,
  VoidCallback? onRemindLaterPressed,
  VoidCallback? onDismissPressed,
}) {
  final priorityColor = switch (recommendation.priority) {
    ActionPriority.high => kHomeOrange,
    ActionPriority.medium => kHomeCyan,
    ActionPriority.low => kHomeGreen,
  };
  final priorityLabel = switch (recommendation.priority) {
    ActionPriority.high => 'Ưu tiên Cao',
    ActionPriority.medium => 'Ưu tiên Vừa',
    ActionPriority.low => 'Bình thường',
  };

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
            colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
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
                    // Header
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
                            Icons.auto_awesome_rounded,
                            color: kHomeBlueLight,
                            size: 19,
                            shadows: [
                              Shadow(
                                color: kHomeBlue.withValues(alpha: 0.9),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'CHI TIẾT KHUYẾN NGHỊ AI',
                            style: TextStyle(
                              color: kHomeBlueLight,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            // Pill ưu tiên + độ tin cậy
                            Row(
                              children: [
                                _Pill(
                                  label: priorityLabel,
                                  color: priorityColor,
                                ),
                                const SizedBox(width: 8),
                                _Pill(
                                  label:
                                      'Tin cậy ${recommendation.confidencePercentage}%',
                                  color: kHomeGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Tiêu đề + mục tiêu
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: homeTileDecoration(radius: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recommendation.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 15,
                                        color: kHomeBlue,
                                        shadows: [
                                          Shadow(
                                            color: kHomeBlue.withValues(
                                              alpha: 0.8,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          recommendation.targetBoxOrArea,
                                          style: const TextStyle(
                                            color: kHomeBlueLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    recommendation.description,
                                    style: const TextStyle(
                                      color: CrabSenseColors.textSecondary,
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Các thông tin phân tích của AI
                            _InfoTile(
                              icon: Icons.psychology_rounded,
                              iconColor: kHomePurple,
                              label: 'LÝ DO (AI PHÂN TÍCH)',
                              value: recommendation.reason,
                            ),
                            const SizedBox(height: 10),
                            _InfoTile(
                              icon: Icons.schedule_rounded,
                              iconColor: kHomeOrange,
                              label: 'THỜI ĐIỂM TỐI ƯU',
                              value: recommendation.optimalTimeframe,
                            ),
                            const SizedBox(height: 10),
                            _InfoTile(
                              icon: Icons.trending_up_rounded,
                              iconColor: kHomeGreen,
                              label: 'TÁC ĐỘNG KỲ VỌNG',
                              value: recommendation.expectedImpact,
                            ),
                            const SizedBox(height: 20),
                            // Nút thực hiện ngay (gradient glow)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          kHomeBlue.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      onExecutePressed();
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    splashColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF4D9AFF),
                                            kHomeBlue,
                                            Color(0xFF1E5FD6),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.bolt_rounded,
                                              size: 19,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Thực hiện ngay',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (onRemindLaterPressed != null)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      onRemindLaterPressed();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          CrabSenseColors.hintText,
                                    ),
                                    child: const Text(
                                      'Nhắc lại sau',
                                      style: TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                if (onDismissPressed != null)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      onDismissPressed();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          CrabSenseColors.hintText,
                                    ),
                                    child: const Text(
                                      'Bỏ qua',
                                      style: TextStyle(fontSize: 12.5),
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

/// Pill nhỏ có viền + glow theo màu.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/// Ô thông tin: icon phát sáng + nhãn in hoa + nội dung.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: homeTileDecoration(radius: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.14),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kHomeBlueLight.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            color: kHomeNavy.withValues(alpha: 0.9),
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
