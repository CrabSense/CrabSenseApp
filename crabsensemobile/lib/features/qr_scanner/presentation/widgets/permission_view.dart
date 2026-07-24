import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-screen permission gate for camera access.
class PermissionView extends StatelessWidget {
  const PermissionView({
    required this.isPermanentlyDenied,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final bool isPermanentlyDenied;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CrabSenseColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CrabSenseColors.container,
                  border: Border.all(color: CrabSenseColors.border),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 40,
                  color: CrabSenseColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cho phép truy cập Camera',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: CrabSenseColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isPermanentlyDenied
                    ? 'Quyền camera đã bị tắt. Mở Cài đặt để bật lại và quét QR.'
                    : 'CrabSense cần camera để quét mã QR trên hộp nuôi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CrabSenseColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isPermanentlyDenied
                      ? () => openAppSettings()
                      : onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: CrabSenseColors.primary,
                    foregroundColor: CrabSenseColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isPermanentlyDenied ? 'Mở Cài đặt' : 'Cho phép Camera',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onCancel,
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
