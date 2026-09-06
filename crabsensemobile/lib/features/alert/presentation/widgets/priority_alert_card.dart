import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/alerts_models.dart';
import 'alert_badges.dart';
import 'ai_recommended_action_card.dart';

class PriorityAlertCard extends StatelessWidget {
  const PriorityAlertCard({
    required this.alert,
    required this.onHandleNow,
    required this.onViewBox,
    required this.onAcknowledge,
    required this.onViewDetail,
    this.onAssign,
    super.key,
  });

  final AlertItem alert;
  final VoidCallback onHandleNow;
  final VoidCallback onViewBox;
  final VoidCallback onAcknowledge;
  final VoidCallback onViewDetail;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cảnh báo ưu tiên: ${alert.title}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              alert.severity.color.withValues(alpha: 0.22),
              kHomeSurface,
            ],
          ),
          border: Border.all(
            color: alert.severity.color.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: alert.severity.color.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const HomeCrabWatermark(alpha: 0.055, trayExtent: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        alert.severity.icon,
                        color: alert.severity.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${alert.severity.labelVi} · ưu tiên',
                        style: TextStyle(
                          color: alert.severity.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      AlertPriorityBadge(priority: alert.priority),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alert.title,
                    style: const TextStyle(
                      color: kHomeTextMain,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.locationLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  if (alert.threshold != null) ...[
                    const SizedBox(height: 10),
                    _MetaRow(
                      label: '${alert.threshold!.label} hiện tại',
                      value:
                          '${alert.threshold!.currentValue ?? '—'} ${alert.threshold!.unit ?? ''}'
                              .trim(),
                    ),
                    _MetaRow(
                      label: 'Ngưỡng an toàn',
                      value: alert.threshold!.allowedRange ?? '—',
                    ),
                  ],
                  _MetaRow(label: 'Phát hiện', value: _timeAgo(alert.detectedAt)),
                  if (alert.impactLevel != null)
                    _MetaRow(label: 'Ảnh hưởng', value: alert.impactLevel!),
                  _MetaRow(label: 'Hạn xử lý', value: alert.priority.slaLabel),
                  const SizedBox(height: 6),
                  Text(
                    alert.priority.explanation,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  if (alert.aiRecommendation != null) ...[
                    const SizedBox(height: 12),
                    AIRecommendedActionCard(
                      recommendation: alert.aiRecommendation!,
                      compact: true,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroBtn(
                        label: 'Xử lý ngay',
                        filled: true,
                        onPressed: onHandleNow,
                      ),
                      if (alert.boxId != null)
                        _HeroBtn(label: 'Xem Box', onPressed: onViewBox),
                      _HeroBtn(label: 'Xác nhận đã xem', onPressed: onAcknowledge),
                      if (onAssign != null)
                        _HeroBtn(label: 'Giao việc', onPressed: onAssign!),
                      _HeroBtn(label: 'Xem chi tiết', onPressed: onViewDetail),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
    if (d.inHours < 24) return '${d.inHours} giờ trước';
    return '${d.inDays} ngày trước';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  const _HeroBtn({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kHomeCyan,
          foregroundColor: kHomeBg,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: kHomeBorderBlue),
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
