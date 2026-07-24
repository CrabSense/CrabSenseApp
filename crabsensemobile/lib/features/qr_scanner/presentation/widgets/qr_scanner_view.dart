import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'camera_overlay.dart';

/// Full-bleed camera preview + scanner overlay.
class QRScannerView extends StatelessWidget {
  const QRScannerView({
    required this.controller,
    required this.onDetect,
    this.isSuccess = false,
    this.isProcessing = false,
    this.showOverlay = true,
    super.key,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final bool isSuccess;
  final bool isProcessing;
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
          fit: BoxFit.cover,
        ),
        if (showOverlay)
          CameraOverlay(
            isSuccess: isSuccess,
            isProcessing: isProcessing,
          ),
      ],
    );
  }
}
