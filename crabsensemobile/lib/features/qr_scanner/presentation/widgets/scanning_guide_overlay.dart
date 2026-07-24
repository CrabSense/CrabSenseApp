import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Overlay widget that guides the user to align the QR code for scanning.
///
/// Displays a semi-transparent dark overlay with a centered transparent
/// scanning frame, corner brackets, and contextual status indicators
/// for processing, success, and error states.
///
/// Requirements: 3.1, 3.4, 3.6, 24.1, 24.2
class ScanningGuideOverlay extends StatelessWidget {
  const ScanningGuideOverlay({
    required this.isProcessing,
    required this.isSuccess,
    required this.isError,
    super.key,
  });

  final bool isProcessing;
  final bool isSuccess;
  final bool isError;

  static const double _frameSide = 250;
  static const double _overlayOpacity = 0.6;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const _ScanningCutout(frameSide: _frameSide, overlayOpacity: _overlayOpacity),
      const _CornerBrackets(side: _frameSide),
      _StatusIndicator(isProcessing: isProcessing, isSuccess: isSuccess, isError: isError),
    ],
  );
}

/// Renders the semi-transparent overlay with a transparent square cutout.
class _ScanningCutout extends StatelessWidget {
  const _ScanningCutout({required this.frameSide, required this.overlayOpacity});

  final double frameSide;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CutoutPainter(
      frameSide: frameSide,
      overlayColor: Colors.black.withValues(alpha: overlayOpacity),
    ),
    child: const SizedBox.expand(),
  );
}

/// Renders the L-shaped corner brackets around the scanning frame.
class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: side,
    height: side,
    child: const CustomPaint(painter: _CornerBracketPainter(color: CrabSenseColors.primary)),
  );
}

/// Shows the appropriate status indicator inside the scanning frame.
class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.isProcessing,
    required this.isSuccess,
    required this.isError,
  });

  final bool isProcessing;
  final bool isSuccess;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(color: CrabSenseColors.primary, strokeWidth: 3),
      );
    }

    if (isSuccess) {
      return const Icon(Icons.check_circle, color: CrabSenseColors.success, size: 64);
    }

    if (isError) {
      return const Icon(Icons.error, color: CrabSenseColors.error, size: 64);
    }

    return const _GuideText();
  }
}

/// The instructional text shown when scanner is idle.
class _GuideText extends StatelessWidget {
  const _GuideText();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'Align QR code within the frame',
      style: TextStyle(
        color: CrabSenseColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

/// [CustomPainter] that draws the semi-transparent overlay with a
/// transparent rectangular cutout at the center.
class _CutoutPainter extends CustomPainter {
  const _CutoutPainter({required this.frameSide, required this.overlayColor});

  final double frameSide;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = overlayColor;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final halfFrame = frameSide / 2;

    final frameRect = Rect.fromLTRB(
      centerX - halfFrame,
      centerY - halfFrame,
      centerX + halfFrame,
      centerY + halfFrame,
    );

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(fullRect)
      ..addRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(_CutoutPainter oldDelegate) =>
      oldDelegate.frameSide != frameSide || oldDelegate.overlayColor != overlayColor;
}

/// [CustomPainter] that draws L-shaped corner brackets in the given color.
class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({required this.color});

  final Color color;

  static const double _bracketLength = 28;
  static const double _strokeWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Top-left corner
    canvas
      ..drawLine(const Offset(0, _bracketLength), Offset.zero, paint)
      ..drawLine(Offset.zero, const Offset(_bracketLength, 0), paint)
      // Top-right corner
      ..drawLine(Offset(w, _bracketLength), Offset(w, 0), paint)
      ..drawLine(Offset(w, 0), Offset(w - _bracketLength, 0), paint)
      // Bottom-left corner
      ..drawLine(Offset(0, h - _bracketLength), Offset(0, h), paint)
      ..drawLine(Offset(0, h), Offset(_bracketLength, h), paint)
      // Bottom-right corner
      ..drawLine(Offset(w, h - _bracketLength), Offset(w, h), paint)
      ..drawLine(Offset(w, h), Offset(w - _bracketLength, h), paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter oldDelegate) => oldDelegate.color != color;
}
