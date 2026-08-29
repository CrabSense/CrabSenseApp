import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.onSync,
    this.message = 'Dữ liệu ngoại tuyến',
    super.key,
  });

  final String message;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kHomeOrange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHomeOrange.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: kHomeOrange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: kHomeTextMain,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TextButton(
              onPressed: onSync,
              style: TextButton.styleFrom(
                foregroundColor: kHomeOrange,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Đồng bộ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
