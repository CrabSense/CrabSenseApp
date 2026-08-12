import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_palette.dart';

/// Dark cutout overlay with QR frame, scan line, and glow corners.
class CameraOverlay extends StatefulWidget {
  const CameraOverlay({
    super.key,
    this.isSuccess = false,
    this.isProcessing = false,
    this.hint = 'Đưa mã QR vào giữa khung',
    this.frameSize,
  });

  final bool isSuccess;
  final bool isProcessing;
  final String hint;

  /// Fixed size; when null, sized from [LayoutBuilder].
  final double? frameSize;

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _line;

  @override
  void initState() {
    super.initState();
    _line = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isSuccess
        ? kHomeGreen
        : widget.isProcessing
            ? kHomeOrange
            : kHomeCyan;
    final topInset = MediaQuery.paddingOf(context).top + 96;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 88;

    return LayoutBuilder(
      builder: (context, constraints) {
        final usableH =
            (constraints.maxHeight - topInset - bottomInset).clamp(160.0, 9999.0);
        final usableW = constraints.maxWidth;
        final maxSide = usableH < usableW ? usableH : usableW;
        final side =
            (widget.frameSize ?? (maxSide * 0.72)).clamp(200.0, 280.0);
        final frameCenterY = topInset + usableH / 2;

        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _CutoutPainter(
                frameSide: side,
                frameCenter: Offset(constraints.maxWidth / 2, frameCenterY),
                overlayColor: Colors.black.withValues(alpha: 0.58),
              ),
            ),
            Positioned(
              left: (constraints.maxWidth - side) / 2,
              top: frameCenterY - side / 2,
              width: side,
              height: side,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    size: Size(side, side),
                    painter: _CornerGlowPainter(color: accent),
                  ),
                  AnimatedBuilder(
                    animation: _line,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(0, -0.85 + 1.7 * _line.value),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0),
                              accent,
                              accent.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.55),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.isSuccess)
                    const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: kHomeGreen,
                        size: 56,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: frameCenterY + side / 2 + 20,
              child: Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 10,
                        ),
                        const Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CutoutPainter extends CustomPainter {
  _CutoutPainter({
    required this.frameSide,
    required this.frameCenter,
    required this.overlayColor,
  });

  final double frameSide;
  final Offset frameCenter;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final cut = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: frameCenter,
        width: frameSide,
        height: frameSide,
      ),
      const Radius.circular(20),
    );
    path.addRRect(cut);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) =>
      oldDelegate.frameSide != frameSide ||
      oldDelegate.frameCenter != frameCenter ||
      oldDelegate.overlayColor != overlayColor;
}

class _CornerGlowPainter extends CustomPainter {
  _CornerGlowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const inset = 4.0;

    canvas.drawLine(
      const Offset(inset, inset + len),
      const Offset(inset, inset),
      paint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + len, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset - len, inset),
      Offset(size.width - inset, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + len),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset - len),
      Offset(inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + len, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset - len, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset - len),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerGlowPainter oldDelegate) =>
      oldDelegate.color != color;
}
