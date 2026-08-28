import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';

/// Lets the operator choose a box first or start camera scanning.
Future<void> showQrEntryChoiceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: CrabSenseColors.hintText.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mở thao tác với hộp nuôi',
              style: TextStyle(
                color: CrabSenseColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn hộp trước hoặc dùng camera để nhận diện mã QR.',
              style: TextStyle(color: CrabSenseColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.push(RoutePaths.boxes);
                    },
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Chọn hộp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CrabSenseColors.primary,
                      side: const BorderSide(color: CrabSenseColors.primary),
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.push(RoutePaths.scanner);
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Quét mã'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CrabSenseColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
