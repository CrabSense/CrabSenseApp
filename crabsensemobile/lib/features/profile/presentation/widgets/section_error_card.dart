import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Inline Error Card for Single Section Failures
class ProfileSectionErrorCard extends StatelessWidget {
  final String sectionTitle;
  final String errorMessage;
  final VoidCallback onRetry;

  const ProfileSectionErrorCard({
    super.key,
    required this.sectionTitle,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CrabSenseColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrabSenseColors.danger.withValues(alpha: 0.4), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CrabSenseColors.danger.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: CrabSenseColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lỗi tải $sectionTitle',
                  style: const TextStyle(
                    color: CrabSenseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: CrabSenseColors.hintText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Thử lại', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: CrabSenseColors.primary,
              backgroundColor: CrabSenseColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
