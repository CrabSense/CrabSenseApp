import 'package:flutter/material.dart';

/// Nền hologram dùng chung cho trang home: lưới khay nuôi isometric với cua
/// wireframe trong từng khay, một con cua lớn phát sáng làm điểm nhấn.
///
/// [trayExtent]: kích thước khay; mặc định tính theo chiều cao vùng vẽ
/// (phù hợp cho thanh thấp như bộ chọn khu). Với vùng cao (card lớn) nên
/// truyền giá trị cố định, ví dụ 24–30.
class CrabHologramPainter extends CustomPainter {
  const CrabHologramPainter({required this.color, this.trayExtent});

  final Color color;
  final double? trayExtent;

  @override
  void paint(Canvas canvas, Size size) {
    // Nét sáng cho con cua điểm nhấn (đậm hơn hẳn các khay nền)
    final heroColor =
        color.withValues(alpha: (color.a * 3.2).clamp(0.0, 0.8));
    final stroke = Paint()
      ..color = heroColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final glow = Paint()
      ..color = heroColor.withValues(alpha: heroColor.a * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6)
      ..isAntiAlias = true;

    final baseAlpha = color.a;

    // Lưới khay nuôi isometric (2 hàng so le), mỗi khay một con cua nhỏ.
    // Tọa độ theo tỉ lệ; các khay mờ dần về bên trái để không che chữ.
    const trayCenters = <List<double>>[
      // hàng trên
      [0.08, 0.10],
      [0.28, 0.00],
      [0.48, 0.08],
      [0.70, -0.02],
      [0.92, 0.08],
      // hàng dưới
      [0.16, 0.92],
      [0.38, 1.02],
      [0.62, 0.94],
      [0.86, 1.04],
    ];

    final trayS = trayExtent ?? size.height * 0.55;

    for (final t in trayCenters) {
      final fx = t[0];
      final c = Offset(size.width * fx, size.height * t[1]);
      final fade = (0.25 + 0.75 * fx).clamp(0.0, 1.0);
      final p = Paint()
        ..color = color.withValues(alpha: baseAlpha * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      _paintTray(canvas, c, trayS, p);
      _paintTopDownCrab(canvas, c, trayS * 0.42, p, p);
    }

    // Con cua lớn phát sáng giữa-phải + khay của nó (điểm nhấn)
    final hero = Offset(size.width * 0.66, size.height * 0.5);
    _paintTray(canvas, hero, trayS * 1.6, stroke);
    _paintTopDownCrab(canvas, hero, trayS * 0.95, stroke, glow);
  }

  /// Vẽ một khay nuôi isometric dạng wireframe: mặt trên hình thoi, vành
  /// trong và độ dày khay phía dưới.
  void _paintTray(Canvas canvas, Offset c, double s, Paint p) {
    final w = s;
    final h = s * 0.48;

    Path diamond(double dw, double dh) => Path()
      ..moveTo(c.dx, c.dy - dh)
      ..lineTo(c.dx + dw, c.dy)
      ..lineTo(c.dx, c.dy + dh)
      ..lineTo(c.dx - dw, c.dy)
      ..close();

    canvas.drawPath(diamond(w, h), p);
    // Vành trong của khay
    canvas.drawPath(diamond(w * 0.78, h * 0.78), p);

    // Độ dày khay (rim ngắn phía dưới)
    final d = h * 0.35;
    canvas.drawLine(
      Offset(c.dx - w, c.dy),
      Offset(c.dx - w, c.dy + d),
      p,
    );
    canvas.drawLine(
      Offset(c.dx + w, c.dy),
      Offset(c.dx + w, c.dy + d),
      p,
    );
    canvas.drawLine(
      Offset(c.dx - w, c.dy + d),
      Offset(c.dx, c.dy + h + d),
      p,
    );
    canvas.drawLine(
      Offset(c.dx, c.dy + h + d),
      Offset(c.dx + w, c.dy + d),
      p,
    );
  }

  void _paintTopDownCrab(
    Canvas canvas,
    Offset c,
    double s,
    Paint stroke,
    Paint glow,
  ) {
    // Chấm khớp co giãn theo kích thước cua
    final r = (s * 0.07).clamp(0.5, 1.5).toDouble();
    final shell = <Offset>[
      Offset(c.dx, c.dy - s * 0.32),
      Offset(c.dx + s * 0.28, c.dy - s * 0.18),
      Offset(c.dx + s * 0.42, c.dy),
      Offset(c.dx + s * 0.28, c.dy + s * 0.22),
      Offset(c.dx, c.dy + s * 0.35),
      Offset(c.dx - s * 0.28, c.dy + s * 0.22),
      Offset(c.dx - s * 0.42, c.dy),
      Offset(c.dx - s * 0.28, c.dy - s * 0.18),
    ];

    final shellPath = Path()..moveTo(shell[0].dx, shell[0].dy);
    for (var i = 1; i < shell.length; i++) {
      shellPath.lineTo(shell[i].dx, shell[i].dy);
    }
    shellPath.close();
    canvas.drawPath(shellPath, glow);
    canvas.drawPath(shellPath, stroke);
    canvas.drawLine(
      Offset(c.dx, c.dy - s * 0.28),
      Offset(c.dx, c.dy + s * 0.32),
      stroke,
    );
    canvas.drawLine(
      Offset(c.dx - s * 0.35, c.dy),
      Offset(c.dx + s * 0.35, c.dy),
      stroke,
    );

    // Mắt
    for (final side in [-1.0, 1.0]) {
      final tip = Offset(c.dx + side * s * 0.16, c.dy - s * 0.42);
      canvas.drawLine(
        Offset(c.dx + side * s * 0.12, c.dy - s * 0.22),
        tip,
        stroke,
      );
      _dot(canvas, tip, stroke, r);
    }

    // Càng
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(c.dx + side * s * 0.4, c.dy - s * 0.05);
      final elbow = Offset(c.dx + side * s * 0.72, c.dy - s * 0.28);
      final tipA = Offset(c.dx + side * s * 0.95, c.dy - s * 0.48);
      final tipB = Offset(c.dx + side * s * 0.88, c.dy - s * 0.18);
      canvas.drawLine(shoulder, elbow, glow);
      canvas.drawLine(shoulder, elbow, stroke);
      canvas.drawLine(elbow, tipA, stroke);
      canvas.drawLine(elbow, tipB, stroke);
      _dot(canvas, shoulder, stroke, r);
      _dot(canvas, elbow, stroke, r);
      _dot(canvas, tipA, stroke, r);
      _dot(canvas, tipB, stroke, r);
    }

    // Chân
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final base = Offset(
          c.dx + side * s * 0.38,
          c.dy + s * (-0.02 + i * 0.16),
        );
        final mid = Offset(
          c.dx + side * s * (0.7 + i * 0.04),
          c.dy + s * (0.12 + i * 0.14),
        );
        final tip = Offset(
          c.dx + side * s * (0.95 + i * 0.06),
          c.dy + s * (0.28 + i * 0.1),
        );
        canvas.drawLine(base, mid, stroke);
        canvas.drawLine(mid, tip, stroke);
        _dot(canvas, mid, stroke, r);
        _dot(canvas, tip, stroke, r);
      }
    }

    for (final p in shell) {
      _dot(canvas, p, stroke, r);
    }
    _dot(canvas, c, stroke, r);
  }

  void _dot(Canvas canvas, Offset p, Paint stroke, double r) {
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CrabHologramPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.trayExtent != trayExtent;
}
