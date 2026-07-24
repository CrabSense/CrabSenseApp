import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_palette.dart';

class SectionErrorCard extends StatelessWidget {
  final String sectionTitle;
  final String errorMessage;
  final VoidCallback onRetry;

  const SectionErrorCard({
    super.key,
    required this.sectionTitle,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kHomeNavy, kHomeNavyDeep],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CrabSenseColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: CrabSenseColors.danger, size: 18),
              const SizedBox(width: 8),
              Text(
                'Lỗi nạp dữ liệu: $sectionTitle',
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
            errorMessage,
            style: const TextStyle(color: CrabSenseColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại section'),
              style: TextButton.styleFrom(
                foregroundColor: kHomeBlueLight,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
