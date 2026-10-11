import 'package:flutter/material.dart';

/// Wraps [child] in a [Stack] with semi-transparent decorative leaf shapes
/// painted behind it using a [CustomPainter].
class LeafBackground extends StatelessWidget {
  const LeafBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _LeafPainter()),
        child,
      ],
    );
  }
}

class _LeafPainter extends CustomPainter {
  // Each entry: (dx fraction, dy fraction, rotation radians, scale)
  static const _leaves = [
    (0.10, 0.08, -0.4, 1.0),
    (0.80, 0.05, 0.6, 0.8),
    (0.55, 0.20, 1.2, 0.7),
    (0.05, 0.45, -1.0, 0.9),
    (0.88, 0.38, 0.3, 1.1),
    (0.30, 0.72, -0.7, 0.85),
    (0.70, 0.80, 1.5, 0.75),
    (0.50, 0.92, -0.2, 0.95),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    for (final (fx, fy, rot, scale) in _leaves) {
      final cx = size.width * fx;
      final cy = size.height * fy;
      _drawLeaf(canvas, paint, Offset(cx, cy), rot, scale * 28);
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Paint paint,
    Offset center,
    double rotation,
    double size,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -size)
      ..cubicTo(size * 0.6, -size * 0.5, size * 0.6, size * 0.5, 0, size)
      ..cubicTo(-size * 0.6, size * 0.5, -size * 0.6, -size * 0.5, 0, -size)
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
