import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';
import '../../domain/models/boxes_models.dart';

class BoxStatusBadge extends StatelessWidget {
  const BoxStatusBadge({required this.status, this.compact = false, super.key});

  final BoxStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Semantics(
      label: 'Trạng thái ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji 🟢🟡🟣🔴 giống hệt app desktop.
            Text(status.emoji, style: TextStyle(fontSize: compact ? 10 : 11)),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AIHealthBadge extends StatelessWidget {
  const AIHealthBadge({
    required this.healthScore,
    this.compact = false,
    this.onExplain,
    super.key,
  });

  final BoxHealthScore healthScore;
  final bool compact;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chưa có đánh giá sức khỏe và AI được xác minh',
      child: Container(
        padding: EdgeInsets.all(compact ? 6 : 10),
        decoration: BoxDecoration(
          color: kHomeBg.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kHomeBorderBlue.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: kHomeTextSub),
            const SizedBox(width: 6),
            Expanded(child: Text('Chưa có đánh giá xác minh',
              style: TextStyle(color: kHomeTextSub, fontSize: compact ? 10 : 12))),
          ],
        ),
      ),
    );
  }
}
