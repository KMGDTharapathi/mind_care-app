import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'paint_models.dart';

class CanvasPainter extends CustomPainter {
  final ui.Image? mandala;
  final List<Stroke> strokes;
  final Stroke? current;
  final List<PlacedShape> shapes;
  final Color bgColor;
  final List<Color>? bgGradient;
  final BgType bgType;
  final Size renderSize;

  // Strokes are stored in canvas-space (0..800)
  static const double kCanvasW = 800, kCanvasH = 800;

  const CanvasPainter({
    required this.mandala,
    required this.strokes,
    required this.current,
    required this.shapes,
    required this.bgColor,
    this.bgGradient,
    required this.bgType,
    required this.renderSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    if (mandala != null) {
      canvas.drawImageRect(
        mandala!,
        Rect.fromLTWH(0, 0, kCanvasW, kCanvasH),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.high,
      );
    }

    // Scale factor: canvas-space → render-space
    final sx = size.width / kCanvasW;
    final sy = size.height / kCanvasH;

    for (final s in strokes) _drawStroke(canvas, s, sx, sy);
    if (current != null) _drawStroke(canvas, current!, sx, sy);
    for (final sh in shapes) _drawShape(canvas, sh);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (bgType == BgType.gradient && bgGradient != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: bgGradient!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
      );
    } else if (bgType == BgType.texture) {
      canvas.drawRect(rect, Paint()..color = Colors.white);
      final p = Paint()
        ..color = Colors.grey.withValues(alpha: 0.18)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      for (double x = 0; x < size.width; x += 18) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      }
      for (double y = 0; y < size.height; y += 18) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      }
    } else {
      canvas.drawRect(rect, Paint()..color = bgColor);
    }
  }

  void _drawStroke(Canvas canvas, Stroke s, double sx, double sy) {
    if (s.points.isEmpty) return;
    // Stroke points are in canvas-space; scale to render-space for drawing
    final scale = math.min(sx, sy);
    final w = s.size * scale;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    if (s.isEraser) {
      paint
        ..color = bgType == BgType.plain ? bgColor : Colors.white
        ..strokeWidth = w * 2.5
        ..blendMode = BlendMode.src;
    } else {
      switch (s.brush) {
        case BrushType.brush:
          paint.color = s.color.withValues(alpha: s.opacity);
        case BrushType.pencil:
          paint
            ..color = s.color.withValues(alpha: s.opacity * 0.8)
            ..strokeWidth = w * 0.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);
        case BrushType.marker:
          paint
            ..color = s.color.withValues(alpha: s.opacity * 0.6)
            ..strokeWidth = w * 2.4
            ..strokeCap = StrokeCap.square;
        case BrushType.watercolor:
          for (int i = 0; i < 3; i++) {
            canvas.drawPath(
              _buildPath(s.points, sx, sy),
              Paint()
                ..color = s.color.withValues(alpha: s.opacity * 0.1)
                ..strokeWidth = w * (1.5 + i * 0.8)
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke
                ..maskFilter =
                    MaskFilter.blur(BlurStyle.normal, 1.0 + i * 0.5),
            );
          }
          paint
            ..color = s.color.withValues(alpha: s.opacity * 0.3)
            ..strokeWidth = w * 0.6;
      }
    }

    if (s.points.length == 1) {
      canvas.drawCircle(
        Offset(s.points.first.dx * sx, s.points.first.dy * sy),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    canvas.drawPath(_buildPath(s.points, sx, sy), paint);
  }

  /// Build a smooth bezier path. Points are in canvas-space; scale to render.
  Path _buildPath(List<Offset> pts, double sx, double sy) {
    final path = Path()..moveTo(pts.first.dx * sx, pts.first.dy * sy);
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2 * sx,
        (pts[i].dy + pts[i + 1].dy) / 2 * sy,
      );
      path.quadraticBezierTo(
          pts[i].dx * sx, pts[i].dy * sy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx * sx, pts.last.dy * sy);
    return path;
  }

  // Shapes are stored in render-space — draw directly
  void _drawShape(Canvas canvas, PlacedShape sh) {
    final r = Rect.fromCenter(
        center: sh.position, width: sh.width, height: sh.height);
    final fill = Paint()..color = sh.color;
    final sel = Paint()
      ..color = const Color(0xFF2979FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (sh.kind) {
      case ShapeKind.circle:
        canvas.drawOval(r, fill);
        if (sh.selected) canvas.drawOval(r, sel);
      case ShapeKind.rect:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(4)), fill);
        if (sh.selected) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(r, const Radius.circular(4)), sel);
        }
      case ShapeKind.triangle:
        final p = Path()
          ..moveTo(sh.position.dx, sh.position.dy - sh.height / 2)
          ..lineTo(sh.position.dx + sh.width / 2, sh.position.dy + sh.height / 2)
          ..lineTo(sh.position.dx - sh.width / 2, sh.position.dy + sh.height / 2)
          ..close();
        canvas.drawPath(p, fill);
        if (sh.selected) canvas.drawPath(p, sel);
      case ShapeKind.star:
        final p = _starPath(sh.position, sh.width / 2);
        canvas.drawPath(p, fill);
        if (sh.selected) canvas.drawPath(p, sel);
      case ShapeKind.heart:
        final p = _heartPath(sh.position, sh.width);
        canvas.drawPath(p, fill);
        if (sh.selected) canvas.drawPath(p, sel);
      case ShapeKind.hexagon:
        final p = _hexPath(sh.position, sh.width / 2);
        canvas.drawPath(p, fill);
        if (sh.selected) canvas.drawPath(p, sel);
      case ShapeKind.arrow:
        final p = _arrowPath(sh.position, sh.width, sh.height);
        canvas.drawPath(p, fill);
        if (sh.selected) canvas.drawPath(p, sel);
      case ShapeKind.diamond:
        final p = Path()
          ..moveTo(sh.position.dx, sh.position.dy - sh.height / 2)
          ..lineTo(sh.position.dx + sh.width / 2, sh.position.dy)
          ..lineTo(sh.position.dx, sh.position.dy + sh.height / 2)
          ..lineTo(sh.position.dx - sh.width / 2, sh.position.dy)
          ..close();
        canvas.drawPath(p, fill);
        if (sh.selected) canvas.drawPath(p, sel);
    }

    if (sh.selected) {
      // Resize handle
      canvas.drawCircle(
        Offset(sh.position.dx + sh.width / 2, sh.position.dy + sh.height / 2),
        7,
        Paint()..color = const Color(0xFF2979FF),
      );
      canvas.drawCircle(
        Offset(sh.position.dx + sh.width / 2, sh.position.dy + sh.height / 2),
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  Path _starPath(Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? r : r * 0.42;
      final x = c.dx + radius * math.cos(angle);
      final y = c.dy + radius * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  Path _heartPath(Offset c, double w) {
    final s = w / 2;
    return Path()
      ..moveTo(c.dx, c.dy + s * 0.35)
      ..cubicTo(c.dx, c.dy - s * 0.5, c.dx - s, c.dy - s * 0.5, c.dx - s, c.dy)
      ..cubicTo(c.dx - s, c.dy + s * 0.6, c.dx, c.dy + s * 0.9, c.dx, c.dy + s)
      ..cubicTo(c.dx, c.dy + s * 0.9, c.dx + s, c.dy + s * 0.6, c.dx + s, c.dy)
      ..cubicTo(c.dx + s, c.dy - s * 0.5, c.dx, c.dy - s * 0.5, c.dx, c.dy + s * 0.35)
      ..close();
  }

  Path _hexPath(Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - math.pi / 6;
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  Path _arrowPath(Offset c, double w, double h) {
    final hw = w / 2, hh = h / 2, hw3 = w / 3, hh3 = h / 3;
    return Path()
      ..moveTo(c.dx - hw, c.dy - hh3)
      ..lineTo(c.dx, c.dy - hh)
      ..lineTo(c.dx + hw, c.dy - hh3)
      ..lineTo(c.dx + hw3, c.dy - hh3)
      ..lineTo(c.dx + hw3, c.dy + hh)
      ..lineTo(c.dx - hw3, c.dy + hh)
      ..lineTo(c.dx - hw3, c.dy - hh3)
      ..close();
  }

  @override
  bool shouldRepaint(CanvasPainter old) => true;
}
