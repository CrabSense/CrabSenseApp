import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../home/presentation/widgets/crab_hologram_painter.dart';
import '../../../home/presentation/widgets/home_palette.dart';

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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kHomeNavyLift, kHomeNavy, kHomeNavyDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: CustomPaint(
                painter: CrabHologramPainter(
                  color: kHomeCyan.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          SafeArea(
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
                      color: kHomeBlue.withValues(alpha: 0.18),
                      border: Border.all(
                        color: kHomeCyan.withValues(alpha: 0.55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kHomeCyan.withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 40,
                      color: kHomeCyan,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cho phép truy cập Camera',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
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
                          color: Colors.white70,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF5BA0FF),
                            kHomeBlue,
                            Color(0xFF1A5FD0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kHomeBlue.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isPermanentlyDenied
                              ? () => openAppSettings()
                              : onRetry,
                          child: Center(
                            child: Text(
                              isPermanentlyDenied
                                  ? 'Mở Cài đặt'
                                  : 'Cho phép Camera',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: kHomeBlueLight),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
