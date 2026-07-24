import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_palette.dart';

class OfflineBanner extends StatelessWidget {
  final DateTime? lastSyncedAt;
  final VoidCallback onRetryPressed;

  const OfflineBanner({
    super.key,
    required this.lastSyncedAt,
    required this.onRetryPressed,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Chưa rõ';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kHomeNavy, kHomeNavyDeep],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CrabSenseColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: CrabSenseColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dữ liệu ngoại tuyến (Offline Cache)',
                  style: TextStyle(
                    color: CrabSenseColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Thời gian đồng bộ gần nhất: ${_formatTime(lastSyncedAt)}',
                  style: const TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onRetryPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: CrabSenseColors.warning,
              side: const BorderSide(color: CrabSenseColors.warning),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Thử lại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
