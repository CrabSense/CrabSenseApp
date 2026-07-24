import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';

class AlertsEmptyState extends StatelessWidget {
  const AlertsEmptyState({
    required this.onRefresh,
    required this.onHistory,
    super.key,
  });

  final VoidCallback onRefresh;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 280,
              height: 220,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CrabHologramPainter(
                    color: Color(0x146FB0FF),
                    trayExtent: 28,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kHomeGreen.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 36,
                    color: kHomeGreen,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hiện không có cảnh báo nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hệ thống đang hoạt động ổn định',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Làm mới'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kHomeCyan,
                        foregroundColor: kHomeNavyDeep,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: onHistory,
                      child: const Text('Xem lịch sử'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AlertsFilterEmptyState extends StatelessWidget {
  const AlertsFilterEmptyState({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không có cảnh báo phù hợp với bộ lọc',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onClear, child: const Text('Xóa bộ lọc')),
          ],
        ),
      ),
    );
  }
}

class AlertsOfflineBanner extends StatelessWidget {
  const AlertsOfflineBanner({
    required this.lastSyncedAt,
    required this.pendingCount,
    required this.onRetrySync,
    super.key,
  });

  final DateTime? lastSyncedAt;
  final int pendingCount;
  final VoidCallback onRetrySync;

  @override
  Widget build(BuildContext context) {
    final syncLabel = lastSyncedAt == null
        ? 'Chưa đồng bộ'
        : 'Đồng bộ cuối: ${_fmt(lastSyncedAt!)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kHomeOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kHomeOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: kHomeOrange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dữ liệu ngoại tuyến',
                  style: TextStyle(
                    color: kHomeOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  pendingCount > 0
                      ? '$syncLabel · $pendingCount thay đổi chờ sync'
                      : syncLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetrySync,
            child: const Text('Thử đồng bộ lại'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class SectionErrorCard extends StatelessWidget {
  const SectionErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class AlertsNoPermissionState extends StatelessWidget {
  const AlertsNoPermissionState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Colors.white54,
            ),
            SizedBox(height: 12),
            Text(
              'Bạn chỉ có quyền xem cảnh báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Liên hệ quản lý nếu cần xử lý hoặc giao việc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
