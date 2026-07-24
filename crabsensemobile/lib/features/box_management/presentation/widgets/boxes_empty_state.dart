import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BoxesEmptyState extends StatelessWidget {
  const BoxesEmptyState({
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon = Icons.inventory_2_outlined,
    super.key,
  });

  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData icon;

  factory BoxesEmptyState.noBoxes({
    Key? key,
    required bool canCreate,
    VoidCallback? onCreate,
  }) {
    return BoxesEmptyState(
      key: key,
      title: 'Chưa có Box nào trong trại này',
      message: canCreate
          ? 'Bắt đầu bằng cách thêm Box đầu tiên vào khu nuôi.'
          : 'Liên hệ quản lý trang trại để được phân công Box.',
      primaryLabel: canCreate ? 'Thêm Box' : null,
      onPrimary: canCreate ? onCreate : null,
      icon: Icons.inventory_2_outlined,
    );
  }

  factory BoxesEmptyState.search({
    Key? key,
    required VoidCallback onClearSearch,
    required VoidCallback onResetFilters,
  }) {
    return BoxesEmptyState(
      key: key,
      title: 'Không tìm thấy Box phù hợp',
      message: 'Thử đổi từ khóa hoặc đặt lại bộ lọc đang áp dụng.',
      primaryLabel: 'Xóa từ khóa',
      onPrimary: onClearSearch,
      secondaryLabel: 'Đặt lại bộ lọc',
      onSecondary: onResetFilters,
      icon: Icons.search_off_rounded,
    );
  }

  factory BoxesEmptyState.noPermission() {
    return const BoxesEmptyState(
      title: 'Không có quyền truy cập',
      message: 'Tài khoản của bạn chưa được cấp quyền xem danh sách Box.',
      icon: Icons.lock_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CrabSenseColors.container,
                border: Border.all(color: CrabSenseColors.border),
              ),
              child: Icon(icon, color: CrabSenseColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CrabSenseColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CrabSenseColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (primaryLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: CrabSenseColors.primary,
                  foregroundColor: CrabSenseColors.background,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(primaryLabel!),
              ),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class BoxesOfflineBanner extends StatelessWidget {
  const BoxesOfflineBanner({
    required this.lastSyncedAt,
    required this.onRetry,
    super.key,
  });

  final DateTime? lastSyncedAt;
  final VoidCallback onRetry;

  String _format(DateTime? dt) {
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
        color: CrabSenseColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrabSenseColors.warning),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: CrabSenseColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dữ liệu ngoại tuyến',
                  style: TextStyle(
                    color: CrabSenseColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Đồng bộ cuối: ${_format(lastSyncedAt)}',
                  style: const TextStyle(
                    color: CrabSenseColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: CrabSenseColors.warning,
              side: const BorderSide(color: CrabSenseColors.warning),
              minimumSize: const Size(48, 36),
            ),
            child: const Text(
              'Thử đồng bộ lại',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class BoxesSectionErrorCard extends StatelessWidget {
  const BoxesSectionErrorCard({
    required this.message,
    required this.onRetry,
    this.title = 'Danh sách Box',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CrabSenseColors.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: CrabSenseColors.danger,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Lỗi nạp dữ liệu: $title',
                style: const TextStyle(
                  color: CrabSenseColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: CrabSenseColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
              style: TextButton.styleFrom(
                foregroundColor: CrabSenseColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
